#!/usr/bin/env bash
# Verify that a Flutter Engine Android tree is wired for FCB snapshot_replace.

set -euo pipefail

ENGINE_SRC="${1:-${FLUTTER_ENGINE_SRC:-}}"

if [ -z "$ENGINE_SRC" ]; then
    echo "usage: $0 <flutter-engine-src>" >&2
    echo "or set FLUTTER_ENGINE_SRC=/path/to/engine/src" >&2
    exit 2
fi

if [ ! -d "$ENGINE_SRC/shell/platform/android" ]; then
    echo "FAIL: local Engine source path is invalid: $ENGINE_SRC" >&2
    exit 1
fi

if [ ! -f "$ENGINE_SRC/shell/platform/android/fcb/fcb_engine_hook.cc" ]; then
    echo "FAIL: FCB Engine hook not installed at $ENGINE_SRC/shell/platform/android/fcb" >&2
    exit 1
fi

if [ ! -f "$ENGINE_SRC/shell/platform/android/fcb/BUILD.gn" ]; then
    echo "FAIL: FCB Engine hook BUILD.gn not installed at $ENGINE_SRC/shell/platform/android/fcb" >&2
    exit 1
fi

if ! grep -R \
    --include='BUILD.gn' \
    --exclude-dir='fcb' \
    -Eq '//(flutter/)?shell/platform/android/fcb:fcb_engine_hook' \
    "$ENGINE_SRC/shell/platform/android"; then
    echo "FAIL: Android Engine BUILD.gn files do not depend on //shell/platform/android/fcb:fcb_engine_hook." >&2
    echo "Add the dependency to the Android target that owns AOT snapshot configuration." >&2
    exit 1
fi

if ! grep -R \
    --include='*.cc' \
    --include='*.cpp' \
    --include='*.h' \
    --include='*.mm' \
    --exclude-dir='fcb' \
    -q 'fcb_apply_android_snapshot_replace_with_config' \
    "$ENGINE_SRC/shell/platform/android"; then
    echo "FAIL: patched Engine source does not call fcb_apply_android_snapshot_replace_with_config outside the FCB hook directory." >&2
    echo "Wire the hook into the Android AOT settings path before running Phase B device validation." >&2
    exit 1
fi

echo "FCB Android Engine patch verification passed: $ENGINE_SRC"
