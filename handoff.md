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
- `server/main.go` 已实现 Go API：apps/releases/patches/promote/rollback/check/events，本地 JSON store。
- `packages/fcb_code_push` 已有 Dart FFI 壳层；`examples/counter_app` 已有最小 Flutter 示例。

**已验证**
- `cargo check`: 通过。
- `go test ./...` in `server/`: 通过。
- `dart analyze packages/fcb_code_push`: 通过。
- 本地闭环通过：启动 server 后运行 `fcb init`、`fcb release android --example examples/counter_app --release-version 1.0.0+1`、`fcb patch android --release-version 1.0.0+1 --patch-number 1`、`fcb promote --release-version 1.0.0+1 --patch-number 1 --rollout-percentage 100`、`fcb check --release-version 1.0.0+1`，check 返回 `patch_available: true`。
- `fcb install` 能验证签名/hash 并写入 `.fcb/cache/state.json`。
- 篡改 payload 后 `fcb install` 返回 `payload sha256 mismatch`。

**当前状态**
- 当前目录是 git repo：`No commits yet on main`，所有源码文件均未提交。
- 本轮启动的 `127.0.0.1:8080` Go server 已结束，端口不再占用。
- `fcb.yaml`、`.fcb/`、`target/` 为验证/构建产物，不应作为源码提交。

**下一步**
1. 增加 Rust/Go 单元测试，覆盖 canonical JSON、签名验签、rollout、state bad patch blocklist。
2. 让 CLI `check/install` 支持从 server 返回的 manifest/payload URL 自动下载并安装，而不是手动传路径。
3. 给 Go server 增加 manifest hash 与 payload URL 更真实的 object storage 语义。
4. 接 Flutter example 的最小 smoke test，确认 package API 在缺 native lib 时行为稳定。
5. 后续再进入 Android `snapshot_replace` 或 native Engine hook。

**完整计划仍缺**
- Android P0 真实 `libapp.so` diff/apply/加载。
- iOS/Play 合规 bytecode backend。
- Dart transformer、HBC compiler/interpreter、Kernel linker。
- Engine fork 和 VM dispatch。
