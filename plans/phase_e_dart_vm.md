# Phase E — Dart VM 真正可用

**所属阶段**：关键路径（Production-Ready 的卡脖子）
**预计工作量**：6–10 人月
**前置依赖**：无（vendor/sdk fork 已经把 skeleton 落地，可直接开工）
**并行性**：与 F/G/H 完全独立

## 目标

把 `vendor/sdk/runtime/vm/fcb_patch_runtime.{h,cc}` 从 plain-struct skeleton 升级为能解释真实业务 Dart 代码的 in-VM interpreter，并在解释失败时安全 fallback 到原 AOT。验收标准是 counter_app 真实业务级 patch（修改 widget tree、调用 setState、调用 plugin method channel）能正确运行。

## 现状（必读，开工前确认）

`vendor/sdk` HEAD = `1b88776798d`，commit `022e0730047` 提供的能力：

| 文件 | 行数 | 角色 |
|------|------|------|
| `runtime/vm/fcb_patch_runtime.{h,cc}` | 137 + 1168 | BytecodeModule 加载、Value/InterpretResult 数据结构、PatchState 枚举 |
| `runtime/vm/fcb_patch_entry.{h,cc}` | 103 + 717 | DispatchDecision、与 stub_code 的 ABI 桥 |
| `runtime/vm/fcb_patch_api.{h,cc}` | 33 + 47 | Engine-facing `LoadPatchRuntimeForIsolateGroup` / `ClearPatchRuntimeForIsolateGroup` |
| `runtime/vm/fcb_patch_runtime_test.cc` | 478 | 现有单测，开工前先跑通 |
| `runtime/vm/compiler/stub_code_compiler_{arm,arm64,x64,ia32,riscv}.cc` | +900 | 全架构 dispatch stub |
| `runtime/vm/runtime_entry.cc` / `runtime_entry_list.h` | +439 | runtime entry 注册 |

**头文件原文（fcb_patch_runtime.h:1–10）已声明 skeleton 状态**：
> "kept header-only with no VM object dependencies for the first landing step; the next integration step wires DispatchDecision into real function entry dispatch and replaces the plain byte vectors with VM ObjectPtr values."

也就是说 dispatch 链路已经打通，只是 `Value` 是不能跟 Dart heap 互通的孤岛。

## 子阶段

### E1 — Value ↔ ObjectPtr 集成（2–3 人月）

**任务**

- 把 `struct Value` 从 plain C++ 升级为持有 `ObjectPtr`（指向 Dart heap 上的真实对象）。
- 修改 `Value::Int / Double / Bool / String / List / Map` 的工厂，在 current `Thread::Current()->isolate_group()` 下 allocate Dart 对象。
- 实现 `Value::FromDart(ObjectPtr)` 与 `Value::ToDart()` 双向转换，用于参数传入和返回值传出。
- 把 `BytecodeModule::Load` 中的 constant pool 改为分配 Dart object（String/Int 直接走 `Smi::New` / `String::New`）。
- 在 `IsolateGroup` 上注册 `FcbPatchRuntime*` 字段，纳入 `IsolateGroup::VisitObjectPointers` 让 GC 扫描 root（避免 GC 移动后悬挂指针）。
- 升级 `fcb_patch_runtime_test.cc`：现有用例从 plain Value 改为构造 Dart 对象，验证 GC 一次后 patch 仍可调用。

**关键文件**

- `vendor/sdk/runtime/vm/fcb_patch_runtime.h:30–80`（`enum ValueKind` 与 `struct Value`）
- `vendor/sdk/runtime/vm/fcb_patch_runtime.cc`（Value 工厂 + ModuleLoader）
- `vendor/sdk/runtime/vm/isolate.cc` / `isolate.h`（添加 `fcb_patch_runtime_` 成员）
- `vendor/sdk/runtime/vm/program_visitor.cc`（snapshot 路径上的 visit）

**验收**

- 现有 478 行 test 全部以 ObjectPtr 形式重写，通过。
- 新增 GC stress test：连续 100 次 GC + patch 调用，无悬挂指针。
- `tools/test.py runtime/vm/fcb_patch_runtime_test` 绿。

---

### E2 — Opcode 集补全（2–3 人月）

**任务**

按业务覆盖优先级顺序实现。每条 opcode 增量做：interpreter case + 单测 + 编译器侧产生（E3 提供 stub）。

| 优先级 | opcode | 覆盖语义 | 难度 |
|--------|--------|---------|------|
| P0 | `call_static` | 静态/顶层函数调用，走 `DartEntry::InvokeFunction` | 中 |
| P0 | `call_dynamic` | instance method（含 vtable lookup） | 高 |
| P0 | `call_original` | 调用未变函数的原 AOT 实现（关键合规点：复用 AOT） | 高 |
| P0 | `get_field` / `set_field` | 实例字段读写，走 `Field::Offset` | 中 |
| P0 | `string_concat` / `string_interp` | 字符串拼接和插值 | 低 |
| P1 | `make_closure` / `call_closure` | 闭包捕获 + 调用 | 高 |
| P1 | `is_type` / `as_type` | 类型检查/转换，走 `TypeTester` | 中 |
| P1 | `try_catch` / `throw` | 异常处理（与 VM unwinder 协作） | 高 |
| P1 | `await` / `async_resume` | future continuation；与 `_FutureImpl` state machine 集成 | 极高 |
| P2 | `new_object` | 调用 generative constructor + 初始化字段 | 中 |
| P2 | `list_lit_extended` / `map_lit_extended` | spread、collection-if、collection-for | 中 |

**关键文件**

- `vendor/sdk/runtime/vm/fcb_patch_runtime.cc` 的 `Interpret()` 主循环（当前 16 个 case）
- `vendor/sdk/runtime/vm/dart_entry.cc`（已加入 6 行 hook，开放给 `call_original`）
- `vendor/sdk/runtime/vm/runtime_entry.cc`（+430 行，已经有 FCB runtime entry 注册框架）

**验收**

- 每条 opcode 至少 3 个单测（happy path、boundary、error）。
- 集成测试：构造一个手写 BytecodeModule，覆盖一条 patched widget `build()` 方法，包含 setState、字符串插值、call_original，端到端跑通。

---

### E3 — 编译器 Dart 化（1–2 人月）

**任务**

扩展 `tool/fcb_kernel_manifest.dart`（当前 455 行，只输出 inventory）：

- 新增 CLI 子命令 `--compile-from-plan plan.json --patch patch.dill -o module.fcbm`。
- 用 `package:kernel` 的 `Visitor<void>` 遍历 `Member.function.body`，把 `Statement` / `Expression` 翻译为 E2 定义的 opcode 序列。
- 输出 binary 格式严格对齐 `fcb_patch_runtime.h::BytecodeModule`（magic + version + constant pool + function table + instructions），用 `package:typed_data` 写 `Uint8List`。
- constant pool 复用：相同字面量去重。
- 遇到 unsupported Kernel node（reflection、`extension` static dispatch 等）→ 输出 `RejectReason::UnsupportedKernelNode` 到 stderr，CLI 侧收集进 `patch_report.json`。
- 删除 `crates/fcb_bytecode/src/compiler.rs`；`format.rs` 缩为 schema 校验 + 反序列化（给 `fcb inspect` 用）。
- CLI 侧 `cli/src/main.rs::automatic_bytecode_payload` 改为 spawn Dart 工具，读 binary 输出。

**关键文件**

- `tool/fcb_kernel_manifest.dart`（扩展）
- `cli/src/main.rs:713–749`（`automatic_bytecode_payload` / `bytecode_payload_from_inventories`）
- `cli/src/main.rs:962–971`（`compile_or_read_bytecode_module`，简化为 read 模式）
- `crates/fcb_bytecode/src/lib.rs`（裁剪）

**验收**

- 一个 e2e：counter_app `int mainValue() => 3` → `int mainValue() => mainValue2() + 1; int mainValue2() => 2` 产生包含 `call_static` 的 module，VM 解释结果正确。
- `patch_report.json` 含 `reject_reason: unsupported_kernel_node` 的用例（手写 mirrors patch）。

---

### E4 — 失败 fallback + stack trace（1 人月）

**任务**

- interpreter 任意 case 抛出 `InterpretResult::Error` → patch 整体标记 `PatchState::kDisabledBadPatch`，**当前调用** fall through 到原 AOT（必须能做到不影响调用者）。
- 把 `kDisabledBadPatch` 写回客户端 cache 的 `state.json`（updater 侧 G 阶段消费），下次启动直接跳过该 patch。
- 上报 `crash_rollback` 事件到 server（POST /v1/events，payload 含 `function_id` + `error_message` + `bytecode_offset`）。
- stack trace：BytecodeModule 持 `source_map`（FunctionId + bytecode_offset → source location）；解释帧异常时把 Dart `StackTrace` 拼上 `package:app/foo.dart:123 (FCB patch)`。

**关键文件**

- `vendor/sdk/runtime/vm/fcb_patch_runtime.cc`（错误路径 + state 回写）
- `vendor/sdk/runtime/vm/exceptions.cc`（StackTrace 注入点）
- `crates/fcb_core/src/state.rs:240`（`mark_failure` 已存在，扩展为接 patch_runtime 的回调）
- `updater/src/lib.rs`（exposed C ABI `fcb_report_interpret_failure(patch_number, function_id, error)`）

**验收**

- 手写 `int crashy() { throw 'boom'; }` patch，触发后：
  - 当前调用回到原 AOT，App 不崩。
  - 重启后 `state.json.bad_patches` 含该 patch_number。
  - server `patch_events` 表有 `crash_rollback` 行。
- StackTrace 含 patch 函数源码位置。

---

### E5 — 性能上报 + 决策辅助（2 周）

**任务**

- 在 `Interpret()` 主循环入口/出口加轻量 counter（atomic uint64），统计 `interpreted_function_calls` 与 `aot_function_calls`。
- 暴露 C ABI `fcb_get_interpreter_stats(uint64_t* interpreted, uint64_t* aot)`。
- `fcb_code_push.dart` 加 `Future<InterpreterStats> interpreterStats()`。
- 客户端定期（每次 mark_success 后）上报 `interpreter_ratio` 事件。
- CLI 加 `fcb inspect patch <path>` 显示估算 interpreter_ratio（基于 plan.interpret 数量 / 总函数数）。
- 如果 ratio > 阈值（例如 5%）→ CLI 在 `fcb patch` 时输出 warning：「该 patch 解释比例高，建议发新 release」。

**关键文件**

- `vendor/sdk/runtime/vm/fcb_patch_runtime.cc`（counter 自增）
- `updater/src/lib.rs`（暴露 stats）
- `packages/fcb_code_push/lib/fcb_code_push.dart`（Dart API）
- `cli/src/main.rs::inspect`（已存在 1050 行）

**验收**

- counter_app patch 后 interpreter_ratio < 1%。
- 故意 patch 大量函数（10+）触发 CLI warning。

## 风险与缓解

| 风险 | 严重性 | 缓解 |
|------|--------|------|
| ObjectPtr 集成踩 GC 时序 | 高 | 先在 stress test mode 验证；review by Dart VM 老手 |
| async/await 实现难度远超预估 | 高 | E2 的 P1 await 可推迟到 Phase E 后期，业务上禁止 async 函数 patch 也能临时回避 |
| Dart SDK upstream rebase 时 stub_code hook 漂移 | 中 | 锁定 Dart SDK 到 3.12.2，rebase 时由 vendor/REBASE.md（Phase H）流程承担 |
| `call_original` 拿不到原 AOT entry point | 高 | 调研 `Function::CurrentCode()` 是否在 patch 加载后仍指向 AOT；备选用 fcb_patch_entry 里保存的 entry 备份 |

## 退出标准

- counter_app 真实 patch（含 widget tree 修改 + setState + plugin call）跑通。
- `tools/test.py runtime/vm/fcb_patch_runtime_test` 全绿。
- 解释失败 fallback 端到端走通（一次解释抛错 → App 不崩 → 下次启动跳过 → server 收到事件）。
- interpreter_ratio 可观测，< 1% 在 counter_app 场景。
- `crates/fcb_bytecode` 已裁剪，编译职责完全转给 Dart 工具。
