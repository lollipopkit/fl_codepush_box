**目标**
实现 `PLAN.md` 到项目 MVP。当前技术栈：server Go/Fiber，cli/updater Rust，package Dart/FFI。

**硬约束**
- 不要把 MVP 缩小成纯文档；继续推进可运行闭环。
- Phase A 已完成闭环；Phase B 需要 Flutter Engine fork，是独立大工程。
- 不提交 ignored/generated 产物。

**Phase A 已完成（闭环验证）**
- `fcb init/doctor/release/patch/promote/rollback/check/install/mark-success/mark-failure/inspect` 全部 CLI 命令实现。
- Go Fiber server：apps/releases/patches/promote/rollback/check/manifest/payload/events。
- Rust updater：manifest sign/verify、state machine、download/install、crash rollback。
- Flutter package：configure/checkForUpdate/downloadUpdate/isNewPatchReadyToInstall/currentPatchNumber/markLaunchSuccessful。
- Counter example：通过 --dart-define 配置，有 Check/Download/Mark success 按钮和 state counter。
- Engine hook scaffold：fcb_engine_hook.{h,cc} + test。
- E2E 测试脚本：tests/e2e/test_e2e.sh 覆盖完整 Phase A 验收标准。

**Phase B 当前进度**
- Flutter 官方 repo（stable/3.44.2）已作为 git submodule 引入到 `third_party/flutter`。
- Engine patch 文件已创建并通过验证：
  - `0001-switches-cc-fcb-patch-path.patch`：在 `application_library_paths` 前插入 FCB patched AOT artifact path。
  - `0002-flutter-loader-java-fcb-init.patch`：在 FlutterLoader.ensureInitializationComplete 中调用 `tryInitFcb()` 初始化 updater。
- C++ hook 已更新为 `fcb::` namespace：`fcb::ResolveAndroidSnapshotReplace(&decision)` 返回 1/0/-1。
- JNI 桥接 `fcb_android_jni.cc`：Java `nativeFcbInit()` 调用 Rust `fcb_init()`。
- `apply_patches.sh` 脚本：apply/reverse patches 到 Engine 源码树。
- GN BUILD.gn 模板：将 libfcb_updater 链入 Engine。
- 所有 hook 单元测试通过，所有 Rust 测试通过。
- Patches 在 Flutter 3.44.2 stable 上 clean apply/reverse 验证通过。

**Phase B 剩余工作**
1. 将 libfcb_updater 编译为 Android static library（.a）并集成到 Engine GN 构建。
2. 修改 Android shell BUILD.gn 添加 fcb_engine_hook 和 fcb_android_jni 依赖。
3. 构建修改后的 Flutter Engine（android_release_arm64）。
4. 用修改后的 Engine 构建 counter_app APK 并验证闭环：
   - build release → upload → patch → download → restart → patched result。
5. 验证 crash rollback：制造 crash patch → 重启 → 自动回滚到 baseline。

**已验证**
- `cargo test`: 3 passed (updater FFI tests)
- `go test ./...`: 3 passed
- `flutter test/analyze`: passed
- `c++ hook test`: passed
- E2E script: full pass
- Engine patches: clean apply/reverse on Flutter 3.44.2 stable
