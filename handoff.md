**目标**
继续完整实现 Phase E Dart VM runtime。当前已推进到同步异常/finally、immediate async、泛型 type args、ObjectPtr 边界和 VM stack trace source frame;完整 Phase E 尚未完成。

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
- debugger handler metadata 已修正:active `TryFinally` 不计入可 catch handler;active `TryBegin` catch 仍正常识别。
- `Rethrow` 会保留原始 throw bytecode/source-map offset。
- 本轮修复 entry bridge stack trace:`fcb_patch_entry.cc` 对逃出的业务 `DartException` 先 materialize `Exceptions::CurrentStackTrace()`,再用 `Exceptions::ThrowWithStackTrace`,让 FCB source-map frame 进入 VM `UnhandledException.stacktrace()`。
- 本轮更新 `FcbPatchRuntimeStackTraceSourceLocation`,直接覆盖 bridge 使用的 `Exceptions::CurrentStackTrace()` 路径。

**已验证**
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`:通过。
- `VPYTHON_VIRTUALENV_ROOT=$PWD/target/fcb/vpython-root PATH=$PATH:$PWD/vendor/flutter/engine/src/flutter/third_party/depot_tools /opt/homebrew/bin/ninja -C vendor/flutter/engine/src/out/host_debug_unopt_arm64 run_vm_tests`:通过。
- `./vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchRuntimeStackTraceSourceLocation`:通过。
- `./vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchRuntimeTryCatchThrow`:通过。
- 注意:相邻旧测试 `FcbPatchEntryThreadsGenericFunctionTypeArguments` 当前因 `LoadTestScript` 报 `Compilation failed Error while starting Kernel isolate task` 失败并崩溃;这不是本轮新增逻辑引入,但后续需要单独修测试防御或 runner 环境。

**当前状态**
- embedded Dart dirty:`runtime/vm/fcb_patch_entry.cc`、`runtime/vm/fcb_patch_runtime_test.cc`。
- 根仓库 dirty:`plans/phase_e_dart_vm.md`、`handoff.md`;另有未处理的 `fl_codepush_box.code-workspace`。
- `vendor/flutter` 外层干净。
- 根仓库为 `main...origin/main [ahead 23]`;embedded Dart 为 detached HEAD。
- `runtime/vm/fcb_patch_runtime_vm.cc` 约 1554 行,仍略超 1500,后续继续拆分。

**下一步**
1. 提交 embedded Dart,建议 `fix: attach fcb stack traces to dart exceptions`。
2. 提交根仓库 plan/handoff,建议 `docs: update phase e stack trace status`。
3. 继续真实 async suspend/resume:pending/chained source Future、pending error resume、await 周围 finally resume。

**完整计划仍缺**
- 真实 async suspend/resume 与 `_FutureImpl`/continuation 集成。
- suspended await 周围 finally resume。
- VM stack/resource guard 命中转真正 Dart `StackOverflowError` unwinder。
- rebuilt precompiler/AOT 真机端到端验证 generic static-call stub。
- debugger breakpoint/step/pause 与 async resume 后逻辑栈。
- counter_app 真实业务 patch(widget tree + setState + plugin call)最终验收。
