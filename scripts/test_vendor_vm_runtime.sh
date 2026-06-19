#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${FCB_VENDOR_SDK_DIR:-$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart}"
OUT_DIR="${FCB_VENDOR_VM_TEST_DIR:-$ROOT_DIR/target/fcb/vendor-vm-test}"
CXX_BIN="${CXX:-clang++}"
DEBUG_RUN_VM_TESTS="${FCB_VENDOR_VM_DEBUG_RUNNER:-$ROOT_DIR/vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests}"
RELEASE_RUN_VM_TESTS="${FCB_VENDOR_VM_RELEASE_RUNNER:-$ROOT_DIR/vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests}"

usage() {
  cat <<USAGE
Usage:
  $0

Builds and runs the vendor Dart SDK FCB VM runtime test and writes the evidence
summary consumed by make audit-plan-completion.

Environment:
  FCB_VENDOR_SDK_DIR       Dart SDK checkout. Default: vendor/flutter/engine/src/flutter/third_party/dart
  FCB_VENDOR_VM_TEST_DIR   Evidence output dir. Default: target/fcb/vendor-vm-test
  FCB_VENDOR_VM_DEBUG_RUNNER    Debug run_vm_tests binary.
  FCB_VENDOR_VM_RELEASE_RUNNER  Release run_vm_tests binary.
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
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_vm.cc" ] || die "missing FCB VM runtime VM helper source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_value.cc" ] || die "missing FCB VM runtime value source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_loader.cc" ] || die "missing FCB VM runtime loader source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_loader_test.cc" ] || die "missing FCB VM runtime loader test source"
command -v "$CXX_BIN" >/dev/null 2>&1 || die "missing C++ compiler: $CXX_BIN"

mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/standalone-test.log"
DEBUG_VM_LOG="$OUT_DIR/debug-run-vm-tests.log"
RELEASE_VM_LOG="$OUT_DIR/release-run-vm-tests.log"
BIN="$OUT_DIR/fcb_patch_runtime_test"
DART_COMMIT="$(git -C "$SDK_DIR" rev-parse HEAD)"

"$CXX_BIN" \
  -std=c++20 \
  -DFCB_PATCH_RUNTIME_STANDALONE \
  -I "$SDK_DIR/runtime" \
  -I "$SDK_DIR/runtime/include" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_async.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_closure.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_helpers.cc" \
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

collect_vm_tests "$DEBUG_RUN_VM_TESTS" "$DEBUG_VM_LOG" "debug"
grep -Fq "FcbPatchDebuggerCollectsActiveInterpreterFrame Pass" "$DEBUG_VM_LOG" \
  || die "debug run_vm_tests list missing active debugger frame test"
grep -Fq "FcbPatchDebuggerFrameEvaluationUsesSourceLibrary Pass" "$DEBUG_VM_LOG" \
  || die "debug run_vm_tests list missing debugger eval source library test"
grep -Fq "FcbPatchDebuggerCollectsMaterializedClosureActiveFrame Pass" "$DEBUG_VM_LOG" \
  || die "debug run_vm_tests list missing materialized closure debugger frame test"
collect_vm_tests "$RELEASE_RUN_VM_TESTS" "$RELEASE_VM_LOG" "release"

{
  echo "standalone FcbPatchRuntime passed"
  echo "sdk_dir: $SDK_DIR"
  echo "dart_commit: $DART_COMMIT"
  echo "standalone_tests: runtime/vm/fcb_patch_runtime_loader_test.cc runtime/vm/fcb_patch_runtime_test.cc runtime/vm/fcb_patch_runtime_try_test.cc"
  echo "standalone_log: $LOG"
  echo "debug_vm_tests: $DEBUG_VM_LOG"
  echo "release_vm_tests: $RELEASE_VM_LOG"
} >"$OUT_DIR/summary.txt"

echo "vendor VM runtime test passed: $OUT_DIR/summary.txt"
