**目标**
继续完整实现 Phase E Dart VM runtime。当前重点是把 immediate async、异常/finally、泛型和 VM 验证通道逐步闭合;完整 Phase E 尚未完成。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`;不要恢复顶层 `vendor/dart`。
- 根仓库、`vendor/flutter`、embedded Dart 是不同 git 状态;提交要分开。
- generated evidence 只放 `target/fcb/*` 或 `target/fcb/evidence/*`;不要放回 `tests/e2e`。
- 不要 force push;除非用户明确要求,最多自动 commit。

**已完成**
- FCBM v3、同步 finally、PatchError/DartException 分层、VM exception bridge、泛型 resolver、bytecode closure/DartEntry/AOT generic type args threading 已完成。
- immediate async 子集已支持:scalar passthrough、completed `_Future.value` 拆箱、completed error Future catch、completed chained Future、`AsyncReturn` completed value/null。
- 本轮恢复 rebuilt VM 验证通道:用 `target/fcb/offsets-host-debug-arm64.json` 刷新 host debug arm64 generated offsets,越过 `CheckOffsets`。
- 本轮修复 `runtime/vm/fcb_patch_runtime_type_test.cc` 中旧 namespace 引用,改用 `fcb::RuntimeTypeEnvironment`。

**已验证**
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`:通过。
- `clang++ -std=c++20 -fsyntax-only ... -DFCB_PATCH_RUNTIME_STANDALONE runtime/vm/fcb_patch_runtime_async.cc`:通过。
- `scripts/test_vendor_vm_runtime.sh`:通过,summary 在 `target/fcb/vendor-vm-test/summary.txt`。
- `cargo test -p fcb_core bytecode`:39 个 bytecode 相关测试通过。
- `VPYTHON_VIRTUALENV_ROOT=target/fcb/vpython-root PATH=$PATH:.../depot_tools /opt/homebrew/bin/ninja -C vendor/flutter/engine/src/out/host_debug_unopt_arm64 run_vm_tests`:通过,成功链接 rebuilt runner。
- `run_vm_tests` 逐个运行并通过:`FcbPatchRuntimeAwaitCompletedFutureValue`、`FcbPatchRuntimeAwaitCompletedFutureErrorCaught`、`FcbPatchRuntimeAwaitChainedCompletedFutureValue`、`FcbPatchRuntimeAsyncReturnCompletedFutureValue`、`FcbPatchRuntimeAsyncReturnCompletedFutureNull`、`FcbPatchRuntimeTypeEnvironmentListT`、`FcbPatchRuntimeTryCatchThrow`、`FcbPatchRuntimeTryCatchesAsTypeMismatch`。

**当前状态**
- 根仓库 dirty:`plans/phase_e_dart_vm.md`、`handoff.md`。
- embedded Dart dirty:`runtime/vm/compiler/runtime_offsets_extracted.h`、`runtime/vm/fcb_patch_runtime_type_test.cc`。
- `vendor/flutter` 外层未修改。
- 根仓库为 `main...origin/main [ahead 18]`;embedded Dart 为 detached HEAD。
- `runtime/vm/fcb_patch_runtime_vm.cc` 约 1548 行,仍略超 1500,后续继续拆分。

**下一步**
1. 提交 embedded Dart,建议 `fix: refresh fcb host arm64 vm offsets`。
2. 提交根仓库 plan/handoff,建议 `docs: update phase e vm rebuild validation`。
3. 继续真实 async suspend/resume:pending/chained source Future、pending error resume、await 周围 finally resume。

**完整计划仍缺**
- rebuilt precompiler/AOT 真机端到端验证 generic static-call stub。
- VM stack/resource guard 命中转真正 Dart `StackOverflowError` unwinder。
- 真实 async suspend/resume 与 `_FutureImpl`/continuation 集成。
- suspended await 周围 finally resume、`ReThrow` stack trace 保留、VM stack trace 注入。
- debugger breakpoint/step/pause 与 async resume 后逻辑栈。
