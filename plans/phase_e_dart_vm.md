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
`0faa95f739c`。验收脚本 `scripts/test_vendor_vm_runtime.sh` 复跑通过(先 audit SDK delta,再
standalone,并默认重建 debug/release `run_vm_tests` 后跑 FCB filters),证据写
`target/fcb/vendor-vm-test/summary.txt`;Kernel compile-from-plan e2e 证据写
`target/fcb/kernel-compile-from-plan/summary.txt`;`make check-phase-e-host-evidence` 会审计两份
host-side summary 及其指向的 SDK delta audit / release filter 日志。
`make check-phase-e-completion` 会额外要求当前 Android preflight、counter_app acceptance +
interpret-failure fallback、patch logcat `interpreter_ratio <= 0.01`、完整 desktop embedder target
同时满足,并写
`target/fcb/phase-e-completion/summary.txt`。`make test-phase-e-completion-gate` 用 fake evidence
回归测试该 completion gate 的 ratio pass/fail/no-samples/missing fail-closed 行为,并已纳入 local
core CI。

子阶段状态:

| 子阶段 | 内容 | 状态 |
|---|---|---|
| E1 | Value ↔ ObjectPtr 集成(真实 heap 对象 + GC root visitor + Smi0 边界) | ✅ |
| E2 | Opcode 集(call_static/dynamic/original、get/set_field、closure、is/as、try/throw、new_object、list/map) | ✅ |
| E3 | 编译器 Dart 化(见 frontend plan) | ✅(子集,持续扩) |
| E4 | 失败 fallback + source-map stack trace | ✅ |
| E5 | interpreter_ratio 统计上报 + completion gate + CLI inspect warning | ✅(当前设备验收待办) |
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

1. **counter_app 真机/模拟器 patch 验收(退出标准)** — 未执行。Android:
   `check-android-arm64-device` / `test-android-arm64-acceptance` Makefile 入口已接到
   `scripts/check_android_arm64_device.sh` / `scripts/accept_android_arm64.sh`;
   `FCB_ADB_TIMEOUT_SECONDS=5 make check-android-arm64-device` 现在会快速失败在
   `adb wait-for-device` timeout,说明当前仍无设备。旧
   `target/fcb/android-arm64-acceptance/summary.txt` 显示 2026-06-19 emulator acceptance 通过,
   但缺 interpret-failure fallback summary,且当前 device preflight 不通过,不作为完成证据。
   `target/fcb/phase-e-completion/summary.txt` 当前显示 host_evidence/pass、android_acceptance/pass,
   android_interpreter_ratio/fail(`0/0/0.000000` 无样本),且
   android_device_preflight/android_interpret_failure/desktop_embedder_full 仍 fail。
   当前仅有 source/JIT 下的 widget smoke(`flutter test test/widget_test.dart`)通过,不替代 bytecode 验收。
2. **Engine/Fork 提交与构建验证** — `vendor/flutter/engine/src/flutter` 的错误嵌套 `.git`
   已移到 `target/fcb/git-metadata-backups/engine-src-flutter-dotgit-bad-head-20260621`;
   该目录现在由父仓库 `vendor/flutter` 管理,`scripts/bootstrap.sh --check` 已通过。embedder bridge
   (`shell/platform/embedder/fcb/fcb_embedder_vm_patch_bridge.{cc,h}`)已通过脚本化 FCB GN 生成和关键 C++
   编译单元验证(`make test-desktop-embedder-bridge`)。完整 macOS embedder target 已脚本化为
   `make test-desktop-embedder-full`,该入口先跑 `make check-macos-metal-toolchain` 等价 preflight;
   当前 fast-fail 并记录 `target/fcb/desktop-embedder-full/summary.txt`。手工完整 target 在带
   `vendor/depot_tools` PATH 与 workspace `VPYTHON_VIRTUALENV_ROOT` 后已越过 `vpython3` 和大段编译,
   但仍在 `metal_library.py` 调 `xcrun -sdk macosx metal` 时报缺 Metal Toolchain
   (`xcodebuild -downloadComponent MetalToolchain`);本轮尝试申请提权安装该组件被安全策略拒绝,
   需用户显式授权或手动安装后复跑。
3. **IDE 级 debugger** — VM `BreakpointLocation`/single-step registry、parked generator/async 帧
   pause/evaluate。已定界为 Phase E 后续独立阶段,非验收 blocker。
4. **前端长尾**(见 frontend plan):复杂交织控制流、更深层 async* stream cancel/error/finally
   cross-product 组合。迭代扩展,非 blocker。

## 退出标准

- counter_app 真实 patch(widget tree + setState + plugin call)真机跑通。
- VM runtime 全绿:`scripts/test_vendor_vm_runtime.sh`(先跑 `audit_vendor_dart_sdk_delta.sh`
  隔离 SDK delta,再重建 debug/release `run_vm_tests` 并验收 VM)。
- 解释失败 fallback 端到端(抛错 → App 不崩 → 重启跳过 → server 收 `crash_rollback`)。
- counter_app 场景 `interpreter_ratio < 1%`(`make check-phase-e-completion`,默认门限 0.01,
  evidence 来自 Android patch logcat)。

## 风险

| 风险 | 缓解 |
|---|---|
| Engine source 由父 `vendor/flutter` 管理,误建嵌套 checkout 会破坏 status | 保留错误 `.git` 备份;后续在父仓库提交 bridge |
| ObjectPtr 集成踩 GC 时序 | stress test 模式;`FcbPatchRuntimeGcStress` 等覆盖 |
| Dart SDK upstream rebase 时 stub_code hook 漂移 | pin SDK commit;rebase 由 `vendor/REBASE.md`(Phase H)承担 |
| `call_original` 拿不到原 AOT entry | 已验证 AOT real extraction 存活(`cargo test -p fcb -- --ignored aot_real`);见 ADR-#2 |
