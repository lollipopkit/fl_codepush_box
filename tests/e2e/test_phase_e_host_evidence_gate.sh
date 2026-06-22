#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/check_phase_e_host_evidence.sh"
WORKDIR="$(mktemp -d /tmp/fcb_phase_e_host_evidence_gate_XXXXXX)"

. "$ROOT_DIR/scripts/fcb_vm_test_filters.sh"

cleanup() {
  if [ "${FCB_KEEP_PHASE_E_HOST_EVIDENCE_GATE_TEST:-0}" = "1" ]; then
    echo "keeping workdir: $WORKDIR" >&2
  else
    rm -rf "$WORKDIR"
  fi
}
trap cleanup EXIT

die() {
  echo "error: $*" >&2
  exit 1
}

require_line() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || die "$file missing: $pattern"
}

run_no_rebuild_canonical_dir_rejected() {
  local name="$1"
  local out_dir="${2:-}"
  local case_dir="$WORKDIR/$name"
  mkdir -p "$case_dir"

  set +e
  if [ -n "$out_dir" ]; then
    (
      cd "$ROOT_DIR"
      FCB_VENDOR_VM_REBUILD_RUNNERS=0 \
      FCB_VENDOR_VM_TEST_DIR="$out_dir" \
        "$ROOT_DIR/scripts/test_vendor_vm_runtime.sh"
    ) >"$case_dir/stdout.txt" 2>"$case_dir/stderr.txt"
  else
    (
      cd "$ROOT_DIR"
      FCB_VENDOR_VM_REBUILD_RUNNERS=0 \
        "$ROOT_DIR/scripts/test_vendor_vm_runtime.sh"
    ) >"$case_dir/stdout.txt" 2>"$case_dir/stderr.txt"
  fi
  local status=$?
  set -e

  [ "$status" -ne 0 ] || die "$name guard unexpectedly passed"
  require_line "$case_dir/stderr.txt" "refusing no-rebuild VM validation in canonical evidence dir"
}

write_valid_evidence() {
  local case_dir="$1"
  local vm_summary="$case_dir/vm-summary.txt"
  local kernel_summary="$case_dir/kernel-summary.txt"
  local sdk_log="$case_dir/sdk-delta-audit.log"
  local filter_dir="$case_dir/run-vm-tests"
  local filter

  mkdir -p "$filter_dir"
  {
    echo "vendor Dart SDK delta audit passed"
    echo "fcb_or_allowed_delta_count: 0"
  } >"$sdk_log"

  {
    echo "standalone FcbPatchRuntime passed"
    echo "sdk_delta_audit: $sdk_log"
    echo "run_vm_test_filter_logs: $filter_dir"
    echo "rebuild_run_vm_tests: 1"
    echo "debug_vm_test_filters: ${DEBUG_VM_TEST_FILTERS[*]}"
    echo "release_vm_test_filters: ${COMMON_VM_TEST_FILTERS[*]}"
  } >"$vm_summary"

  for filter in "${COMMON_VM_TEST_FILTERS[@]}"; do
    {
      echo "running release $filter"
      echo "Running test: $filter"
      echo "Done: $filter"
    } >"$filter_dir/release-$filter.log"
  done

  for filter in "${DEBUG_VM_TEST_FILTERS[@]}"; do
    {
      echo "running debug $filter"
      echo "Running test: $filter"
      echo "Done: $filter"
    } >"$filter_dir/debug-$filter.log"
  done

  {
    echo "kernel_compile_from_plan passed"
    echo "interpreted_count: 463"
    echo "reject_count: 2"
    echo "unchanged_count: 13"
    echo "module_function_count: 478"
    echo "binary_function_count: 478"
    echo "source_runtime_filters: FcbPatchRuntimeAsyncStarSourceModuleStreamListen FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor"
    echo "triple_nested_runtime_cases: normal cancel outer-error middle-error inner-error"
  } >"$kernel_summary"
}

run_host_gate() {
  local case_dir="$1"
  local expected_exit="$2"
  local expected_line="$3"
  local vm_summary="$case_dir/vm-summary.txt"
  local kernel_summary="$case_dir/kernel-summary.txt"

  set +e
  FCB_PHASE_E_VM_SUMMARY="$vm_summary" \
  FCB_PHASE_E_KERNEL_SUMMARY="$kernel_summary" \
    "$SCRIPT" >"$case_dir/stdout.txt" 2>"$case_dir/stderr.txt"
  local status=$?
  set -e

  if [ "$status" -ne "$expected_exit" ]; then
    echo "stdout:" >&2
    cat "$case_dir/stdout.txt" >&2 || true
    echo "stderr:" >&2
    cat "$case_dir/stderr.txt" >&2 || true
    die "$case_dir exited $status, expected $expected_exit"
  fi
  if [ "$expected_exit" -eq 0 ]; then
    require_line "$case_dir/stdout.txt" "$expected_line"
  else
    require_line "$case_dir/stderr.txt" "$expected_line"
  fi
}

case_dir="$WORKDIR/pass"
write_valid_evidence "$case_dir"
run_host_gate "$case_dir" 0 "Phase E host evidence check passed"

run_no_rebuild_canonical_dir_rejected no_rebuild_default_dir
run_no_rebuild_canonical_dir_rejected no_rebuild_relative_dir "target/fcb/vendor-vm-test/"
run_no_rebuild_canonical_dir_rejected no_rebuild_trailing_slash "$ROOT_DIR/target/fcb/vendor-vm-test/"

case_dir="$WORKDIR/missing_release_log"
write_valid_evidence "$case_dir"
rm "$case_dir/run-vm-tests/release-FcbPatchRuntimeGcStress.log"
run_host_gate "$case_dir" 1 "missing or empty evidence file:"

case_dir="$WORKDIR/missing_debug_done"
write_valid_evidence "$case_dir"
{
  echo "running debug FcbPatchDebuggerSourceBreakpointAndStepPause"
  echo "Running test: FcbPatchDebuggerSourceBreakpointAndStepPause"
} >"$case_dir/run-vm-tests/debug-FcbPatchDebuggerSourceBreakpointAndStepPause.log"
run_host_gate "$case_dir" 1 "missing evidence: Done: FcbPatchDebuggerSourceBreakpointAndStepPause"

case_dir="$WORKDIR/missing_summary_filter"
write_valid_evidence "$case_dir"
grep -Fv "release_vm_test_filters:" "$case_dir/vm-summary.txt" >"$case_dir/vm-summary-filtered.txt"
mv "$case_dir/vm-summary-filtered.txt" "$case_dir/vm-summary.txt"
run_host_gate "$case_dir" 1 "missing evidence: FcbPatchRuntimeMapCrossesDynamicCallBoundary"

echo "Phase E host evidence gate test passed"
echo "workdir: $WORKDIR"
