**目标**
Phase D：通过 fork Flutter Engine / Dart SDK，在 Android AOT `arm64-v8a` 上透明拦截普通 Dart static 函数并执行 VM 侧 bytecode patch。

**本轮完成**
- 修复 ARM64 `FcbAotStaticCall4` stub：第 4 个 Dart 实参现在传给 `FcbPatchStaticCallAot4` runtime entry。
- 在 VM patch runtime 中新增 lazy argument conversion：只转换 bytecode 实际 `LoadArg` 读取的参数，常量 patch 不再因未使用的 AOT 参数槽异常而崩溃。
- 同步修改到 `vendor/sdk/runtime/vm` 和 `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm`。
- 旧 Phase C annotation/codegen/Dart interpreter 已删除，counter app 不再依赖 Dart 层 dispatcher。

**已验证**
- `FCB_SKIP_SYNC=1 scripts/build_phase_d_android_engine.sh`: pass。
- `FCB_ALLOW_SECONDARY_ABI=1 FCB_FLUTTER_CLEAN=1 scripts/accept_phase_d_android_arm64.sh`: pass。
- 验收设备为 x86_64 primary ABI + `arm64-v8a` secondary/native-bridge，用户已允许该模式。
- no-patch observed: `1/8/7/base/10`，tombstones `100 -> 100`。
- patch observed: `42/42/42/patched/42`，含 `quadCounterValue` 4 参数路径，tombstones `100 -> 100`。

**产物**
- Summary: `target/fcb/phase-d-android-arm64-acceptance/summary.txt`
- Patch logcat: `target/fcb/phase-d-android-arm64-acceptance/patch/logs/logcat.txt`
- APK: `examples/counter_app/build/app/outputs/flutter-apk/app-release.apk`

**剩余风险**
- 尚未在 primary ABI 为真实 `arm64-v8a` 的 Android 设备上复跑；当前验收是 native-bridge smoke。
