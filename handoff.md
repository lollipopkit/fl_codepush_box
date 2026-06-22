**目标**
继续 Phase E Kernel 前端追平,保持 VM/Android arm64 AOT patch 已闭合状态不回退,逐步补真实 Dart source -> IR 的长尾覆盖。

**硬约束**
- 工作树很脏且疑似并行 agent;不要 reset/checkout/revert/清理无关改动。
- SDK delta 继续隔离在 FCB flag/path 下,避免影响官方 Dart SDK 默认路径。
- reader 支持的 Kernel node 必须有 fixture + plan/module/binary 断言;reader 不支持的 node 必须 fail-closed reject。
- 单源码/测试文件继续守住 1500 行限制,用 `make check-kernel-compile-fixture-size` 验证。

**已完成**
- 本轮扩展受限 switch 前端 lowering 与 loop body 组合:
  - switch expression:源码保留 `SwitchExpression` 常量 case + `_` default,以及 CFE 降级后的 `BlockExpression + LabeledStatement + if/break` 形状。
  - switch statement:CFE `SwitchStatement` 常量 case + default,支持 case 直接 `return` / `throw`,case body 局部变量 + `return`/`throw` 序列,async case body 内 pending `await` + `return`/`throw`,以及 case 内多条 side-effect 后 `break` 再继续 shared tail return;assignment switch 也支持分支直接 `throw`。
  - loop body + switch assignment:覆盖 `while`、`do-while`、pending-await condition `while`、`for`、pending-await update `for`、返回 List 的 `for`、返回 Map 的 `for`,以及 nested branch-local / try-catch / try-finally 组合。
  - guarded switch expression/statement 继续 fail-closed,通过 unchanged fixture 锁住。
- 相关 fixture 在 `tests/e2e/kernel_compile_from_plan/fixtures/{release_main_parts,patch_main_parts}/01b_core_async_loops.dart`、`06_switch_expressions.dart` 和 `07_switch_statements.dart`。
- 相关断言已覆盖 `assert_plan_switch_expr_sources.py`、`assert_plan_switch_statement_sources.py`、`assert_plan_async_loop_switch_sources.py`、`assert_module.py`、`assert_binary.py`、`assert_plan_inventory.py`、host evidence gate scripts。
- compile-from-plan 计数更新为 interpreted 463、reject 2、unchanged 13、module/binary function 478;reject 集合仍为 `isCallable:function_type_unsupported` 与 `isRecord:record_type_unsupported`。

**已验证**
- `tests/e2e/test_kernel_compile_from_plan.sh`:通过;两个 source async* VM filters 均 `Done`;summary 写入 463/2/13/478/478。
- `scripts/audit_vendor_dart_sdk_delta.sh`:通过,`fcb_or_allowed_delta_count: 0`。
- `make test-phase-e-host-evidence-gate`:通过。
- `make check-kernel-compile-fixture-size`:通过。
- `make check-phase-e-host-evidence`:通过。
- `make check-phase-e-completion`:通过。
- `git diff --check`:通过。

**当前状态**
- 当前工作树包含本轮 Phase E 文件改动,并保留并行 agent/既有改动;本轮未清理无关文件。
- `target/fcb/kernel-compile-from-plan/summary.txt` 已刷新到 463/2/13/478/478。
- 文件规模风险可控:release `07_switch_statements.dart` 229/1500,patch `07_switch_statements.dart` 350/1500,`fcb_kernel_switch_statement_expr.dart` 474/1500,`assert_plan_switch_statement_sources.py` 469/1500,`assert_module.py` 349/1500,`assert_binary.py` 547/1500。

**下一步**
1. 继续补 P1/P2/P3 前端长尾,优先选择一组同主题缺口,避免每轮只补单个 case。
2. 每组缺口至少跑 `tests/e2e/test_kernel_compile_from_plan.sh`;触及 evidence 计数时同步跑 host evidence gate/check。
3. 若后续要 commit,先按责任拆分 Kernel 前端、plan/handoff 与并行 agent 改动。

**完整计划仍缺**
- 更复杂 loop update/嵌套 branch-local 组合。
- 更多 async*/await-for cancel/error/finally cross-product。
- IDE debugger parked async/generator frame 后续独立阶段。
