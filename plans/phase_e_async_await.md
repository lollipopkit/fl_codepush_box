# Phase E — async/await 真正挂起(pending await suspend/resume)

**所属阶段**:Phase E 关键路径长尾(E2 `await`/`async_resume` 的真实实现)
**预计工作量**:~1.5–2.5 人月(已通过"单帧挂起"砍掉 heap frame-stack 这一最大风险块)
**前置依赖**:无(现有 v3 已有 `AsyncKind`、`Await`(0x62)、`AsyncReturn`(0x63)、`TryFinally`、`InterpretResultKind::kDartException` 脚手架)

## 目标

让 patch 里的 async 函数能 `await` **未完成(pending)** 的 Future:在 await 点把解释器帧挂起、立刻把 Future 还给调用者,
待被 await 的 Future 完成后在 microtask 里从 await 点恢复执行。保留现有 PatchError / DartException / fallback 全部语义。

## 现状(开工前确认,均已读代码核对)

- `fcb_patch_runtime.cc::InterpretFunction` 是单个递归 C++ 函数,`stack`/`locals`/`handlers`/`ip` 均为 native 栈局部。
- `Await`(0x62)经 `internal::DartAwaitCompletedFuture`(`fcb_patch_runtime_async.cc`)**同步**读 `_Future` 的
  `_state`/`_resultOrListeners`:value→拆箱、error→注入 throw、chained→跟随(≤64);**pending→硬报错**
  (`async.cc:146` "suspend/resume is not implemented")。这是唯一缺口。
- `AsyncReturn`(0x63)把返回值包 `dart:async::class:_Future.value`(已避免 `Future<Future<T>>`,见 `DartIsFutureValue` adopt)。
- `is_tail_await_async_return` fast path 已存在(tail `await` + `AsyncReturn` 直接返回原 Future)。
- `PatchTable` 当前只持有**一个** `bytecode_` vector,`BytecodeFunction` 全是其 offset → reload/clear 会让任何挂起帧悬垂。

## 关键设计决策

1. **单帧挂起(single-frame suspension),不实现 heap frame-stack。**
   推演:sync 函数不能 `await`(永不挂起,native 递归必先同步返回);`await foo()` 中 foo(async)作为 CallStatic
   **同步返回自己的 Future**(foo 要么跑完、要么 park 自己那一帧),调用者栈正常解开后才执行 `Await`。故任一 suspend 点
   **活着的解释器帧只有当前这一个 async 帧**,各 async 帧 solo 挂起,无需具象化调用链。
   *对 caller:被调 async target 的 Suspended 永远表现为 Completed(future)。*

2. **heap frame-stack 延后为独立阶段**,服务于 generator、深递归去 native 栈、debugger 单步;**不作为 async 上线依赖**。
   CallStatic/CallClosure 在本阶段继续用现有 native recursion + depth/headroom guard。

3. **Frame 必须 pin immutable `ModuleSnapshot`;resume 绝不通过 `function_id` 重查当前 `PatchTable`。**
   否则 patch clear/reload 后会用新 bytecode 跑旧帧 ip/stack → 内存错乱。

4. **"懒 completer"**:挂起前不创建 Completer;但 async entry **无论是否挂起最终都返回 Future**(async 函数签名即 `Future<T>`)。
   懒创建保留了 **pre-suspend transparent fallback 窗口**。

## Runtime 改动

- 新增 `ModuleSnapshot = shared_ptr<const ...>`,含 `bytecode`、`functions`、function index、`constants`。
  `PatchTable::LoadModule` 只**原子替换** current snapshot;`DispatchDecision` 不再暴露悬垂 function pointer。
- 新增 `FcbFrame`:持 `snapshot`、function index、`ip`、args、locals、stack、handlers、type_env、depth、captured count。
  - 正常调用栈上创建;遇 pending await 时 move 到 heap `SuspendedFrame`。
- 解释器主循环改为操作 `FcbFrame&`(同步路径行为不变);`return_value`/`throw_value`/`enter_finally`/`complete_finally` 改接 frame。
- 运行结果保留**四态**:`Completed(value)`、`Suspended(future/token)`、`PatchError`、`DartException`。

### async_future 调用边界规范化(entry bridge)
- completed raw value  → `Future.value(value)`
- completed Future     → adopt/返回同一 Future(不二次包裹)
- DartException(pre-suspend)→ `Future.error(error, stackTrace)`
- suspended            → 返回懒创建的 `Completer.future`

## Suspend / Resume

- `Await`(0x62):
  - completed value Future → 同步拆箱(现有 fast path)
  - completed error Future → 注入 interpreted throw(现有)
  - pending tail-await + `AsyncReturn` → 保留直接返回原 Future fast path
  - 其它 pending Future → **分配 token → 插入 suspended table → 创建/保存 completer → attach
    `_FcbContinuation(token).onValue/onError` → 返回 `completer.future`**(此 attach 顺序固定,防迟到/重入)
- resume native entry(`Fcb_resumeValue(token, value)` / `Fcb_resumeError(token, error, stackTrace)`):
  - 新开 `StackZone`/`HandleScope`
  - value resume:在 await 后 `push(resolved)`,继续
  - error resume:按 await source offset 调 `throw_value`,交给 interpreted try/catch/finally
  - resume 前重新 `UpdateActivePatchFrame`,保 FCB stack trace / debugger frame 可见
- token 单调 `uint64_t`,**永不复用**;重复 / 迟到 resume 为 no-op。

### Dart helper / native bridge
- 在 dart:async 私有实现新增 `_FcbContinuation(token)`,提供 instance tearoff `onValue` / `onError`。
- C++ 只注册 token;Dart 侧 `awaited.then(cont.onValue, onError: cont.onError)`。
- **不复用** VM `_SuspendState` / resume stub(抗 Dart SDK rebase 漂移,见风险表)。

## Fallback 矩阵(写进 ADR)

| | suspend 之前 | suspend 之后(future 已交出) |
|---|---|---|
| **PatchError**(解释器跑不动) | 透明 fallback AOT(仅限有原 AOT entry 的 dispatch path) | completeError + mark bad patch,下次启动走 AOT |
| **DartException**(patch 主动抛) | 包成 errored Future(正常 async 语义,不 fallback / 不同步抛) | completeError |
| **sync DartException** | 保持现有 VM unwinder 抛出 | — |

- pre-suspend async fallback 复用现有 AOT dispatch gate(`TryInvoke...` 返回 false 后续 original entry,ADR-#2 AOT-presence)。

## Lifecycle / GC

- `LoadModule`:旧 suspended frame 继续持旧 snapshot,**不混跑新 bytecode**。
- `Clear` / `DisablePatch` / bad patch:drain 对应 suspended frame,eager `completeError` 并移除 token。
- **isolate / IsolateGroup teardown(`ClearPatchRuntimeForIsolateGroup`)同样 drain suspended table**,释放 snapshot 强引用,避免悬挂。
- `VisitObjectPointers` 扫:current snapshot constants、各 suspended snapshot、frame 的 args/locals/stack/handlers pending values、
  completer/future/error/stacktrace。

## 实施顺序

1. **ModuleSnapshot**:`PatchTable`/`DispatchDecision` 不再暴露悬垂 function pointer(零行为变化,最稳的地基)。
2. 把 interpreter 的 locals/stack/handlers/ip 抽成 `FcbFrame`,同步路径行为保持不变。
3. 新增 `SuspendedFrame` token table + GC visitor + clear/disable/teardown drain。
4. 新增 Dart helper `_FcbContinuation(token)` 与 native resume value/error entry。
5. 改 `Await`(0x62) pending 路径为 suspend/resume;entry bridge 支持懒 completer / errored Future / post-suspend 完成。
6. 扩编译器(`tool/fcb_kernel_manifest.dart`)支持一般 `await` 表达式;`async*`/`sync*`/`Yield`(0x64)继续 fail-closed。
7. 拆分 runtime 文件,避免单文件继续超过 1500 行。

## 测试

- VM runtime:`Future.delayed(Duration.zero)` resume value、连续两次 await、await in loop、pending error 被 try/catch 捕获、
  未捕获 async error → completeError、suspend 周围 finally 在 return/throw/error resume 下执行。
- lifecycle:suspend 后 `LoadModule` 不混跑新 bytecode、`Clear`/`DisablePatch` completeError、迟到 token resume no-op、
  teardown drain、GC visitor 覆盖 suspended frame values。
- 回归:completed Future await、completed error catch、chained completed Future、`AsyncReturn` adopt existing Future、
  tail pending await fast path、sync DartException unwinder、pre-suspend PatchError fallback。
- 验证命令:targeted `run_vm_tests FcbPatchRuntime...`、`scripts/test_vendor_vm_runtime.sh`、`cargo test -p fcb_core bytecode`、`diff --check`。

## 假设 / 边界

- 不复用 VM `_SuspendState` / resume stub。
- `async*` / `sync*` 在 async-Future CPS 稳定前保持 unsupported(fail-closed)。
- 一旦 FCB future 交给调用者,在飞 async 调用**无法透明回退**原 AOT,只能 completeError + mark bad patch,下次调用走 AOT。
- 根工作树中无关改动不纳入 Phase E 提交。
