# Android snapshot_replace Engine Integration

This directory contains the Flutter Engine modifications needed for FCB's
`snapshot_replace` backend (Phase B). The integration allows a patched
`libapp.so` to be loaded on next app restart when the FCB updater has a
ready patch.

## Architecture

```
App Startup
│
├─ FlutterLoader.java (Android embedding)
│   └─ tryInitFcb(context) → nativeFcbInit(cacheDir, publicKey, serverUrl)
│       └─ fcb_init() (Rust FFI) → reads state.json, configures updater
│
├─ switches.cc (Flutter Engine C++)
│   └─ After populating application_library_paths:
│       fcb::ResolveAndroidSnapshotReplace(&decision)
│       └─ fcb_get_launch_patch() (Rust FFI) → checks state.json
│       └─ If decision.use_snapshot_artifact == 1:
│           Insert decision.artifact_path at front of
│           application_library_paths
│
└─ dart_snapshot.cc
    └─ SearchMapping() iterates application_library_paths
        └─ Finds patched libapp.so first (if present)
        └─ Falls back to bundled libapp.so (if no patch)
```

## Files

| File | Purpose |
|------|---------|
| `fcb_engine_hook.h` | C/C++ header defining `FcbLaunchPatch` (C ABI from Rust updater) and `fcb::EnginePatchDecision` (C++ helper) |
| `fcb_engine_hook.cc` | C++ implementation of `fcb::ResolveEnginePatch()` and `fcb::ResolveAndroidSnapshotReplace()` |
| `fcb_engine_hook_test.cc` | Unit tests for the engine hook (no Rust dependency) |
| `fcb_android_jni.cc` | JNI bridge for `FlutterLoader.nativeFcbInit()` |
| `gn/BUILD.gn` | GN build configuration for linking into the Engine |
| `patches/0001-switches-cc-fcb-patch-path.patch` | Patch for `flutter/shell/common/switches.cc` |
| `patches/0002-flutter-loader-java-fcb-init.patch` | Patch for `FlutterLoader.java` |
| `apply_patches.sh` | Script to apply/reverse all patches and copy hook files |

## Integration Steps

### 1. Get the Flutter Engine source

The FCB project includes Flutter as a git submodule at `third_party/flutter`
(branch: stable). The Engine source is at `third_party/flutter/engine/src`.

### 2. Apply Engine patches

```sh
cd /path/to/fl_codepush_box
./engine_patch/android/apply_patches.sh

# To reverse:
./engine_patch/android/apply_patches.sh --reverse
```

This script:
1. Copies `fcb_engine_hook.h`, `fcb_engine_hook.cc`, `fcb_android_jni.cc`
   into the Engine source tree
2. Applies patches to `switches.cc` and `FlutterLoader.java`

### 3. Cross-compile the FCB updater for Android

```sh
cd /path/to/fl_codepush_box
cd packages/fcb_code_push
./tool/build_android_native.sh arm64-v8a
# Produces native/android/arm64-v8a/libfcb_updater.so
```

For Engine integration, you need a static library (.a) instead of .so:

```sh
cd /path/to/fl_codepush_box/updater
cargo ndk -t arm64-v8a build --release --crate-type staticlib
# Output: target/aarch64-linux-android/release/libfcb_updater.a
```

### 4. Build the Engine

```sh
ENGINE_SRC=third_party/flutter/engine/src

# Android arm64 release
cd "$ENGINE_SRC"
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode=release
ninja -C out/android_release_arm64

# Host release (needed for gen_snapshot)
./flutter/tools/gn --runtime-mode=release
ninja -C out/host_release
```

### 5. Use with a Flutter app

```sh
flutter build apk \
  --release \
  --target-platform android-arm64 \
  --local-engine-src-path "$ENGINE_SRC" \
  --local-engine android_release_arm64
```

## End-to-end flow

1. **App install**: App ships with baseline `libapp.so` bundled in the APK.
2. **First launch**: Engine loads the bundled `libapp.so`. No FCB patch found.
3. **Patch check**: Dart code calls `FcbCodePush.instance.checkForUpdate()`.
4. **Download**: Dart code calls `FcbCodePush.instance.downloadUpdate()`.
   - The updater downloads manifest + payload, verifies signature,
     applies binary diff against baseline, writes patched `libapp.so` to
     `<cache>/.fcb/patches/<N>/libapp.so`.
   - State transitions to `installed_pending`.
5. **Next launch**: `FlutterLoader.tryInitFcb()` calls `fcb_init()`.
6. `switches.cc` calls `fcb::ResolveAndroidSnapshotReplace()`, which
   returns the patched `libapp.so` path.
7. Engine inserts this path at the front of `application_library_paths`.
8. `SearchMapping()` in `dart_snapshot.cc` finds the patched library first.
9. Engine loads patched `libapp.so` → the new code runs.
10. App calls `FcbCodePush.instance.markLaunchSuccessful()`.
    - State transitions to `active`.

### Crash rollback

If the app crashes before `markLaunchSuccessful()`:

1. Next launch: `launch_patch()` sees `pending_success` status from last launch.
2. Marks the patch as `bad` (added to `bad_patches`).
3. Falls back to baseline or previous active patch.

## Limitations

- **Android only**: iOS does not support downloading and loading native
  executable code (App Store policy restriction).
- **Google Play**: The `snapshot_replace` backend downloads a native `.so`
  file, which may violate Google Play policy. For Play distribution, use
  the `bytecode` backend (Phase C) instead.
- **Architecture**: Each ABI requires its own patch. The updater handles
  `arm64-v8a` by default; add `armeabi-v7a` and `x86_64` as needed.

## Testing the hook

```sh
c++ -std=c++17 -Wall -Wextra -Werror -Iengine_patch/android \
  engine_patch/android/fcb_engine_hook.cc \
  engine_patch/android/fcb_engine_hook_test.cc \
  -o /tmp/fcb_engine_hook_test
/tmp/fcb_engine_hook_test
```
