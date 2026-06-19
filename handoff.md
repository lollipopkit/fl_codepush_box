**目标**
继续完整实现 Phase E Dart VM runtime。当前同步解释器、泛型 threading、同步 finally 和 immediate await 子集在推进中,完整 Phase E 仍未闭合。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`;不要恢复顶层 `vendor/dart`。
- 根仓库、`vendor/flutter`、embedded Dart 是不同 git 状态;提交要分开。
- generated evidence 只放 `target/fcb/*` 或 `target/fcb/evidence/*`;不要放回 `tests/e2e`。
- 不要 force push;除非用户明确要求,最多自动 commit。

**已完成**
- FCBM v3、同步 finally、PatchError/DartException 分层、VM exception bridge、泛型 resolver、bytecode closure/DartEntry/AOT generic type args threading 已完成。
- AOT generic static-call bridge 已支持 `TypeArguments + 4 user args` 五 raw slot 场景。
- interpreter VM stack headroom guard 已接入。
- immediate `Await` 子集已支持:
  - 非 Future/FutureOr 值直接通过。
  - 已完成 `_Future.value(...)` 从 `_resultOrListeners` 同步拆箱。
  - 本轮新增已完成 error Future: `_stateError` 从 `AsyncError.error` 取业务异常,走 `fail_or_throw`,可被 interpreted `TryBegin` catch 捕获。
- `plans/phase_e_dart_vm.md` 已更新:completed Future value/error await 已完成;真正 suspend/resume 仍未完成。

**已验证**
- `git diff --check`:通过。
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`:通过。
- `cargo fmt --check`:通过。
- `cargo test -p fcb_core bytecode`:39 个 bytecode 相关测试通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/fcb_patch_runtime_async.cc`:通过,覆盖 VM-only `AsyncError.error` helper 语法。
- `clang++ -std=c++20 -fsyntax-only ... -DFCB_PATCH_RUNTIME_STANDALONE runtime/vm/fcb_patch_runtime.cc`:通过。
- `scripts/test_vendor_vm_runtime.sh`:通过,summary 在 `target/fcb/vendor-vm-test/summary.txt`。
- `ninja -C vendor/flutter/engine/src/out/host_debug_unopt_arm64 run_vm_tests`:阻塞于 GN regen,`vpython3 ... Returned 127`;未验证 rebuilt VM unit tests。

**当前状态**
- 根仓库 dirty:`plans/phase_e_dart_vm.md`、`handoff.md`。
- embedded Dart dirty:`runtime/vm/fcb_patch_runtime_async.cc`、`runtime/vm/fcb_patch_runtime_new_object_test.cc`。
- `vendor/flutter` 外层未修改。
- 根仓库仍为 `main...origin/main [ahead 13]`;embedded Dart 为 detached HEAD。
- `runtime/vm/fcb_patch_runtime_vm.cc` 约 1548 行,仍略超 1500,后续继续拆分。

**下一步**
1. 在 embedded Dart 提交本轮 runtime/test,建议 `fix: propagate fcb await future errors`。
2. 在根仓库提交 plan/handoff,建议 `docs: update phase e await error progress`。
3. 修复/刷新 depot_tools bootstrap 后 rebuilt `run_vm_tests`,执行新增 await isolate test。
4. 继续真实 async suspend/resume:pending/chained Future、pending error resume、await 周围 finally。

**完整计划仍缺**
- rebuilt precompiler/AOT 真机端到端验证 generic static-call stub。
- VM stack/resource guard 命中转真正 Dart `StackOverflowError` unwinder。
- 真实 async suspend/resume 与 `_FutureImpl`/continuation 集成。
- pending/chained Future、await 周围 finally、`ReThrow` stack trace 保留、VM stack trace 注入。
- debugger breakpoint/step/pause 与 async resume 后逻辑栈。
