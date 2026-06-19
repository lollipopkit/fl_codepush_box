**目标**
完成 FCB bytecode / VM interpreter 已确认缺口，补齐测试集与审计证据。当前 goal 状态仍是 blocked，原因是外部证据项仍缺真实闭环，不是本地提交缺失。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库不使用 vendor submodule。
- generated evidence 只放 `target/fcb/evidence/*`；`tests/e2e` 不再保存生成证据归档。
- 不要 force push。

**已完成**
- 根仓库本地新增 3 个 commit，尚未 push：
  - `fa835e5 fix: harden phase h evidence audit`
  - `c78eebe fix: prepare fcb ios swiftpm package`
  - `9e33fb1 fix: infer fcb kernel return convention`
- `fa835e5`：Phase H audit/runbook 证据校验加固，GitHub Actions evidence 绑定 expected HEAD，TestFlight/vendor rebase evidence 要求绑定 build/ref/commit，旧 `tests/e2e/vm_patch_*` 生成证据归档删除。
- `c78eebe`：iOS plugin 增加 SwiftPM package 结构，counter_app 调整 bundle/team 配置与 H4 设备日志辅助，plugin 增加 `log` channel。
- `9e33fb1`：kernel reader 记录 return type，manifest 为 `int` return 自动使用 `unboxed_int64`。
- 已用 `exedev-ctl` 修复 `lkghr1` / `lkghr5` runner workspace 权限；实际失败 runner 是 `lkghr1-fl-codepush-box` Docker 容器，修复点在容器内 `/tmp/runner/work/fl_codepush_box`。

**已验证**
- `dart format examples/counter_app/lib/main.dart examples/counter_app/lib/pricing_source.dart packages/fcb_code_push/lib/fcb_code_push.dart tool/fcb_kernel_manifest.dart tool/fcb_kernel_reader.dart`: 通过，仅格式化了 `examples/counter_app/lib/main.dart`。
- `scripts/check_workflows.sh`: 通过。
- `scripts/check_phase_h_runbooks.sh`: 通过。
- 最新 `origin/main` push commit `23c9126d6d7a87332a8144e85499aca03e52c710` 的 required workflows 已全绿：Workflow Lint、E2E x64、Rust、Server、Flutter Package。
- 权限修复后，Server 与 Flutter Package rerun 的 `Checkout` 步骤均成功，最终 workflow 也成功。

**当前状态**
- `git status --short --branch`: `main...origin/main [ahead 3]`，工作树干净。
- 这 3 个 commit 尚未 push；用户当前只要求“该提交的全部提交了”，未要求本轮自动 push。
- 旧的 Android/iOS nightly failure 是 `9d9d67c` 的 workflow_dispatch 结果，不代表最新 `23c9126d` push 状态。

**下一步**
1. 如用户确认推送，执行普通 `git push`，不要 force push。
2. push 后重新观察 latest Actions；如需要 H2 证据，重新触发/记录绑定最新 HEAD 的 scheduled workflows。
3. H4 仍需真实 App Store Connect External Testing 证据。
4. H5 仍需真实 vendor rebase validation evidence。
