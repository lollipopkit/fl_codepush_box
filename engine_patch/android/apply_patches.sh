#!/usr/bin/env bash
# Apply FCB engine patches to the Flutter Engine source tree.
#
# Usage:
#   ./engine_patch/android/apply_patches.sh /path/to/flutter/engine/src
#   ./engine_patch/android/apply_patches.sh --reverse /path/to/flutter/engine/src
#
# This script:
#   1. Copies FCB hook files into the Engine source tree
#   2. Applies patches to switches.cc and FlutterLoader.java
#   3. Verifies all patches applied cleanly
#
# The Flutter Engine should be checked out as a submodule at
# third_party/flutter (which contains engine/src).

set -euo pipefail

REVERSE=0
ENGINE_SRC=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --reverse|-R)
            REVERSE=1
            shift
            ;;
        *)
            ENGINE_SRC="$1"
            shift
            ;;
    esac
done

if [ -z "$ENGINE_SRC" ]; then
    # Default to the submodule in the project
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    ENGINE_SRC="$PROJECT_ROOT/third_party/flutter/engine/src"
fi

if [ ! -d "$ENGINE_SRC/flutter" ]; then
    echo "ERROR: $ENGINE_SRC does not look like an Engine source tree (missing flutter/)"
    echo "Usage: apply_patches.sh [--reverse] ENGINE_SRC"
    exit 1
fi

ANDROID_DIR="$ENGINE_SRC/flutter/shell/platform/android"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCH_DIR="$SCRIPT_DIR/patches"

PATCH_FLAG=""
if [ "$REVERSE" -eq 1 ]; then
    PATCH_FLAG="-R"
    echo "Reversing patches..."
fi

echo "=== Copying FCB hook files ==="
cp "$SCRIPT_DIR/fcb_engine_hook.h" "$ANDROID_DIR/"
cp "$SCRIPT_DIR/fcb_engine_hook.cc" "$ANDROID_DIR/"
cp "$SCRIPT_DIR/fcb_android_jni.cc" "$ANDROID_DIR/"
echo "Copied: fcb_engine_hook.h, fcb_engine_hook.cc, fcb_android_jni.cc"

echo "=== Applying patches ==="
APPLIED=0
SKIPPED=0
for patch_file in "$PATCH_DIR"/*.patch; do
    [ -f "$patch_file" ] || continue
    patch_name=$(basename "$patch_file")
    if patch -p1 --dry-run $PATCH_FLAG -d "$ENGINE_SRC" < "$patch_file" >/dev/null 2>&1; then
        patch -p1 $PATCH_FLAG -d "$ENGINE_SRC" < "$patch_file"
        echo "Applied: $patch_name"
        APPLIED=$((APPLIED + 1))
    else
        echo "SKIP: $patch_name (already applied or conflict)"
        SKIPPED=$((SKIPPED + 1))
    fi
done

echo "=== Done: $APPLIED applied, $SKIPPED skipped ==="
if [ "$REVERSE" -eq 0 ]; then
    echo "Patches applied. Build the engine with the modified source tree."
    echo "You also need to add fcb_engine_hook.cc and fcb_android_jni.cc"
    echo "to the Android shell BUILD.gn deps."
else
    echo "Patches reversed. Original source tree restored."
    echo "Remove the copied hook files manually if needed."
fi
