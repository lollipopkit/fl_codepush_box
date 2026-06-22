#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_SUMMARY="${FCB_PHASE_E_VM_SUMMARY:-$ROOT_DIR/target/fcb/vendor-vm-test/summary.txt}"
KERNEL_SUMMARY="${FCB_PHASE_E_KERNEL_SUMMARY:-$ROOT_DIR/target/fcb/kernel-compile-from-plan/summary.txt}"

. "$ROOT_DIR/scripts/fcb_vm_test_filters.sh"

usage() {
  cat <<USAGE
Usage:
  $0

Checks the host-side Phase E evidence that does not require a real Android
device or a complete macOS Metal Toolchain:
  - vendor Dart SDK delta + VM runtime gate summary with rebuild_run_vm_tests: 1
  - every release/debug VM filter from scripts/fcb_vm_test_filters.sh
    listed in the VM summary and completed in its run_vm_tests log
  - Kernel compile-from-plan summary
  - Kernel compile-from-plan fixture/check file size gate

Regression coverage:
  make test-phase-e-host-evidence-gate

Environment:
  FCB_PHASE_E_VM_SUMMARY      VM gate summary. Default: target/fcb/vendor-vm-test/summary.txt
  FCB_PHASE_E_KERNEL_SUMMARY  Kernel e2e summary. Default: target/fcb/kernel-compile-from-plan/summary.txt
  FCB_KERNEL_COMPILE_MAX_LINES
                               Per-file line limit for Kernel compile fixture/check files.
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_file() {
  [ -s "$1" ] || die "missing or empty evidence file: $1"
}

require_line() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || die "$file missing evidence: $pattern"
}

summary_value() {
  local file="$1"
  local key="$2"
  local line
  line="$(grep -F "$key: " "$file" | tail -n 1)" || true
  [ -n "$line" ] || die "$file missing summary key: $key"
  printf '%s\n' "${line#"$key: "}"
}

require_filter_log() {
  local mode="$1"
  local filter="$2"
  require_line "$VM_SUMMARY" "$filter"
  require_file "$FILTER_LOG_DIR/$mode-$filter.log"
  require_line "$FILTER_LOG_DIR/$mode-$filter.log" "Done: $filter"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

require_file "$VM_SUMMARY"
require_file "$KERNEL_SUMMARY"

"$ROOT_DIR/scripts/check_kernel_compile_fixture_size.sh" >/dev/null

require_line "$VM_SUMMARY" "standalone FcbPatchRuntime passed"
require_line "$VM_SUMMARY" "sdk_delta_audit:"
require_line "$VM_SUMMARY" "rebuild_run_vm_tests: 1"

SDK_DELTA_AUDIT_LOG="$(summary_value "$VM_SUMMARY" "sdk_delta_audit")"
FILTER_LOG_DIR="$(summary_value "$VM_SUMMARY" "run_vm_test_filter_logs")"
require_file "$SDK_DELTA_AUDIT_LOG"
require_line "$SDK_DELTA_AUDIT_LOG" "vendor Dart SDK delta audit passed"
require_line "$SDK_DELTA_AUDIT_LOG" "fcb_or_allowed_delta_count:"

for filter in "${COMMON_VM_TEST_FILTERS[@]}"; do
  require_filter_log release "$filter"
done

for filter in "${DEBUG_VM_TEST_FILTERS[@]}"; do
  require_filter_log debug "$filter"
done

require_line "$KERNEL_SUMMARY" "kernel_compile_from_plan passed"
require_line "$KERNEL_SUMMARY" "interpreted_count: 404"
require_line "$KERNEL_SUMMARY" "reject_count: 2"
require_line "$KERNEL_SUMMARY" "unchanged_count: 11"
require_line "$KERNEL_SUMMARY" "module_function_count: 419"
require_line "$KERNEL_SUMMARY" "binary_function_count: 419"
require_line "$KERNEL_SUMMARY" "FcbPatchRuntimeAsyncStarSourceModuleStreamListen"
require_line "$KERNEL_SUMMARY" "FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor"
require_line "$KERNEL_SUMMARY" "triple_nested_runtime_cases: normal cancel outer-error middle-error inner-error"

echo "Phase E host evidence check passed"
echo "vm_summary: $VM_SUMMARY"
echo "kernel_summary: $KERNEL_SUMMARY"
echo "kernel_compile_fixture_size: pass"
