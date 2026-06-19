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

## 现状（开工前确认）

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

dispatch 链路已打通;核心剩余工作是让 `Value` 与 Dart heap 互通,并补全 opcode 语义。

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
