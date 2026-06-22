#!/usr/bin/env bash
# Builds the FCB-enabled Flutter macOS engine (libFlutterMacOS.dylib) using
# the pre-configured GN out dir host_release_fcb_embedder_arm64.
#
# Prerequisites:
#   - vendor/flutter engine source tree (scripts/bootstrap.sh)
#   - vendor/depot_tools checkout
#   - libfcb_updater.a (run scripts/build_desktop_updater.sh first)
#   - Xcode + either the MobileAsset Metal toolchain or TOOLCHAINS=Metal set
#
# Usage:
#   scripts/build_macos_fcb_engine.sh [--dest <dir>]
#
#   --dest <dir>   Copy libFlutterMacOS.dylib into <dir> after building.
#
# Env:
#   FCB_ENGINE_OUT_DIR   Engine out dir.
#                        Default: vendor/flutter/engine/src/out/host_release_fcb_embedder_arm64
#   FCB_VENDOR_DEPOT_TOOLS_DIR   Default: vendor/depot_tools
#   FCB_VPYTHON_ROOT             Default: target/fcb/vpython-root
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE_OUT_DIR="${FCB_ENGINE_OUT_DIR:-$ROOT_DIR/vendor/flutter/engine/src/out/host_release_fcb_embedder_arm64}"
DEPOT_TOOLS_DIR="${FCB_VENDOR_DEPOT_TOOLS_DIR:-$ROOT_DIR/vendor/depot_tools}"
VPYTHON_ROOT="${FCB_VPYTHON_ROOT:-$ROOT_DIR/target/fcb/vpython-root}"
STATICLIB="$ROOT_DIR/target/release/libfcb_updater.a"
DEST=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dest) DEST="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

die() { echo "error: $*" >&2; exit 1; }

case "$(uname -s)" in
  Darwin) ;;
  *) die "build_macos_fcb_engine.sh: macOS only" ;;
esac

[ -d "$ENGINE_OUT_DIR" ] || die "missing engine out dir: $ENGINE_OUT_DIR (run scripts/bootstrap.sh)"
[ -f "$ENGINE_OUT_DIR/build.ninja" ] || die "missing build.ninja in $ENGINE_OUT_DIR (run gn gen first)"
[ -f "$STATICLIB" ] || die "missing $STATICLIB (run scripts/build_desktop_updater.sh first)"
[ -d "$DEPOT_TOOLS_DIR" ] || die "missing depot_tools: $DEPOT_TOOLS_DIR"

# Auto-detect MobileAsset Metal toolchain if TOOLCHAINS is not set.
if [ -z "${TOOLCHAINS:-}" ]; then
  _mtl=$(ls -d /var/run/com.apple.security.cryptexd/mnt/com.apple.MobileAsset.MetalToolchain*/Metal.xctoolchain/usr/bin/metal 2>/dev/null | head -1)
  [ -n "$_mtl" ] && export TOOLCHAINS=Metal
fi

echo "Building FCB macOS engine (flutter_framework_dylib)..."
echo "  out dir:  $ENGINE_OUT_DIR"
echo "  updater:  $STATICLIB"
echo "  TOOLCHAINS: ${TOOLCHAINS:-<not set>}"
echo

NCPU=$(sysctl -n hw.logicalcpu 2>/dev/null || nproc 2>/dev/null || echo 4)
PATH="$DEPOT_TOOLS_DIR:$PATH" \
VPYTHON_VIRTUALENV_ROOT="$VPYTHON_ROOT" \
  ninja -j"$NCPU" -C "$ENGINE_OUT_DIR" flutter_framework_dylib

DYLIB="$ENGINE_OUT_DIR/libFlutterMacOS.dylib"
[ -f "$DYLIB" ] || die "build completed but $DYLIB not found"

FCB_SYMS=$(nm -g "$DYLIB" 2>/dev/null | grep -c "_fcb_" || true)

if [ -n "$DEST" ]; then
  mkdir -p "$DEST"
  cp "$DYLIB" "$DEST/"
  echo "Copied libFlutterMacOS.dylib -> $DEST/"
fi

cat <<EOF

FCB macOS engine built.
  dylib: $DYLIB
  size:  $(ls -lh "$DYLIB" | awk '{print $5}')
  FCB C-ABI symbols: $FCB_SYMS

To use in a Flutter macOS app bundle:
  1. Build counter_app normally: cd examples/counter_app && flutter build macos --release
  2. Replace the bundled engine:
       APP=build/macos/Build/Products/Release/counter_app.app
       FW=\$APP/Contents/Frameworks/FlutterMacOS.framework/Versions/A/FlutterMacOS
       cp $DYLIB \$FW
  3. Place libfcb_updater.dylib next to the .app (or in \$APP/Contents/Frameworks):
       cp target/release/libfcb_updater.dylib examples/counter_app/
  4. Set FCB_CACHE_DIR and run: open examples/counter_app/\$APP

Or use scripts/accept_macos_fcb.sh for the full baseline→patch→restart→rollback acceptance.
EOF
