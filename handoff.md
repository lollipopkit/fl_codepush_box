**目标**
继续 Phase E Kernel 前端追平,保持 VM/Android arm64 AOT patch 已闭合状态不回退,逐步补真实 Dart source -> IR 的长尾覆盖。

**硬约束**
- 工作树很脏且疑似并行 agent;不要 reset/checkout/revert/清理无关改动。
- SDK delta 继续隔离在 FCB flag/path 下,避免影响官方 Dart SDK 默认路径。
- reader 支持的 Kernel node 必须有 fixture + plan/module/binary 断言;reader 不支持的 node 必须 fail-closed reject。
- 单源码/测试文件继续守住 1500 行限制,用 `make check-kernel-compile-fixture-size` 验证。

**已完成**
- 本轮新增 6 个有限 Stream value/empty/guard 组合:
  - `asyncGeneratedYieldStarValueCatchFinally`
  - `asyncGeneratedYieldStarEmptyCatchFinally`
  - `asyncGeneratedAwaitForValueCatchFinally`
  - `asyncGeneratedAwaitForEmptyCatchFinally`
  - `asyncGeneratedAwaitForFutureBreakCatchFinally`
  - `asyncGeneratedAwaitForPendingContinueCatchFinally`
- 相关 fixture 在 `tests/e2e/kernel_compile_from_plan/fixtures/{release_main_parts,patch_main_parts}/02_async_generators.dart`。
- 相关断言已覆盖 `assert_generator_sources.py`、`assert_module_stream_generators.py`、`assert_binary.py`、`assert_plan_inventory.py`、host evidence gate scripts。
- compile-from-plan 计数更新为 interpreted 398、reject 2、unchanged 11、module/binary function 413;reject 集合仍为 `isCallable:function_type_unsupported` 与 `isRecord:record_type_unsupported`。

**已验证**
- `tests/e2e/test_kernel_compile_from_plan.sh`:通过;两个 source async* VM filters 均 `Done`;summary 写入 398/2/11/413/413。
- `scripts/audit_vendor_dart_sdk_delta.sh`:通过,`fcb_or_allowed_delta_count: 6`。
- `make test-phase-e-host-evidence-gate`:通过。
- `make check-kernel-compile-fixture-size`:通过。
- `make check-phase-e-host-evidence`:通过。
- `make check-phase-e-completion`:通过。
- `git diff --check`:通过。

**当前状态**
- 当前工作树包含本轮 Phase E 文件改动,同时仍有无关 `.github/workflows/*` 改动;本轮未修改 workflow。
- `target/fcb/kernel-compile-from-plan/summary.txt` 已刷新到 398/2/11/413/413。
- 文件规模风险暂可控:patch `02_async_generators.dart` 904/1500,`assert_generator_sources.py` 843/1500,`assert_module_stream_generators.py` 731/1500。

**下一步**
1. 继续补 P1/P2/P3 前端长尾,优先选择一组同主题缺口,避免每轮只补单个 case。
2. 每组缺口至少跑 `tests/e2e/test_kernel_compile_from_plan.sh`;触及 evidence 计数时同步跑 host evidence gate/check。
3. 若后续要 commit,先按责任拆分 Kernel 前端、plan/handoff 与并行 agent 的 workflow 改动。

**完整计划仍缺**
- 更复杂 loop update/嵌套 branch-local 组合。
- 更多 async*/await-for cancel/error/finally cross-product。
- IDE debugger parked async/generator frame 后续独立阶段。
