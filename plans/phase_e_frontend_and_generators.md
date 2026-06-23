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

## 现状(2026-06-23,据代码)

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
`if/else` 双分支 try/finally + try/catch pending `await` + shared tail(含两侧同时
try/finally、两侧同时 try/catch+finally recovery/cleanup await)、
ternary conditional + pending `await` branch(含两侧均 pending await、condition 自身 pending await、
nested ternary 多 await branch)、
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
async logical `&&` / `||` / `!` → conditional IR、async pending `await` 后 logical conditional IR
(含 logical operand 内 pending await、nested logical 多 await branch,以及 `if`/`if-else`/`while`
condition control-flow;后续已拆 `13_async_logical_control.dart` 覆盖 `do-while`/`for` condition
和 try/catch/finally 分支,以及 collection-if list/map dynamic spread/runtime for-in,
并补到 logical collection `try/catch+finally` 的 catch recovery await + finally cleanup await)、
async `throw` expression → `Throw(0x60)` + `AsyncReturn(0x63)`、async pending `await` 后
`Throw(0x60)`、async pending `await` 后 conditional `null` literal、async pending `await` 后
ternary conditional string、
async collection literal static spread/for/if list/map → `MakeList(0x40)` / `MakeMap(0x41)` +
conditional IR、async pending `await` 后 static list/map `MakeList(0x40)` / `MakeMap(0x41)`、
async pending `await` local 作为 list/map collection literal `if/else` condition、
受限 switch expression lowering(常量 case + `_` default,同时支持源码保留 `SwitchExpression`
和 CFE 降级后的 `BlockExpression + LabeledStatement + if/break` 形状;guarded switch 继续
fail-closed)、受限 switch statement lowering(CFE `SwitchStatement` 常量 case + default,
同一 body 多 case label,case body 直接 `return` / `throw`,case body 局部变量 + `return`/`throw` 序列,
async case body 内 pending `await` + `return`/`throw`,
case 内多条 side-effect 后 `break` 并继续 shared tail return,或给同一 local 赋值后 `break` 并继续 tail return;
assignment switch 也支持分支直接 `throw`;guarded switch statement 已支持受限常量 pattern + `when`
guard;已覆盖 `while` / pending-await condition `while` / `for` /
pending-await update `for` 的 loop body switch assignment,以及返回 List/Map 的 `for`
loop body switch assignment,并覆盖 `do-while`、nested branch-local、try/catch、
try/finally、pending-await condition + try/catch、pending-await update + try/finally 组合;
loop body 内 Dart 3 OR-pattern switch assignment 已覆盖 `while`、pending-await update `for`、
pending-await condition `while` + try/catch、`do-while` + try/finally)、
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
结构化/fallback 解析,并支持 mapped item/key/value 形态;普通 async list/map literal 的 list-source
`list_for_in` / `map_for_in` 已覆盖 switch value、try/finally cleanup await、
try/catch/finally recovery+cleanup await、while `!await` break guard + try/finally、
for-loop finally、do-while catch/finally、nested branch recovery 组合,并覆盖 collection-if
`if (!await ready)` 的 list/map dynamic spread + runtime for-in、try/finally cleanup await、
try/catch/finally recovery+cleanup await 组合,以及普通 async 控制流中的
`if (!await ready)`、`if/else (!await ready)`、`while (!await ready)`、
`for (... && !await ready)`、`do/while (!await ready)` 与 try/finally、
try/catch/finally、break/tail 的组合)、async collection literal 中
`if (await ready) ...switch (...)` 的 list/map dynamic spread lowering,覆盖后续 mapped
`for-in` append 及 try/finally、try/catch wrapper,并覆盖 `final enabled = await ready; if (enabled) ...switch (...)`
的 await-then local collection-switch 形态,以及 `enabled = await ready` + `selectedTier = await tierReady`
双 pending-await local 后 switch spread;guarded collection switch spread 已覆盖 direct `if (await ready)`、
await-then local、双 pending-await local 三种 list/map 形态、async `for`/`while`/`do-while` loop body 中的 `try/finally` / `try/catch`
语句序列(含 await guard 分支、throw、finally 内 await local;已覆盖 `while` / `do-while`
pending await condition + body `try/catch`/`try/finally` + pending await guard/finalizer,
以及 `for` pending await condition + pending await update + body
`try/catch`/`try/finally`,并覆盖普通 async `while` 中 `try/finally` + pending-await
continue/break guard、nested branch-local、内层 `try/catch` 包裹 guard 的 finalizer-before-exit
形态,普通 async `do-while` 中同构 finalizer-before-continue/break 形态,以及 `while`/`do-while`
finalizer guard 内 switch statement / OR-pattern switch statement body 形态、直接 list/map collection
literal body/finalizer 形态,以及 `List.of(local)` / `LinkedHashMap.of(local)` copy 后追加静态
element/entry 的 dynamic spread body/finalizer 形态);direct `if (await ready)` collection chain 与
await-then collection chain 已覆盖 list/map 的 dynamic spread、runtime for-in、static tail/spread,
并补到 try/catch、try/finally、try/catch+finally 组合,含 static spread/tail 深链和
dynamic/runtime/dynamic、runtime/dynamic/runtime、runtime/runtime/dynamic 三段 append 链,
以及 catch/finally 内 pending await recovery/cleanup;await-then local 后 collection literal +
try/catch recovery await、try/finally cleanup await、try/catch+finally recovery/cleanup await 已覆盖
list/map 矩阵,并补到双 pending-await local 后 list/map collection literal 矩阵;
collection switch spread 已补到 try/catch+finally 内 pending recovery/cleanup await 的 direct await condition
与双 pending-await local list/map 组合;async switch expression 已补 `switch (await ready)` scrutinee
经 CFE lowered `BlockExpression` 的 async-aware lowering,并覆盖 await-then/double-await 后 switch 与
try/catch recovery await、try/finally cleanup await、try/catch+finally recovery/cleanup await 组合;
async switch statement 已补源码态与 CFE lowered switch statement 的 `switch (await ready)` async-aware
scrutinee lowering,并覆盖 await-then/double-await 后 switch statement 与 recovery/cleanup await 组合;
async guarded switch 已补 `when await enabled` guard lowering,覆盖 switch expression/statement 的 direct
async guard 与 await-then scrutinee 后 async guard;普通 async guarded switch 继续补到
`case ... when !await enabled`,覆盖 switch expression/statement、`switch (await ready)`
scrutinee、try/finally cleanup await、try/catch+finally recovery/cleanup await 组合;
普通 async loop/finalizer 继续补到独立 `21_async_loop_guarded_switch_chains.dart`,
覆盖 `!await` guarded switch 与 while/do-while/for、`switch (await ready)` statement、
list/map runtime for-in、try/finally cleanup await、try/catch+finally recovery/cleanup await
交叉,并补齐 labeled do/while 下 break-only try/finally finalizer-before-break lowering)。

**P2/P3 已覆盖**:多 `yield`、guarded `if` yield、静态/动态 `for-in` yield body(含多层
dynamic `for-in` + 内层 `continue`/`break` + 外层 `break`)、`yield*`
(sync* list literal 静态展开、动态 Iterable 委派、async* `Stream.fromIterable/value/empty/fromFuture`
及通用 Stream 参数真实 subscription 委派)、`await for`(各有限 stream 源 + 通用 Stream 参数 v1,含
guarded continue/break、nested、外层 finally cleanup、多源 nested `await for`(外层 `continue`、
内层 `break`、三层 nested stream lowering、finally cleanup,含正常/cancel/outer error/inner error
runtime 路径)、generic Stream `yield*` / `await for` 的 try/catch、try/catch+finally
error/cleanup 组合(单 Stream、双 Stream、三 Stream、sandwich yield*、nested/triple nested await-for))、
有限 Stream source(`Stream.fromIterable`、`Stream.fromFuture(Future.value)`、pending `Future`)
在 `yield*` / `await for` 下的 try/catch+finally error/cleanup 组合、
generic `await for` 与 generic Stream `yield*` catch/finally 内 pending recovery/cleanup await 组合、
sequential+nested `await for`、nested `await for` 后 `yield*`、
`yield*` → `await for` → `yield*`、`yield*` → nested `await for` → `yield*`
的 catch recovery await + finally cleanup await 组合、
body `await for` 后 `yield*` + finally 内 `await for` cleanup,以及 body `yield*` +
finally 内 `await for` 后 `yield*` cleanup 的混合 cross-product、
async* 内 pending `await` 挂起/恢复(`ResumeAsyncStar`)、cancel 跑 `finally`、
subscription pause/resume 背压、sync*/async* 生成器内 switch expression OR pattern、lowered
switch statement OR pattern、guarded switch expression/statement(`yield switch`、`case a || b: yield ...`
与 `case a when guard: yield ...`),以及 sync*/async*
`while`/`for` 与 generic/nested `await for` body 内 lowered OR-pattern switch yield,含
generic/nested `await for` + try/catch/finally、break/continue/finally 的 error/cleanup 组合;
async Future `for` 多 update 与 branch-local await / await condition / try-finally / try-catch /
双 pending-await update + nested branch-local
组合,并补到 pending condition + 双 pending update 与 collection dynamic spread、switch spread、
runtime for-in、try/finally、try/catch+finally recovery/cleanup await 的交叉;以及 guarded switch expression/statement(含 generator context)的源码态与 CFE lowered
`(case == scrutinee) && guard` 形态,以及 generator collection 内 nested guarded
collection-for switch、await-then nested collection-for switch、list/map dynamic spread +
try/catch/finally recovery/cleanup 组合,以及 sync*/async* list/map dynamic spread + switch
spread + runtime for-in cross-product,并补到 async* generator collection 中 dynamic spread + switch
spread + runtime for-in 与 `try/finally` / `try/catch+finally` recovery/cleanup await 的交叉,
并继续补到 sync*/async* dynamic spread + nested runtime-for、await-then dynamic spread、
double-cleanup finalizer 与 map/list cleanup 组合,其中 reader 已支持 list-source map literal
runtime `map_for_in` 的 key/value lowering,并覆盖 async* await-then / try-finally /
try-catch-finally 组合;普通 async loop finalizer 也覆盖 copied collection dynamic
switch spread + runtime for-in append 组合,并补到 pending loop condition 与 collection switch/finalizer
交织的 list/map try/finally、try/catch+finally 形态;async* stream finalizer/catch/cleanup
也补到 body/catch/finally 中 `await for` 与 `yield*` 的交叉、catch stream recovery、
finally stream cleanup、nested try/catch/finally、sequential await-for、多 cleanup tail、
triple yield*、switch expression recovery、collection switch/list/map for-in 组合,并继续补到
`yield*`/`await for` 顺序链、catch recovery、finally 双 cleanup、nested inner catch 与
list/map collection cleanup tail 组合;普通 async
loop/finalizer 继续补到独立 `15_async_loop_finalizer_chains.dart`,覆盖 pending loop condition、
while/do-while/for、nested branch、switch spread、list/map runtime for-in、try/catch recovery await、
finally double cleanup await,并补到普通 async loop/finalizer 的 recovery、double-cleanup、
switch/list/map cross-product 第二组;普通 async loop/finalizer + guarded switch 交叉覆盖已在
`21_async_loop_guarded_switch_chains.dart` 补齐;async* guarded switch 交叉覆盖已在
`22_async_generator_guarded_switch_chains.dart` 补齐,覆盖 generic `await for` body 内
`yield switch`、`!await` guard、list/map collection-for、throw/catch/finally recovery/cleanup
await、`switch (await ready)` + `yield* tail`、nested `await for` + break + collection yield,
并补 generator switch lowering 的 async* aware scrutinee/guard 编译;async* lowered switch statement
case body 中的 terminating `throw` 分支已在 `23_async_generator_switch_statement_chains.dart`
补齐,覆盖 generic `await for` body 内 `case ... when !await ...: yield map-for; break`,
无 `break` 的 `throw` case、catch recovery await 与 finally cleanup await;async* switch statement
stream 委派组合已在 `24_async_generator_switch_stream_chains.dart` 补齐,覆盖
`switch (await tierReady)` + `when !await enabled`、case `yield*`、case 内 generic
`await for`、terminating `throw`、catch 后 `yield* recoveryStream`、finally 内 cleanup await
与 cleanup stream `await for`;sync* switch statement iterable 委派对称覆盖已在
`25_sync_generator_switch_iterable_chains.dart` 补齐,覆盖 guarded case、dynamic
`yield*`、runtime iterable `for-in`、terminating `throw`、catch 后 `yield* recoveryItems`
以及 finally `yield* cleanupItems`;普通 async switch statement + collection assignment 已在
`26_async_switch_statement_collection_chains.dart` 补齐,覆盖 `switch (await tierReady)`、
`when !await enabled`、terminating `throw`、list/map runtime `for-in`、catch recovery await、
finally cleanup await 与 return tail;普通 async object/call/type/collection 组合已在
`27_async_object_call_type_collection_chains.dart` 补齐,覆盖 async 局部 object construction、
type-test/cast、dynamic named call、static call、list/map runtime `for-in`、guarded switch、
catch recovery await、finally cleanup await 与 return tail;普通 async object/call/type 与
loop/finalizer 交叉已在 `28_async_object_loop_finalizer_chains.dart` 补齐,覆盖 while/for/do-while
loop 内 object construction、type-test/cast、dynamic/static call、list/map runtime `for-in`、
guarded switch、try/catch recovery await、finally cleanup await、continue/break 与 return tail。
async* generator object/call/type 交叉已在
`29_async_generator_object_call_type_chains.dart` 补齐,覆盖 async* 局部 object construction、
type-test/cast、dynamic named call、project static call、await-for body、yield* body/recovery/cleanup、
list/map runtime `for-in`、catch recovery 与 finally cleanup。
async* object/call/type 与 switch/collection/finalizer 交叉已在
`30_async_generator_object_switch_collection_chains.dart` 补齐,覆盖 async* switch statement /
switch expression、await scrutinee、`when !await` guard、object construction、type-test/cast、
dynamic/static call、list/map runtime `for-in`、yield* recovery/cleanup、catch recovery 与
finally cleanup。sync* object/call/type 与 switch/collection/finalizer 对称覆盖已在
`31_sync_generator_object_switch_collection_chains.dart` 补齐,覆盖 sync* switch statement、
object construction、type-test/cast、dynamic/static call、list/map runtime `for-in`、`yield*`
body/recovery/cleanup、catch recovery 与 finally cleanup。sync* loop/object/finalizer
交叉已在 `32_sync_generator_object_loop_finalizer_chains.dart` 补齐,覆盖 sync*
while/for/do-while、object construction、type-test/cast、dynamic/static call、list/map runtime
`for-in`、`yield*` recovery/cleanup、try/catch recovery 与 finally cleanup。async*
loop/object/finalizer 交叉已在
`33_async_generator_object_loop_finalizer_chains.dart` 补齐,覆盖 async*
while/for/do-while、pending `await`、object construction、type-test/cast、dynamic/static call、
list/map runtime `for-in`、stream `yield*` recovery/cleanup、try/catch recovery 与 finally
cleanup。async* nested stream loop/switch/collection 交叉已在
`34_async_generator_nested_stream_loop_switch_collection_chains.dart` 补齐,覆盖 async*
loop 内 `await for`、switch statement、collection-for、object construction、type-test/cast、
dynamic/static call、stream recovery/cleanup 与 try/catch/finally。
sync* nested iterable loop/switch/collection 对称交叉已在
`35_sync_generator_nested_iterable_loop_switch_collection_chains.dart` 补齐,覆盖 sync*
loop 内 iterable `for-in`、switch statement、collection-for、object construction、
type-test/cast、dynamic/static call、`yield*` recovery/cleanup 与 try/catch/finally。
普通 async collection deep spread/runtime-for 交叉已在
`36_async_collection_deep_spread_for_chains.dart` 补齐,覆盖 await 后 list/map dynamic spread、
runtime `for-in`、静态 tail、try/catch/finally recovery/cleanup 的深链组合。普通 async
collection/control super-chain 已在 `37_async_collection_control_super_chains.dart` 补齐,覆盖
list/map await 条件 spread 分支、runtime `for-in`、static tail/static spread、while loop、
try/catch/finally recovery/cleanup 与 switch expression 组合。async* stream super-chain 已在
`38_async_generator_stream_super_chains.dart` 补齐,覆盖 nested `await for`、`yield*`
到 `await for` 的混合委派、while loop、catch recovery、finally cleanup/tail、collection
yield 与 switch expression 组合。async* stream guarded super-chain 已在
`39_async_generator_stream_guarded_super_chains.dart` 补齐,覆盖 generic Stream
continue/break guard、nested await-for、while loop、catch recovery、finally cleanup、
collection yield 与 switch expression 组合。async* pending guard super-chain 已在
`40_async_generator_pending_guard_super_chains.dart` 补齐,覆盖 generic Stream
pending-await continue/break guard、nested await-for、catch recovery、finally cleanup、
collection yield 与 switch expression 组合;continue+break 同时复用同一 pending guard 仍保持
fail-closed,避免重复 await 求值。async* yield value pending-await super-chain 已在
`41_async_generator_yield_await_value_chains.dart` 补齐,覆盖 `yield [await ...]`、
`yield {'k': await ...}`、yield value 内 conditional/switch/string interpolation pending
`await`、`await for` body 与 finally cleanup 的 source -> module -> binary 路径。async*
yield collection-for pending-await super-chain 已在
`42_async_generator_yield_await_collection_for_chains.dart` 补齐,覆盖 yield value 内
list/map collection `if (await ...)`、runtime `for-in`、dynamic spread、for item/key/value
pending `await` 与 cleanup seed pending `await`。async* `yield* await streamFuture`
super-chain 已在 `43_async_generator_yield_star_await_stream_chains.dart` 补齐,覆盖
pending `await` 后的 Stream 委派、yield-star iterator cancel finalizer、body await-for、
conditional tail `yield* await`、catch recovery 与 finally `yield* await cleanup`。async*
`await for (... in await streamFuture)` super-chain 已在
`44_async_generator_await_for_await_stream_chains.dart` 补齐,覆盖 pending `await` 后
generic Stream async iterator、continue/break guard、try/finally cleanup、try/catch recovery
与 cleanup Stream 全部来自 pending `await` 的路径。async* switch-selected Stream
super-chain 已在 `45_async_generator_switch_selected_stream_chains.dart` 补齐,覆盖
`yield* switch (await tier) { ... => await streamFuture }` 与
`await for (... in switch (await tier) { ... => await streamFuture })`,以及 cleanup
`await for`、pending await stream operand、switch-selected Stream 的 source -> module -> binary
路径。async* switch-selected Stream finalizer super-chain 已在
`46_async_generator_switch_selected_stream_finalizer_chains.dart` 补齐,覆盖 switch-selected
pending Stream 的 `yield*` 后接 generic `await for`、finally 内 `yield* await cleanup`,
以及 nested switch-selected `await for` + catch recovery + cleanup `await for` 的更深
stream/finalizer cross-product。async* triple switch-selected Stream finalizer super-chain 已在
`47_async_generator_triple_switch_stream_finalizer_chains.dart` 补齐,覆盖三层
switch-selected pending Stream `await for`、continue/break guard、catch recovery、finally
`yield* await cleanup`,以及 `yield*` + switch-selected `await for` + catch `yield*`
recovery + finally switch-selected cleanup `await for`。async* collection/stream/finalizer
super-chain 已在 `48_async_generator_collection_stream_finalizer_chains.dart` 补齐,覆盖
generic `await for` body 内 await-aware list/map yield、list `if (await ...)`、dynamic spread、
map runtime `for-in` 的 pending `await` source/value、catch map recovery 与 finally
`...await cleanup` dynamic map spread。async* awaited runtime collection source super-chain
已在 `49_async_generator_awaited_runtime_collection_sources.dart` 补齐,覆盖 list runtime
`for (final x in await xs)` source、`...await tail`、finally list runtime for-in cleanup,以及
map runtime `for (final entry in (await map).entries)` body/finally 双 pending source。普通
async awaited runtime collection source 对称覆盖已在
`50_async_awaited_runtime_collection_sources.dart` 补齐,覆盖 async Future return 路径下
list `for (final x in await xs)`、`...await tail`、map `(await map).entries` runtime
for-in 与 `...await tail`。普通 async awaited runtime collection try/catch/switch
super-chain 已在 `51_async_awaited_runtime_collection_try_chains.dart` 补齐,覆盖 async
Future return 路径下 list `for (final item in await primary)`、`...await tail`、
`switch (await tier)`、try/catch recovery list,以及 map `(await primary).entries`
runtime for-in、`...await tail`、catch recovery map。普通 async awaited runtime collection
try/catch/finally cleanup super-chain 已在
`52_async_awaited_runtime_collection_finalizer_chains.dart` 补齐,覆盖 async Future return
路径下 list/map awaited runtime collection source、catch recovery、finally 内 awaited
runtime collection cleanup,以及 condition/switch pending await 与 cleanup pending await 的组合。

**测试锚点**:`tests/e2e/test_kernel_compile_from_plan.sh`(真实 Kernel → binary module →
`FcbPatchRuntimeAsyncStarSourceModuleStreamListen` 和
`FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor` 跑源级生成器/await-for 用例,含多源
nested `await for` + break/continue/finally 的正常、cancel、outer error、inner error runtime
路径,以及三层 nested stream lowering/runtime normal/cancel/outer-error/middle-error/inner-error 路径;
source fixture 继续覆盖 body `await for` / `yield*` + finalizer 内 `await for` / `yield*`
cleanup 组合;
`22_async_generator_guarded_switch_chains.dart` 覆盖 async* guarded switch + await-for /
yield* / collection / catch/finally 组合;
`23_async_generator_switch_statement_chains.dart` 覆盖 async* lowered switch statement +
terminating throw case + map-for yield 组合;
`24_async_generator_switch_stream_chains.dart` 覆盖 async* switch statement + stream
delegation/recovery/cleanup 组合;
`25_sync_generator_switch_iterable_chains.dart` 覆盖 sync* switch statement + iterable
delegation/recovery/cleanup 对称组合;
`26_async_switch_statement_collection_chains.dart` 覆盖普通 async switch statement +
collection/recovery/cleanup 组合;
`27_async_object_call_type_collection_chains.dart` 覆盖普通 async object construction +
dynamic/static call + type-test/cast + collection/recovery/cleanup 组合;
`28_async_object_loop_finalizer_chains.dart` 覆盖普通 async object/type/call + loop/finalizer
组合;
`29_async_generator_object_call_type_chains.dart` 覆盖 async* object/type/dynamic/static call +
await-for/yield*/recovery/cleanup 组合;
`30_async_generator_object_switch_collection_chains.dart` 覆盖 async* object/type/call +
switch/collection/finalizer 组合;
`31_sync_generator_object_switch_collection_chains.dart` 覆盖 sync* object/type/call +
switch/collection/finalizer 对称组合;
`32_sync_generator_object_loop_finalizer_chains.dart` 覆盖 sync* object/type/call +
while/for/do-while loop/finalizer 组合;
`33_async_generator_object_loop_finalizer_chains.dart` 覆盖 async* object/type/call +
while/for/do-while loop/finalizer 组合;
`34_async_generator_nested_stream_loop_switch_collection_chains.dart` 覆盖 async*
nested await-for + loop/switch/collection/finalizer 组合;
`35_sync_generator_nested_iterable_loop_switch_collection_chains.dart` 覆盖 sync*
nested iterable for-in + loop/switch/collection/finalizer 对称组合;
`36_async_collection_deep_spread_for_chains.dart` 覆盖普通 async list/map dynamic
spread + runtime for-in + static tail/catch/finally 深链组合;
新 deep-nested filter 也已纳入 `scripts/test_vendor_vm_runtime.sh` release VM gate;summary 写
`target/fcb/kernel-compile-from-plan/summary.txt`;`make check-phase-e-host-evidence` 会检查该 summary
与 VM summary 及其底层 SDK delta audit / 全量 release+debug VM filter 日志);
VM filter 列表已抽到 `scripts/fcb_vm_test_filters.sh`,由
`scripts/test_vendor_vm_runtime.sh` 与 `scripts/check_phase_e_host_evidence.sh` 共同 source;
`make test-phase-e-host-evidence-gate` 覆盖 host evidence gate 的 pass、缺 release log、缺 debug
`Done:`、缺 VM summary filter、no-rebuild 写 canonical dir 必拒绝等 fail-closed 场景;
release/patch Dart fixture 已拆到
`tests/e2e/kernel_compile_from_plan/fixtures/{release_main_parts,patch_main_parts}/`
已按主题再分组,包括 `01_core/`、`02_generators_and_collections/`,
`03_async_loop_stream_seed/`、`04_async_collections_control/`,
`05_generator_object_nested/`、`06_generator_async_stream_super/` 和
`07_async_awaited_runtime_collections/`;`test_kernel_compile_from_plan.sh` 会递归按路径排序拼回
`main.dart`,保持原编号顺序同时避免 fixture part 继续堆在同一级。`make check-kernel-compile-fixture-size`
递归扫描 fixture part、拆分后的 Python
断言文件,以及相邻 Phase E gate 脚本(`fcb_vm_test_filters.sh`、
`check_phase_e_host_evidence.sh`、`test_vendor_vm_runtime.sh`、
`test_phase_e_host_evidence_gate.sh`、`check_phase_e_completion.sh`、
`test_phase_e_completion_gate.sh`)钉在默认 1500 行以内,并已接入 local core CI;
`tests/e2e/test_kernel_business_stream_e2e.sh`(`FcbPatchRuntimeBusinessStreamSourceE2e` 跑真实业务
`async* { await; yield; await for; yield*; finally }` 含 error-after-yield、第二个通用
`yield* delegated` 的 data/error/cancel-after-fourth、cancel-after-second);
Python 断言已按职责拆到 `tests/e2e/kernel_compile_from_plan/assertions/` 下:
`plan/` 负责 source inventory 与 reject/audit 对齐断言,`generator/` 负责 generator
source inventory 断言,`module/` 负责 FCBM JSON module 断言,`binary/` 负责 binary
smoke/string anchor 断言。高频新增的小型 chain 断言已合并为主题文件,例如
`assert_plan_async_collection_chains.py`,
`assert_plan_async_object_generator_chains.py`,
`assert_generator_async_chains.py`,
`assert_generator_object_sync_chains.py`,
`assert_module_async_chain_groups.py` 和
`assert_module_generator_async_chain_groups.py`。`test_kernel_compile_from_plan.sh` 通过 `ASSERT_DIR`
引用这些分层目录;`make check-kernel-compile-fixture-size` 递归扫描 `assertions/`,
避免新增断言继续堆在 `kernel_compile_from_plan/` 顶层,并继续把单文件大小钉在默认
1500 行以内。同时仍覆盖 unchanged `Future<Function>` / `Future<Record>` type arg 不产出
`bytecode_source`,防止 reader/audit 覆盖漂移时用错误 reject 抵消计数。

**前端代码组织**:`fcb_kernel_reader.dart` 已把 switch expression lowering 拆到
`fcb_kernel_switch_expr.dart`,switch statement lowering 拆到
`fcb_kernel_switch_statement_expr.dart`,collection literal / collection-for lowering
拆到 `fcb_kernel_collection_expr.dart`,collection append/runtime-for helper 拆到
`fcb_kernel_collection_append_expr.dart`;`fcb_kernel_manifest.dart` 已把 reader bundle
拆到 `fcb_kernel_reader_bundle.dart`,IR→bytecode 编译器拆到
`fcb_kernel_manifest_compiler.dart`,control-flow/collection/generator helpers 拆到
`fcb_kernel_manifest_control_compiler.dart`;generator lowering 拆为
`fcb_kernel_generator_{expr,for_expr,loop_expr,stream_expr}.dart`(do-while lowering 已归入
`fcb_kernel_generator_loop_expr.dart`,yield lowering 已归入
`fcb_kernel_generator_yield_expr.dart`,lowered for-in body / label guard helper 已归入
`fcb_kernel_generator_for_in_body_expr.dart`);
普通 async lowering 拆为
`fcb_kernel_async_expr.dart`、`fcb_kernel_async_loop_expr.dart` 和
`fcb_kernel_async_for_expr.dart`。
SDK delta 边界由 `scripts/audit_vendor_dart_sdk_delta.sh` 守护(禁止 `async_patch.dart` 带 FCB
delta,FCB helper 集中在 `fcb_async_patch.dart`;已验收的 5 个 FCB VM hook official-path delta
必须在 diff 内带 FCB marker 才允许通过 audit)。

## 剩余

1. **前端长尾**(非 blocker,迭代扩):复杂交织控制流(更复杂 `while`/`for` update、更多嵌套
   branch-local 组合;当前普通 async `local; nested if; return`、branch-local pending `await`、
   语句序列 `if`/`if/else` side-effect + tail、`if` branch try/finally 和 try/catch pending `await` +
   shared tail、`if/else` 双分支 try/finally + try/catch pending `await` + shared tail、
   ternary conditional + pending `await` branch(含两侧均 pending await、condition 自身 pending await、
   nested ternary 多 await branch)、
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
   async collection literal dynamic spread list/map、loop finalizer copy-spread list/map、async runtime
   collection-for list/map 已覆盖);
   async* yield value 内 list/map/string/switch pending `await` 已覆盖;async* yield
   collection-for/dynamic-spread + pending `await` 已覆盖;async* `yield* await streamFuture`
   已覆盖;async* `await for (... in await streamFuture)` 已覆盖;
   async* switch-selected Stream finalizer cross-product 与三层 switch-selected
   stream/finalizer super-chain 已覆盖;
   async* collection/stream/finalizer super-chain 已覆盖;
   async* awaited runtime collection source super-chain 已覆盖;
   普通 async awaited runtime collection source 对称覆盖已覆盖;
   普通 async awaited runtime collection try/catch/switch super-chain 已覆盖;
   普通 async awaited runtime collection try/catch/finally cleanup super-chain 已覆盖;
   更多多层 async* stream 委派 cancel/finally 组合;多源嵌套 `await for` 更深层级的
   cancel/error/finally cross-product 组合继续扩。
   后续继续补更深 collection/control-flow 组合。
2. **IDE 级 debugger**:parked generator/async 帧的 pause/evaluate、VM breakpoint registry(后续独立阶段)。

## 已闭合的 P4/设备证据(2026-06-23)

- `tests/e2e/test_kernel_compile_from_plan.sh`:通过。`target/fcb/kernel-compile-from-plan/summary.txt`
  记录 pass 结果、workdir、runtime filters,并运行
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
