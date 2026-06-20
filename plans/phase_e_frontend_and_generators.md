# Phase E 补全 — Kernel 前端追平 + 生成器完整化

**背景**:VM 执行层已铺满 sync / async-await(含 pending 真挂起)/ sync* / async*。本 plan 覆盖
Kernel 前端(`tool/fcb_kernel_*.dart`)把"VM 能跑"追平到"真实源能热更",以及生成器语义完整化。

## 架构

```
真实 Dart 源 → Kernel(.dill)
  → fcb_kernel_reader.dart            # Kernel AST → 受限 JSON IR(bytecode_source)
    ├─ fcb_kernel_unsupported_audit.dart   # 闸门:reader 不支持的节点必 reject(fail-closed)
    └─ fcb_kernel_*_expr.dart              # 按构造下降(async/statement/generator/stream…)
  → fcb_kernel_manifest.dart          # 受限 IR → bytecode 字节(Pop/seq/yield/async_kind)
  → fcb_core(Rust)                   # IR/字节 ⇄ 二进制 FCBM
  → VM fcb_patch_runtime*             # 解释执行
```

关键约束:`reader` 按 body 形状识别,reader 不支持的节点 audit 必 reject(覆盖度严格对齐)。

## 现状(2026-06-21,据代码)

| 阶段 | 内容 | 状态 |
|---|---|---|
| P0 | VM 编译 + `run_vm_tests` + compile-from-plan e2e | ✅ |
| P1 | 通用语句下降 + 一般 `async/await` 前端 | ✅(子集,持续扩) |
| P2 | `sync*`/`async*` 生成器前端下降 | ✅(子集,持续扩) |
| P3 | `async*` 完整化(yield* / 内 await / finally-cancel) | ✅(核心闭合,长尾扩) |
| P4 | 硬化 + debugger + counter_app 退出 e2e | ⚠️ 设备验收阻断 |

**P1 已覆盖**:`Block`/`seq`、`if-else`、`while`/`do-while`/C-style `for`(含 guard
`break`/`continue` 及其组合)、local `let`/`set_local`、一般 pending `await`(`Await(0x62)` +
`AsyncReturn(0x63)`)、await tail 序列、`try/catch/finally`(含 finalizer 内二次 await)、
`Future<void>` 隐式/显式 return、`dart:*` static invocation → `CallOriginal(0x52)`。

**P2/P3 已覆盖**:多 `yield`、guarded `if` yield、静态/动态 `for-in` yield body、`yield*`
(sync* list literal 静态展开、动态 Iterable 委派、async* `Stream.fromIterable/value/empty/fromFuture`
及通用 Stream 参数真实 subscription 委派)、`await for`(各有限 stream 源 + 通用 Stream 参数 v1,含
guarded continue/break、nested、外层 finally cleanup)、async* 内 pending `await` 挂起/恢复
(`ResumeAsyncStar`)、cancel 跑 `finally`、subscription pause/resume 背压。

**测试锚点**:`tests/e2e/test_kernel_compile_from_plan.sh`(真实 Kernel → binary module →
`FcbPatchRuntimeAsyncStarSourceModuleStreamListen` 跑 ~30 个源级生成器/await-for 用例);
`tests/e2e/test_kernel_business_stream_e2e.sh`(`FcbPatchRuntimeBusinessStreamSourceE2e` 跑真实业务
`async* { await; yield; await for; yield*; finally }` 含 error-after-yield、cancel-after-second);
Python 断言拆在 `tests/e2e/kernel_compile_from_plan/`。

**前端代码组织**:`fcb_kernel_reader.dart`(1471)、`fcb_kernel_manifest.dart`(1488,reader bundle
拆到 `fcb_kernel_reader_bundle.dart`)、generator lowering 拆为
`fcb_kernel_generator_{expr,for_expr,loop_expr,stream_expr}.dart`、`fcb_kernel_async_expr.dart`。
SDK delta 边界由 `scripts/audit_vendor_dart_sdk_delta.sh` 守护(禁止 `async_patch.dart` 带 FCB
delta,FCB helper 集中在 `fcb_async_patch.dart`)。

## 剩余

1. **P4 退出标准(阻断)**:counter_app 真实 `sync*`/`async*`/一般 `async` 业务 patch 真机/模拟器
   跑通。当前仅 source/JIT widget smoke(`flutter test test/widget_test.dart`)通过;Android 设备验收
   卡在无设备(`adb devices` 空)。引擎侧接线提交还受 engine repo `bad object HEAD` 阻断(见
   `phase_e_dart_vm.md`)。
2. **前端长尾**(非 blocker,迭代扩):复杂交织控制流(多层 dynamic `for-in`、复杂 `while`/`for`
   update);更复杂/多层 async* stream 委派 cancel/finally 组合;更多多源嵌套 `await for` cancel/error 组合。
3. **IDE 级 debugger**:parked generator/async 帧的 pause/evaluate、VM breakpoint registry(后续独立阶段)。

## 风险

| 风险 | 缓解 |
|---|---|
| 通用语句下降范围发散 | 已覆盖 block/if/while/for/return/await/try;其余 fail-closed 到 `unsupported_kernel_node`,迭代扩 |
| 前端 reject 收窄导致误编不支持节点 | reader 不支持的节点 audit 必 reject,覆盖度严格对齐 |
| async* 内 await 与背压交织复杂 | 已单独闭合(P3)并充分单测;长尾组合继续补 |

## 不在本 plan(沿用既有边界)

- snapshot_replace 后端;debugger 完整化的非生成器部分。
- 顶层 vendor 本地 checkout;根工作树无关改动不纳入提交。
