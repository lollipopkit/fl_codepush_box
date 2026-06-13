#!/usr/bin/env bash
# Apply the FCB snapshot_replace patch to a Flutter Engine Android build.
#
# Prerequisites:
#   - Flutter Engine source checked out at $FLUTTER_ENGINE_SRC
#   - FCB libfcb_updater.so built for the target ABI
#   - Rust toolchain with cargo-ndk for cross-compilation
#
# Usage:
#   FLUTTER_ENGINE_SRC=/path/to/engine ./apply_engine_patch.sh [arm64-v8a]
#
# This script:
#   1. Copies fcb_engine_hook.{h,cc} into the Engine source tree.
#   2. Installs a GN source_set for the hook.
#   3. Copies the prebuilt updater library when available.
#   4. Writes an integration note with the exact callback contract the Android
#      AOT settings code must call before launching the root isolate.
#
# After running this script, build the Flutter Engine per the official
# instructions and use the patched engine in your Flutter app.

set -euo pipefail

ABI="${1:-arm64-v8a}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ENGINE_SRC="${FLUTTER_ENGINE_SRC:?FLUTTER_ENGINE_SRC must be set}"

case "$ABI" in
  arm64-v8a|armeabi-v7a|x86|x86_64)
    ;;
  *)
    echo "ERROR: unsupported Android ABI: $ABI" >&2
    exit 2
    ;;
esac

echo "=== FCB Engine Patch for Android (ABI: $ABI) ==="
echo "Engine source: $ENGINE_SRC"

# Validate Engine source.
if [ ! -d "$ENGINE_SRC/shell/platform/android" ]; then
    echo "ERROR: $ENGINE_SRC does not appear to be a Flutter Engine source tree." >&2
    exit 1
fi

# 1. Copy hook files into the Engine source.
FCB_ENGINE_DIR="$ENGINE_SRC/shell/platform/android/fcb"
mkdir -p "$FCB_ENGINE_DIR"
cp "$SCRIPT_DIR/fcb_engine_hook.h" "$FCB_ENGINE_DIR/fcb_engine_hook.h"
cp "$SCRIPT_DIR/fcb_engine_hook.cc" "$FCB_ENGINE_DIR/fcb_engine_hook.cc"
echo "Copied fcb_engine_hook.h and fcb_engine_hook.cc to $FCB_ENGINE_DIR"

# 2. Install a GN source_set. The parent Android BUILD.gn must depend on
# //shell/platform/android/fcb:fcb_engine_hook from the concrete AOT settings
# target for the checked-out Engine revision.
cat > "$FCB_ENGINE_DIR/BUILD.gn" <<'GN_EOF'
source_set("fcb_engine_hook") {
  sources = [
    "fcb_engine_hook.cc",
  ]

  public = [
    "fcb_engine_hook.h",
  ]

  include_dirs = [ "." ]
  libs = [ "dl" ]
}
GN_EOF
echo "Wrote $FCB_ENGINE_DIR/BUILD.gn"

# 3. Copy the prebuilt updater library if it exists. Prefer the plugin
# packaging location because that is what the Android APK validation uses.
UPDATER_LIB=""
for candidate in \
    "$SCRIPT_DIR/../../packages/fcb_code_push/android/src/main/jniLibs/$ABI/libfcb_updater.so" \
    "$SCRIPT_DIR/../../packages/fcb_code_push/native/android/$ABI/libfcb_updater.so"; do
    if [ -f "$candidate" ]; then
        UPDATER_LIB="$candidate"
        break
    fi
done
if [ -z "$UPDATER_LIB" ]; then
    echo "WARNING: libfcb_updater.so not found for $ABI" >&2
    echo "Build it first with: packages/fcb_code_push/tool/build_android_native.sh $ABI" >&2
else
    ENGINE_UPDATER_DIR="$ENGINE_SRC/third_party/fcb/android/$ABI"
    mkdir -p "$ENGINE_UPDATER_DIR"
    cp "$UPDATER_LIB" "$ENGINE_UPDATER_DIR/libfcb_updater.so"
    echo "Copied $UPDATER_LIB to $ENGINE_UPDATER_DIR"
fi

# 4. Write the exact integration contract into the Engine tree. This avoids
# hard-coding one Flutter Engine revision's AOT settings file.
cat > "$FCB_ENGINE_DIR/ANDROID_SNAPSHOT_REPLACE_INTEGRATION.md" <<'MD_EOF'
# FCB Android snapshot_replace Engine integration

Add `//shell/platform/android/fcb:fcb_engine_hook` to the GN target that owns
Android AOT snapshot configuration.

Include:

```cc
#include "shell/platform/android/fcb/fcb_engine_hook.h"
```

Before the root isolate is launched, call:

```cc
namespace {
int SetFcbAotArtifactPath(const char* artifact_path,
                          const char* manifest_path,
                          int patch_number) {
  // Write artifact_path into this Engine revision's Android AOT setting.
  // Common targets call this aot_library_path, aot_assets_path, or the
  // libapp.so path used by the Android shell holder.
  //
  // manifest_path and patch_number are provided for logging/diagnostics.
  return 0;
}
}  // namespace

FcbAndroidSnapshotReplaceConfig fcb_config = {};
fcb_config.app_id = "<optional app id>";
fcb_config.channel = "stable";
fcb_config.release_version = "<release version>";
fcb_config.arch = "<android abi>";
fcb_config.cache_dir = "<application cache dir>/fcb";
fcb_config.updater_library_path = "libfcb_updater.so";

const int fcb_rc =
    fcb_apply_android_snapshot_replace_with_config(&fcb_config,
                                                   SetFcbAotArtifactPath);
if (fcb_rc < 0) {
  // Keep the bundled libapp.so and continue startup.
}
```

`fcb_apply_android_snapshot_replace_with_config` calls the setter only when the
updater selects a signed, installed `snapshot_replace` patch with a
reconstructed `libapp.so`.

`cache_dir` is required and must match the Flutter package cache directory. The
hook returns `-1` without initializing the updater when `cache_dir` is null or
empty.
MD_EOF

echo "Wrote $FCB_ENGINE_DIR/ANDROID_SNAPSHOT_REPLACE_INTEGRATION.md"
echo ""
echo "Patch files installed. Next, add //shell/platform/android/fcb:fcb_engine_hook"
echo "to the Android AOT settings target for this Flutter Engine revision and wire"
echo "SetFcbAotArtifactPath to that target's libapp.so path field."
echo "Then verify the Engine wiring with:"
echo "  $SCRIPT_DIR/verify_engine_patch.sh $ENGINE_SRC"
