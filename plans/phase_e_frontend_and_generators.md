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

**P1 已覆盖**:`Block`/`seq`、`if-else`、`while`(含 guard `break`、`continue`、
`continue+break`,以及 `continue`/`break` guard 内 pending `await`)、`do-while`/C-style `for`(含 guard `break`/`continue` 及其组合、
guard/update 内 pending `await`)、local `let`/`set_local`、
嵌套 branch-local `if` return(含 branch-local initializer 内 pending `await`)、语句序列中的
`if`/`if/else` side-effect + tail、ternary conditional + pending `await` branch、
`if/else` nested branch-local(含 `while`/`for` body 内 pending `await` initializer)、C-style `for`
update pending `await` + loop-body branch-local / nested branch-local、multi-update `for`、
一般 pending `await`(`Await(0x62)` +
`AsyncReturn(0x63)`)、await tail 序列、`try/catch/finally`(含 finalizer 内二次 await)、
`while` pending `await` condition、普通 async `do-while`(含 pending `await` condition、
pending `await` guard,以及二者同存、body branch-local、break、continue、continue+break)、
`Future<void>` 隐式/显式 return、sync `Future.value<T>(...)` returning helper、
sync/async field read → `GetField(0x43)`、async pending `await` 后读取字段并拼接字符串、
函数参数 callback 调用(零参/positional/named/mixed args,含 async mixed positional+named,
以及 async pending `await` 后 callback 调用) →
`CallClosure(0x53)`、sync/async direct string concat → `StringConcat(0x42)`、sync/async local mutation →
`set_local` / `StoreLocal(0x04)`、sync expression-statement block →
`seq`/`Pop(0x05)`/`null`、async conditional `null` literal、sync/async field assignment → `SetField(0x44)`、
async pending `await` 后 field assignment/readback、
sync/async dynamic named call → `CallDynamic(0x51)`、async pending `await` 后 dynamic named call、
sync/async `dart:*` static invocation →
`CallOriginal(0x52)`、async pending `await` 后 `CallOriginal(0x52)`、
async project static invocation → `CallStatic(0x50)`、async pending `await` 后 `CallStatic(0x50)`、
async object construction / named construction / generic construction →
`NewObject(0x55)` + `AsyncReturn(0x63)`、async pending `await` 后 generic object construction、
`!=`/`<`/`<=`/`>=` binary comparison lowering(复用
`>`/`==`/conditional IR)、async arithmetic binary op →
`Add(0x10)` / `Sub(0x11)` / `Mul(0x12)` / `Div(0x13)`、async pending `await` 后
plain `Add(0x10)` / `Sub(0x11)` / `Mul(0x12)`、async `is`/`as`
type-test/cast → `IsType(0x45)` / `AsType(0x46)`、async pending `await` 后 type-test/cast、
async logical `&&` / `||` / `!` → conditional IR、
async `throw` expression → `Throw(0x60)` + `AsyncReturn(0x63)`、
async collection literal static spread/for/if list/map → `MakeList(0x40)` / `MakeMap(0x41)` +
conditional IR、async collection literal dynamic spread list/map → `CallDynamic(addAll)`、async runtime
collection-for list/map → `list_for_in` / `map_for_in`(含 `Future<Map<String,String>>` type arg
结构化/fallback 解析)。

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
248/263/263;`make check-phase-e-host-evidence` 会检查该 summary
与 VM summary 及其底层 SDK delta audit / release filter 日志);
release/patch Dart fixture 已拆到
`tests/e2e/kernel_compile_from_plan/fixtures/{release_main_parts,patch_main_parts}/*.dart`,
`test_kernel_compile_from_plan.sh` 会按文件名排序拼回 `main.dart`,避免单个 fixture 或 shell
继续膨胀;`make check-kernel-compile-fixture-size` 把 shell、fixture part 和拆分后的 Python
断言文件钉在默认 1500 行以内,并已接入 local core CI;
`tests/e2e/test_kernel_business_stream_e2e.sh`(`FcbPatchRuntimeBusinessStreamSourceE2e` 跑真实业务
`async* { await; yield; await for; yield*; finally }` 含 error-after-yield、第二个通用
`yield* delegated` 的 data/error/cancel-after-fourth、cancel-after-second);
Python 断言拆在 `tests/e2e/kernel_compile_from_plan/`;其中 `assert_plan_inventory.py` 会把
plan reject 集合严格钉在 `isCallable:function_type_unsupported` 与
`isRecord:record_type_unsupported`,普通 async control-flow source 断言已拆到
`assert_plan_async_control.py`,core-call source 断言已拆到 `assert_plan_core_calls.py`,
dynamic for-in module 断言已拆到 `assert_module_dynamic_for_in.py`,
同时覆盖 unchanged `Future<Function>` / `Future<Record>` type arg 不产出 `bytecode_source`,
防止 reader/audit 覆盖漂移时用错误 reject 抵消计数,并避免单个断言文件继续膨胀。

**前端代码组织**:`fcb_kernel_reader.dart`(903,collection literal / collection-for lowering
拆到 `fcb_kernel_collection_expr.dart`(659))、`fcb_kernel_manifest.dart`(358,reader bundle
拆到 `fcb_kernel_reader_bundle.dart`,IR→bytecode 编译器拆到
`fcb_kernel_manifest_compiler.dart`(1133))、generator lowering 拆为
`fcb_kernel_generator_{expr,for_expr,loop_expr,stream_expr}.dart`;普通 async lowering 拆为
`fcb_kernel_async_expr.dart` 和 `fcb_kernel_async_loop_expr.dart`。
SDK delta 边界由 `scripts/audit_vendor_dart_sdk_delta.sh` 守护(禁止 `async_patch.dart` 带 FCB
delta,FCB helper 集中在 `fcb_async_patch.dart`)。

## 剩余

1. **P4 退出标准(阻断)**:counter_app 真实 `sync*`/`async*`/一般 `async` 业务 patch 真机/模拟器
   跑通。当前仅 source/JIT widget smoke(`flutter test test/widget_test.dart`)通过;Android 设备验收
   已有 `check-android-arm64-device` / `test-android-arm64-acceptance` Makefile 入口,但当前快速失败在
   `adb wait-for-device` timeout。引擎侧错误嵌套 `.git` 已移走并通过 `scripts/bootstrap.sh --check`,
   embedder bridge 已通过脚本化 FCB GN 生成和关键 C++ 编译单元验证
   (`make test-desktop-embedder-bridge`);完整 macOS embedder target 已脚本化为
   `make test-desktop-embedder-full`,当前 fast-fail 于 `xcrun -sdk macosx metal` 缺 Metal
   Toolchain;提权安装请求已被安全策略拒绝,需用户显式授权或手动安装后复跑(见
   `phase_e_dart_vm.md`)。`make check-phase-e-completion` 已脚本化最终 audit,当前 summary 显示
   host_evidence/pass、android_acceptance/pass、android_interpreter_ratio/fail(`0/0/0.000000`
   无样本),且 android_device_preflight/android_interpret_failure/desktop_embedder_full 仍 fail。
   `make test-phase-e-completion-gate` 已覆盖 completion gate 的 ratio pass/fail/no-samples/missing
   回归。
2. **前端长尾**(非 blocker,迭代扩):复杂交织控制流(更复杂 `while`/`for` update、更多嵌套
   branch-local 组合;当前普通 async `local; nested if; return`、branch-local pending `await`、
   语句序列 `if`/`if/else` side-effect + tail、ternary conditional + pending `await` branch、
   `if/else` nested branch-local(含 `while`/`for` body 内 pending `await` initializer)、
   while condition pending `await`、普通 async `while continue+break`(含 pending `await` guard)、
   普通 async `do-while`(含 pending `await` condition/guard、body branch-local、break、continue、continue+break)、
   for guard/update pending `await`(含二者同存)、for update pending `await` +
   loop-body branch-local/nested branch-local、
   普通 async multi-update `for`、sync `Future.value<T>(...)` returning helper、sync/async field read、
   sync/async local mutation、函数参数 callback 调用(零参/positional/named/mixed args)、sync expression-statement block、
   sync/async field assignment、sync/async dynamic named call、sync/async `dart:*` static invocation、
   async positional/named `new_object` construction、async arithmetic binary op、
   `!=`/`<`/`<=`/`>=` binary comparison lowering、
   async `is`/`as` type-test/cast、async collection literal static spread/for/if list/map、
   async collection literal dynamic spread list/map、async runtime
   collection-for list/map 已覆盖);
   更多多层 async* stream 委派 cancel/finally 组合;多源嵌套 `await for` 更深层级的
   cancel/error/finally cross-product 组合。
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
