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
- E2E 测试脚本：tests/e2e/test_e2e.sh 覆盖 init→release→patch→promote→check→install→mark-failure→rollback→invalid sig rejection。

**Review 修复已提交**
- Android build 脚本 rm -rf 安全校验、updater FFI unsafe/panic guard/public key PEM/DER 规范化/last_check 失效、state installed 修剪保留 current/pending、server payload key 校验/Host header 端口保留、Dart configure 输入校验、C++ hook 注释、counter FAB、Gradle buildscript 移除。

**已验证**
- `cargo test`: 11 passed
- `go test ./...`: 3 passed (eligible stability, path traversal, create+check)
- `flutter test/analyze`: passed
- `c++ hook test`: passed
- `build_android_native.sh arm64-v8a`: passed
- E2E script: full pass (init→patch→promote→check→install→failure→rollback→bad sig rejection)

**Phase B 当前状态**
- Engine hook 已有 scaffold + test，但需要接入真实 Flutter Engine AOT settings 初始化路径。
- 需要修改 Engine GN 配置链接 libfcb_updater、在 root isolate 启动前调用 fcb_init/fcb_get_launch_patch、对 Android 设置 patched AOT artifact path。
- 这是 Engine fork 工作，不在当前 MVP 范围内一键完成。

**下一步**
1. 将 engine_patch 接入真实 Flutter Engine Android embedder 的 AOT loading 路径。
2. 替换 `fcb-simple-v1` diff 为 bsdiff/zstd。
3. Phase C: bytecode backend for iOS/Play 合规。
