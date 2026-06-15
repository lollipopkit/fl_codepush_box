**当前状态**
Android Phase D（bytecode）热更新实现完整，x86_64 模拟器全流程通过。

**已实现层（全部完整）**
- Dart 插件 API：configure/check/download/markSuccess/markFailure/restart/launchBytecodePatchPath
- Java 插件：cacheDir、baselineArtifactPath（nativeLibraryDir + APK zip 回退）、restart
- 预置 .so：arm64-v8a + x86_64
- Engine hook：`fcb_engine_hook.cc`（两种 backend 决策）+ `fcb_android_vm_patch_bridge.cc`（bytecode root_isolate_create_callback）
- flutter_main.cc：`InstallFcbAndroidVmBytecodePatchCallback`
- platform_view_android.cc：`FireFirstFrameCallback` → `fcb_mark_android_launch_success`
- Dart VM patch runtime：PatchTable/PatchRuntime/Interpret/LoadModuleFromFile
- VM dispatch hookup：dart_entry.cc、runtime_entry.cc、flow_graph_compiler.cc、precompiler.cc 全部接入

**已验证（x86_64 模拟器）**
- `scripts/test_android_x64.sh`: pass，`1/8/7/base/10`，tombstones 无增
- `FCB_INSTALL_BYTECODE_PATCH=1 scripts/test_android_x64.sh`: pass，`42/42/42/patched/42`
- `FCB_ENABLE_AOT_DISPATCH=0` 路径: pass
- `tests/e2e/test_e2e.sh`: pass

**已知缺口**
1. `snapshot_replace` 后端未在 vendor fork flutter_main.cc 中接线（仅 bytecode 路径可用）
2. `engine_patch/android/flutter_engine_current.patch` 过时（仍为旧 snapshot_replace 方案，不含 fcb_android_vm_patch_bridge）
3. **arm64 真机验收未完成**（emulator-5554 primary ABI 为 x86_64，arm64-v8a 仅 native-bridge）
4. armeabi-v7a 无预置 .so
