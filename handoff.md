**目标**
实现 `PLAN.md` 到项目 MVP。当前技术栈约束：`server` 用 Go，`cli` 和 `updater` 用 Rust。

**硬约束**
- 不要把 MVP 缩小成纯文档；需要继续推进可运行闭环。
- Engine hook、真实 AOT replacement、bytecode compiler/interpreter 尚未实现。
- `fcb.yaml` 和 `.fcb/` 是本轮验证生成物，已被 `.gitignore` 忽略。

**已完成**
- `PLAN.md` 已更新为 `FCB/fcb` 命名，并改为 `cli` Rust、`server` Go、`updater` Rust。
- 创建 Rust workspace：`crates/fcb_core`、`cli`、`updater`。
- `cli/src/main.rs` 已实现 `fcb init/release/patch/promote/check/install/mark-success/mark-failure/inspect` MVP。
- `crates/fcb_core` 已实现 config 解析、manifest canonical JSON、Ed25519 sign/verify、server client、updater state/install。
- `updater/src/lib.rs` 已导出 `fcb_*` C ABI 基础符号。
- `server/main.go` 已用 Fiber 实现 Go API：apps/releases/patches/promote/rollback/check/manifest/events，本地 JSON store。
- `packages/fcb_code_push` 已有 Dart FFI 壳层；`examples/counter_app` 已有最小 Flutter 示例。
- 已处理 PR inline review：私钥权限、iOS ABI round-trip、manifest 签名失败恢复、HTTP timeout、atomic temp 文件、mark_success 错误路径、schema required drift 测试、Go marshal 错误处理、FFI panic/poison/range 防护、Flutter 示例状态处理和 debug 日志。
- 已处理后续 schema review：`patch_manifest.schema.json` 补齐 root/nested properties、types、format/range/pattern、additionalProperties；schema required 测试会验证 required 字段均存在于 properties。
- `fcb check --install` 已支持从 server check response 自动下载 manifest/payload、校验 hash、再调用 updater 安装。
- server 已有本地 filesystem object store：`fcb patch` 上传 payload，server 写入 `objects/`，`check` 返回 HTTP payload URL，不再依赖 CLI 工作目录里的本地 payload 路径。
- 已补测试：Go server 覆盖 rollout 稳定性、object key 防穿越、payload object store/check URL；Flutter package 覆盖缺 native lib 时 MVP API 不崩溃。
- 已补 Rust 测试：canonical JSON、patch manifest sign/verify/失败恢复、updater pending launch crash rollback。
- `Updater::launch_patch()` 现在会把上次未 mark success 的 `pending_success` patch 标记为 bad，避免 crash loop。
- 已处理后续 review：`fcb check --install` 对无补丁响应改为成功 no-op、Fiber advisory 注释写入 `server/go.mod`、server payload atomic write 改用 `os.CreateTemp` + `Sync`、`download_bytes` 增加本地路径信任边界说明、payload endpoint 增加 URL-encoded traversal 集成测试。
- Flutter package 的 `checkForUpdate()` / `downloadUpdate()` 已从硬编码未接线改为调用 native updater ABI；缺 native lib 时仍安全降级。`fcb_download_and_install_blocking()` 现在对未配置下载路径返回明确错误，避免 native 存在时误报成功。
- `.gitignore` 已忽略 Flutter package/example 生成的 `pubspec.lock`。
- `snapshot_replace` patch manifest 现在标记 `snapshot_replace_artifact`；updater 安装时会把 payload 同步写成 `patches/<n>/libapp.so`，state 记录 `artifact_path`，`fcb_get_launch_patch()` 对 snapshot backend 返回绝对 artifact path。
- 已实现最小 binary diff/apply：`fcb-simple-v1` 用共同前缀/后缀 + 插入段生成 `binary_diff` payload，manifest 记录 `diff_algorithm/base_hash/output_hash`，updater 使用本地 baseline artifact apply diff 并验证输出 hash 后写入 `libapp.so`。
- 已新增 Android Engine hook scaffold：`engine_patch/android/fcb_engine_hook.{h,cc}` 把 `fcb_get_launch_patch()` 结果转换成 `FcbEnginePatchDecision`，snapshot backend 返回可接入 Engine AOT artifact settings 的 `artifact_path`；`fcb_engine_hook_test.cc` 覆盖 no patch、snapshot、bytecode、错误路径。
- 已补无副作用 ready-check：`Updater::ready_patch()` / `fcb_is_new_patch_ready_to_install()` 会检查 pending installed patch 但不写入 `last_launch`；Flutter package 的 `isNewPatchReadyToInstall()` 和 `requestRestartToApply()` 已接入该 FFI。
- Rust updater 的 native check/download/install 已接入：`fcb_init` 保存 app/channel/release/platform/arch/cache/public key，新增 `fcb_set_server_url` / `fcb_set_client_id` / `fcb_set_baseline_artifact_path`；`fcb_check_for_update_async()` 调 server check 并缓存结果，`fcb_download_and_install_blocking()` 下载 manifest/payload、校验 hash/signature 并调用 updater install。
- Flutter package 新增 `FcbCodePush.configure(...)`，通过 Dart FFI 调 `fcb_init` 和 server/client/baseline setters；缺 native lib 时仍返回 `false` 且不崩溃。

**已验证**
- `cargo test`: 通过。
- `go test ./...` in `server/`: 通过。
- `cargo fmt --all -- --check`: 通过。
- `flutter analyze` in `packages/fcb_code_push`: 通过。
- `flutter test` in `packages/fcb_code_push`: 通过。
- `flutter analyze` in `examples/counter_app`: 通过。
- `cargo test -p fcb_updater`: 通过。
- 新增单测覆盖 signed `snapshot_replace` 安装生成 `libapp.so`，以及 updater FFI 返回 artifact path。
- `/tmp` 新目录执行 `fcb init` 后，`.fcb/keys/dev-ed25519.private` 权限为 `600`。
- 本地闭环通过：启动 server 后运行 `fcb init`、`fcb release android --example examples/counter_app --release-version 1.0.0+1`、`fcb patch android --release-version 1.0.0+1 --patch-number 1`、`fcb promote --release-version 1.0.0+1 --patch-number 1 --rollout-percentage 100`、`fcb check --release-version 1.0.0+1`，check 返回 `patch_available: true`。
- `fcb install` 能验证签名/hash 并写入 `.fcb/cache/state.json`。
- 篡改 payload 后 `fcb install` 返回 `payload sha256 mismatch`。
- Fiber server + object store 本地闭环通过：`fcb init -> release -> patch -> promote -> check --install`，自动从 server 下载 manifest/payload 到 `.fcb/downloads/...` 并安装到 `.fcb/cache`。
- 当前代码重建 CLI 后，`snapshot_replace` artifact 闭环通过：临时 Fiber server + `fcb init -> release -> patch --payload patched-libapp.so -> promote -> check --install`，`cmp` 确认 `.fcb/cache/patches/4/libapp.so` 与输入 artifact 一致，`state.json` 记录 `artifact_path = patches/4/libapp.so`。
- binary diff 闭环通过：临时 Fiber server + `fcb init -> release -> patch --payload patched-libapp.so -> promote -> check --install`，manifest 显示 `payload.kind=binary_diff` / `diff_algorithm=fcb-simple-v1`，`cmp` 确认 apply 后 `.fcb/cache/patches/5/libapp.so` 与目标 artifact 一致。
- Android hook scaffold 验证通过：`c++ -std=c++17 -Wall -Wextra -Werror -Iengine_patch/android engine_patch/android/fcb_engine_hook.cc engine_patch/android/fcb_engine_hook_test.cc -o /tmp/fcb_engine_hook_test`，随后 `/tmp/fcb_engine_hook_test` 通过。
- ready-check 验证通过：`cargo test` 覆盖 core ready 状态和 FFI ready 状态不污染 `last_launch`；`flutter test` / `flutter analyze` 覆盖 Dart package 缺 native lib 降级行为。
- native check/download 验证通过：`cargo test -p fcb_updater` 用本地 `TcpListener` 模拟 server，直接调用 FFI 完成 check、manifest/payload 下载、安装并确认 ready。

**当前状态**
- 当前目录是 git repo，`main` 已包含 PR #1 合并结果。
- 当前分支 `feat/fiber-server-install-flow` 已有 PR #2；本地提交领先远端，后续需要按需 push 到 PR。
- 本轮启动的 `127.0.0.1:8080` Fiber server 已结束，端口不再占用。
- 本轮临时 `127.0.0.1:18080/18081` Fiber server 已结束。
- 本轮临时 `127.0.0.1:18082` Fiber server 已结束。
- `fcb.yaml`、`.fcb/`、`target/` 为验证/构建产物，不应作为源码提交。

**下一步**
1. 将 `engine_patch/android/fcb_engine_hook.cc` 接入真实 Flutter Engine Android AOT settings 初始化路径。
2. 将 `fcb-simple-v1` 替换为真正 bsdiff/zstd，或保留为 MVP fallback 并新增 bsdiff backend。

**完整计划仍缺**
- Android P0 真实 `libapp.so` 加载。
- iOS/Play 合规 bytecode backend。
- Dart transformer、HBC compiler/interpreter、Kernel linker。
- Engine fork 和 VM dispatch。
