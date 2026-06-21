#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${FCB_MACOS_METAL_CHECK_DIR:-$ROOT_DIR/target/fcb/macos-metal-toolchain}"
SUMMARY="$OUT_DIR/summary.txt"
LOG="$OUT_DIR/check.log"
SDK="${FCB_MACOS_METAL_SDK:-macosx}"

usage() {
  cat <<USAGE
Usage:
  $0

Checks the Xcode Metal Toolchain path used by Flutter Engine macOS embedder
build actions. This intentionally probes the same SDK-qualified invocation
used by impeller/tools/metal_library.py:

  xcrun -sdk macosx metal -v

Environment:
  FCB_MACOS_METAL_CHECK_DIR  Evidence output dir.
                             Default: target/fcb/macos-metal-toolchain
  FCB_MACOS_METAL_SDK        SDK passed to xcrun. Default: macosx
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

case "$(uname -s)" in
  Darwin) ;;
  *) die "Metal Toolchain preflight only applies on macOS" ;;
esac

command -v xcrun >/dev/null 2>&1 || die "missing xcrun"
command -v xcodebuild >/dev/null 2>&1 || die "missing xcodebuild"

mkdir -p "$OUT_DIR"

{
  echo "xcodebuild:"
  xcodebuild -version
  echo
  echo "developer_dir:"
  xcode-select -p
  echo
  echo "sdk_path:"
  xcrun -sdk "$SDK" --show-sdk-path
  echo
  echo "unqualified_metal:"
  xcrun --find metal || true
  echo
  echo "sdk_qualified_metal:"
  xcrun -sdk "$SDK" --find metal
  echo
  echo "sdk_qualified_metal_version:"
  xcrun -sdk "$SDK" metal -v
} >"$LOG" 2>&1 || {
  cat "$LOG" >&2
  cat >"$SUMMARY" <<EOF
FCB macOS Metal Toolchain preflight failed
sdk: $SDK
log: $LOG
hint: run xcodebuild -downloadComponent MetalToolchain, then retry this check.
EOF
  cat "$SUMMARY" >&2
  exit 1
}

cat >"$SUMMARY" <<EOF
FCB macOS Metal Toolchain preflight passed
sdk: $SDK
log: $LOG
EOF

cat "$SUMMARY"
