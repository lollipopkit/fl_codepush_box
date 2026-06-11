# Android native packaging

`fcb_code_push` is a Flutter plugin on Android so the app can bundle
`libfcb_updater.so` and load it through Dart FFI.

Prepare a prebuilt updater library per ABI:

```sh
packages/fcb_code_push/tool/prepare_android_prebuilt.sh \
  arm64-v8a path/to/arm64-v8a/libfcb_updater.so
```

The script copies the library to:

```text
packages/fcb_code_push/android/src/main/jniLibs/<abi>/libfcb_updater.so
```

Those copied libraries are generated artifacts and are ignored by git. The
actual cross-build step can use `cargo-ndk` or the project buildroot; the MVP
contract here is the stable Flutter/Android packaging location.
