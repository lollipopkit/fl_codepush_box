**当前进度**
- Phase E VM/Android arm64 AOT patch 验收已闭环;当前继续推进 Kernel 前端长尾。
- 上轮新增 6 个有限 Stream source error/cleanup 组合,覆盖 `Stream.fromIterable`、`Stream.fromFuture(Future.value(...))`、`Stream.fromFuture(pending Future)` 在 `yield*` / `await for` 下的 `try_catch` + `try_finally` lowering。
- 本轮新增 6 个有限 Stream value/empty/guard 组合:
  - `asyncGeneratedYieldStarValueCatchFinally`
  - `asyncGeneratedYieldStarEmptyCatchFinally`
  - `asyncGeneratedAwaitForValueCatchFinally`
  - `asyncGeneratedAwaitForEmptyCatchFinally`
  - `asyncGeneratedAwaitForFutureBreakCatchFinally`
  - `asyncGeneratedAwaitForPendingContinueCatchFinally`
- 已锁住 `Stream.value`、`Stream.empty`、`Stream.fromFuture(... break)`、`Stream.fromFuture(pending ... continue)` 在 `yield*` / `await for` 下的 `try_catch` + `try_finally` lowering,包括直接 yield、empty source、guard break/continue、catch cleanup yield、module opcode/debug constants 和 binary 字符串。
- compile-from-plan 计数已更新为 interpreted 398、reject 2、unchanged 11、module/binary function 413;reject 集合仍为 `isCallable:function_type_unsupported` 与 `isRecord:record_type_unsupported`。
- 文件规模仍在 1500 行内:patch `02_async_generators.dart` 904/1500,`assert_generator_sources.py` 843/1500,`assert_module_stream_generators.py` 731/1500。

**关键验证**
- `tests/e2e/test_kernel_compile_from_plan.sh`:通过,并运行 `FcbPatchRuntimeAsyncStarSourceModuleStreamListen` / `FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor`;summary 写入 398/2/11/413/413。
- `scripts/audit_vendor_dart_sdk_delta.sh`:通过,`fcb_or_allowed_delta_count: 6`。
- `make test-phase-e-host-evidence-gate`:通过。
- `make check-kernel-compile-fixture-size`:通过。
- `make check-phase-e-host-evidence`:通过。
- `make check-phase-e-completion`:通过。
- `git diff --check`:通过。

**剩余任务**
- 继续 P1/P2/P3 前端长尾:更复杂 loop update/嵌套 branch-local、更多 async*/await-for cancel/error/finally cross-product。
- IDE debugger parked async/generator frame 后续独立阶段。
