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
`0faa95f739c`。验收脚本 `scripts/test_vendor_vm_runtime.sh` 复跑通过(standalone +
debug/release `run_vm_tests` FCB filters),证据写 `target/fcb/vendor-vm-test/summary.txt`。

子阶段状态:

| 子阶段 | 内容 | 状态 |
|---|---|---|
| E1 | Value ↔ ObjectPtr 集成(真实 heap 对象 + GC root visitor + Smi0 边界) | ✅ |
| E2 | Opcode 集(call_static/dynamic/original、get/set_field、closure、is/as、try/throw、new_object、list/map) | ✅ |
| E3 | 编译器 Dart 化(见 frontend plan) | ✅(子集,持续扩) |
| E4 | 失败 fallback + source-map stack trace | ✅ |
| E5 | interpreter_ratio 统计上报 + CLI inspect warning | ✅(设备实测待办) |
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
  finally-cancel、backpressure);abandoned Iterable/Iterator 经 Dart `Finalizer` →
  `_fcbDropGenerator` 回收。

## 剩余(真正未闭合)

1. **⚠️ 阻断:Engine repo 损坏** — `vendor/flutter/engine/src/flutter` 报 `fatal: bad object HEAD`
   (HEAD ref → `d0a71d3`,但该 commit object 缺失)。embedder bridge
   (`shell/platform/embedder/fcb/fcb_embedder_vm_patch_bridge.{cc,h}`)已在磁盘但无法 status/commit。
   需先修复(reflog/重新 fetch fork pin)才能提交引擎接线与做 desktop/per-OS 引擎构建。
2. **counter_app 真机/模拟器 patch 验收(退出标准)** — 未执行。Android:
   `scripts/check_android_arm64_device.sh` 卡 `adb wait-for-device`、`adb devices` 为空。
   当前仅有 source/JIT 下的 widget smoke(`flutter test test/widget_test.dart`)通过,不替代 bytecode 验收。
3. **IDE 级 debugger** — VM `BreakpointLocation`/single-step registry、parked generator/async 帧
   pause/evaluate。已定界为 Phase E 后续独立阶段,非验收 blocker。
4. **前端长尾**(见 frontend plan):复杂交织控制流、更多多层 async* stream cancel/finally 组合。迭代扩展,非 blocker。

## 退出标准

- counter_app 真实 patch(widget tree + setState + plugin call)真机跑通。
- VM runtime 全绿:`scripts/test_vendor_vm_runtime.sh`(先跑 `audit_vendor_dart_sdk_delta.sh`
  隔离 SDK delta,再验收 VM)。
- 解释失败 fallback 端到端(抛错 → App 不崩 → 重启跳过 → server 收 `crash_rollback`)。
- counter_app 场景 `interpreter_ratio < 1%`(`scripts/accept_android_arm64.sh`,默认门限 0.01)。

## 风险

| 风险 | 缓解 |
|---|---|
| Engine repo HEAD 损坏阻断引擎侧提交/构建 | 优先修复;不盲改无关对象 |
| ObjectPtr 集成踩 GC 时序 | stress test 模式;`FcbPatchRuntimeGcStress` 等覆盖 |
| Dart SDK upstream rebase 时 stub_code hook 漂移 | pin SDK commit;rebase 由 `vendor/REBASE.md`(Phase H)承担 |
| `call_original` 拿不到原 AOT entry | 已验证 AOT real extraction 存活(`cargo test -p fcb -- --ignored aot_real`);见 ADR-#2 |
