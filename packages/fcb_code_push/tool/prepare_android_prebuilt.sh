#!/usr/bin/env sh
set -eu

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <abi> <path-to-libfcb_updater.so>" >&2
  echo "example: $0 arm64-v8a native/android/arm64-v8a/libfcb_updater.so" >&2
  exit 2
fi

ABI=$1
SOURCE=$2
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGE_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
DEST_DIR="$PACKAGE_DIR/android/src/main/jniLibs/$ABI"

case "$ABI" in
  arm64-v8a|armeabi-v7a|x86|x86_64)
    ;;
  *)
    echo "unsupported Android ABI: $ABI" >&2
    exit 2
    ;;
esac

if [ ! -f "$SOURCE" ]; then
  echo "missing native library: $SOURCE" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SOURCE" "$DEST_DIR/libfcb_updater.so"
echo "$DEST_DIR/libfcb_updater.so"
