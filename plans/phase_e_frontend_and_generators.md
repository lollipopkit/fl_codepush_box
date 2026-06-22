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
| P4 | 硬化 + debugger + counter_app 退出 e2e | ✅(设备验收已闭合;IDE debugger 后续独立阶段) |

**P1 已覆盖**:`Block`/`seq`、`if-else`、`while`(含 guard `break`、`continue`、
`continue+break`,以及 `continue`/`break` guard 内 pending `await`)、`do-while`/C-style `for`(含 guard `break`/`continue` 及其组合、
guard/update 内 pending `await`)、C-style `for` condition/update pending `await` +
nested branch-local、C-style `for` condition/continue/break guard/update 全 pending `await`、
local `let`/`set_local`、
嵌套 branch-local `if` return(含 branch-local initializer 内 pending `await`)、语句序列中的
`if`/`if/else` side-effect + tail、`if` branch try/finally 和 try/catch pending `await` + shared tail、
`if/else` 双分支 try/finally + try/catch pending `await` + shared tail、
ternary conditional + pending `await` branch、
`if/else` nested branch-local(含 `while`/`for` body 内 pending `await` initializer,
以及 `while` pending `await` condition + nested branch-local)、C-style `for`
update pending `await` + loop-body branch-local / nested branch-local、multi-update `for`、
一般 pending `await`(`Await(0x62)` +
`AsyncReturn(0x63)`)、await tail 序列、`try/catch/finally`(含 finalizer 内二次 await、
try/catch statement + tail return)、
`while` pending `await` condition、普通 async `do-while`(含 pending `await` condition、
pending `await` guard,以及二者同存、body branch-local、pending `await` condition + branch-local、
pending `await` condition + local initializer pending `await`、
break、continue、continue+break)、
`Future<void>` 隐式/显式 return、sync `Future.value<T>(...)` returning helper、
sync/async field read → `GetField(0x43)`、async pending `await` 后读取字段并拼接字符串、
函数参数 callback 调用(零参/positional/named/mixed args,含 async mixed positional+named,
以及 async pending `await` 后 callback 调用) →
`CallClosure(0x53)`、sync/async direct string concat → `StringConcat(0x42)`、async pending `await`
后 direct string concat、sync/async local mutation →
`set_local` / `StoreLocal(0x04)`、sync expression-statement block →
`seq`/`Pop(0x05)`/`null`、sync `try/catch` / `try/finally` expression-statement + tail return,
sync 单 `try/catch` / `try/finally` statement + 隐式 null return、sync `if`/`if/else`
side-effect + tail(含分支 local)、
sync `try/catch` / `try/finally` return-value preserve(`value:true`,
含 sync catch-local `let`、嵌套 statement sequence local `let`、sync/async
`try/catch/finally` 嵌套返回值保留、sync try/catch body local、sync try/finally body/finalizer local、
async direct `try/finally` statement body/finalizer local side-effect + tail,
含 finalizer pending `await` + tail、async direct `try/catch` statement catch pending
`await` + tail、nested async `try/catch/finally` statement catch/finalizer pending `await` + tail)、
async conditional `null` literal、sync/async field assignment → `SetField(0x44)`、
async pending `await` 后 field assignment/readback、
sync/async dynamic named call → `CallDynamic(0x51)`、async pending `await` 后 dynamic named call、
sync/async `dart:*` static invocation →
`CallOriginal(0x52)`、async pending `await` 后 `CallOriginal(0x52)`、
async project static invocation → `CallStatic(0x50)`、async pending `await` 后 `CallStatic(0x50)`、
async pending `await` 后带 positional args 的 project static invocation、
async object construction / named construction / generic construction →
`NewObject(0x55)` + `AsyncReturn(0x63)`、async pending `await` 后 positional/generic/named object construction、
`!=`/`<`/`<=`/`>=` binary comparison lowering(复用
`>`/`==`/conditional IR)、async arithmetic binary op →
`Add(0x10)` / `Sub(0x11)` / `Mul(0x12)` / `Div(0x13)`、async pending `await` 后
plain `Add(0x10)` / `Sub(0x11)` / `Mul(0x12)` / `Div(0x13)`、async `is`/`as`
type-test/cast → `IsType(0x45)` / `AsType(0x46)`、async pending `await` 后 type-test/cast、
async logical `&&` / `||` / `!` → conditional IR、async pending `await` 后 logical conditional IR、
async `throw` expression → `Throw(0x60)` + `AsyncReturn(0x63)`、async pending `await` 后
`Throw(0x60)`、async pending `await` 后 conditional `null` literal、async pending `await` 后
ternary conditional string、
async collection literal static spread/for/if list/map → `MakeList(0x40)` / `MakeMap(0x41)` +
conditional IR、async pending `await` 后 static list/map `MakeList(0x40)` / `MakeMap(0x41)`、
async pending `await` local 作为 list/map collection literal `if/else` condition、
async collection literal `if (await future)` direct condition(含后续 list/map dynamic spread append
与 runtime `for-in` append,dynamic spread ⇄ runtime `for-in` 双向链式 lowering,
dynamic spread/runtime `for-in` 后静态 tail / 静态 spread literal append,
dynamic spread → runtime `for-in` → dynamic spread 深链 append,
dynamic spread → dynamic spread → runtime `for-in` 深链 append,
dynamic spread → dynamic spread → dynamic spread 深链 append,
runtime `for-in` → dynamic spread → runtime `for-in` 深链 append,
runtime `for-in` → runtime `for-in` → dynamic spread 深链 append,
runtime `for-in` → runtime `for-in` → runtime `for-in` 深链 append,
以及 dynamic spread ⇄ runtime `for-in` 后静态 tail / 静态 spread literal 深链 append)、
async pending `await` local collection conditional 后 list/map dynamic spread append(含静态 tail
链式 append、静态 spread literal 链式 append、dynamic spread → runtime `for-in` 链式 append,
dynamic spread → runtime `for-in` → 静态 tail 深链 append,
以及 dynamic spread → runtime `for-in` → 静态 spread literal 深链 append)、
async pending `await` local collection conditional 后 list/map runtime `for-in` append(含静态 tail /
静态 spread literal 链式 append、runtime `for-in` → dynamic spread 链式 append,
runtime `for-in` → dynamic spread → 静态 tail 深链 append,
以及 runtime `for-in` → dynamic spread → 静态 spread literal 深链 append)、
async collection literal dynamic spread list/map → `CallDynamic(addAll)`、
async pending `await` 后 dynamic list/map spread → `CallDynamic(addAll)`、async runtime
collection-for list/map → `list_for_in` / `map_for_in`、async pending `await` 后 runtime
collection-for list/map → `list_for_in` / `map_for_in`(含 `Future<Map<String,String>>` type arg
结构化/fallback 解析)、async `for`/`while`/`do-while` loop body 中的 `try/finally` / `try/catch`
语句序列(含 await guard 分支、throw、finally 内 await local;已覆盖 `while` / `do-while`
pending await condition + body `try/catch`/`try/finally` + pending await guard/finalizer,
以及 `for` pending await condition + pending await update + body
`try/catch`/`try/finally`)。

**P2/P3 已覆盖**:多 `yield`、guarded `if` yield、静态/动态 `for-in` yield body(含多层
dynamic `for-in` + 内层 `continue`/`break` + 外层 `break`)、`yield*`
(sync* list literal 静态展开、动态 Iterable 委派、async* `Stream.fromIterable/value/empty/fromFuture`
及通用 Stream 参数真实 subscription 委派)、`await for`(各有限 stream 源 + 通用 Stream 参数 v1,含
guarded continue/break、nested、外层 finally cleanup、多源 nested `await for`(外层 `continue`、
内层 `break`、三层 nested stream lowering、finally cleanup,含正常/cancel/outer error/inner error
runtime 路径))、async* 内 pending `await` 挂起/恢复(`ResumeAsyncStar`)、cancel 跑 `finally`、
subscription pause/resume 背压。

**测试锚点**:`tests/e2e/test_kernel_compile_from_plan.sh`(真实 Kernel → binary module →
`FcbPatchRuntimeAsyncStarSourceModuleStreamListen` 和
`FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor` 跑源级生成器/await-for 用例,含多源
nested `await for` + break/continue/finally 的正常、cancel、outer error、inner error runtime
路径,以及三层 nested stream lowering/runtime normal/cancel/outer-error/middle-error/inner-error 路径;
新 deep-nested filter 也已纳入 `scripts/test_vendor_vm_runtime.sh` release VM gate;summary 写
`target/fcb/kernel-compile-from-plan/summary.txt`,当前 interpreted/module/binary 计数为
374/389/389;`make check-phase-e-host-evidence` 会检查该 summary
与 VM summary 及其底层 SDK delta audit / 全量 release+debug VM filter 日志);
VM filter 列表已抽到 `scripts/fcb_vm_test_filters.sh`,由
`scripts/test_vendor_vm_runtime.sh` 与 `scripts/check_phase_e_host_evidence.sh` 共同 source;
`make test-phase-e-host-evidence-gate` 覆盖 host evidence gate 的 pass、缺 release log、缺 debug
`Done:`、缺 VM summary filter、no-rebuild 写 canonical dir 必拒绝等 fail-closed 场景;
release/patch Dart fixture 已拆到
`tests/e2e/kernel_compile_from_plan/fixtures/{release_main_parts,patch_main_parts}/*.dart`,
其中 core async loop/control-flow 另拆到 `01b_core_async_loops.dart`,把
`01_core_async.dart` 控制在 release 1151 行 / patch 1155 行,`01b_core_async_loops.dart`
当前 release/patch 均 625 行;
其中 direct `if (await ready)` collection chain 另拆到
`04_direct_await_collection_chains.dart`,避免 `03_sync_generators.dart` 继续膨胀;
其中 collection literal / labels / type-test helper 另拆到 `03b_collection_literals.dart`,
把 `03_sync_generators.dart` 降到 release/patch 均 356 行;
`test_kernel_compile_from_plan.sh` 会按文件名排序拼回 `main.dart`,避免单个 fixture 或 shell
继续膨胀;`make check-kernel-compile-fixture-size` 把 shell、fixture part、拆分后的 Python
断言文件,以及相邻 Phase E gate 脚本(`fcb_vm_test_filters.sh`、
`check_phase_e_host_evidence.sh`、`test_vendor_vm_runtime.sh`、
`test_phase_e_host_evidence_gate.sh`、`check_phase_e_completion.sh`、
`test_phase_e_completion_gate.sh`)钉在默认 1500 行以内,并已接入 local core CI;
`tests/e2e/test_kernel_business_stream_e2e.sh`(`FcbPatchRuntimeBusinessStreamSourceE2e` 跑真实业务
`async* { await; yield; await for; yield*; finally }` 含 error-after-yield、第二个通用
`yield* delegated` 的 data/error/cancel-after-fourth、cancel-after-second);
Python 断言拆在 `tests/e2e/kernel_compile_from_plan/`;其中 `assert_plan_inventory.py` 会把
plan reject 集合严格钉在 `isCallable:function_type_unsupported` 与
`isRecord:record_type_unsupported`,普通 async control-flow source 入口断言保留在
`assert_plan_async_control.py`,async loop source 断言已拆到 `assert_plan_async_loop_sources.py`,
其中 async expression/comparison source 断言已拆到
`assert_plan_async_expression_sources.py`,core-call source 断言已拆到 `assert_plan_core_calls.py`,
core op/type-test source 断言已拆到 `assert_plan_core_ops.py`,
core list/names collection source 断言已拆到 `assert_plan_core_collection_names.py`,
async/await inventory 断言已拆到 `assert_plan_inventory_async_await.py`,
pending-await local collection chain source 断言已拆到 `assert_plan_collection_await_then_chains.py`,
其 runtime tail/static-spread/reverse 链断言已拆到
`assert_plan_collection_await_then_runtime_chains.py`,
direct-await collection reverse chain source 断言已拆到
`assert_plan_collection_reverse_chains.py`,
direct await static tail/static spread source 断言已拆到
`assert_plan_collection_static_tail_chains.py`,
escaping closure inventory 断言已拆到 `assert_plan_inventory_escaping.py`,
local mutation inventory 断言已拆到 `assert_plan_inventory_local_mutation.py`,
async-future module 主体断言已拆到 `assert_module_async_future.py`,async branch module 断言已拆到
`assert_module_async_branch.py`,async loop module 断言已拆到 `assert_module_async_loops.py`,
module callback/closure-call 断言已拆到 `assert_module_callback_calls.py`,
core module constant 检查已收敛为 helper,`assert_module_core_calls.py` 当前 717/1500,
dynamic for-in module 断言已拆到 `assert_module_dynamic_for_in.py`,
generator for-in module 断言已拆到 `assert_module_generator_for_in.py`,
generator for-in source 断言已拆到 `assert_generator_for_in_sources.py`,
collection module label/map/dynamic 断言已拆到 `assert_module_collection_label_calls.py`,
且其中重复 string constant 检查已收敛为 helper,当前 774/1500,
static label/map module 断言已拆到 `assert_module_collection_static_label_calls.py`,
dynamic/runtime label 断言继续拆到 `assert_module_collection_dynamic_label_calls.py`,
同时覆盖 unchanged `Future<Function>` / `Future<Record>` type arg 不产出 `bytecode_source`,
防止 reader/audit 覆盖漂移时用错误 reject 抵消计数,并避免单个断言文件继续膨胀。

**前端代码组织**:`fcb_kernel_reader.dart`(939,collection literal / collection-for lowering
拆到 `fcb_kernel_collection_expr.dart`(574),collection append/runtime-for helper 拆到
`fcb_kernel_collection_append_expr.dart`(443))、`fcb_kernel_manifest.dart`(359,reader bundle
拆到 `fcb_kernel_reader_bundle.dart`(40),IR→bytecode 编译器拆到
`fcb_kernel_manifest_compiler.dart`(737),control-flow/collection/generator helpers 拆到
`fcb_kernel_manifest_control_compiler.dart`(413))、generator lowering 拆为
`fcb_kernel_generator_{expr,for_expr,loop_expr,stream_expr}.dart`(do-while lowering 已归入
`fcb_kernel_generator_loop_expr.dart`,yield lowering 已归入
`fcb_kernel_generator_yield_expr.dart`(91),lowered for-in body / label guard helper 已归入
`fcb_kernel_generator_for_in_body_expr.dart`(338),`fcb_kernel_generator_expr.dart` 当前 620 行);
普通 async lowering 拆为
`fcb_kernel_async_expr.dart`、`fcb_kernel_async_loop_expr.dart`(496) 和
`fcb_kernel_async_for_expr.dart`(355)。
SDK delta 边界由 `scripts/audit_vendor_dart_sdk_delta.sh` 守护(禁止 `async_patch.dart` 带 FCB
delta,FCB helper 集中在 `fcb_async_patch.dart`;已验收的 5 个 FCB VM hook official-path delta
必须在 diff 内带 FCB marker 才允许通过 audit)。

## 剩余

1. **前端长尾**(非 blocker,迭代扩):复杂交织控制流(更复杂 `while`/`for` update、更多嵌套
   branch-local 组合;当前普通 async `local; nested if; return`、branch-local pending `await`、
   语句序列 `if`/`if/else` side-effect + tail、`if` branch try/finally 和 try/catch pending `await` +
   shared tail、`if/else` 双分支 try/finally + try/catch pending `await` + shared tail、
   ternary conditional + pending `await` branch、
   `if/else` nested branch-local(含 `while`/`for` body 内 pending `await` initializer)、
   while condition pending `await`、while pending `await` condition + nested branch-local、
   while pending `await` condition + pending `await` continue/break guard、
   普通 async `while continue+break`(含 pending `await` guard)、
   普通 async `do-while`(含 pending `await` condition/guard、body branch-local、
   pending `await` condition + branch-local、pending `await` condition +
   local initializer pending `await`、break、continue、continue+break)、
   for guard/update pending `await`(含二者同存)、for condition/update pending `await` +
   loop-body branch-local/nested branch-local、for condition/continue/break guard/update 全 pending `await`、
   普通 async multi-update `for`、sync `Future.value<T>(...)` returning helper、sync/async field read、
   sync/async local mutation、函数参数 callback 调用(零参/positional/named/mixed args)、sync expression-statement block、
   sync/async field assignment、sync/async dynamic named call、sync/async `dart:*` static invocation、
   async positional/named `new_object` construction、async arithmetic binary op、
   `!=`/`<`/`<=`/`>=` binary comparison lowering、
   async `is`/`as` type-test/cast、async collection literal static spread/for/if list/map、
   pending `await` local 作为 list/map collection literal `if/else` condition、
   collection literal `if (await future)` direct condition(含后续 list/map dynamic spread append
   与 runtime `for-in` append,dynamic spread ⇄ runtime `for-in` 双向链式 lowering,
   dynamic spread/runtime `for-in` 后静态 tail / 静态 spread literal append,
   dynamic spread/runtime `for-in` 三段深链 append、
   以及 dynamic spread ⇄ runtime `for-in` 后静态 tail / 静态 spread literal 深链 append)、
   pending `await` local collection conditional 后 list/map dynamic spread append(含静态 tail
   链式 append、静态 spread literal 链式 append、dynamic spread → runtime `for-in` 链式 append,
   dynamic spread → runtime `for-in` → 静态 tail 深链 append,
   以及 dynamic spread → runtime `for-in` → 静态 spread literal 深链 append)、
   pending `await` local collection conditional 后 list/map runtime `for-in` append(含静态 tail /
   静态 spread literal 链式 append、runtime `for-in` → dynamic spread 链式 append,
   runtime `for-in` → dynamic spread → 静态 tail 深链 append,
   以及 runtime `for-in` → dynamic spread → 静态 spread literal 深链 append)、
   async collection literal dynamic spread list/map、async runtime
   collection-for list/map 已覆盖);
   更多多层 async* stream 委派 cancel/finally 组合;多源嵌套 `await for` 更深层级的
   cancel/error/finally cross-product 组合。
   后续继续补更深 collection/control-flow 组合。
2. **IDE 级 debugger**:parked generator/async 帧的 pause/evaluate、VM breakpoint registry(后续独立阶段)。

## 已闭合的 P4/设备证据(2026-06-22)

- `tests/e2e/test_kernel_compile_from_plan.sh`:通过。`target/fcb/kernel-compile-from-plan/summary.txt`
  记录 interpreted 374、reject 2、unchanged 11、module/binary function 389,并运行
  `FcbPatchRuntimeAsyncStarSourceModuleStreamListen` 与
  `FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor`。
- `make test-android-arm64-acceptance`:通过。Android primary arm64-v8a emulator 覆盖 nopatch、
  patch 7 项真实业务结果、interpret-failure fallback + bad patch recorded。
- `FCB_ADB_TIMEOUT_SECONDS=5 make check-phase-e-completion`:通过。Phase E completion summary
  显示 host_evidence/android_device_preflight/android_acceptance/android_interpret_failure/
  android_interpreter_ratio/desktop_embedder_full 全 pass。

## 风险

| 风险 | 缓解 |
|---|---|
| 通用语句下降范围发散 | 已覆盖 block/if/while/for/return/await/try;其余 fail-closed 到 `unsupported_kernel_node`,迭代扩 |
| 前端 reject 收窄导致误编不支持节点 | reader 不支持的节点 audit 必 reject,覆盖度严格对齐 |
| async* 内 await 与背压交织复杂 | 已单独闭合(P3)并充分单测;长尾组合继续补 |

## 不在本 plan(沿用既有边界)

- snapshot_replace 后端;debugger 完整化的非生成器部分。
- 顶层 vendor 本地 checkout;根工作树无关改动不纳入提交。
