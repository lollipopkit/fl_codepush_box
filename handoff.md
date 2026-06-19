**目标**
继续完整实现 Phase E Dart VM runtime。当前同步解释器、泛型 threading、同步 finally 和 immediate async 子集在推进中,完整 Phase E 仍未闭合。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`;不要恢复顶层 `vendor/dart`。
- 根仓库、`vendor/flutter`、embedded Dart 是不同 git 状态;提交要分开。
- generated evidence 只放 `target/fcb/*` 或 `target/fcb/evidence/*`;不要放回 `tests/e2e`。
- 不要 force push;除非用户明确要求,最多自动 commit。

**已完成**
- FCBM v3、同步 finally、PatchError/DartException 分层、VM exception bridge、泛型 resolver、bytecode closure/DartEntry/AOT generic type args threading 已完成。
- AOT generic static-call bridge 已支持 `TypeArguments + 4 user args` 五 raw slot 场景。
- interpreter VM stack headroom guard 已接入。
- immediate async 子集已支持:
  - 非 Future/FutureOr 值直接通过。
  - 已完成 `_Future.value(...)` 从 `_resultOrListeners` 同步拆箱。
  - 已完成 error Future:`_stateError` 从 `AsyncError.error` 取业务异常,走 `fail_or_throw`,可被 interpreted `TryBegin` catch 捕获。
  - completed chained Future:`_stateChained` 最多同步跟随 64 层 `_resultOrListeners` source Future,source 已完成 value/error 时复用现有 await 路径。
  - `AsyncReturn(0x63)` immediate `async_future`:把栈顶值包装成 completed `_Future.value(...)`,并走正常 return/finally 路径。
- E5 stats 链路已存在:VM bridge weak-call `fcb_record_interpreter_call`/`fcb_record_aot_call`,updater/Dart API/CLI 已有 stats/ratio。

**已验证**
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`:通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/fcb_patch_runtime_async.cc`:通过。
- `scripts/test_vendor_vm_runtime.sh`:通过,summary 在 `target/fcb/vendor-vm-test/summary.txt`;注意该脚本未覆盖 VM-only `fcb_patch_runtime_new_object_test.cc`。
- `cargo test -p fcb_core bytecode`:39 个 bytecode 相关测试通过。
- `ninja -C vendor/flutter/engine/src/out/host_debug_unopt_arm64 run_vm_tests`:阻塞于 GN regen,`vpython3 ... Returned 127`;新增 `FcbPatchRuntimeAwaitChainedCompletedFutureValue` 尚未由 rebuilt VM unit tests 验证。

**当前状态**
- 根仓库 dirty:`plans/phase_e_dart_vm.md`、`handoff.md`。
- embedded Dart dirty:`runtime/vm/fcb_patch_runtime_async.cc`、`runtime/vm/fcb_patch_runtime_new_object_test.cc`。
- `vendor/flutter` 外层未修改。
- 根仓库为 `main...origin/main [ahead 15]`;embedded Dart 为 detached HEAD。
- `runtime/vm/fcb_patch_runtime_vm.cc` 约 1548 行,仍略超 1500,后续继续拆分。

**下一步**
1. 提交 embedded Dart,建议 `fix: await completed chained fcb futures`。
2. 提交根仓库 plan/handoff,建议 `docs: update phase e chained await progress`。
3. 修复/刷新 depot_tools bootstrap 后 rebuilt `run_vm_tests`,验证 `FcbPatchRuntimeAwaitChainedCompletedFutureValue`、`FcbPatchRuntimeAsyncReturnCompletedFutureValue` 和 await isolate tests。
4. 继续真实 async suspend/resume:pending/chained source Future、pending error resume、await 周围 finally。

**完整计划仍缺**
- rebuilt precompiler/AOT 真机端到端验证 generic static-call stub。
- VM stack/resource guard 命中转真正 Dart `StackOverflowError` unwinder。
- 真实 async suspend/resume 与 `_FutureImpl`/continuation 集成。
- pending/chained source Future、await 周围 finally、`ReThrow` stack trace 保留、VM stack trace 注入。
- debugger breakpoint/step/pause 与 async resume 后逻辑栈。
