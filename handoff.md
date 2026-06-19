**目标**
继续完成 `plans/phase_e_dart_vm.md`。Phase E 仍未完成；剩余硬项是真正挂起的 `await` continuation / `_FutureImpl` state-machine、VM unwinder 级 try/catch/throw，以及 materialized bytecode closure 的完整 debugger scope / pause / evaluate。

**硬约束**
- Dart VM / engine 逻辑唯一真源：`vendor/flutter/engine/src/flutter/third_party/dart`。
- 不要恢复 `engine_patch/`、`dart_sdk_patch/`、`scripts/sync_dart_vm_patch.sh`。
- 顶层 `vendor/sdk/` 暂不删除，除非用户明确允许。
- 工作树很脏且可能有并行 agent；不要 revert 无关改动，不要整理暂存区。
- 单源码文件尽量不超过 1500 行；`tests/e2e/test_kernel_compile_from_plan.sh` 当前约 1633 行，后续应拆 helper 而不是继续膨胀。

**已完成**
- FCB debugger active frame 的 `BuildParameters()` 已过滤 `valueMaterialized=false` 的 local，避免未 materialize 的内部 bytecode closure 被作为 `null` 注入 service evaluate 参数。
- `runtime/vm/fcb_patch_runtime_debugger_test.cc` 已新增断言：`FcbPatchDebuggerDescribesUnmaterializedBytecodeClosure` 中 `param_names` / `param_values` 均为空。
- 修复 debug-only 测试里两处 `String::New("boom").ptr()` 编译错误，改为先创建 `String` handle 再构造 `Instance` handle。
- `plans/phase_e_dart_vm.md` 已同步该 debugger/evaluate 边界。

**已验证**
- `VPYTHON_VIRTUALENV_ROOT=/private/tmp/fcb-vpython-root PATH=/Users/lk/proj/fl_codepush_box/vendor/depot_tools:$PATH ninja -C vendor/flutter/engine/src/out/host_debug_unopt_arm64 run_vm_tests`：通过并 relink debug `run_vm_tests`，仅有既有 hidden symbol linker warnings。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerDescribesUnmaterializedBytecodeClosure`：通过。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerCollectsActiveInterpreterFrame`：通过。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerCollectsCapturedClosureActiveFrame`：通过。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerFrameEvaluationUsesSourceLibrary`：通过。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerExposesActiveHandlerMetadata`：通过。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerStackTraceFromStringFrame`：通过。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerCollectsLivePatchFrame`：通过。
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check -- runtime/vm/debugger.cc runtime/vm/fcb_patch_runtime_debugger_test.cc`：通过。
- `git diff --check -- plans/phase_e_dart_vm.md handoff.md`：通过。
- `cargo test -p fcb_core bytecode`：通过，37 个 bytecode/filter 命中测试全绿，包含 v1 无 `debug_locals` 兼容、v2 round-trip、too-new version 拒绝和 updater 安装 binary/unknown opcode 回归。

**当前状态**
- `run_vm_tests FcbPatchDebugger` 不是有效过滤器，返回 `No tests matched`；已改跑具名测试。
- `crates/fcb_core/src/bytecode.rs` 的 binary 前向兼容修复在当前工作树已存在：`FORMAT_VERSION=2`、`MIN_SUPPORTED_MODULE_VERSION=1`，`read_binary` 仅在 `version >= 2` 读取 `debug_locals`，`to_binary_vec` 写当前格式。
- 根仓库仍有大量既有/并行改动；`vendor/flutter/`、`vendor/depot_tools/`、`vendor/sdk/` 在根仓库视角仍是 untracked。
- 普通 `git diff --stat` 不会显示 vendor C++ 改动；用 `git -C vendor/flutter/engine/src/flutter/third_party/dart diff -- runtime/vm/debugger.cc runtime/vm/fcb_patch_runtime_debugger_test.cc` 查看。
- 本轮未跑 `cargo test --workspace`、`go test ./...` 或 Android e2e。

**下一步**
1. 实现真正挂起 `await`：`_FutureImpl` / continuation / suspend-resume state machine。
2. 推进 VM unwinder 级 try/catch/throw，让 FCB handler 承接真实 Dart stack unwind/resume。
3. 补 materialized bytecode closure 的完整 captured context debugger scope、pause/evaluate 停靠帧。
