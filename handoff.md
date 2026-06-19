**目标**
继续完整实现 Phase E Dart VM runtime。当前已推进到同步异常/finally、immediate async、泛型 type args、ObjectPtr 边界、VM stack trace source frame 和 VM stack guard Dart exception;完整 Phase E 尚未完成。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`;不要恢复顶层 `vendor/dart`。
- 根仓库、`vendor/flutter`、embedded Dart 是不同 git 状态;提交要分开。
- generated evidence 只放 `target/fcb/*` 或 `target/fcb/evidence/*`;不要放回 `tests/e2e`。
- 不要 force push;除非用户明确要求,最多自动 commit。
- 根仓库既有 dirty `fl_codepush_box.code-workspace` 是显示名改动,本轮未触碰。

**已完成**
- FCBM v3、同步 finally、PatchError/DartException 分层、业务异常 VM bridge、泛型 resolver、bytecode closure/DartEntry/AOT generic type args threading 已完成。
- immediate async 子集已支持:scalar passthrough、completed `_Future.value` 拆箱、completed error Future catch、completed chained Future、`AsyncReturn` completed value/null。
- pending/non-completed Future fail-closed 为 `PatchError`,不会被 interpreted `TryBegin` catch 当作业务异常吞掉。
- `Rethrow` 保留原始 throw bytecode/source-map offset;entry bridge 逃逸业务异常已携带 FCB source-map stack trace。
- 本轮修复 VM stack guard 语义:`OSThread::HasStackHeadroom()` 失败时返回 `DartException(StackOverflowError)`;entry bridge 因此走 VM unwinder,不会 disable patch/fallback。
- 新增 `PatchRuntimeOptions::force_vm_stack_overflow_for_testing` 只用于 VM 单测覆盖 stack guard 路径。

**已验证**
- `clang++ -std=c++20 -fsyntax-only -DFCB_PATCH_RUNTIME_STANDALONE ... runtime/vm/fcb_patch_runtime.cc`:通过。
- `VPYTHON_VIRTUALENV_ROOT=$PWD/target/fcb/vpython-root PATH=$PATH:$PWD/vendor/flutter/engine/src/flutter/third_party/depot_tools /opt/homebrew/bin/ninja -C vendor/flutter/engine/src/out/host_debug_unopt_arm64 run_vm_tests`:通过。
- `./vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchRuntimeVmStackGuardIsDartException`:通过。
- `./vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchRuntime`:通过。
- `./vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchRuntimeTryCatchThrow`:通过。
- `scripts/test_vendor_vm_runtime.sh`:通过。
- `cargo test -p fcb_core bytecode`:39 个 bytecode 相关测试通过。
- `git diff --check` 和 `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`:通过。

**当前状态**
- embedded Dart dirty:`runtime/vm/fcb_patch_runtime.cc`、`runtime/vm/fcb_patch_runtime.h`、`runtime/vm/fcb_patch_runtime_test.cc`。
- 根仓库 dirty:`plans/phase_e_dart_vm.md`、`handoff.md`;另有未处理的 `fl_codepush_box.code-workspace`。
- `vendor/flutter` 外层干净。
- 根仓库为 `main...origin/main [ahead 24]`;embedded Dart 为 detached HEAD。
- `runtime/vm/fcb_patch_runtime_vm.cc` 约 1554 行,仍略超 1500,后续继续拆分。

**下一步**
1. 提交 embedded Dart,建议 `fix: propagate fcb stack guard as stack overflow`。
2. 提交根仓库 plan/handoff,建议 `docs: update phase e stack guard status`。
3. 继续真实 async suspend/resume:pending/chained source Future、pending error resume、await 周围 finally resume。

**完整计划仍缺**
- 真实 async suspend/resume 与 `_FutureImpl`/continuation 集成。
- suspended await 周围 finally resume。
- rebuilt precompiler/AOT 真机端到端验证 generic static-call stub。
- debugger breakpoint/step/pause 与 async resume 后逻辑栈。
- counter_app 真实业务 patch(widget tree + setState + plugin call)最终验收。
