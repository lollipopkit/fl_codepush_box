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
- 根仓库 `origin/main` 已推到 `ca496d3514e8fdb2997c85d45ce2dc54db2a76e4`，包含 `e6d3863 wip`、`19e5e93 wip`、`b4529d1 fix: bootstrap vendor checkouts without submodules`、`ca496d3 fix: stabilize cancelled download test`。
- H2 expected HEAD SHA gate、H4/H5 evidence 绑定校验、vendor VM standalone/debug/release evidence、evidence hygiene gate、`.gitignore` 清理都已在本地改动中补强。
- 本轮修复 Rust CI 失败点：`crates/fcb_core/src/server_api.rs` 的 `download_bytes_from_with_cancel_aborts_mid_body` 测试先置 cancel 并释放服务端响应，再 join worker，避免 worker 在第二段 body 上阻塞到 timeout。
- 本轮继续修复 scheduled evidence 阻塞：`scripts/bootstrap.sh` 会替换 Flutter framework 自带的 nested non-git placeholders，再 clone independent engine/Dart checkouts；`scripts/test_s3_storage.sh` 放宽 server 启动等待，并在失败时保留 server/MinIO logs 供 artifact 上传。
- Android/iOS scheduled workflows 已补前置依赖：Android 安装 `x86_64-linux-android` target 与 `cargo-ndk`，iOS 安装 `x86_64-apple-ios` target，两者在 bootstrap 后运行 `scripts/bootstrap_engine_min_deps.sh`。
- `scripts/bootstrap_engine_min_deps.sh` 的 OpenJDK 校验已兼容 macOS CIPD layout：支持 `third_party/java/openjdk/Contents/Home/bin/javac`。
- `scripts/bootstrap.sh` 已改为使用 Flutter framework checkout 自带的 `vendor/flutter/engine/src/flutter` engine source；该目录不再要求独立 git checkout。`third_party/dart` 仍会替换为独立 `lollipopkit/dartsdk` git checkout。

**已验证**
- `cargo test -p fcb_core server_api::tests::download_bytes_from_with_cancel_aborts_mid_body`: 通过。
- `bash -n scripts/bootstrap.sh scripts/test_s3_storage.sh`: 通过。
- `scripts/check_workflows.sh`: 通过。
- `bash -n scripts/bootstrap_engine_min_deps.sh`: 通过。
- `bash -n scripts/bootstrap.sh`: 通过。
- `scripts/bootstrap.sh --check`: 通过。
- `origin/main` `ca496d3514e8fdb2997c85d45ce2dc54db2a76e4` push workflows 已全绿：Workflow Lint、Flutter Package、Rust、Server、E2E x64。
- 远端 Rust run `27827682968` 在 `b4529d1` 上失败，失败测试为 `server_api::tests::download_bytes_from_with_cancel_aborts_mid_body`，panic 为 `timeout: receive body`。
- 手动 scheduled workflows 在 `ca496d3` 上仍失败：Android/iOS 都卡在 `scripts/bootstrap.sh` 的 nested engine placeholder；Server S3 卡在 `/healthz` 60 秒超时且原脚本未保留 artifact 日志。
- 手动 Server S3 Storage 在 `9cc8fdb` 上已通过：run `27828396980`。
- 手动 Android/iOS 在 `9cc8fdb` 上仍失败，但失败已后移：Android 缺 Engine `tools/gn`，iOS 缺 Rust `x86_64-apple-ios` target。
- 手动 Android 在 `ec0564b` 上失败于 `scripts/bootstrap_engine_min_deps.sh` 的 `openjdk bootstrap failed`，日志显示 macOS OpenJDK 已部署但路径不是 `bin/javac`。
- 手动 Android 在 `56a3b22` 上已通过 bootstrap 和 cache，失败后移到 build：`vendor/flutter/engine/src/flutter/tools/gn` 缺失。根因是 bootstrap 曾把 framework repo 再 clone 到 engine source 目录，导致实际 engine files 落在嵌套 `engine/src/flutter` 下。
- 之前本地已验证：`scripts/test_vendor_vm_runtime.sh` 通过；`scripts/check_phase_h_runbooks.sh` 通过；`scripts/audit_plan_completion.sh` 非 0 但剩余为 H2/H4/H5 外部证据。

**当前状态**
- 根仓库 `main...origin/main` 当前本地新增未提交修复：`scripts/bootstrap.sh`、`handoff.md`。
- 工作树仍有大量既有 staged/unstaged 改动，涉及 PLAN/docs、iOS SwiftPM、audit scripts、旧 `tests/e2e/vm_patch_*` 删除、kernel reader/manifest 等；不要盲目纳入本轮 Rust fix commit。
- 当前需要提交并 push scheduled evidence 修复后，再重新触发三条手动 scheduled workflows。

**下一步**
1. 提交并 push bootstrap engine source model 修复，commit message 建议 `fix: use framework engine source in bootstrap`。
2. 重新触发 Android Emulator Nightly、iOS Simulator Nightly，并等待结果。
3. H2 仍需所有 required push workflows 与 scheduled workflows 绑定新 expected HEAD 成功。
4. H4 需要真实 App Store Connect `External Testing` 证据。
5. H5 需要真实 `Vendor rebase validation passed` 证据，并用 record 脚本归档。
