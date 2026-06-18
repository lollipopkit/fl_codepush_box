#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${FCB_VENDOR_SDK_DIR:-$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart}"
OUT_DIR="${FCB_VENDOR_VM_TEST_DIR:-$ROOT_DIR/target/fcb/vendor-vm-test}"
CXX_BIN="${CXX:-clang++}"

usage() {
  cat <<USAGE
Usage:
  $0

Builds and runs the vendor Dart SDK FCB VM runtime test and writes the evidence
summary consumed by make audit-plan-completion.

Environment:
  FCB_VENDOR_SDK_DIR       Dart SDK checkout. Default: vendor/flutter/engine/src/flutter/third_party/dart
  FCB_VENDOR_VM_TEST_DIR   Evidence output dir. Default: target/fcb/vendor-vm-test
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
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_vm.cc" ] || die "missing FCB VM runtime VM helper source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_value.cc" ] || die "missing FCB VM runtime value source"
[ -f "$SDK_DIR/runtime/vm/fcb_patch_runtime_loader.cc" ] || die "missing FCB VM runtime loader source"
command -v "$CXX_BIN" >/dev/null 2>&1 || die "missing C++ compiler: $CXX_BIN"

mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/standalone-test.log"
BIN="$OUT_DIR/fcb_patch_runtime_test"
DART_COMMIT="$(git -C "$SDK_DIR" rev-parse HEAD)"

"$CXX_BIN" \
  -std=c++20 \
  -DFCB_PATCH_RUNTIME_STANDALONE \
  -I "$SDK_DIR/runtime" \
  -I "$SDK_DIR/runtime/include" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_vm.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_value.cc" \
  "$SDK_DIR/runtime/vm/fcb_patch_runtime_loader.cc" \
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

{
  echo "standalone FcbPatchRuntime passed"
  echo "sdk_dir: $SDK_DIR"
  echo "dart_commit: $DART_COMMIT"
  echo "test: runtime/vm/fcb_patch_runtime_test.cc"
  echo "log: $LOG"
} >"$OUT_DIR/summary.txt"

echo "vendor VM runtime test passed: $OUT_DIR/summary.txt"
