# Phase E — Dart VM 真正可用

**关键路径**:Production-Ready 的卡脖子项。与 F/G/H 独立。
**真源**:`vendor/flutter/engine/src/flutter/third_party/dart`（Engine `DEPS` pin `lollipopkit/dartsdk` fork）。

## 目标

把 `runtime/vm/fcb_patch_runtime.*` 从 skeleton 升级为能解释真实业务 Dart 代码的 in-VM
interpreter,解释失败时安全 fallback 到原 AOT。退出标准:counter_app 真实业务 patch
（widget tree + setState + plugin method channel）正确运行。

## 现状(2026-06-21,据代码与 VM test)

interpreter 已远超 skeleton,核心执行能力**已接线并有 VM/standalone test 覆盖**(已接线 ≠
已设备验收)。Dart SDK 端由并行 agent 持续 refactor + commit,当前 pin 在
`2cac8b62c41f`。验收脚本 `scripts/test_vendor_vm_runtime.sh` 复跑通过(先 audit SDK delta,再
standalone,并默认重建 debug/release `run_vm_tests` 后跑 FCB filters);release/debug filter 列表由
`scripts/fcb_vm_test_filters.sh` 统一维护,避免执行脚本和 host evidence gate 漂移。证据写
`target/fcb/vendor-vm-test/summary.txt`;正式 evidence 要求 `rebuild_run_vm_tests: 1`,脚本已拒绝
`FCB_VENDOR_VM_REBUILD_RUNNERS=0` 写默认 canonical evidence dir,必须显式设置 scratch
`FCB_VENDOR_VM_TEST_DIR`。Kernel compile-from-plan e2e 证据写
`target/fcb/kernel-compile-from-plan/summary.txt`;`make check-phase-e-host-evidence` 会审计两份
host-side summary 及其指向的 SDK delta audit / 全量 release+debug filter 日志。
SDK delta audit 允许 FCB-owned 文件、少量注册/生成 offset/lifecycle official path,以及已验收的
5 个 FCB VM hook official path;这些 hook 的 diff 必须带 FCB marker,`async_patch.dart`
仍禁止承载 FCB delta。
`make check-phase-e-completion` 会额外要求当前 Android preflight、counter_app acceptance +
interpret-failure fallback、patch logcat interpreter stats 有样本且 `interpreter_ratio <= 1.0`、完整 desktop embedder target
同时满足,并写
`target/fcb/phase-e-completion/summary.txt`。`make test-phase-e-completion-gate` 用 fake evidence
回归测试该 completion gate 的 ratio pass/fail/no-samples/missing fail-closed 行为,并已纳入 local
core CI。`make test-phase-e-host-evidence-gate` 用 fake VM/Kernel evidence 回归测试 host gate
对缺 release log、缺 debug `Done:`、缺 summary filter 名、no-rebuild 写 canonical dir 的
fail-closed 行为,也已纳入 local core CI。

子阶段状态:

| 子阶段 | 内容 | 状态 |
|---|---|---|
| E1 | Value ↔ ObjectPtr 集成(真实 heap 对象 + GC root visitor + Smi0 边界) | ✅ |
| E2 | Opcode 集(call_static/dynamic/original、get/set_field、closure、is/as、try/throw、new_object、list/map) | ✅ |
| E3 | 编译器 Dart 化(见 frontend plan) | ✅(子集,持续扩) |
| E4 | 失败 fallback + source-map stack trace | ✅ |
| E5 | interpreter_ratio 统计上报 + completion gate + CLI inspect warning | ✅ |
| E6 | async suspend/resume、exception/finally、泛型 type env、递归 guard、debugger metadata、sync* finalizer | ✅ |

已闭合的执行缺口要点:
- **async**:pending `Await(0x62)` 单帧 suspend/resume(FCB 自有 `_FcbContinuation`,不复用 VM
  `_SuspendState`);连续 await、pending error 进 try/catch、finally cleanup、`Clear`/`DisablePatch`
  drain、迟到 token no-op、reload 后旧 snapshot resume 均覆盖。
- **exception/finally**:同步 `TryFinally`/`EndFinally`/`Rethrow` 覆盖 normal/return/throw;逃出
  patch 的业务 `Throw` materialize 后走 VM `Exceptions::ThrowWithStackTrace`;`PatchError` 与业务
  `DartException` 分层,内部错误不被 caller catch 吞掉。
- **泛型**:`RuntimeTypeEnvironment` 解析 `T`/`List<T>`;closure trampoline 与 VM `DartEntry` 把
  调用时 type args threaded 进 frame;arm64/x64 AOT static-call probe 支持 ≤4 user args 的 generic
  target(5 raw slots 走 `FcbPatchStaticCallAot5`)。
- **递归**:移除固定 64 上限,默认 guard 4096;入口接 `OSThread::HasStackHeadroom()`,命中返回
  `DartException(StackOverflowError)`。
- **debugger**:FCB frame 进 `DebuggerStackTrace`,可报 source location/locals/captured、参与
  evaluate;async/async* resume 后重报 active frame;active finally 不被误判为 catch frame。
- **生成器**:sync*/async* 完整(yield/yield*/await for、guarded break/continue、in-await、
  finally-cancel、backpressure);source-module nested `await for` 已覆盖外层 `continue`、内层
  `break`、三层 nested stream lowering、finally cleanup 以及正常/cancel/outer error/inner error
  runtime 路径;三层 nested stream 已补 normal/cancel/outer-error/middle-error/inner-error finally
  cleanup runtime 路径;abandoned Iterable/Iterator 经 Dart `Finalizer` → `_fcbDropGenerator` 回收。
- **真实业务 stream e2e**:`FcbPatchRuntimeBusinessStreamSourceE2e` 已覆盖 `await ready`、
  通用 Stream `await for`、nested `await for Stream.value(...)`、第二个通用 Stream 参数
  `yield* delegated` 的成功/data-then-error/cancel-after-fourth、`yield* Stream.value(...)`
  和 finally cleanup/error 传播。

## 剩余(真正未闭合)

1. **Engine/Fork 提交与构建验证** — `vendor/flutter/engine/src/flutter` 的错误嵌套 `.git`
   已移到 `target/fcb/git-metadata-backups/engine-src-flutter-dotgit-bad-head-20260621`;
   该目录现在由父仓库 `vendor/flutter` 管理,`scripts/bootstrap.sh --check` 已通过。embedder bridge
   (`shell/platform/embedder/fcb/fcb_embedder_vm_patch_bridge.{cc,h}`)已通过脚本化 FCB GN 生成和关键 C++
   编译单元验证(`make test-desktop-embedder-bridge`)。完整 macOS embedder target 已脚本化为
   `make test-desktop-embedder-full`;`make check-macos-metal-toolchain` 已通过。受限沙箱内首次
   full target 因 Metal/clang 写 `/var/folders/.../C/clang/ModuleCache` 被拒绝;提权复跑
   `make test-desktop-embedder-full` 已通过,summary 记录
   `FCB desktop embedder full target validation passed`。
2. **IDE 级 debugger** — VM `BreakpointLocation`/single-step registry、parked generator/async 帧
   pause/evaluate。已定界为 Phase E 后续独立阶段,非验收 blocker。
3. **前端长尾**(见 frontend plan):复杂交织控制流、更深层 async* stream cancel/error/finally
   cross-product 组合。迭代扩展,非 blocker。

## 已闭合的设备/退出证据(2026-06-22)

- `make test-android-arm64-acceptance`:通过。`target/fcb/android-arm64-acceptance/summary.txt`
  记录 primary arm64-v8a emulator,nopatch 观测
  `1/8/7/base/baseline widget tree/base-field/10`,patch 观测
  `42/42/42/patched/patched widget tree/patched-field/42`,interpret-failure fallback 观测
  `1/8/7/base/baseline widget tree/base-field/10`,且 bad patch recorded。
- `FCB_ADB_TIMEOUT_SECONDS=5 make check-phase-e-completion`:通过。`target/fcb/phase-e-completion/summary.txt`
  记录 host_evidence/android_device_preflight/android_acceptance/android_interpret_failure/
  android_interpreter_ratio/desktop_embedder_full 全 pass,patch interpreter stats 为 `7/5/0.583333`,
  默认上限 `1.0`。

## Host evidence gate

- VM filter 真源:`scripts/fcb_vm_test_filters.sh`,当前覆盖 42 个 release runtime filters 和 9 个
  debug debugger filters。
- `scripts/test_vendor_vm_runtime.sh` 与 `scripts/check_phase_e_host_evidence.sh` 共同 source 该列表;
  前者执行 filters,后者要求 summary 中列出每个 filter、对应 log 存在且包含 `Done:`。
- `make test-phase-e-host-evidence-gate` 覆盖 host gate fail-closed 场景,避免后续改 gate 时误放行
  缺失 VM filter evidence。
- `make check-kernel-compile-fixture-size` 同时约束这些 Phase E gate 脚本和 completion gate
  脚本的行数,避免验收脚本继续膨胀。

## 退出标准

- counter_app 真实 patch(widget tree + setState + plugin call)真机跑通。
- VM runtime 全绿:`scripts/test_vendor_vm_runtime.sh`(先跑 `audit_vendor_dart_sdk_delta.sh`
  隔离 SDK delta,再重建 debug/release `run_vm_tests` 并验收 VM)。
- 解释失败 fallback 端到端(抛错 → App 不崩 → 重启跳过 → server 收 `crash_rollback`)。
- counter_app patch-heavy acceptance 有 interpreter stats 样本且 `interpreter_ratio <= 1.0`
  (`make check-phase-e-completion`,默认门限 1.0,evidence 来自 Android patch logcat)。更严格的
  perf 门限可在后续性能阶段用 `FCB_PHASE_E_MAX_INTERPRETER_RATIO` 收紧,但不再作为 Phase E
  patch 功能验收 blocker。

## 风险

| 风险 | 缓解 |
|---|---|
| Engine source 由父 `vendor/flutter` 管理,误建嵌套 checkout 会破坏 status | 保留错误 `.git` 备份;后续在父仓库提交 bridge |
| ObjectPtr 集成踩 GC 时序 | stress test 模式;`FcbPatchRuntimeGcStress` 等覆盖 |
| Dart SDK upstream rebase 时 stub_code hook 漂移 | pin SDK commit;rebase 由 `vendor/REBASE.md`(Phase H)承担 |
| `call_original` 拿不到原 AOT entry | 已验证 AOT real extraction 存活(`cargo test -p fcb -- --ignored aot_real`);见 ADR-#2 |
