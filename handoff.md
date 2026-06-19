**目标**
继续完整实现 Phase E Dart VM runtime。当前重点是把 async、异常/finally、泛型、ObjectPtr 边界和 debugger 语义逐步推进到生产可验收;完整 Phase E 尚未完成。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`;不要恢复顶层 `vendor/dart`。
- 根仓库、`vendor/flutter`、embedded Dart 是不同 git 状态;提交要分开。
- generated evidence 只放 `target/fcb/*` 或 `target/fcb/evidence/*`;不要放回 `tests/e2e`。
- 不要 force push;除非用户明确要求,最多自动 commit。

**已完成**
- FCBM v3、同步 finally、PatchError/DartException 分层、VM exception bridge、泛型 resolver、bytecode closure/DartEntry/AOT generic type args threading 已完成。
- immediate async 子集已支持:scalar passthrough、completed `_Future.value` 拆箱、completed error Future catch、completed chained Future、`AsyncReturn` completed value/null。
- pending/non-completed Future fail-closed 为 `PatchError`,不会被 interpreted `TryBegin` catch 当作业务异常吞掉;completed error Future 仍可被 catch。
- debugger handler metadata 已修正:active `TryFinally` 不计入可 catch handler;active `TryBegin` catch 仍正常识别。
- `Rethrow` 会保留原始 throw bytecode/source-map offset。
- 本轮修复 Smi 0 ObjectPtr 边界:`Value::FromDart(Smi 0)` 还原为 `Value::Int(0)`,`TryMaterializeDartObject(Value::Int(0))` 不再误报未 materialized。
- 本轮把 pending Future 测试改回直接 `_Future._state = 0`,覆盖 Smi 0 经 `SetField` 写入 Dart heap 字段。

**已验证**
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`:通过。
- `VPYTHON_VIRTUALENV_ROOT=target/fcb/vpython-root PATH=$PATH:.../depot_tools /opt/homebrew/bin/ninja -C vendor/flutter/engine/src/out/host_debug_unopt_arm64 run_vm_tests`:通过。
- `run_vm_tests` 逐个运行并通过:`FcbPatchRuntimeSmiZeroRoundTripsAsInt`、`FcbPatchRuntimeAwaitPendingFutureIsPatchError`。
- `clang++ -std=c++20 -fsyntax-only ... -DFCB_PATCH_RUNTIME_STANDALONE runtime/vm/fcb_patch_runtime_async.cc`:通过。
- `scripts/test_vendor_vm_runtime.sh`:通过,summary 在 `target/fcb/vendor-vm-test/summary.txt`。
- `cargo test -p fcb_core bytecode`:39 个 bytecode 相关测试通过。

**当前状态**
- embedded Dart dirty:`runtime/vm/fcb_patch_runtime_vm.cc`、`runtime/vm/fcb_patch_runtime_new_object_test.cc`、`runtime/vm/fcb_patch_runtime_semantics_test.cc`。
- 根仓库 dirty:`plans/phase_e_dart_vm.md`、`handoff.md`;另有未处理的 `fl_codepush_box.code-workspace` 显示名改动。
- `vendor/flutter` 外层未修改。
- 根仓库为 `main...origin/main [ahead 22]`;embedded Dart 为 detached HEAD。
- `runtime/vm/fcb_patch_runtime_vm.cc` 约 1547 行,仍略超 1500,后续继续拆分。

**下一步**
1. 提交 embedded Dart,建议 `fix: preserve fcb smi zero object values`。
2. 提交根仓库 plan/handoff,建议 `docs: update phase e smi zero boundary`。
3. 继续真实 async suspend/resume:pending/chained source Future、pending error resume、await 周围 finally resume。

**完整计划仍缺**
- rebuilt precompiler/AOT 真机端到端验证 generic static-call stub。
- VM stack/resource guard 命中转真正 Dart `StackOverflowError` unwinder。
- 真实 async suspend/resume 与 `_FutureImpl`/continuation 集成。
- suspended await 周围 finally resume、VM stack trace 注入。
- debugger breakpoint/step/pause 与 async resume 后逻辑栈。
