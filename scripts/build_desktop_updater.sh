#!/usr/bin/env bash
# Builds the FCB Rust updater for the host desktop platform (macOS/Linux/Windows)
# and reports the artifacts the FCB-enabled engine build + Flutter app need.
#
# The FCB interpreter itself lives in the shared Dart VM, so desktop code-push
# needs only:
#   1. libfcb_updater static lib  -> linked into the engine (gn arg below).
#   2. libfcb_updater dynamic lib -> loaded by the Dart FFI at runtime
#      (DynamicLibrary.open in packages/fcb_code_push), placed next to the app
#      binary or on the library search path.
#
# Usage:
#   scripts/build_desktop_updater.sh [--dest <dir>]
#
#   --dest <dir>   Copy the dynamic lib into <dir> (e.g. the desktop app's
#                  bundle / build output) so the FFI loader finds it.
#
# Env:
#   FCB_CARGO_PROFILE   release (default) | debug
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${FCB_CARGO_PROFILE:-release}"
DEST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dest) DEST="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

case "$(uname -s)" in
  Darwin) PLATFORM="macos"; DYLIB="libfcb_updater.dylib" ;;
  Linux)  PLATFORM="linux"; DYLIB="libfcb_updater.so" ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM="windows"; DYLIB="fcb_updater.dll" ;;
  *) echo "unsupported host: $(uname -s)" >&2; exit 2 ;;
esac

profile_flag=""
[ "$PROFILE" = "release" ] && profile_flag="--release"

echo "Building libfcb_updater ($PROFILE) for host $PLATFORM..."
( cd "$ROOT_DIR" && cargo build $profile_flag -p fcb_updater )

OUT_DIR="$ROOT_DIR/target/$PROFILE"
STATICLIB="$OUT_DIR/libfcb_updater.a"
DYNLIB="$OUT_DIR/$DYLIB"

for f in "$STATICLIB" "$DYNLIB"; do
  [ -f "$f" ] || { echo "missing expected artifact: $f" >&2; exit 1; }
done

if [ -n "$DEST" ]; then
  mkdir -p "$DEST"
  cp "$DYNLIB" "$DEST/"
  echo "Copied $DYLIB -> $DEST/"
fi

cat <<EOF

FCB desktop updater built.
  static lib (engine link): $STATICLIB
  dynamic lib (Dart FFI):   $DYNLIB

Enable code-push in the engine (embedder) build with gn args:
  fcb_enable_code_push = true
  fcb_updater_staticlib = "$STATICLIB"

Then place $DYLIB next to the app executable (or on the library search path),
and set FCB_CACHE_DIR so the engine startup hook and the Dart updater share one
cache location (see packages/fcb_code_push _defaultCacheDir +
shell/platform/embedder/fcb/fcb_embedder_vm_patch_bridge ResolveCacheDir).
EOF
