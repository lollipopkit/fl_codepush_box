# Phase E — Dart VM 真正可用

**所属阶段**：关键路径（Production-Ready 的卡脖子）
**预计工作量**：6–10 人月
**前置依赖**：无（vendor fork 已把 skeleton 落地，可直接开工）
**并行性**：与 F/G/H 完全独立

## 目标

把 `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.{h,cc}`
从 plain-struct skeleton 升级为能解释真实业务 Dart 代码的 in-VM interpreter,并在解释失败时
安全 fallback 到原 AOT。验收标准:counter_app 真实业务级 patch（修改 widget tree、调用
setState、调用 plugin method channel）能正确运行。

## 现状（2026-06-19 实测确认）

Dart VM 真源 = `vendor/flutter/engine/src/flutter/third_party/dart`（Engine `DEPS` 指向并 pin
`lollipopkit/dartsdk` fork）。已有能力:

| 文件 | 角色 |
|------|------|
| `runtime/vm/fcb_patch_runtime.{h,cc}` | BytecodeModule 加载、Value/InterpretResult 数据结构、PatchState 枚举 |
| `runtime/vm/fcb_patch_entry.{h,cc}` | DispatchDecision、与 stub_code 的 ABI 桥 |
| `runtime/vm/fcb_patch_api.{h,cc}` | Engine-facing `LoadPatchRuntimeForIsolateGroup` / `ClearPatchRuntimeForIsolateGroup` |
| `runtime/vm/fcb_patch_runtime_test.cc` | VM 单测,开工前先跑通 |
| `runtime/vm/compiler/stub_code_compiler_{arm,arm64,x64,ia32,riscv}.cc` | 全架构 dispatch stub |
| `runtime/vm/runtime_entry.cc` / `runtime_entry_list.h` | runtime entry 注册 |

dispatch 链路已打通。当前 runtime 已不再是纯 plain-struct skeleton: `Value` 已持有
`ObjectPtr object_value`,有 `Value::FromDart(ObjectPtr)` / `Value::ToDart()` 与 GC root
visitor,`List`/`Map`/`NewObject`/`CallDynamic`/`CallOriginal` 可跨 Dart 边界跑通。已有
VM tests 覆盖 concrete generic `List<int>` vs `List<String>`、Dart exception 被本地
`TryBegin` catch、debugger active frame/evaluate metadata。

仍未闭合的执行缺口:

1. **真实 async suspend/resume**:已支持 immediate async 子集:非 Future/FutureOr 值、已完成
   `_Future.value(...)` 可在 interpreter 内同步拆箱,已完成 error Future 可把 `AsyncError.error`
   转成业务 Dart exception 并被 interpreted `TryBegin` 捕获,`async_future` 的 `AsyncReturn`
   可生成 completed `_Future.value(...)`。仍没有 VM continuation 挂起/恢复,未完成 Future、
   chained Future 仍 fail-closed。
2. **VM unwinder 级异常传播/finally**:同步 `TryFinally`/`EndFinally`/`Rethrow` 已能在
   interpreter 内覆盖 normal/return/throw 三条路径;逃出 patched function 的业务 `Throw` 已变为
   `InterpretResult::DartException`,并由 `fcb_patch_entry.cc` materialize 后调用 VM
   `Exceptions::Throw`。await suspension 周围的 finally 尚未实现。内部 `PatchError` 已和业务
   `DartException` 分层,不会再被 caller 的 catch handler 当作业务异常吞掉。
3. **泛型 type parameter 语义**:concrete `List<String>` 已覆盖;resolver 已支持 runtime type
   environment 下的 `T` / `List<T>` 解析并传给 `IsInstanceOf`;bytecode closure invocation 和
   VM `DartEntry` 普通 generic function call 已把调用时 type args threaded 到 interpreter frame。
   arm64/x64 AOT static-call probe 已支持最多 4 个 user args 的 generic target,通过 raw
   `TypeArguments` slot 构建 interpreter type environment;5 raw slots 走专用
   `FcbPatchStaticCallAot5` runtime entry。
4. **递归深度策略**:固定 `kMaxCallStaticDepth = 64` 已移除;默认 runaway guard 提升为
   `PatchRuntimeOptions::max_call_depth = 4096`,测试覆盖 96 层递归通过和低 guard 清晰失败。
   interpreter 入口已接入 VM `OSThread::HasStackHeadroom()` 检查,在 C++ stack headroom 不足时
   fail-closed 为 `PatchError`;真正 Dart `StackOverflowError` unwinder 语义仍未闭合。
5. **debugger pause/evaluate 完整性**:active frame 已上报,但 breakpoint/step/pause 与 async
   resume 后逻辑栈仍未完整。

## 子阶段

### E1 — Value ↔ ObjectPtr 集成（2–3 人月）

**任务**

- 把 `struct Value` 从 plain C++ 升级为持有 `ObjectPtr`（指向 Dart heap 上的真实对象）。
- `Value::Int / Double / Bool / String / List / Map` 工厂在 `Thread::Current()->isolate_group()`
  下 allocate Dart 对象。
- 实现 `Value::FromDart(ObjectPtr)` 与 `Value::ToDart()` 双向转换。
- `BytecodeModule::Load` 的 constant pool 改为分配 Dart object。
- 在 `IsolateGroup` 注册 `FcbPatchRuntime*` 字段,纳入 `VisitObjectPointers` 让 GC 扫 root。

**关键文件**

- `runtime/vm/fcb_patch_runtime.{h,cc}`（`enum ValueKind`、`struct Value`、Value 工厂、ModuleLoader）
- `runtime/vm/isolate.{cc,h}`（添加 `fcb_patch_runtime_` 成员）
- `runtime/vm/program_visitor.cc`（snapshot 路径上的 visit）

**验收**

- 现有 VM test 以 ObjectPtr 形式重写,通过。
- GC stress test:连续 100 次 GC + patch 调用,无悬挂指针。
- `tools/test.py runtime/vm/fcb_patch_runtime_test` 绿。

---

### E2 — Opcode 集补全（2–3 人月）

按业务覆盖优先级实现。每条 opcode:interpreter case + 单测 + 编译器侧产生（E3）。

| 优先级 | opcode | 覆盖语义 | 难度 |
|--------|--------|---------|------|
| P0 | `call_static` | 静态/顶层函数调用,走 `DartEntry::InvokeFunction` | 中 |
| P0 | `call_dynamic` | instance method（含 vtable lookup） | 高 |
| P0 | `call_original` | 调用未变函数的原 AOT 实现（关键合规点:复用 AOT） | 高 |
| P0 | `get_field` / `set_field` | 实例字段读写,走 `Field::Offset` | 中 |
| P0 | `string_concat` / `string_interp` | 字符串拼接和插值 | 低 |
| P1 | `make_closure` / `call_closure` | 闭包捕获 + 调用 | 高 |
| P1 | `is_type` / `as_type` | 类型检查/转换,走 `TypeTester` | 中 |
| P1 | `try_catch` / `throw` | 异常处理（与 VM unwinder 协作） | 高 |
| P1 | `await` / `async_resume` | future continuation;与 `_FutureImpl` state machine 集成 | 极高 |
| P2 | `new_object` | 调用 generative constructor + 初始化字段 | 中 |
| P2 | `list_lit_extended` / `map_lit_extended` | spread、collection-if、collection-for | 中 |

**关键文件**

- `runtime/vm/fcb_patch_runtime.cc` 的 `Interpret()` 主循环
- `runtime/vm/dart_entry.cc`（`call_original` hook）
- `runtime/vm/runtime_entry.cc`（FCB runtime entry 注册）

**验收**

- 每条 opcode 至少 3 个单测（happy path、boundary、error）。
- 集成测试:手写 BytecodeModule 覆盖一条 patched widget `build()`,含 setState、字符串插值、
  call_original,端到端跑通。

---

### E3 — 编译器 Dart 化（1–2 人月）

扩展 `tool/fcb_kernel_manifest.dart`:

- CLI 子命令 `--compile-from-plan plan.json --patch patch.dill -o module.fcbm`。
- 用 `package:kernel` 遍历 `Member.function.body`,把 `Statement`/`Expression` 翻译为 E2 的
  opcode 序列。
- 输出 binary 格式严格对齐 `fcb_core::bytecode::BytecodeModule`（magic + version + constant
  pool + function table + instructions）。
- constant pool 去重。
- 遇到 unsupported Kernel node → `RejectReason::UnsupportedKernelNode` 写进 `patch_report`。
- `crates/fcb_bytecode` 退化为 schema 校验 + 反序列化（给 `fcb inspect` 用）。
- CLI 侧改为 spawn Dart 工具,读 binary 输出。

**关键文件**

- `tool/fcb_kernel_manifest.dart`
- `cli/src/main.rs`、`cli/src/auto.rs`（compile/read bytecode）
- `crates/fcb_core/src/bytecode.rs`（schema/reader）

**验收**

- e2e:counter_app `int mainValue() => 3` → `int mainValue() => mainValue2() + 1` 产生含
  `call_static` 的 module,VM 解释结果正确。
- `patch_report` 含 `reject_reason: unsupported_kernel_node` 的用例。

---

### E4 — 失败 fallback + stack trace（1 人月）

**任务**

- interpreter 抛 `InterpretResult::Error` → patch 整体标 `PatchState::kDisabledBadPatch`,
  **当前调用** fall through 到原 AOT（不影响调用者）。
- 把 `kDisabledBadPatch` 写回客户端 `state.json`,下次启动跳过该 patch。
- 上报 `crash_rollback` 事件到 server（payload 含 `function_id` + `error_message` +
  `bytecode_offset`）。
- stack trace:BytecodeModule 持 `source_map`（FunctionId + bytecode_offset → source
  location）;异常帧拼上 `package:app/foo.dart:123 (FCB patch)`。

**关键文件**

- `runtime/vm/fcb_patch_runtime.cc`（错误路径 + state 回写）
- `runtime/vm/exceptions.cc`（StackTrace 注入点）
- `crates/fcb_core/src/state.rs`（`mark_failure` 接 patch_runtime 回调）
- `updater/src/lib.rs`（C ABI `fcb_report_interpret_failure`）

**验收**

- 手写 `int crashy() { throw 'boom'; }` patch,触发后:当前调用回 AOT、App 不崩;重启后
  `state.json.bad_patches` 含该 patch;server `patch_events` 有 `crash_rollback` 行。
- StackTrace 含 patch 函数源码位置。

---

### E5 — 性能上报 + 决策辅助（2 周）

**任务**

- `Interpret()` 主循环入口/出口加 atomic counter,统计 `interpreted_function_calls` 与
  `aot_function_calls`。
- C ABI `fcb_get_interpreter_stats(uint64_t* interpreted, uint64_t* aot)`。
- `fcb_code_push.dart` 加 `Future<InterpreterStats> interpreterStats()`。
- 客户端定期（mark_success 后）上报 `interpreter_ratio` 事件。
- CLI `fcb inspect patch <path>` 显示估算 interpreter_ratio。
- ratio 超阈值（如 5%）→ `fcb patch` 输出 warning「该 patch 解释比例高,建议发新 release」。

**关键文件**

- `runtime/vm/fcb_patch_runtime.cc`（counter）
- `updater/src/lib.rs`（暴露 stats）
- `packages/fcb_code_push/lib/fcb_code_push.dart`
- `cli/src/inspect.rs`

**验收**

- counter_app patch 后 interpreter_ratio < 1%。
- 故意 patch 大量函数（10+）触发 CLI warning。

---

### E6 — Runtime gap closure（当前 blocker）

**目标**

把当前 interpreter 从"大部分同步业务函数可跑"提升到"异常、async、泛型和 debugger 语义可被
生产验收"。本阶段不得用 fallback 掩盖 Dart 语义错误:只有 interpreter 内部错误、格式错误、
unsupported opcode 才 disable patch;业务 `throw` 必须按 Dart exception 传播。

**任务**

- FCBM v3 格式:
  - `FORMAT_VERSION = 3`,继续接受 v1/v2。
  - 每个 function 增加 `async_kind`: `sync` / `async_future` / `async_star` / `sync_star`。
  - 新 opcode 保留并 fail-closed: `Await(0x62)`、`AsyncReturn(0x63)`、`Yield(0x64)`、
    `TryFinally(0x65)`、`EndFinally(0x66)`、`Rethrow(0x67)`。
- Exception/finally:
  - 将 `InterpretResult` 拆成 `Ok`、`Suspended`、`DartException`、`PatchError`。
  - `Throw` 在 handler 为空时调用 VM `Exceptions::Throw`/`ReThrow`,而不是返回 fallback error。
  - `TryFinally` 维护 pending action(return/throw/await),确保离开 try block 前必跑 finally。
  - 已完成:同步 pending `continue`/`jump`/`return`/`throw` 的 finally 路径,并用 standalone test
    覆盖 normal jump、return override、throw rethrow 到外层 catch。
  - 已完成:`InterpretResult` 区分 `PatchError` 与 `DartException`;`CallStatic`/bytecode closure
    只把 `DartException` 送入 catch handler,内部 patch error 直接失败。
  - 已完成:`fcb_patch_entry.cc` 对逃出的 `DartException` 调用 VM `Exceptions::Throw`,不再 disable
    patch 或 fallback 到 AOT。
  - 未完成:pending `await`、`ReThrow` stack trace 保留、VM stack trace 注入和 rebuilt
    `run_vm_tests` 执行验证。
- Async:
  - 已完成:immediate `Await` 子集。`Await` 可处理非 Future/FutureOr 值和已完成 `_Future.value`
    的 `_stateValue`,并把 `_resultOrListeners` 作为 await 结果压回 interpreter stack。
  - 已完成:已完成 error Future 的 `_stateError` 路径。runtime 从 `_resultOrListeners` 的
    `AsyncError` 中取 `error` 字段,作为业务异常进入 `fail_or_throw`,可被 interpreted
    `TryBegin` catch 捕获;VM test 用已完成 `_Future.value` 手动设置 `_stateError` 与
    `AsyncError("boom", null)` 覆盖该路径。
  - 已完成:`AsyncReturn(0x63)` 的 immediate `async_future` 子集。解释器把栈顶返回值包装成
    completed `_Future.value(...)`,然后走正常 return/finally 路径;VM test 覆盖直接返回
    Future 以及 `CallStatic + Await` 拆箱该 completed Future。
  - 未完成:对 `async_future` 接入 Dart VM object store 中 `_SuspendState`/async return stubs,实现
    真正 `Await` suspend 与 resume。
  - 未完成:支持 `await Future.delayed`、chained Future、pending Future error resume、
    try/catch/finally around suspended await。
  - `async_star`/`sync_star` 后续接入 async stream controller / sync iterator。
- 泛型:
  - 已完成:resolver 接受 `RuntimeTypeEnvironment`,支持 `T`、`List<T>` 这类 type parameter
    引用映射到 concrete type 后调用 `IsInstanceOf`。
  - 已完成:bytecode closure trampoline 从 `ArgumentsDescriptor`/`TypeArguments` 构建 runtime type
    environment,支持 generic escaping closure body 内的 `AsType T`。
  - 已完成:VM `DartEntry` 普通 generic function entry 从 `ArgumentsDescriptor`/`TypeArguments`
    构建 runtime type environment,`IsType`/`AsType` 可使用调用方真实 function type args。
  - 已完成:arm64/x64 AOT static-call probe 对 generic target 的 type args ABI。precompiler 对
    generic target 选择 `user_arg_count + 1` raw slot stub;runtime entry 用 descriptor 跳过
    raw `TypeArguments` slot,并把真实 type args 传给 interpreter。
  - 已完成:generic AOT target 带 4 个 user args 的 `TypeArguments + 4 user args` 五 raw slot
    entry;`FcbAotStaticCall5` 调用 `FcbPatchStaticCallAot5`。
  - 未完成:rebuilt precompiler/AOT 真机端到端验证 generic static call stub。
- 递归:
  - 已完成:移除固定语义上限 64;默认 guard 提升为 4096。
  - 已完成:保留可配置 runaway 防护,触发时返回 `PatchError` 并带 function id + depth。
  - 已完成:interpreter 入口接入 VM `OSThread::HasStackHeadroom()` C++ stack headroom guard。
  - 未完成:把 VM stack/resource guard 命中接成真正 Dart `StackOverflowError` unwinder 信号。
- Debugger:
  - FCB frame 作为可暂停 frame 进入 `DebuggerStackTrace`。
  - 支持 breakpoint/step、locals/args/captured vars evaluate。
  - async suspension/resume 后保留逻辑调用栈。

**关键文件**

- `crates/fcb_core/src/bytecode.rs`
- `tool/fcb_binary_module_writer.dart`、`tool/fcb_kernel_manifest.dart`
- `runtime/vm/fcb_patch_runtime.{h,cc}`、`runtime/vm/fcb_patch_runtime_loader.cc`
- `runtime/vm/fcb_patch_runtime_vm.cc`、`runtime/vm/debugger.cc`、`runtime/vm/exceptions.cc`

**验收**

- `cargo test -p fcb_core bytecode` 通过,覆盖 v1/v2 兼容和 v3 async metadata。
- standalone loader test 覆盖 v3 `async_kind` 与新增 opcode fail-closed。
- VM tests 新增:
  - `await Future.delayed` resume 后返回 patched value。
  - 已完成的 await error 可被 interpreted catch 捕获;pending Future error resume 仍需覆盖。
  - `AsyncReturn` immediate `async_future` 返回 completed Future,并可被 interpreted `Await` 消费。
  - uncaught interpreted throw 可被 AOT caller catch 捕获。
  - try/finally 在 return/throw/await resume 三条路径均执行。
  - `T`/`List<T>` is/as 在 generic method 中区分正确。
  - 深递归不被固定 64 限制,但 runaway guard 有清晰 error。
  - debugger 在 patched frame 停靠后可 evaluate locals/captured vars。
- `tests/e2e/test_kernel_compile_from_plan.sh` 生成 v3 module 并验证 `async_kind`。

## 风险与缓解

| 风险 | 严重性 | 缓解 |
|------|--------|------|
| ObjectPtr 集成踩 GC 时序 | 高 | 先 stress test mode 验证;由 Dart VM 老手 review |
| async/await 实现难度远超预估 | 高 | P1 await 可推迟到后期;临时禁止 async 函数 patch |
| Dart SDK upstream rebase 时 stub_code hook 漂移 | 中 | 锁定 Dart SDK 版本;rebase 由 vendor/REBASE.md（Phase H）承担 |
| `call_original` 拿不到原 AOT entry point | 高 | 调研 `Function::CurrentCode()` 是否仍指向 AOT;备选保存 entry 备份。AOT-presence gate 见 `docs/architecture_decisions.md` ADR-#2 |

## 退出标准

- counter_app 真实 patch（widget tree + setState + plugin call）跑通。
- `tools/test.py runtime/vm/fcb_patch_runtime_test` 全绿。
- 解释失败 fallback 端到端走通（解释抛错 → App 不崩 → 下次启动跳过 → server 收到事件）。
- interpreter_ratio 可观测,counter_app 场景 < 1%。
- `crates/fcb_bytecode` 已裁剪,编译职责完全转给 Dart 工具。
