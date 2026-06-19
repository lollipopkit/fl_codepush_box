#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${FCB_PLAN_AUDIT_DIR:-$ROOT_DIR/target/fcb/plan-completion-audit}"
SUMMARY="$OUT_DIR/summary.txt"
RUN_GITHUB_EVIDENCE="${FCB_PLAN_AUDIT_GITHUB_EVIDENCE:-1}"
GITHUB_EVIDENCE_BRANCH="${FCB_PLAN_AUDIT_GITHUB_BRANCH:-main}"
GITHUB_EVIDENCE_REPOSITORY="${FCB_PLAN_AUDIT_GITHUB_REPOSITORY:-$(git -C "$ROOT_DIR" config --get remote.origin.url | sed -E 's#^git@github.com:##; s#^https://github.com/##; s#\.git$##')}"
GITHUB_EXPECTED_HEAD_SHA="${FCB_PLAN_AUDIT_GITHUB_EXPECTED_SHA:-$(git -C "$ROOT_DIR" rev-parse HEAD)}"
GITHUB_MAX_MAIN_MINUTES="${FCB_PLAN_AUDIT_GITHUB_MAX_MAIN_MINUTES:-5.0}"
GITHUB_MAX_ANDROID_MINUTES="${FCB_PLAN_AUDIT_GITHUB_MAX_ANDROID_MINUTES:-60.0}"
GITHUB_MAX_IOS_MINUTES="${FCB_PLAN_AUDIT_GITHUB_MAX_IOS_MINUTES:-90.0}"
S3_SUMMARY="${FCB_PLAN_AUDIT_S3_SUMMARY:-$ROOT_DIR/target/fcb/s3-storage/summary.txt}"
EVIDENCE_ROOT="${FCB_PLAN_AUDIT_EVIDENCE_ROOT:-$ROOT_DIR/target/fcb/evidence}"
VM_PATCH_SUMMARY_OVERRIDE="${FCB_PLAN_AUDIT_VM_PATCH_SUMMARY:-}"
TESTFLIGHT_SUMMARY_OVERRIDE="${FCB_PLAN_AUDIT_TESTFLIGHT_SUMMARY:-}"
VENDOR_REBASE_SUMMARY_OVERRIDE="${FCB_PLAN_AUDIT_VENDOR_REBASE_SUMMARY:-}"

mkdir -p "$OUT_DIR"

failures=()
passes=()

pass() {
  passes+=("$1")
}

fail() {
  failures+=("$1")
}

has_file() {
  [ -f "$ROOT_DIR/$1" ]
}

has_glob() {
  local pattern="$1"
  compgen -G "$ROOT_DIR/$pattern" >/dev/null
}

latest_glob() {
  local pattern="$1"
  local file
  local latest=""
  for file in $ROOT_DIR/$pattern; do
    [ -e "$file" ] || continue
    if [ -z "$latest" ] || [ "$file" -nt "$latest" ]; then
      latest="$file"
    fi
  done
  echo "$latest"
}

latest_evidence_summary() {
  local prefix="$1"
  local file
  local latest=""
  for file in "$EVIDENCE_ROOT"/${prefix}_*/summary.txt; do
    [ -e "$file" ] || continue
    if [ -z "$latest" ] || [ "$file" -nt "$latest" ]; then
      latest="$file"
    fi
  done
  echo "$latest"
}

contains() {
  local file="$1"
  local pattern="$2"
  [ -f "$ROOT_DIR/$file" ] && grep -Fq "$pattern" "$ROOT_DIR/$file"
}

contains_any() {
  local pattern="$1"
  shift
  grep -Fq "$pattern" "$@" 2>/dev/null
}

remote_matches() {
  local path="$1"
  local expected="$2"
  local actual
  actual="$(git -C "$ROOT_DIR/$path" remote get-url origin 2>/dev/null || true)"
  [ "${actual%.git}" = "${expected%.git}" ]
}

summary_has_completion_marker() {
  local file="$1"
  local marker="$2"
  [ -f "$file" ] \
    && grep -Fq "$marker" "$file" \
    && ! grep -Fq "Manual Phase" "$file" \
    && ! grep -Fq "still required" "$file" \
    && ! grep -Fq "still needs" "$file"
}

summary_value() {
  local file="$1"
  local key="$2"
  awk -v key="$key" 'index($0, key ": ") == 1 { print substr($0, length(key) + 3); exit }' "$file"
}

summary_values_equal() {
  local file="$1"
  local left_key="$2"
  local right_key="$3"
  local left_value
  local right_value
  left_value="$(summary_value "$file" "$left_key")"
  right_value="$(summary_value "$file" "$right_key")"
  [ -n "$left_value" ] && [ "$left_value" = "$right_value" ]
}

archive_evidence_contains() {
  local summary="$1"
  local key="$2"
  local pattern="$3"
  local rel_path
  local evidence_path
  rel_path="$(summary_value "$summary" "$key")"
  [ -n "$rel_path" ] || return 1
  case "$rel_path" in
    /*|..|../*|*/../*) return 1 ;;
  esac
  evidence_path="$(dirname "$summary")/$rel_path"
  [ -f "$evidence_path" ] || return 1
  [ ! -L "$evidence_path" ] || return 1
  grep -Fq "$pattern" "$evidence_path" 2>/dev/null
}

archive_evidence_contains_summary_value() {
  local summary="$1"
  local key="$2"
  local value_key="$3"
  local value
  value="$(summary_value "$summary" "$value_key")"
  [ -n "$value" ] || return 1
  archive_evidence_contains "$summary" "$key" "$value"
}

archive_evidence_interpreter_ratio_below_one_percent() {
  local summary="$1"
  local key="$2"
  local rel_path
  local evidence_path
  local ratio
  rel_path="$(summary_value "$summary" "$key")"
  [ -n "$rel_path" ] || return 1
  case "$rel_path" in
    /*|..|../*|*/../*) return 1 ;;
  esac
  evidence_path="$(dirname "$summary")/$rel_path"
  [ -f "$evidence_path" ] || return 1
  [ ! -L "$evidence_path" ] || return 1
  ratio="$(grep -Eo '"interpreter_ratio"[[:space:]]*:[[:space:]]*[0-9]+(\.[0-9]+)?' "$evidence_path" \
    | head -1 \
    | sed -E 's/.*:[[:space:]]*//')"
  [ -n "$ratio" ] || return 1
  awk -v ratio="$ratio" 'BEGIN { exit !(ratio >= 0 && ratio < 0.01) }'
}

github_actions_run_line_passed() {
  local file="$1"
  local workflow="$2"
  local event="$3"
  local expected_sha="${4:-}"
  local escaped_workflow
  local escaped_repository
  local sha_pattern="([0-9a-f]{12,40}|unknown)"
  if [ -n "$expected_sha" ]; then
    sha_pattern="$expected_sha"
  fi
  escaped_workflow="$(printf '%s' "$workflow" | sed 's/[][\\.^$*+?{}()|]/\\&/g')"
  escaped_repository="$(printf '%s' "$GITHUB_EVIDENCE_REPOSITORY" | sed 's/[][\\.^$*+?{}()|]/\\&/g')"
  [ -n "$escaped_repository" ] || return 1
  grep -Eq "^- ${escaped_workflow} \\[${event}\\]: run #[0-9]+ sha ${sha_pattern} ([0-9]+\\.[0-9]m|unknown) https://github\\.com/${escaped_repository}/actions/runs/[0-9]+$" "$file"
}

github_actions_summary_passed() {
  local file="$1"
  local push_head_sha
  local push_head_short
  [ -f "$file" ] || return 1
  grep -Fq "status: passed" "$file" || return 1
  grep -Fxq "branch: $GITHUB_EVIDENCE_BRANCH" "$file" || return 1
  grep -Fxq "expected_head_sha: $GITHUB_EXPECTED_HEAD_SHA" "$file" || return 1
  grep -Fxq "max_main_minutes: $GITHUB_MAX_MAIN_MINUTES" "$file" || return 1
  grep -Fxq "max_android_minutes: $GITHUB_MAX_ANDROID_MINUTES" "$file" || return 1
  grep -Fxq "max_ios_minutes: $GITHUB_MAX_IOS_MINUTES" "$file" || return 1
  grep -Eq '^push_head_sha: [0-9a-f]{40}$' "$file" || return 1
  push_head_sha="$(summary_value "$file" "push_head_sha")"
  [ "$push_head_sha" = "$GITHUB_EXPECTED_HEAD_SHA" ] || return 1
  push_head_short="${push_head_sha:0:12}"
  github_actions_run_line_passed "$file" "Workflow Lint" "push" "$push_head_short" || return 1
  github_actions_run_line_passed "$file" "Rust" "push" "$push_head_short" || return 1
  github_actions_run_line_passed "$file" "Server" "push" "$push_head_short" || return 1
  github_actions_run_line_passed "$file" "E2E x64" "push" "$push_head_short" || return 1
  github_actions_run_line_passed "$file" "Flutter Package" "push" "$push_head_short" || return 1
  github_actions_run_line_passed "$file" "Android Emulator Nightly" "schedule" || return 1
  github_actions_run_line_passed "$file" "iOS Simulator Nightly" "schedule" || return 1
  github_actions_run_line_passed "$file" "Server S3 Storage" "schedule" || return 1
}

vm_patch_summary_passed() {
  local summary="$1"
  summary_has_completion_marker "$summary" "Counter app real VM patch passed" || return 1
  grep -Fq "status: passed" "$summary" || return 1
  grep -Eq '^platform: [^[:space:]]+$' "$summary" || return 1
  grep -Eq '^patch_number: [^[:space:]]+$' "$summary" || return 1
  grep -Fq "scenario: widget_tree_setState_method_channel" "$summary" || return 1
  archive_evidence_contains "$summary" "baseline_evidence" "baseline counter_app release rendered" || return 1
  archive_evidence_contains "$summary" "patched_ui_evidence" "patched widget tree" || return 1
  archive_evidence_contains "$summary" "patched_ui_evidence" "setState" || return 1
  archive_evidence_contains "$summary" "patched_ui_evidence" "method channel" || return 1
  archive_evidence_contains "$summary" "restart_evidence" "restart kept patch active" || return 1
  archive_evidence_contains "$summary" "vm_log_evidence" "FCB VM interpreter executed patch function" || return 1
  archive_evidence_contains "$summary" "payload_inspect_evidence" "FCBM" || return 1
  archive_evidence_contains "$summary" "payload_inspect_evidence" "source_map" || return 1
  archive_evidence_contains "$summary" "payload_inspect_evidence" "uses_call_static" || return 1
  archive_evidence_contains "$summary" "payload_inspect_evidence" "uses_get_field" || return 1
  archive_evidence_contains "$summary" "payload_inspect_evidence" "true" || return 1
  archive_evidence_contains "$summary" "server_events_evidence" "launch_success" || return 1
  archive_evidence_contains "$summary" "server_events_evidence" "interpreter_ratio" || return 1
  archive_evidence_interpreter_ratio_below_one_percent "$summary" "server_events_evidence" || return 1
}

arm64_summary_passed() {
  local summary="$1"
  summary_has_completion_marker "$summary" "H3 Android arm64 drill passed" || return 1
  archive_evidence_contains "$summary" "crash_rollback_evidence" "rolled back to LKG" || return 1
  archive_evidence_contains "$summary" "server_events_evidence" "crash_rollback" || return 1
}

ios_device_summary_passed() {
  local summary="$1"
  summary_has_completion_marker "$summary" "H4 iPhone device drill passed" || return 1
  archive_evidence_contains "$summary" "device_evidence" "iPhone baseline patched restart passed" || return 1
  archive_evidence_contains "$summary" "server_events_evidence" "launch_success" || return 1
}

testflight_summary_passed() {
  local summary="$1"
  summary_has_completion_marker "$summary" "TestFlight External Testing entered" || return 1
  grep -Eq '^bundle_id: [^[:space:]]+$' "$summary" || return 1
  grep -Eq '^build_number: [^[:space:]]+$' "$summary" || return 1
  grep -Fq "status: External Testing" "$summary" || return 1
  archive_evidence_contains "$summary" "external_testing_evidence" "External Testing" || return 1
  archive_evidence_contains_summary_value "$summary" "external_testing_evidence" "bundle_id" || return 1
  archive_evidence_contains_summary_value "$summary" "external_testing_evidence" "build_number" || return 1
  local upload_path
  upload_path="$(summary_value "$summary" "upload_evidence")"
  if [ -n "$upload_path" ]; then
    archive_evidence_contains "$summary" "upload_evidence" "accepted" || return 1
    archive_evidence_contains_summary_value "$summary" "upload_evidence" "build_number" || return 1
  fi
}

rebase_summary_passed() {
  local summary="$1"
  summary_has_completion_marker "$summary" "Vendor rebase validation passed" || return 1
  grep -Fq "status: passed" "$summary" || return 1
  grep -Eq '^source_ref: [^[:space:]]+$' "$summary" || return 1
  grep -Eq '^target_ref: [^[:space:]]+$' "$summary" || return 1
  grep -Eq '^flutter_commit: [0-9a-f]{7,40}$' "$summary" || return 1
  grep -Eq '^dart_commit: [0-9a-f]{7,40}$' "$summary" || return 1
  archive_evidence_contains "$summary" "rebase_log" "replayed FCB hook commits" || return 1
  archive_evidence_contains_summary_value "$summary" "rebase_log" "source_ref" || return 1
  archive_evidence_contains_summary_value "$summary" "rebase_log" "target_ref" || return 1
  archive_evidence_contains_summary_value "$summary" "rebase_log" "flutter_commit" || return 1
  archive_evidence_contains_summary_value "$summary" "rebase_log" "dart_commit" || return 1
  archive_evidence_contains "$summary" "engine_build_evidence" "engine build passed" || return 1
  archive_evidence_contains_summary_value "$summary" "engine_build_evidence" "flutter_commit" || return 1
  archive_evidence_contains "$summary" "cargo_test_evidence" "cargo test --workspace passed" || return 1
  archive_evidence_contains "$summary" "e2e_x64_evidence" "e2e_x64 passed" || return 1
  archive_evidence_contains "$summary" "arm64_drill_evidence" "arm64 drill passed" || return 1
}

rebase_doc_passed() {
  local file="$ROOT_DIR/vendor/REBASE.md"
  [ -f "$file" ] || return 1
  grep -Fq "quarterly" "$file" || grep -Fq "每季度" "$file" || return 1
  grep -Fq "Flutter stable" "$file" || return 1
  grep -Fq "cherry-pick" "$file" || return 1
  grep -Fq "FCB hook" "$file" || return 1
  grep -Fq "stub_code_compiler" "$file" || return 1
  grep -Fq "rollback" "$file" || grep -Fq "回滚" "$file" || return 1
  grep -Fq "record-vendor-rebase-evidence" "$file" || return 1
  grep -Fq "Vendor rebase validation passed" "$file" || return 1
}

audit_h1_vendor_checkouts() {
  local missing=0
  for path in vendor/flutter vendor/depot_tools; do
    if [ ! -d "$ROOT_DIR/$path/.git" ]; then
      fail "H1 vendor checkouts: $path is missing or is not a git checkout"
      missing=1
    fi
  done
  if [ -e "$ROOT_DIR/vendor/dart" ]; then
    fail "H1 vendor checkouts: top-level vendor/dart must not exist"
    missing=1
  fi
  if ! remote_matches "vendor/flutter" "https://github.com/lollipopkit/flutter.git"; then
    fail "H1 vendor checkouts: vendor/flutter remote is not lollipopkit/flutter"
    missing=1
  fi
  if ! contains "vendor/flutter/engine/src/flutter/DEPS" "'fcb_dart_sdk_git': 'https://github.com/lollipopkit/dartsdk'"; then
    fail "H1 vendor checkouts: Engine DEPS does not point embedded Dart at lollipopkit/dartsdk"
    missing=1
  fi
  if ! remote_matches "vendor/depot_tools" "https://chromium.googlesource.com/chromium/tools/depot_tools.git"; then
    fail "H1 vendor checkouts: vendor/depot_tools remote is not chromium depot_tools"
    missing=1
  fi
  if [ "$missing" = "0" ]; then
    pass "H1 vendor checkouts: local checkouts, remotes, and embedded Dart DEPS pin present"
  fi
}

audit_h2_ci_evidence() {
  if [ "$RUN_GITHUB_EVIDENCE" = "1" ]; then
    if FCB_CI_EVIDENCE_BRANCH="$GITHUB_EVIDENCE_BRANCH" \
      FCB_CI_EVIDENCE_EXPECTED_SHA="$GITHUB_EXPECTED_HEAD_SHA" \
      FCB_CI_EVIDENCE_MAX_MAIN_MINUTES="$GITHUB_MAX_MAIN_MINUTES" \
      FCB_CI_EVIDENCE_MAX_ANDROID_MINUTES="$GITHUB_MAX_ANDROID_MINUTES" \
      FCB_CI_EVIDENCE_MAX_IOS_MINUTES="$GITHUB_MAX_IOS_MINUTES" \
      "$ROOT_DIR/scripts/check_github_actions_evidence.sh" >"$OUT_DIR/github-actions-evidence.log" 2>&1; then
      pass "H2 GitHub Actions: remote evidence gate passed"
      return
    fi
    fail "H2 GitHub Actions: remote evidence gate failed; run make check-github-actions-evidence after workflows are pushed"
    return
  fi

  local evidence="$ROOT_DIR/target/fcb/github-actions-evidence/summary.txt"
  if github_actions_summary_passed "$evidence"; then
    pass "H2 GitHub Actions: cached evidence summary passed in explicit offline mode"
  else
    fail "H2 GitHub Actions: no passing cached evidence summary in explicit offline mode"
  fi
}

audit_evidence_hygiene() {
  local pattern
  local found=0
  for pattern in \
    "$ROOT_DIR"/tests/e2e/arm64_drill_* \
    "$ROOT_DIR"/tests/e2e/ios_drill_* \
    "$ROOT_DIR"/tests/e2e/testflight_* \
    "$ROOT_DIR"/tests/e2e/vendor_rebase_* \
    "$ROOT_DIR"/tests/e2e/vm_patch_*; do
    if [ -e "$pattern" ]; then
      fail "Evidence hygiene: generated evidence must not live under tests/e2e"
      found=1
      break
    fi
  done
  if [ "$found" = "0" ]; then
    pass "Evidence hygiene: tests/e2e contains no generated evidence archives"
  fi
}

audit_e_vm() {
  if has_file "vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.cc" \
    && has_file "vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_entry.cc" \
    && has_file "vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_test.cc"; then
    pass "E vendor VM skeleton source: expected FCB runtime files exist"
  else
    fail "E vendor VM skeleton source: expected fcb_patch_runtime/entry/test files are missing"
  fi

  local runtime_h="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.h"
  local runtime_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.cc"
  local runtime_vm_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_vm.cc"
  local runtime_value_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_value.cc"
  local runtime_loader_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_loader.cc"
  local runtime_semantics_test_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_semantics_test.cc"
  local runtime_test_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_test.cc"
  local runtime_call_dynamic_test_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_call_dynamic_test.cc"
  local runtime_call_original_test_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_call_original_test.cc"
  local runtime_debugger_test_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_debugger_test.cc"
  local runtime_new_object_test_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_new_object_test.cc"
  local runtime_try_test_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_try_test.cc"
  local entry_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_entry.cc"
  local object_cc="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/object.cc"
  local async_expr="$ROOT_DIR/tool/fcb_kernel_async_expr.dart"
  local kernel_compile_test="$ROOT_DIR/tests/e2e/test_kernel_compile_from_plan.sh"

  if [ -f "$runtime_h" ] \
    && ! grep -Fq "header-only with no VM object dependencies" "$runtime_h" \
    && ! grep -Fq "plain byte vectors" "$runtime_h" \
    && grep -Fq "ObjectPtr object_value" "$runtime_h" \
    && grep -Fq "VisitObjectPointers(ObjectPointerVisitor" "$runtime_h" \
    && grep -Fq "visitor->VisitPointer(&object_value)" "$runtime_value_cc" \
    && grep -Fq "Value Value::FromDart(ObjectPtr value)" "$runtime_value_cc" \
    && grep -Fq "ObjectPtr Value::ToDart()" "$runtime_value_cc" \
    && grep -Fq "out_value->object_value = object.ptr()" "$entry_cc" \
    && grep -Fq "*out_object = value.object_value" "$entry_cc"; then
    pass "E ObjectPtr integration: runtime Value/module directly uses Dart VM objects"
  else
    fail "E ObjectPtr integration: fcb_patch_runtime still looks like plain Value skeleton"
  fi

  if [ -f "$runtime_cc" ] \
    && contains_any "FCBM" "$runtime_cc" "$runtime_loader_cc" \
    && contains_any "source_map" "$runtime_h" "$runtime_cc" "$runtime_loader_cc"; then
    pass "E binary/source map reader: vendor VM consumes FCBM and source maps"
  else
    fail "E binary/source map reader: vendor VM does not yet consume binary FCBM/source maps"
  fi

  if [ -f "$runtime_cc" ] \
    && contains_any "CallStatic" "$runtime_cc" "$runtime_h" \
    && contains_any "DartEntry::InvokeFunction" "$runtime_cc" "$runtime_vm_cc" "$entry_cc"; then
    pass "E opcode dispatch: call_static reaches DartEntry from the runtime"
  else
    fail "E opcode dispatch: missing real call_static runtime dispatch"
  fi

  if [ -f "$runtime_cc" ] \
    && contains_any "fcb_report_interpret_failure" "$runtime_cc" "$entry_cc" \
    && contains_any "PatchState::kDisabledBadPatch" "$runtime_cc" "$entry_cc"; then
    pass "E fallback: interpreter failures disable bad patch and report rollback"
  else
    fail "E fallback: vendor VM does not yet report interpret failures into updater rollback"
  fi

  if [ -f "$object_cc" ] \
    && contains_any "LastPatchStackTraceLocation" "$object_cc" "$runtime_vm_cc" \
    && contains_any "FcbPatchRuntimeStackTraceSourceLocation" "$runtime_test_cc"; then
    pass "E stack trace: vendor VM injects patch source locations"
  else
    fail "E stack trace: missing patch source location injection"
  fi

  if [ -f "$entry_cc" ] \
    && contains_any "fcb_record_interpreter_call" "$entry_cc" \
    && contains_any "fcb_record_aot_call" "$entry_cc" \
    && contains_any "fcb_get_interpreter_stats" "$ROOT_DIR/updater/src/lib.rs" \
    && contains_any "interpreted_function_calls" "$ROOT_DIR/updater/src/lib.rs" \
    && contains_any "aot_function_calls" "$ROOT_DIR/updater/src/lib.rs"; then
    pass "E interpreter stats: vendor VM records interpreted/AOT counters"
  else
    fail "E interpreter stats: missing real VM interpreted/AOT counters"
  fi

  local evidence="$ROOT_DIR/target/fcb/vendor-vm-test/summary.txt"
  local vendor_vm_log="$ROOT_DIR/target/fcb/vendor-vm-test/standalone-test.log"
  local debug_vm_tests_log="$ROOT_DIR/target/fcb/vendor-vm-test/debug-run-vm-tests.log"
  local release_vm_tests_log="$ROOT_DIR/target/fcb/vendor-vm-test/release-run-vm-tests.log"
  if [ -f "$evidence" ] \
    && grep -Fq "standalone FcbPatchRuntime passed" "$evidence" \
    && grep -Eq '^dart_commit: [0-9a-f]{40}$' "$evidence" \
    && grep -Fq "standalone_tests: runtime/vm/fcb_patch_runtime_loader_test.cc runtime/vm/fcb_patch_runtime_test.cc runtime/vm/fcb_patch_runtime_try_test.cc" "$evidence" \
    && grep -Fq "standalone_log: $vendor_vm_log" "$evidence" \
    && grep -Fq "debug_vm_tests: $debug_vm_tests_log" "$evidence" \
    && grep -Fq "release_vm_tests: $release_vm_tests_log" "$evidence" \
    && grep -Fq "standalone FcbPatchRuntime passed" "$vendor_vm_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeMapCrossesDynamicCallBoundary Pass" "$debug_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeListMaterializesAsDartArray Pass" "$debug_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeNewObjectFutureValue Pass" "$debug_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeTryCatchesCallDynamicException Pass" "$debug_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeTryCatchesCallOriginalException Pass" "$debug_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeTryCatchesNewObjectException Pass" "$debug_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchDebuggerCollectsActiveInterpreterFrame Pass" "$debug_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchDebuggerFrameEvaluationUsesSourceLibrary Pass" "$debug_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchDebuggerCollectsMaterializedClosureActiveFrame Pass" "$debug_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeMapCrossesDynamicCallBoundary Pass" "$release_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeListMaterializesAsDartArray Pass" "$release_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeNewObjectFutureValue Pass" "$release_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeTryCatchesCallDynamicException Pass" "$release_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeTryCatchesCallOriginalException Pass" "$release_vm_tests_log" 2>/dev/null \
    && grep -Fq "FcbPatchRuntimeTryCatchesNewObjectException Pass" "$release_vm_tests_log" 2>/dev/null; then
    pass "E vendor VM tests: standalone and debug/release FCB VM test evidence present"
  else
    fail "E vendor VM tests: missing complete standalone or run_vm_tests FCB evidence"
  fi

  if [ -f "$runtime_semantics_test_cc" ] \
    && grep -Fq "FcbPatchRuntimeMapCrossesDynamicCallBoundary" "$runtime_semantics_test_cc" \
    && grep -Fq "FcbPatchRuntimeListMaterializesAsDartArray" "$runtime_semantics_test_cc" \
    && contains "vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/vm_sources.gni" "fcb_patch_runtime_semantics_test.cc"; then
    pass "E semantic regression tests: ObjectPtr materialization crosses Dart boundaries"
  else
    fail "E semantic regression tests: missing ObjectPtr materialization boundary coverage"
  fi

  if [ -f "$async_expr" ] \
    && [ -f "$runtime_new_object_test_cc" ] \
    && grep -Fq "_asyncFutureValueSource" "$async_expr" \
    && grep -Fq "_awaitedImmediateFutureValueExpr" "$async_expr" \
    && grep -Fq "AsyncAwaitUnsupported" "$ROOT_DIR/crates/fcb_core/src/linker.rs" \
    && grep -Fq "FcbPatchRuntimeNewObjectFutureValue" "$runtime_new_object_test_cc" \
    && grep -Fq "asyncLabel should now be supported" "$kernel_compile_test" \
    && grep -Fq "awaitedLabel" "$kernel_compile_test" \
    && grep -Fq "awaitedLocalLabel" "$kernel_compile_test"; then
    pass "E async tests: immediate Future.value async/await lowering covered"
  else
    fail "E async tests: missing immediate Future.value async/await coverage"
  fi

  if [ -f "$runtime_try_test_cc" ] \
    && [ -f "$runtime_call_dynamic_test_cc" ] \
    && [ -f "$runtime_call_original_test_cc" ] \
    && [ -f "$runtime_new_object_test_cc" ] \
    && grep -Fq "CatchesCallStaticThrow" "$runtime_try_test_cc" \
    && grep -Fq "FcbPatchRuntimeTryCatchesCallDynamicException" "$runtime_call_dynamic_test_cc" \
    && grep -Fq "FcbPatchRuntimeTryCatchesCallOriginalException" "$runtime_call_original_test_cc" \
    && grep -Fq "FcbPatchRuntimeTryCatchesNewObjectException" "$runtime_new_object_test_cc"; then
    pass "E exception tests: interpreted and Dart call exceptions are catchable"
  else
    fail "E exception tests: missing interpreted/Dart call exception coverage"
  fi

  if [ -f "$runtime_debugger_test_cc" ] \
    && grep -Fq "FcbPatchDebuggerFrameEvaluationUsesSourceLibrary" "$runtime_debugger_test_cc" \
    && grep -Fq "FcbPatchDebuggerCollectsActiveInterpreterFrame" "$runtime_debugger_test_cc" \
    && grep -Fq "FcbPatchDebuggerExposesActiveHandlerMetadata" "$runtime_debugger_test_cc" \
    && grep -Fq "FcbPatchDebuggerCollectsMaterializedClosureActiveFrame" "$runtime_debugger_test_cc"; then
    pass "E debugger tests: active frame, handler, closure, and eval coverage present"
  else
    fail "E debugger tests: missing active frame/eval coverage"
  fi

  local vm_patch_summary
  if [ -n "$VM_PATCH_SUMMARY_OVERRIDE" ]; then
    vm_patch_summary="$VM_PATCH_SUMMARY_OVERRIDE"
  else
    vm_patch_summary="$(latest_evidence_summary "vm_patch")"
  fi
  if vm_patch_summary_passed "$vm_patch_summary"; then
    pass "E end-to-end VM patch: counter_app real VM patch evidence passed"
  else
    fail "E end-to-end VM patch: missing evidence with marker 'Counter app real VM patch passed'"
  fi
}

audit_f_g_local_gates() {
  local local_ci="$ROOT_DIR/target/fcb/local-ci-core/summary.txt"
  local missing_local_step=0
  if [ -f "$local_ci" ] && grep -Fq "FCB local core CI passed" "$local_ci"; then
    for step in \
      check-workflows \
      github-actions-inventory \
      cargo-fmt \
      cargo-clippy \
      cargo-test \
      crash-rollback \
      phase-h-runbooks \
      server-vet \
      server-test \
      webui-check \
      webui-build \
      admin-runtime \
      backup-restore \
      kernel-compile \
      build-cli \
      build-server \
      fake-flutter-e2e \
      flutter-package; do
      if ! grep -Fq -- "- $step" "$local_ci"; then
        fail "F/G local gates: local core CI summary missing step $step"
        missing_local_step=1
      elif ! grep -Fq "step passed: $step" "$ROOT_DIR/target/fcb/local-ci-core/$step.log" 2>/dev/null; then
        fail "F/G local gates: local core CI pass marker missing for $step"
        missing_local_step=1
      fi
    done
  else
    fail "F/G local gates: missing passing target/fcb/local-ci-core/summary.txt"
    missing_local_step=1
  fi
  if [ "$missing_local_step" = "0" ]; then
    pass "F/G local gates: local core CI summary passed"
  fi

  local s3="$S3_SUMMARY"
  if [ -f "$s3" ] \
    && grep -Fq "S3 storage drill passed" "$s3" \
    && grep -Fq "bucket: fcb-payloads" "$s3" \
    && grep -Fq "key: patches/s3-drill-app/1.0.0+1/android/arm64-v8a/1/payload.bin" "$s3" \
    && grep -Eq '^hash: [0-9a-f]{64}$' "$s3" \
    && grep -Eq '^downloaded_hash: [0-9a-f]{64}$' "$s3" \
    && summary_values_equal "$s3" "hash" "downloaded_hash" \
    && grep -Fq "payload_url_has_signature: 1" "$s3" \
    && grep -Fq "object_stat: passed" "$s3"; then
    pass "F S3 drill: summary passed"
  else
    fail "F S3 drill: missing complete passing S3 storage drill summary"
  fi
}

audit_h3_h4_devices() {
  local arm64_summary
  arm64_summary="$(latest_evidence_summary "arm64_drill")"
  if arm64_summary_passed "$arm64_summary"; then
    pass "H3 Android arm64: full drill evidence passed"
  else
    fail "H3 Android arm64: missing full drill evidence with marker 'H3 Android arm64 drill passed'"
  fi

  local ios_summary
  ios_summary="$(latest_evidence_summary "ios_drill")"
  if ios_device_summary_passed "$ios_summary"; then
    pass "H4 iOS: iPhone device evidence passed"
  else
    fail "H4 iOS: missing device evidence with marker 'H4 iPhone device drill passed'"
  fi

  local testflight_summary
  if [ -n "$TESTFLIGHT_SUMMARY_OVERRIDE" ]; then
    testflight_summary="$TESTFLIGHT_SUMMARY_OVERRIDE"
  else
    testflight_summary="$(latest_evidence_summary "testflight")"
  fi
  if testflight_summary_passed "$testflight_summary"; then
    pass "H4 TestFlight: External Testing evidence passed"
  else
    fail "H4 TestFlight: missing evidence with marker 'TestFlight External Testing entered'"
  fi
}

audit_h5_rebase() {
  if rebase_doc_passed; then
    pass "H5 vendor rebase: vendor/REBASE.md runbook passed"
  elif has_file "vendor/REBASE.md"; then
    fail "H5 vendor rebase: vendor/REBASE.md is missing required runbook content"
  else
    fail "H5 vendor rebase: vendor/REBASE.md missing"
  fi

  local rebase_summary
  if [ -n "$VENDOR_REBASE_SUMMARY_OVERRIDE" ]; then
    rebase_summary="$VENDOR_REBASE_SUMMARY_OVERRIDE"
  else
    rebase_summary="$(latest_evidence_summary "vendor_rebase")"
  fi
  if rebase_summary_passed "$rebase_summary"; then
    pass "H5 vendor rebase: first real rebase evidence passed"
  else
    fail "H5 vendor rebase: missing evidence with marker 'Vendor rebase validation passed'"
  fi
}

audit_h1_vendor_checkouts
audit_h2_ci_evidence
audit_evidence_hygiene
audit_e_vm
audit_f_g_local_gates
audit_h3_h4_devices
audit_h5_rebase

{
  echo "FCB plan completion audit"
  echo "out_dir: $OUT_DIR"
  echo
  echo "passed:"
  for item in "${passes[@]}"; do
    echo "- $item"
  done
  echo
  echo "missing:"
  for item in "${failures[@]}"; do
    echo "- $item"
  done
} >"$SUMMARY"

echo "Plan completion audit summary: $SUMMARY"
if [ "${#failures[@]}" -gt 0 ]; then
  exit 1
fi
