# iOS Engine Integration

FCB iOS hot update uses the **bytecode backend only** (Apple policy forbids
downloading native executable code). The integration mirrors the Android Phase D
implementation, replacing Android-specific JNI and adb paths with iOS equivalents.

## Key Files

| File | Role |
|------|------|
| `vendor/flutter/engine/src/flutter/shell/platform/darwin/ios/fcb/fcb_ios_vm_patch_bridge.h` | C++ header exposing the two hook functions |
| `vendor/flutter/engine/src/flutter/shell/platform/darwin/ios/fcb/fcb_ios_vm_patch_bridge.mm` | ObjC++ implementation — init updater, install root-isolate callback |
| `engine_patch/ios/BUILD.gn.snippet` | GN additions for the iOS Flutter framework target |
| `packages/fcb_code_push/ios/` | Flutter plugin: `getPaths` + `restart` method channel |

## Hook Points

### 1. `FlutterEngine.mm` — before `Shell::Create()`

```objc
// Added inside -launchEngine:libraryURI:entrypointArgs: after SetEntryPoint()
#if FCB_ENABLE_CODE_PUSH
{
    NSArray<NSString*>* cachesPaths = NSSearchPathForDirectoriesInDomains(
        NSCachesDirectory, NSUserDomainMask, YES);
    if (cachesPaths.count > 0) {
        flutter::InstallFcbIosVmBytecodePatchCallback(
            &settings, cachesPaths[0].UTF8String);
    }
}
#endif
```

`InstallFcbIosVmBytecodePatchCallback` calls `fcb_init()` (Rust updater) and
chains a `root_isolate_create_callback` that calls
`dart::fcb::LoadPatchRuntimeForCurrentIsolateGroup()` before user Dart code runs.

### 2. `FlutterViewController.mm` — `onFirstFrameRendered`

```objc
#if FCB_ENABLE_CODE_PUSH
  flutter::FcbIosMarkLaunchSuccess();
#endif
```

Promotes the pending patch to `active`. If the process exits before this call
the updater rolls back on next launch.

## Build

```sh
# 1. Build libfcb_updater.a for iOS device
cargo build --target aarch64-apple-ios --release -p fcb_updater
export FCB_UPDATER_STATICLIB="$PWD/target/aarch64-apple-ios/release/libfcb_updater.a"

# 2. Build iOS Engine with FCB patches
FCB_IOS_CPU=arm64 scripts/build_ios_engine.sh

# 3. Build counter_app against local engine
FCB_ENABLE_AOT_DISPATCH=1 vendor/flutter/bin/flutter build ios \
  --release \
  --local-engine-src-path "$PWD/vendor/flutter/engine/src" \
  --local-engine ios_release_arm64 \
  --dart-define FCB_APP_ID=<uuid> \
  --dart-define FCB_PUBLIC_KEY=<key> \
  --dart-define FCB_PLATFORM=ios \
  --dart-define FCB_ARCH=arm64 \
  -C examples/counter_app
```

## Differences from Android

| Aspect | Android | iOS |
|--------|---------|-----|
| Cache dir | `Context.getCodeCacheDir()` | `NSCachesDirectory` |
| Arch string | `arm64-v8a` / `x86_64` | `arm64` / `x86_64` |
| Library format | `libfcb_updater.so` (shared) | `libfcb_updater.a` (static, linked into `Flutter.xcframework`) |
| Restart | `Process.killProcess()` | `UIApplication.suspend()` (user must relaunch) |
| AOT backend | snapshot_replace + bytecode | **bytecode only** |
| Engine hook file | `flutter_main.cc` | `FlutterEngine.mm` |
| First frame hook | `platform_view_android.cc` | `FlutterViewController.mm` |

## Compliance Note

Apple Developer Program License Agreement section 3.3.2 permits downloading
interpreted code as long as it:
- Does not change the primary purpose of the App.
- Does not bypass the signature/sandbox/system security mechanisms.
- Does not create another App Store.

FCB iOS patches are bytecode data executed by the embedded interpreter inside
the FCB-forked Dart VM. They cannot load native `.dylib`, `.framework`, or JIT
code. The interpreter is compiled into the app binary and reviewed by App Review.
