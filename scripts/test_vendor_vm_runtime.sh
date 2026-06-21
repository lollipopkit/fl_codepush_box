#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${FCB_VENDOR_SDK_DIR:-$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart}"
OUT_DIR="${FCB_VENDOR_VM_TEST_DIR:-$ROOT_DIR/target/fcb/vendor-vm-test}"
CXX_BIN="${CXX:-clang++}"
SDK_DELTA_AUDIT="${FCB_VENDOR_SDK_DELTA_AUDIT:-$ROOT_DIR/scripts/audit_vendor_dart_sdk_delta.sh}"
DEBUG_RUN_VM_TESTS="${FCB_VENDOR_VM_DEBUG_RUNNER:-$ROOT_DIR/vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests}"
RELEASE_RUN_VM_TESTS="${FCB_VENDOR_VM_RELEASE_RUNNER:-$ROOT_DIR/vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests}"
FCB_VENDOR_VM_REBUILD_RUNNERS="${FCB_VENDOR_VM_REBUILD_RUNNERS:-1}"
NINJA_BIN="${FCB_VENDOR_NINJA:-$ROOT_DIR/vendor/depot_tools/ninja}"
DEPOT_TOOLS_DIR="${FCB_VENDOR_DEPOT_TOOLS_DIR:-$ROOT_DIR/vendor/depot_tools}"
VPYTHON_ROOT="${VPYTHON_VIRTUALENV_ROOT:-$ROOT_DIR/target/fcb/vpython-root}"
RUN_VM_TEST_LOG_DIR="$OUT_DIR/run-vm-tests"
RUN_VM_TEST_REBUILD_LOG_DIR="$OUT_DIR/rebuild-run-vm-tests"

COMMON_VM_TEST_FILTERS=(
  FcbPatchRuntimeMapCrossesDynamicCallBoundary
  FcbPatchRuntimeListMaterializesAsDartArray
  FcbPatchRuntimeNewObjectFutureValue
  FcbPatchRuntimeAwaitCompletedFutureValue
  FcbPatchRuntimeAwaitCompletedFutureErrorCaught
  FcbPatchRuntimeAwaitChainedCompletedFutureValue
  FcbPatchRuntimeAwaitPendingFutureSuspendsAndResumes
  FcbPatchRuntimeDisablePatchDrainsSuspendedAwait
  FcbPatchRuntimeResumePatchErrorMarksBadPatch
  FcbPatchRuntimeResumeErrorCompletesWithoutBadPatch
  FcbPatchRuntimeClearDrainsSuspendedAwait
  FcbPatchRuntimeAwaitPendingFutureDrainsMicrotask
  FcbPatchRuntimeAwaitTwoPendingFuturesDrainsMicrotasks
  FcbPatchRuntimeAwaitPendingErrorCaughtFromMicrotask
  FcbPatchRuntimeAwaitPendingErrorCompletesFutureError
  FcbPatchRuntimeAwaitPendingFutureRunsFinally
  FcbPatchRuntimeAwaitPendingErrorRunsFinally
  FcbPatchRuntimeAsyncReturnCompletedFutureValue
  FcbPatchRuntimeAsyncReturnAdoptsFutureValue
  FcbPatchRuntimeAsyncReturnCompletedFutureNull
  FcbPatchRuntimeSyncStarYieldsValues
  FcbPatchRuntimeSyncStarReiterates
  FcbPatchRuntimeSyncStarAbandonedIterableFinalizer
  FcbPatchRuntimeSyncStarAbandonedIteratorFinalizer
  FcbPatchRuntimeClearDrainsSyncGenerators
  FcbPatchRuntimeAsyncStarReturnsStream
  FcbPatchRuntimeAsyncStarPendingAwaitResumes
  FcbPatchRuntimeAsyncStarPendingAwaitErrorAddsStreamError
  FcbPatchRuntimeAsyncStarBackpressureResumes
  FcbPatchRuntimeAsyncStarCancelRunsFinally
  FcbPatchRuntimeAsyncStarSourceModuleStreamListen
  FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor
  FcbPatchRuntimeBusinessStreamSourceE2e
  FcbPatchRuntimeAsyncStarPendingAwaitSurvivesGc
  FcbPatchRuntimeTryCatchesCallDynamicException
  FcbPatchRuntimeTryCatchesCallOriginalException
  FcbPatchRuntimeTryCatchesNewObjectException
  FcbPatchRuntimeTryCatchesCallClosureException
  FcbPatchRuntimeTryCatchesMakeClosureMissingTarget
  FcbPatchRuntimeTryCatchesAsTypeMismatch
  FcbPatchRuntimeTypeEnvironmentListT
  FcbPatchRuntimeGcStress
)

DEBUG_VM_TEST_FILTERS=(
  FcbPatchDebuggerCollectsActiveInterpreterFrame
  FcbPatchDebuggerCollectsAsyncResumeFrame
  FcbPatchDebuggerCollectsAsyncStarResumeFrame
  FcbPatchDebuggerAsyncStarErrorHasSourceStackFrame
  FcbPatchDebuggerExposesActiveHandlerMetadata
  FcbPatchDebuggerDoesNotTreatFinallyAsCatchHandler
  FcbPatchDebuggerFrameEvaluationUsesSourceLibrary
  FcbPatchDebuggerCollectsMaterializedClosureActiveFrame
  FcbPatchDebuggerSourceBreakpointAndStepPause
)

usage() {
  cat <<USAGE
Usage:
  $0

Builds and runs the vendor Dart SDK FCB VM runtime test and writes the evidence
summary consumed by make audit-plan-completion.

Environment:
  FCB_VENDOR_SDK_DIR       Dart SDK checkout. Default: vendor/flutter/engine/src/flutter/third_party/dart
  FCB_VENDOR_VM_TEST_DIR   Evidence output dir. Default: target/fcb/vendor-vm-test
  FCB_VENDOR_SDK_DELTA_AUDIT    SDK delta audit script.
  FCB_VENDOR_VM_DEBUG_RUNNER    Debug run_vm_tests binary.
  FCB_VENDOR_VM_RELEASE_RUNNER  Release run_vm_tests binary.
  FCB_VENDOR_VM_REBUILD_RUNNERS Rebuild run_vm_tests before running filters. Default: 1.
  FCB_VENDOR_NINJA              ninja binary. Default: vendor/depot_tools/ninja.
  FCB_VENDOR_DEPOT_TOOLS_DIR    depot_tools dir prepended to PATH for ninja actions.
  VPYTHON_VIRTUALENV_ROOT       vpython cache root. Default: target/fcb/vpython-root.
  CXX                       C++ compiler. Default: clang++
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

[ -d "$SDK_DIR" ] || die "missing Dart SDK checkout: $SDK_DIR"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_test.cc" ] || die "missing FCB VM runtime test source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime.cc" ] || die "missing FCB VM runtime source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_try_test.cc" ] || die "missing FCB VM runtime try test source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_async.cc" ] || die "missing FCB VM runtime async source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_closure.cc" ] || die "missing FCB VM runtime closure source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_generator.cc" ] || die "missing FCB VM runtime generator source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_deep_stream_test.cc" ] || die "missing FCB VM runtime deep stream test source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_suspend.cc" ] || die "missing FCB VM runtime suspend source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_vm.cc" ] || die "missing FCB VM runtime VM helper source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_value.cc" ] || die "missing FCB VM runtime value source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_loader.cc" ] || die "missing FCB VM runtime loader source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_loader_test.cc" ] || die "missing FCB VM runtime loader test source"
command -v "$CXX_BIN" >/dev/null 2>&1 || die "missing C++ compiler: $CXX_BIN"
if [ "$FCB_VENDOR_VM_REBUILD_RUNNERS" != "0" ]; then
  [ -x "$NINJA_BIN" ] || command -v "$NINJA_BIN" >/dev/null 2>&1 \
    || die "missing ninja: $NINJA_BIN"
fi

mkdir -p "$OUT_DIR" "$RUN_VM_TEST_LOG_DIR" "$RUN_VM_TEST_REBUILD_LOG_DIR"
LOG="$OUT_DIR/standalone-test.log"
SDK_DELTA_AUDIT_LOG="$OUT_DIR/sdk-delta-audit.log"
DEBUG_VM_LOG="$OUT_DIR/debug-run-vm-tests.log"
RELEASE_VM_LOG="$OUT_DIR/release-run-vm-tests.log"
BIN="$OUT_DIR/fcb_patch_runtime_test"
DART_COMMIT="$(git -C "$SDK_DIR" rev-parse HEAD)"

[ -x "$SDK_DELTA_AUDIT" ] || die "missing SDK delta audit script: $SDK_DELTA_AUDIT"
FCB_VENDOR_SDK_DIR="$SDK_DIR" "$SDK_DELTA_AUDIT" >"$SDK_DELTA_AUDIT_LOG" 2>&1 || {
  cat "$SDK_DELTA_AUDIT_LOG" >&2
  echo "vendor Dart SDK delta audit failed; log: $SDK_DELTA_AUDIT_LOG" >&2
  exit 1
}

"$CXX_BIN" \
  -std=c++20 \
  -DFCB_PATCH_RUNTIME_STANDALONE \
  -I "$SDK_DIR/runtime" \
  -I "$SDK_DIR/runtime/include" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_async.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_closure.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_generator.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_helpers.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_suspend.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_vm.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_value.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_loader.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_loader_test.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_test.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_try_test.cc" \
  -o "$BIN" >"$LOG" 2>&1 || {
  cat "$LOG" >&2
  echo "vendor VM runtime test build failed; log: $LOG" >&2
  exit 1
}

{
  echo "running standalone FcbPatchRuntime"
  "$BIN"
  echo "standalone FcbPatchRuntime passed"
} >>"$LOG" 2>&1 || {
  cat "$LOG" >&2
  echo "vendor VM runtime test failed; log: $LOG" >&2
  exit 1
}

rebuild_vm_runner() {
  local runner="$1"
  local label="$2"
  local build_dir
  local log="$RUN_VM_TEST_REBUILD_LOG_DIR/$label-run-vm-tests.log"
  if [ "$FCB_VENDOR_VM_REBUILD_RUNNERS" = "0" ]; then
    echo "skipped rebuild for $label run_vm_tests" >"$log"
    return
  fi
  build_dir="$(cd "$(dirname "$runner")" && pwd)"
  [ -f "$build_dir/build.ninja" ] || die "missing $label build.ninja: $build_dir/build.ninja"
  {
    echo "rebuilding $label run_vm_tests"
    echo "build_dir: $build_dir"
    echo "ninja: $NINJA_BIN"
    PATH="$DEPOT_TOOLS_DIR:$PATH" VPYTHON_VIRTUALENV_ROOT="$VPYTHON_ROOT" \
      "$NINJA_BIN" -C "$build_dir" run_vm_tests
    echo "rebuilt $label run_vm_tests"
  } >"$log" 2>&1 || {
    cat "$log" >&2
    echo "$label run_vm_tests rebuild failed; log: $log" >&2
    exit 1
  }
}

collect_vm_tests() {
  local runner="$1"
  local log="$2"
  local label="$3"
  [ -x "$runner" ] || die "missing $label run_vm_tests binary: $runner"
  "$runner" --list >"$log" 2>&1 || {
    cat "$log" >&2
    echo "$label run_vm_tests --list failed; log: $log" >&2
    exit 1
  }
  grep -Fq "FcbPatchRuntimeMapCrossesDynamicCallBoundary Pass" "$log" \
    || die "$label run_vm_tests list missing semantic map boundary test"
  grep -Fq "FcbPatchRuntimeListMaterializesAsDartArray Pass" "$log" \
    || die "$label run_vm_tests list missing semantic list materialization test"
  grep -Fq "FcbPatchRuntimeNewObjectFutureValue Pass" "$log" \
    || die "$label run_vm_tests list missing Future.value materialization test"
  grep -Fq "FcbPatchRuntimeTryCatchesCallDynamicException Pass" "$log" \
    || die "$label run_vm_tests list missing dynamic exception test"
  grep -Fq "FcbPatchRuntimeTryCatchesCallOriginalException Pass" "$log" \
    || die "$label run_vm_tests list missing call original exception test"
  grep -Fq "FcbPatchRuntimeTryCatchesNewObjectException Pass" "$log" \
    || die "$label run_vm_tests list missing new object exception test"
}

require_vm_test() {
  local list_log="$1"
  local label="$2"
  local filter="$3"
  grep -Fq "$filter Pass" "$list_log" || die "$label run_vm_tests list missing $filter"
}

run_vm_test_filter() {
  local runner="$1"
  local label="$2"
  local filter="$3"
  local log="$RUN_VM_TEST_LOG_DIR/$label-$filter.log"
  echo "running $label $filter" >>"$log"
  "$runner" "$filter" >>"$log" 2>&1 || {
    cat "$log" >&2
    echo "$label run_vm_tests $filter failed; log: $log" >&2
    exit 1
  }
  grep -Fq "Done:" "$log" || die "$label run_vm_tests $filter did not report completion"
}

run_vm_test_filters() {
  local runner="$1"
  local list_log="$2"
  local label="$3"
  shift 3
  local filter
  for filter in "$@"; do
    require_vm_test "$list_log" "$label" "$filter"
    run_vm_test_filter "$runner" "$label" "$filter"
  done
}

rebuild_vm_runner "$DEBUG_RUN_VM_TESTS" "debug"
rebuild_vm_runner "$RELEASE_RUN_VM_TESTS" "release"
collect_vm_tests "$DEBUG_RUN_VM_TESTS" "$DEBUG_VM_LOG" "debug"
grep -Fq "FcbPatchDebuggerCollectsActiveInterpreterFrame Pass" "$DEBUG_VM_LOG" \
  || die "debug run_vm_tests list missing active debugger frame test"
grep -Fq "FcbPatchDebuggerFrameEvaluationUsesSourceLibrary Pass" "$DEBUG_VM_LOG" \
  || die "debug run_vm_tests list missing debugger eval source library test"
grep -Fq "FcbPatchDebuggerCollectsMaterializedClosureActiveFrame Pass" "$DEBUG_VM_LOG" \
  || die "debug run_vm_tests list missing materialized closure debugger frame test"
run_vm_test_filters "$DEBUG_RUN_VM_TESTS" "$DEBUG_VM_LOG" "debug" "${DEBUG_VM_TEST_FILTERS[@]}"
collect_vm_tests "$RELEASE_RUN_VM_TESTS" "$RELEASE_VM_LOG" "release"
run_vm_test_filters "$RELEASE_RUN_VM_TESTS" "$RELEASE_VM_LOG" "release" "${COMMON_VM_TEST_FILTERS[@]}"

{
  echo "standalone FcbPatchRuntime passed"
  echo "sdk_dir: $SDK_DIR"
  echo "dart_commit: $DART_COMMIT"
  echo "standalone_tests: runtime/vm/fcb_patch_runtime_loader_test.cc runtime/vm/fcb_patch_runtime_test.cc runtime/vm/fcb_patch_runtime_try_test.cc"
  echo "sdk_delta_audit: $SDK_DELTA_AUDIT_LOG"
  echo "standalone_log: $LOG"
  echo "debug_vm_tests: $DEBUG_VM_LOG"
  echo "release_vm_tests: $RELEASE_VM_LOG"
  echo "run_vm_test_filter_logs: $RUN_VM_TEST_LOG_DIR"
  echo "run_vm_test_rebuild_logs: $RUN_VM_TEST_REBUILD_LOG_DIR"
  echo "rebuild_run_vm_tests: $FCB_VENDOR_VM_REBUILD_RUNNERS"
  echo "debug_vm_test_filters: ${DEBUG_VM_TEST_FILTERS[*]}"
  echo "release_vm_test_filters: ${COMMON_VM_TEST_FILTERS[*]}"
} >"$OUT_DIR/summary.txt"

echo "vendor VM runtime test passed: $OUT_DIR/summary.txt"
