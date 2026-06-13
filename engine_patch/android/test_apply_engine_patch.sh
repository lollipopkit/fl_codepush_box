#!/usr/bin/env bash
# Unit-style tests for apply_engine_patch.sh using a fake Engine tree.

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WORKDIR=$(mktemp -d /tmp/fcb_apply_engine_patch_XXXXXX)
ENGINE="$WORKDIR/engine/src"
UPDATER_LIB="$SCRIPT_DIR/../../packages/fcb_code_push/android/src/main/jniLibs/arm64-v8a/libfcb_updater.so"
UPDATER_BACKUP=""

cleanup() {
    if [ -n "$UPDATER_BACKUP" ] && [ -f "$UPDATER_BACKUP" ]; then
        mkdir -p "$(dirname "$UPDATER_LIB")"
        mv "$UPDATER_BACKUP" "$UPDATER_LIB"
    else
        rm -f "$UPDATER_LIB"
    fi
    rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

if [ -f "$UPDATER_LIB" ]; then
    UPDATER_BACKUP="$WORKDIR/libfcb_updater.so.backup"
    mv "$UPDATER_LIB" "$UPDATER_BACKUP"
fi

echo "=== apply_engine_patch rejects non-Engine source tree ==="
mkdir -p "$WORKDIR/not_engine"
if FLUTTER_ENGINE_SRC="$WORKDIR/not_engine" \
    "$SCRIPT_DIR/apply_engine_patch.sh" arm64-v8a \
    >/tmp/fcb_apply_engine_invalid.log 2>&1; then
    echo "FAIL: apply_engine_patch accepted invalid Engine tree" >&2
    exit 1
fi
grep -q 'does not appear to be a Flutter Engine source tree' \
    /tmp/fcb_apply_engine_invalid.log

echo "=== apply_engine_patch rejects unsupported ABI ==="
mkdir -p "$ENGINE/shell/platform/android"
if FLUTTER_ENGINE_SRC="$ENGINE" \
    "$SCRIPT_DIR/apply_engine_patch.sh" mips \
    >/tmp/fcb_apply_engine_bad_abi.log 2>&1; then
    echo "FAIL: apply_engine_patch accepted unsupported ABI" >&2
    exit 1
fi
grep -q 'unsupported Android ABI: mips' /tmp/fcb_apply_engine_bad_abi.log

echo "=== apply_engine_patch installs hook files and integration docs ==="
mkdir -p "$ENGINE/shell/platform/android/shell"
mkdir -p "$(dirname "$UPDATER_LIB")"
printf '\177ELFfake updater so\n' > "$UPDATER_LIB"
FLUTTER_ENGINE_SRC="$ENGINE" "$SCRIPT_DIR/apply_engine_patch.sh" arm64-v8a \
    >/tmp/fcb_apply_engine_ok.log 2>&1

test -f "$ENGINE/shell/platform/android/fcb/fcb_engine_hook.h"
test -f "$ENGINE/shell/platform/android/fcb/fcb_engine_hook.cc"
test -f "$ENGINE/shell/platform/android/fcb/BUILD.gn"
test -f "$ENGINE/shell/platform/android/fcb/ANDROID_SNAPSHOT_REPLACE_INTEGRATION.md"
test -f "$ENGINE/third_party/fcb/android/arm64-v8a/libfcb_updater.so"
grep -q 'source_set("fcb_engine_hook")' \
    "$ENGINE/shell/platform/android/fcb/BUILD.gn"
grep -q 'libs = \[ "dl" \]' "$ENGINE/shell/platform/android/fcb/BUILD.gn"
grep -q 'fcb_apply_android_snapshot_replace_with_config' \
    "$ENGINE/shell/platform/android/fcb/ANDROID_SNAPSHOT_REPLACE_INTEGRATION.md"
grep -q 'android/src/main/jniLibs/arm64-v8a/libfcb_updater.so' \
    /tmp/fcb_apply_engine_ok.log
grep -q 'verify_engine_patch.sh' /tmp/fcb_apply_engine_ok.log

echo "=== copied hook alone does not satisfy Engine verifier ==="
if "$SCRIPT_DIR/verify_engine_patch.sh" "$ENGINE" \
    >/tmp/fcb_apply_engine_unwired.log 2>&1; then
    echo "FAIL: verifier accepted copied but unwired Engine hook" >&2
    exit 1
fi
grep -q 'do not depend on //shell/platform/android/fcb:fcb_engine_hook' \
    /tmp/fcb_apply_engine_unwired.log

echo "=== applied hook verifies after Engine-specific wiring ==="
cat > "$ENGINE/shell/platform/android/shell/BUILD.gn" <<'GN'
source_set("android_shell") {
  deps = [ "//shell/platform/android/fcb:fcb_engine_hook" ]
}
GN
cat > "$ENGINE/shell/platform/android/shell/fcb_integration.cc" <<'CC'
void FcbIntegration() {
  fcb_apply_android_snapshot_replace_with_config(nullptr, nullptr);
}
CC
"$SCRIPT_DIR/verify_engine_patch.sh" "$ENGINE" >/tmp/fcb_apply_engine_verified.log
grep -q 'FCB Android Engine patch verification passed' \
    /tmp/fcb_apply_engine_verified.log

echo "=== Engine patch apply tests passed ==="
