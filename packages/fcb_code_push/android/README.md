# Android native packaging

`fcb_code_push` is a Flutter plugin on Android so the app can bundle
`libfcb_updater.so` and load it through Dart FFI.

Build and package the updater library for an ABI with `cargo-ndk`:

```sh
packages/fcb_code_push/tool/build_android_native.sh arm64-v8a
```

Build all supported Android ABIs:

```sh
packages/fcb_code_push/tool/build_android_native.sh all
```

This produces an ARM64 shared library at:

```text
packages/fcb_code_push/android/src/main/jniLibs/arm64-v8a/libfcb_updater.so
```

Or copy an already-built updater library per ABI:

```sh
packages/fcb_code_push/tool/prepare_android_prebuilt.sh \
  arm64-v8a path/to/arm64-v8a/libfcb_updater.so
```

The script copies the library to:

```text
packages/fcb_code_push/android/src/main/jniLibs/<abi>/libfcb_updater.so
```

Those copied libraries are generated artifacts and are ignored by git. The
script expects the Rust Android target and Android NDK toolchain to be available
through `cargo-ndk`.

Useful validation:

```sh
file packages/fcb_code_push/android/src/main/jniLibs/arm64-v8a/libfcb_updater.so
nm -gU packages/fcb_code_push/android/src/main/jniLibs/arm64-v8a/libfcb_updater.so | rg 'fcb_'
```

The Phase B Android device validation script can build the missing updater
library automatically when `cargo-ndk` and the Android NDK are available:

```sh
FCB_AUTO_BUILD_ANDROID_UPDATER=1 \
FLUTTER_BUILD_EXTRA_ARGS='--local-engine-src-path /path/to/engine/src --local-engine android_release_arm64 --local-engine-host host_release' \
tests/e2e/test_phase_b_android.sh
```

By default the script sets `DEVICE_SERVER_URL=http://127.0.0.1:<port>` and runs
`adb reverse tcp:<port> tcp:<port>` so both emulators and physical USB devices
can reach the local FCB server. To use emulator host networking instead:

```sh
DEVICE_SERVER_URL=http://10.0.2.2:18097 USE_ADB_REVERSE=0 \
FLUTTER_BUILD_EXTRA_ARGS='--local-engine-src-path /path/to/engine/src --local-engine android_release_arm64 --local-engine-host host_release' \
tests/e2e/test_phase_b_android.sh
```

To check the Android validation environment without building the temporary
Flutter app, run the shared preflight first:

```sh
FCB_AUTO_BUILD_ANDROID_UPDATER=1 \
FLUTTER_BUILD_EXTRA_ARGS='--local-engine-src-path /path/to/engine/src --local-engine android_release_arm64 --local-engine-host host_release' \
tests/e2e/phase_b_preflight.sh
```

The preflight requires `--local-engine-src-path` or `FCB_ENGINE_SRC`, requires
the `out/<local-engine>` and `out/<local-engine-host>` build directories named
by `--local-engine` and `--local-engine-host`, then verifies that:

- `engine_patch/android/apply_engine_patch.sh` installed the FCB hook under
  `shell/platform/android/fcb`.
- Android Engine `BUILD.gn` files depend on
  `//shell/platform/android/fcb:fcb_engine_hook`, proving the hook is linked.
- Android Engine source outside that hook directory calls
  `fcb_apply_android_snapshot_replace_with_config(...)`, proving the hook is
  wired into the AOT settings path rather than only copied into the tree.

The Dart package and Android plugin must agree on the path bridge contract used
by Phase B:

- MethodChannel: `dev.fcb.code_push/android_paths`
- `getCacheDir`: returns Android `Context.getCacheDir()`; Dart appends `/fcb`
  so the Engine hook and Dart updater share the same cache state.
- `getBaselineArtifactPath`: returns `ApplicationInfo.nativeLibraryDir/libapp.so`
  so binary diffs can reconstruct patched `libapp.so` from the bundled baseline.
