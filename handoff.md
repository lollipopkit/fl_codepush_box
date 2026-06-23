**目标**
继续 Phase E Kernel 前端追平,扩大真实 Dart source -> IR -> FCBM binary 覆盖,同时保持 SDK delta、VM/host/Android completion gate 不回退。

**硬约束**
- 不要更新 `progress.md`;当前它仍是删除状态。
- 不要再引入总量类 gate、summary 字段或文档事实。
- 工作树很脏且疑似并行 agent;不要 reset/checkout/revert/清理无关改动。
- reader 支持的 Kernel node 必须有 source/module/binary/gate 断言;不支持必须 fail-closed reject。
- SDK delta audit 必须保持 `fcb_or_allowed_delta_count: 0`。
- 单源码/测试文件继续由 `make check-kernel-compile-fixture-size` 约束。

**已完成**
- 本轮整理 `tests/e2e/kernel_compile_from_plan/` 断言目录结构:
  - `assertions/plan/`: source inventory / reject / audit 对齐断言。
  - `assertions/generator/`: generator source inventory 断言。
  - `assertions/module/`: FCBM JSON module 断言。
  - `assertions/binary/`: binary smoke/string anchor 断言。
- `tests/e2e/test_kernel_compile_from_plan.sh` 已改为通过 `ASSERT_DIR` 引用分层断言目录。
- `scripts/check_kernel_compile_fixture_size.sh` 已改为递归扫描 `assertions/` 下的 `assert_*.py`,继续执行单文件大小 gate。
- `fixtures/{patch_main_parts,release_main_parts}/` 已按主题分组到 `01_core/`、`02_generators_and_collections/`、`03_async_loop_stream_seed/`、`04_async_collections_control/`、`05_generator_object_nested/`、`06_generator_async_stream_super/`、`07_async_awaited_runtime_collections/`。
- `tests/e2e/test_kernel_compile_from_plan.sh` 的 fixture compose 已改为递归按路径排序读取;`scripts/check_kernel_compile_fixture_size.sh` 也递归扫描 fixture `.dart`。
- 小型 chain 断言已按主题合并:
  - `plan/assert_plan_async_collection_chains.py`
  - `plan/assert_plan_async_object_generator_chains.py`
  - `generator/assert_generator_async_chains.py`
  - `generator/assert_generator_object_sync_chains.py`
  - `module/assert_module_async_chain_groups.py`
  - `module/assert_module_generator_async_chain_groups.py`
- reader 近期已扩到 async*/普通 async 的 awaited collection/stream/finalizer super-chain:40-49 号覆盖 async* pending guard、yield 内 pending await、`yield* await`、`await for (... in await streamFuture)`、switch-selected Stream、collection/stream/finalizer、awaited runtime collection source。
- `tool/fcb_kernel_collection_expr.dart` 已让 runtime collection-for iterator source 走 await-aware `_collectionValueExpr`,闭合 `for (... in await keys)` / `(await map).entries` receiver pending await,其余 unsupported 形态仍 fail-closed。
- 50/51 号普通 async 对称覆盖已接入: awaited runtime collection source、try/catch/switch recovery 的 list/map Future return 路径。
- 52 号普通 async try/catch/finally cleanup super-chain已接入:
  - `tests/e2e/kernel_compile_from_plan/fixtures/patch_main_parts/52_async_awaited_runtime_collection_finalizer_chains.dart`
  - `tests/e2e/kernel_compile_from_plan/fixtures/release_main_parts/52_async_awaited_runtime_collection_finalizer_chains.dart`
  - 覆盖 list/map awaited runtime collection source、catch recovery、finally 内 awaited runtime collection cleanup,以及 condition/switch pending await 与 cleanup pending await 的组合。
- 52 号已接入 source/module/binary 断言:
  - `plan/assert_plan_async_collection_chains.py`
  - `module/assert_module_async_chain_groups.py`
  - `binary/assert_binary.py`
- `plans/phase_e_frontend_and_generators.md` 已同步 52 号覆盖。
- `progress.md` 未更新。

**已验证**
- `FCB_KEEP_KERNEL_COMPILE_TEST=1 tests/e2e/test_kernel_compile_from_plan.sh`:通过;最新保留 workdir `/tmp/fcb_kernel_compile_from_plan_rwwxQm`;同时跑过 `FcbPatchRuntimeAsyncStarSourceModuleStreamListen` / `FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor`。
- `scripts/audit_vendor_dart_sdk_delta.sh`:通过,`fcb_or_allowed_delta_count: 0`。
- `make check-kernel-compile-fixture-size`:通过。
- `make test-phase-e-host-evidence-gate`:通过。
- `make check-phase-e-host-evidence`:通过。
- `make check-phase-e-completion`:通过。
- `git diff --check`:通过。
- 禁用总量字段扫描:无命中。

**当前状态**
- `target/fcb/kernel-compile-from-plan/summary.txt` 是最新 compile-from-plan 通过证据。
- 本轮未改 vendor Dart SDK;顶层 `tests/e2e/kernel_compile_from_plan/` 已不再直接放 `assert_*.py`,fixture part 也不再堆在 patch/release 同一级。
- pending-await continue+break 同时复用同一 guard 仍保持 fail-closed 边界,未放宽 audit。
- 工作树仍包含大量既有和并行改动;不要清理无关文件。

**下一步**
1. 继续按较大组合扩 P1/P2/P3 前端长尾,优先更深 collection/control-flow 与 sync*/async* stream/loop/finalizer/cancel cross-product。
2. 后续仍缺 IDE debugger parked async/generator frame 独立阶段。
