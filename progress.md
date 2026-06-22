**当前进度**
- Phase E VM/Android arm64 AOT patch 验收已闭环;当前继续推进 Kernel 前端长尾。
- 本轮一次性新增 6 个普通 `async` loop + `try` 交叉覆盖:
  - `asyncWhileAwaitConditionTryCatchAwaitGuard`
  - `asyncWhileAwaitConditionTryFinallyAwaitGuard`
  - `asyncDoWhileAwaitConditionTryCatchAwaitGuard`
  - `asyncDoWhileAwaitConditionTryFinallyAwaitGuard`
  - `asyncForAwaitConditionTryFinallyAwaitGuardAwaitUpdate`
  - `asyncForAwaitConditionTryCatchAwaitGuardAwaitUpdate`
- 已锁住 `while`/`do-while` pending `await` condition + body `try/catch`/`try/finally` + pending await guard/finalizer,以及 `for` pending `await` condition + pending `await` update + body `try/catch`/`try/finally`。
- compile-from-plan 计数已更新为 interpreted 374、reject 2、unchanged 11、module/binary function 389;reject 集合仍为 `isCallable:function_type_unsupported` 与 `isRecord:record_type_unsupported`。
- 文件规模仍在 1500 行内:`assert_plan_async_loop_sources.py` 1251/1500,`assert_module_async_loops.py` 886/1500,release/patch `01b_core_async_loops.dart` 均 625/1500。

**关键验证**
- `tests/e2e/test_kernel_compile_from_plan.sh`:通过,并运行 `FcbPatchRuntimeAsyncStarSourceModuleStreamListen` / `FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor`;summary 写入 374/2/11/389/389。
- `scripts/audit_vendor_dart_sdk_delta.sh`:通过,`fcb_or_allowed_delta_count: 6`。
- `make test-phase-e-host-evidence-gate`:通过。
- `make check-kernel-compile-fixture-size`:通过。
- `make check-phase-e-host-evidence`:通过。
- `make check-phase-e-completion`:通过。
- `git diff --check`:通过。

**剩余任务**
- 继续 P1/P2/P3 前端长尾:更复杂 loop update/嵌套 branch-local、更多 async*/await-for cancel/error/finally cross-product。
- IDE debugger parked async/generator frame 后续独立阶段。
