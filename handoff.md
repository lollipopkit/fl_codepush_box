**目标**
完整实现并验证 `PLAN.md` Phase B：Android `snapshot_replace` backend。

**本轮完成**
- 修复 Android 默认路径：Dart `configure()` 不再默认 `.fcb/cache`；Android 通过 plugin helper 使用 `context.codeCacheDir/fcb`。
- 修复 Android baseline 自动发现：优先使用已解压 `nativeLibraryDir/libapp.so`；若 `extractNativeLibs=false`，从当前 APK 的 `lib/<abi>/libapp.so` 提取到 `code_cache/fcb/baseline/libapp.so`。
- 示例 App 不再默认传 `FCB_CACHE_DIR`，只有显式 dart-define 时才覆盖 package 默认值。
- Dart wrapper 保留 `fcb_last_error()` 错误透出，设备侧能直接看到 native 失败原因。

**已验证**
- `cargo test`: pass。
- `go test ./...` in `server/`: pass。
- `flutter test` in `packages/fcb_code_push`: pass。
- `tests/e2e/test_e2e.sh` with `target/debug/fcb` + `/tmp/fcb_server_phase_b`: pass。
- `flutter build apk --release --target-platform android-x64 --local-engine android_release_x64_fcb --local-engine-host host_release_fcb`: pass。
- Android 模拟器 `emulator-5554` Phase B 全链路：
  - v1 APK 启动显示 `Counter: 1`。
  - App 未传 `FCB_CACHE_DIR` / `FCB_BASELINE_ARTIFACT` 时，下载成功，文件直接写入 `/data/user/0/com.example.fcb_counter_app/code_cache/fcb`。
  - 设备端 baseline hash 等于当前 v1 `libapp.so`；patch hash 等于 v2 `libapp.so`。
  - 重启后 Engine 加载 `code_cache/fcb/patches/1/libapp.so`，显示 `Counter: 2`。
  - 移除 `adb reverse` 后离线重启仍显示 `Counter: 2`，`Current patch` 为 1。
  - 手动损坏 active patch 后首次启动崩溃；第二次启动自动回退到 baseline，显示 `Counter: 1`，`bad_patches: [1]`。

**当前判断**
Phase B 验收项已完成：release/patch/check/download/install、bsdiff-zstd、custom Engine snapshot_replace、离线 active patch、坏 patch 自动回滚均已通过。

**注意**
- P0 `snapshot_replace` 仍是 policy-sensitive backend，不应作为 Google Play 默认方案。
- 临时验证产物在 `/tmp/fcb_phase_b_current` 和 `/tmp/fcb_phase_b_aligned`；不需要提交。
