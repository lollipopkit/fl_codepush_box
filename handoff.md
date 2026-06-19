**目标**
完成 FCB bytecode / VM interpreter 已确认缺口，补齐测试集与审计证据。当前 VM/runtime 本地项已基本闭环；goal 仍未完成，因为 H2 远端 CI、H4 TestFlight、H5 vendor rebase 仍需真实外部证据。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库不使用 vendor submodule；`.gitmodules` 已删除。
- generated evidence 只放 `target/fcb/evidence/*`；`tests/e2e` 只保留脚本。
- 工作树有 staged/unstaged 混合改动；不要 `git add .`，不要 revert 无关改动。
- 用户已授权根仓库和 embedded Dart push；不要 force push。

**已完成**
- embedded Dart 已推到 `https://github.com/lollipopkit/dartsdk.git`，分支 `fcb-vm-runtime-semantics`，commit `5f1d102fbdeb98944248d26e4ac9380d96aafa52`。
- 根仓库 `origin/main` 已推到 `b4529d1`，包含 `e6d3863 wip`、`19e5e93 wip`、`b4529d1 fix: bootstrap vendor checkouts without submodules`。
- H2 expected HEAD SHA gate、H4/H5 evidence 绑定校验、vendor VM standalone/debug/release evidence、evidence hygiene gate、`.gitignore` 清理都已在本地改动中补强。
- 本轮修复 Rust CI 失败点：`crates/fcb_core/src/server_api.rs` 的 `download_bytes_from_with_cancel_aborts_mid_body` 测试先置 cancel 并释放服务端响应，再 join worker，避免 worker 在第二段 body 上阻塞到 timeout。

**已验证**
- `cargo test -p fcb_core server_api::tests::download_bytes_from_with_cancel_aborts_mid_body`: 通过。
- 远端 Rust run `27827682968` 在 `b4529d1` 上失败，失败测试为 `server_api::tests::download_bytes_from_with_cancel_aborts_mid_body`，panic 为 `timeout: receive body`。
- 之前本地已验证：`scripts/test_vendor_vm_runtime.sh` 通过；`scripts/check_phase_h_runbooks.sh` 通过；`scripts/audit_plan_completion.sh` 非 0 但剩余为 H2/H4/H5 外部证据。

**当前状态**
- 根仓库 `main...origin/main` 当前本地新增未提交修复：`crates/fcb_core/src/server_api.rs`、`handoff.md`。
- 工作树仍有大量既有 staged/unstaged 改动，涉及 PLAN/docs、iOS SwiftPM、audit scripts、旧 `tests/e2e/vm_patch_*` 删除、kernel reader/manifest 等；不要盲目纳入本轮 Rust fix commit。
- 当前需要提交并 push 本轮 Rust test fix 后，再观察新一轮 CI。

**下一步**
1. 提交并 push `crates/fcb_core/src/server_api.rs` 与 `handoff.md`，commit message 建议 `fix: stabilize cancelled download test`。
2. 等待 `origin/main` 新 HEAD 的 GitHub Actions，重点检查 Rust、Server、E2E x64。
3. H2 仍需所有 required push workflows 与 scheduled workflows 绑定新 expected HEAD 成功；旧 nightly schedule 仍可能停在旧 SHA。
4. H4 需要真实 App Store Connect `External Testing` 证据。
5. H5 需要真实 `Vendor rebase validation passed` 证据，并用 record 脚本归档。
