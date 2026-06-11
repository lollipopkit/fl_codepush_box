#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGE_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
REPO_DIR=$(CDPATH= cd -- "$PACKAGE_DIR/../.." && pwd)

ABI=${1:-arm64-v8a}

case "$ABI" in
  arm64-v8a|armeabi-v7a|x86|x86_64)
    ;;
  *)
    echo "unsupported Android ABI: $ABI" >&2
    exit 2
    ;;
esac

if ! command -v cargo-ndk >/dev/null 2>&1; then
  echo "cargo-ndk is required for Android native builds." >&2
  echo "Install it with: cargo install cargo-ndk" >&2
  exit 127
fi

OUT_DIR="$PACKAGE_DIR/native/android"
rm -rf "$OUT_DIR/$ABI"
mkdir -p "$OUT_DIR"

cargo ndk \
  --manifest-path "$REPO_DIR/Cargo.toml" \
  -t "$ABI" \
  -o "$OUT_DIR" \
  build \
  -p fcb_updater \
  --release

"$SCRIPT_DIR/prepare_android_prebuilt.sh" "$ABI" "$OUT_DIR/$ABI/libfcb_updater.so"
