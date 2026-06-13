#!/usr/bin/env bash
# Tests for Android updater native packaging helper scripts.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORKDIR=$(mktemp -d /tmp/fcb_android_native_packaging_XXXXXX)
ABI=arm64-v8a
DEST="$REPO_ROOT/packages/fcb_code_push/android/src/main/jniLibs/$ABI/libfcb_updater.so"
BACKUP=""

cleanup() {
    if [ -n "$BACKUP" ] && [ -f "$BACKUP" ]; then
        mkdir -p "$(dirname "$DEST")"
        mv "$BACKUP" "$DEST"
    else
        rm -f "$DEST"
    fi
    rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

if [ -f "$DEST" ]; then
    BACKUP="$WORKDIR/libfcb_updater.so.backup"
    mv "$DEST" "$BACKUP"
fi

echo "=== prepare_android_prebuilt copies updater library to jniLibs ==="
SOURCE="$WORKDIR/libfcb_updater.so"
printf '\177ELFpackaging test\n' > "$SOURCE"
OUTPUT=$("$REPO_ROOT/packages/fcb_code_push/tool/prepare_android_prebuilt.sh" \
    "$ABI" "$SOURCE")
test "$OUTPUT" = "$DEST"
cmp "$SOURCE" "$DEST"

echo "=== prepare_android_prebuilt rejects unsupported ABI ==="
if "$REPO_ROOT/packages/fcb_code_push/tool/prepare_android_prebuilt.sh" \
    mips "$SOURCE" >/tmp/fcb_prepare_bad_abi.log 2>&1; then
    echo "FAIL: unsupported ABI was accepted" >&2
    exit 1
fi
grep -q 'unsupported Android ABI: mips' /tmp/fcb_prepare_bad_abi.log

echo "=== prepare_android_prebuilt rejects missing source library ==="
if "$REPO_ROOT/packages/fcb_code_push/tool/prepare_android_prebuilt.sh" \
    "$ABI" "$WORKDIR/missing.so" >/tmp/fcb_prepare_missing.log 2>&1; then
    echo "FAIL: missing source library was accepted" >&2
    exit 1
fi
grep -q 'missing native library' /tmp/fcb_prepare_missing.log

echo "=== build_android_native rejects unsupported ABI before cargo-ndk ==="
if "$REPO_ROOT/packages/fcb_code_push/tool/build_android_native.sh" \
    mips >/tmp/fcb_build_bad_abi.log 2>&1; then
    echo "FAIL: unsupported build ABI was accepted" >&2
    exit 1
fi
grep -q 'unsupported Android ABI: mips' /tmp/fcb_build_bad_abi.log

echo "=== Android native packaging tests passed ==="
