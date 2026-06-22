# Phase H — Vendor 集成 + CI + 真机/商店验证

**所属阶段**：production-ready 必做
**预计工作量**：1 月（不含 TestFlight 审核等待时间）
**前置依赖**：Phase E 完成（真机能验证 bytecode 语义），G 完成（crash 自动回滚可测）
**并行性**：H1 / H2 可与 E/F/G 并行启动；H3 / H4 串行依赖 E、G

## 目标

把项目从"本地能跑"提升到"任意人 clone + CI 绿 + 真机/真用户验证"：

1. `vendor/{flutter,depot_tools}` 作为本地 checkout 管理；Flutter Engine embedded
   Dart 通过 `DEPS` 指向并 pin `lollipopkit/dartsdk` fork；文档化 rebase 流程。
2. GitHub Actions：Linux runner 构建 + cargo test + e2e；macOS runner 跑 iOS build 与模拟器测试。
3. arm64-v8a 真机走完整 release → patch → restart → crash → 回滚流程。
4. iPhone arm64 同样跑一遍；TestFlight 提交 counter_app 验证 Apple 审核通过。
5. `vendor/REBASE.md` 写每季度 rebase fork 到 Flutter stable 的步骤。

## 现状

- Engine embedded Dart SDK = `vendor/flutter/engine/src/flutter/third_party/dart`，`DEPS` 指向 `github.com/lollipopkit/dartsdk`，pin 到 `1b88776798d`（已含 FCB Phase D commits）
- vendor/flutter = `github.com/lollipopkit/flutter`，HEAD `87c1bc51504`（已含 FCB Android + iOS engine hooks）
- vendor/depot_tools：上游 chromium depot_tools（无 fork 必要，pin commit 即可）
- 顶层 vendor 不使用 submodule；当前 audit 只要求本地 checkout、remote 与 Engine DEPS pin 正确
- `scripts/build_android_engine.sh`、`build_ios_engine.sh`、`test_android_arm64.sh`、`test_ios_sim.sh` 已存在
- `.github/workflows/` 已有本地 workflow 定义；远端成功 run 证据仍缺

## 子阶段

### H1 — vendor checkout + 锁定（3 天）

**任务**

- 把 2 个顶层 vendor 目录作为本地 checkout 管理，并由 Flutter Engine `DEPS` pin Dart SDK fork：

- 各 fork 内创建长期分支：
  - `lollipopkit/flutter` 上建 `fcb-stable`（追 Flutter stable + FCB engine hooks）
  - `lollipopkit/dartsdk` 上建 `fcb-3.12.2`（追 Dart 3.12.2 + FCB patch runtime）
- 锁定 commit：在对应 fork branch / Engine `DEPS` 中记录，不通过根仓库 gitlink 记录。
- 不再维护顶层 `vendor/dart`、`vendor/sdk`、`engine_patch/`、`dart_sdk_patch/` 或同步脚本；开发期直接在
  `vendor/flutter` 与 embedded Dart checkout 上开分支，稳定后更新 pinned commits。
- `scripts/bootstrap.sh`：只校验本地 checkout 与 embedded Dart 真源，不执行 submodule update。

**关键文件**

- `scripts/bootstrap.sh`
- 修改 `README.md`：加 clone 步骤

**验收**

- 在干净机器上 `git clone --recursive` + `scripts/bootstrap.sh` 后 `vendor/` 三个目录就绪。
- HEAD commit 在 PR 中可见（不会 silent drift）。

---

### H2 — GitHub Actions CI（2 周）

**任务**

- `.github/workflows/rust.yml`：
  - Linux runner，Rust stable
  - `cargo fmt --check`
  - `cargo clippy --all-targets -- -D warnings`
  - `cargo test --workspace`
- `.github/workflows/server.yml`：
  - Go 1.22
  - `go vet ./...`
  - `go test ./...`
- `.github/workflows/e2e_x64.yml`：
  - Linux runner
  - Bootstrap vendor
  - `scripts/test_e2e.sh`（fake Flutter 路径，快速验证 CLI/server/updater）
- `.github/workflows/android_emulator.yml`（夜间）：
  - macOS runner（KVM 兼容性最好）
  - 安装 Android SDK + emulator
  - Bootstrap vendor → `scripts/build_android_engine.sh` → 启动 emulator → `scripts/test_android_x64.sh`
  - 缓存 engine out 目录避免每次重编
- `.github/workflows/ios_simulator.yml`（夜间，optional）：
  - macOS runner
  - Bootstrap → `scripts/build_ios_engine.sh` → `scripts/test_ios_sim.sh`

**关键文件**

- 5 个 workflow YAML

**验收**

- 每次 push 到 main 触发 rust + server + e2e_x64 三个 workflow，全绿。
- 夜间 android_emulator 在 1 小时内完成。

---

### H3 — arm64-v8a 真机验证（1 周，依赖 G）

**任务**

- 设备：物理 arm64 Android 手机（用户已有，参考 `scripts/check_android_arm64_device.sh`）
- 流程脚本 `scripts/full_arm64_drill.sh`：
  1. 构造 counter_app，`fcb release android --arch arm64-v8a`
  2. install APK，启动验证 baseline
  3. 修改 main.dart，`fcb patch android --patch-number 1`
  4. promote 100%
  5. 启动 App，下载 patch（log 验证）
  6. 重启，验证 patched 输出
  7. 故意造 crash patch（首帧前 throw）：`fcb patch android --patch-number 2 --payload ...`
  8. 启动 3 次，验证自动回滚到 patch 1（LKG）
  9. server admin UI 验证 `crash_rollback` 事件可见
  10. `fcb rollback --patch-number 1`，重启验证回 baseline
- 录屏 + 日志归档到 `target/fcb/evidence/arm64_drill_<date>/`
- 已知问题列入 `docs/known_issues.md`

**关键文件**

- 新建 `scripts/full_arm64_drill.sh`
- 复用 `scripts/test_android_arm64.sh`（已存在）

**验收**

- 全流程 10 步无人工干预通过。
- crash patch 在 3 次启动后自动回滚，App 不再加载 bad patch。
- server 事件流完整。

---

### H4 — iPhone arm64 + TestFlight（1 周 + 审核等待）

**任务**

- 设备：物理 iPhone（arm64）
- 流程：
  1. `scripts/build_ios_engine.sh` 构建 iOS engine（设备 + 模拟器双架构）
  2. counter_app 配 fcb_code_push pod，xcode 签名
  3. 装机跑 release / patch / restart 三步
  4. 触发 crash patch 验证 LKG 回滚（Phase G 必须完成）
- TestFlight：
  - Apple Developer 账号、bundle id、provisioning profile
  - `fastlane` 或 `xcrun altool` 上传 build
  - 提交内审核（External Testing 一般 24h）
  - 通过即"Apple 审核接受 FCB bytecode payload"的实证
- 失败应对：
  - 若 Apple 拒，分析 review 通知，可能涉及：bytecode 不能下载（policy 4.7）、interpreter scope（policy 2.5）。
  - 准备申诉文档：明确"FCB bytecode 是 interpreted code，不改变 App 主要功能，不绕过 sandbox"。

**关键文件**

- `docs/ios_distribution.md`：xcode 签名 + TestFlight 上传步骤
- `docs/apple_compliance.md`：基于 Apple Developer Program License 的合规说明

**验收**

- 真机 patch 安装 + crash 回滚正确。
- TestFlight build 至少进入 External Testing。
- 若被拒，issue 跟踪整改路径。

---

### H5 — vendor rebase 文档（3 天）

**任务**

- `vendor/REBASE.md`：
  - 每季度 rebase 流程（Flutter stable cherry-pick → FCB hook commits 重放）
  - 验证 checklist：engine 编译通过、cargo test 通过、e2e_x64 通过、arm64 真机 drill 通过
  - 已知冲突点：stub_code_compiler 因 Dart SDK upstream 变动易冲突，提供 rebase 策略
  - 回滚预案：若 rebase 引入 regression，回退到上一稳定 vendor checkout commit

**关键文件**

- 新建 `vendor/REBASE.md`

**验收**

- 文档至少在一次实际 rebase 中验证可执行。

## 风险与缓解

| 风险 | 严重性 | 缓解 |
|------|--------|------|
| GitHub Actions Android emulator 不稳定 | 中 | 降级为夜间 + retry 3 次，关键 PR 检查在 e2e_x64 |
| iOS engine 构建在 CI 上慢（>1h） | 中 | 缓存 `out/ios_release` + 仅在 vendor checkout ref 变动时重编 |
| TestFlight 被 Apple 拒 | 高 | 接受作为 risk，准备申诉材料；预留备选路线"仅 Android" |
| vendor checkout 拉不到老 commit | 低 | 在 rebase 时 fetch 对应 fork branch/commit，CI 不受影响 |
| Rust + Go + Dart + C++ 多语言 CI 难维护 | 中 | 拆 workflow 单一职责，job 失败原因清晰 |

## 退出标准

- `vendor/flutter` 与 `vendor/depot_tools` 作为本地 checkout 校验；
  embedded Dart SDK commit 由 Flutter Engine `DEPS` 清晰锁定。
- main 分支 CI 三个 workflow 持续绿。
- arm64-v8a 真机 drill 全流程通过且录屏归档。
- iPhone 真机验证通过，TestFlight 至少进入 External Testing。
- REBASE.md 完成首次实战验证。
