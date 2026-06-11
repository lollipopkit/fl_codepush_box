# Android native packaging

`fcb_code_push` is a Flutter plugin on Android so the app can bundle
`libfcb_updater.so` and load it through Dart FFI.

Build and package the updater library for an ABI with `cargo-ndk`:

```sh
packages/fcb_code_push/tool/build_android_native.sh arm64-v8a
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
