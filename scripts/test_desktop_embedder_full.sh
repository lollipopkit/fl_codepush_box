#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPOT_TOOLS_DIR="${FCB_VENDOR_DEPOT_TOOLS_DIR:-$ROOT_DIR/vendor/depot_tools}"
TARGET_DIR="${FCB_DESKTOP_EMBEDDER_TARGET_DIR:-host_release_fcb_embedder_arm64}"
TARGET="${FCB_DESKTOP_EMBEDDER_TARGET:-flutter/shell/platform/embedder:embedder}"
OUT_DIR="${FCB_DESKTOP_EMBEDDER_FULL_TEST_DIR:-$ROOT_DIR/target/fcb/desktop-embedder-full}"
ENGINE_OUT_DIR="$ROOT_DIR/vendor/flutter/engine/src/out/$TARGET_DIR"
VPYTHON_ROOT="${FCB_VPYTHON_ROOT:-$ROOT_DIR/target/fcb/vpython-root}"
METAL_CHECK="${FCB_MACOS_METAL_CHECK:-$ROOT_DIR/scripts/check_macos_metal_toolchain.sh}"
SUMMARY="$OUT_DIR/summary.txt"
LOG="$OUT_DIR/ninja.log"

usage() {
  cat <<USAGE
Usage:
  $0

Runs the full desktop embedder Engine target used to validate the FCB desktop
embedder bridge beyond key translation units. On macOS this first runs the
Metal Toolchain preflight, because the full target reaches Impeller metallib
packaging.

Environment:
  FCB_DESKTOP_EMBEDDER_TARGET_DIR      Engine out target dir name.
                                       Default: host_release_fcb_embedder_arm64
  FCB_DESKTOP_EMBEDDER_TARGET          Ninja target.
                                       Default: flutter/shell/platform/embedder:embedder
  FCB_DESKTOP_EMBEDDER_FULL_TEST_DIR   Evidence output dir.
                                       Default: target/fcb/desktop-embedder-full
  FCB_VENDOR_DEPOT_TOOLS_DIR           depot_tools dir prepended to PATH.
                                       Default: vendor/depot_tools
  FCB_VPYTHON_ROOT                     vpython virtualenv root.
                                       Default: target/fcb/vpython-root
  FCB_MACOS_METAL_CHECK                macOS Metal preflight script.
                                       Default: scripts/check_macos_metal_toolchain.sh
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

[ -d "$DEPOT_TOOLS_DIR" ] || die "missing depot_tools checkout: $DEPOT_TOOLS_DIR"
[ -f "$ENGINE_OUT_DIR/build.ninja" ] || die "missing Engine build dir: $ENGINE_OUT_DIR"
[ -x "$METAL_CHECK" ] || die "missing Metal preflight script: $METAL_CHECK"
command -v ninja >/dev/null 2>&1 || [ -x "$DEPOT_TOOLS_DIR/ninja" ] || die "missing ninja"

mkdir -p "$OUT_DIR"

case "$(uname -s)" in
  Darwin)
    # Auto-detect MobileAsset Metal toolchain if TOOLCHAINS is not already set,
    # so builds work even when the Xcode Metal component was not formally installed.
    if [ -z "${TOOLCHAINS:-}" ]; then
      _mtl_tc=$(ls -d /var/run/com.apple.security.cryptexd/mnt/com.apple.MobileAsset.MetalToolchain*/Metal.xctoolchain/usr/bin/metal 2>/dev/null | head -1)
      [ -n "$_mtl_tc" ] && export TOOLCHAINS=Metal
    fi
    "$METAL_CHECK" >"$OUT_DIR/macos-metal-toolchain.log" 2>&1 || {
      cat "$OUT_DIR/macos-metal-toolchain.log" >&2
      cat >"$SUMMARY" <<EOF
FCB desktop embedder full target validation failed
reason: macOS Metal Toolchain preflight failed
target_dir: $TARGET_DIR
target: $TARGET
engine_out_dir: $ENGINE_OUT_DIR
metal_log: $OUT_DIR/macos-metal-toolchain.log
hint: run xcodebuild -downloadComponent MetalToolchain, then retry this script.
EOF
      cat "$SUMMARY" >&2
      exit 1
    }
    ;;
esac

PATH="$DEPOT_TOOLS_DIR:$PATH" \
VPYTHON_VIRTUALENV_ROOT="$VPYTHON_ROOT" \
ninja -C "$ENGINE_OUT_DIR" "$TARGET" >"$LOG" 2>&1 || {
  cat "$LOG" >&2
  cat >"$SUMMARY" <<EOF
FCB desktop embedder full target validation failed
reason: ninja target failed
target_dir: $TARGET_DIR
target: $TARGET
engine_out_dir: $ENGINE_OUT_DIR
ninja_log: $LOG
EOF
  cat "$SUMMARY" >&2
  exit 1
}

cat >"$SUMMARY" <<EOF
FCB desktop embedder full target validation passed
target_dir: $TARGET_DIR
target: $TARGET
engine_out_dir: $ENGINE_OUT_DIR
ninja_log: $LOG
EOF

cat "$SUMMARY"
