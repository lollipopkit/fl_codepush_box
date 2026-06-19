**目标**
继续完整实现 Phase E Dart VM runtime。当前同步解释器和部分 immediate async 能力继续推进中，但完整 Phase E 仍未闭合。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库、`vendor/flutter`、embedded Dart 是不同 git 状态；提交要分开。
- generated evidence 只放 `target/fcb/*` 或 `target/fcb/evidence/*`；不要放回 `tests/e2e`。
- 不要 force push；除非用户明确要求，最多自动 commit。

**已完成**
- FCBM v3、同步 finally、PatchError/DartException 分层、VM exception bridge、泛型 resolver、bytecode closure/DartEntry/AOT generic type args threading 已完成。
- AOT generic static-call bridge 已支持 `TypeArguments + 4 user args` 五 raw slot 场景。
- interpreter VM stack headroom guard 已接入。
- 本轮新增 immediate `Await` 子集：
  - `runtime/vm/fcb_patch_runtime.cc` 的 `Await(0x62)` 现在 pop awaited value 并调用 VM helper。
  - 新增 `runtime/vm/fcb_patch_runtime_async.cc`，支持非 Future/FutureOr 值和已完成 `_Future.value` 的 `_stateValue` 同步拆箱。
  - `runtime/vm/fcb_patch_runtime_new_object_test.cc` 增加 `FcbPatchRuntimeAwaitCompletedFutureValue`。
  - `runtime/vm/vm_sources.gni` 和 `scripts/test_vendor_vm_runtime.sh` 已加入新源文件。
- `plans/phase_e_dart_vm.md` 已更新：completed Future await 已完成；真正 suspend/resume 仍未完成。

**已验证**
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`: 通过。
- `git diff --check`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/fcb_patch_runtime.cc`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/fcb_patch_runtime_async.cc`: 通过。
- `scripts/test_vendor_vm_runtime.sh`: 通过。
- `cargo fmt --check`: 通过。
- `cargo test -p fcb_core bytecode`: 39 个 bytecode 相关测试通过。
- rebuilt `run_vm_tests` 仍受 depot_tools bootstrap 环境阻塞：`vpython3` 缺 `.cipd_bin/vpython3`; `ensure_bootstrap` 暴露 mac-arm64 CIPD digest 缺失和 `curl: (18) Transferred a partial file`。

**当前状态**
- embedded Dart 有未提交改动：`runtime/vm/fcb_patch_runtime.cc`、`runtime/vm/fcb_patch_runtime_async.cc`、`runtime/vm/fcb_patch_runtime_internal.h`、`runtime/vm/fcb_patch_runtime_loader_test.cc`、`runtime/vm/fcb_patch_runtime_new_object_test.cc`、`runtime/vm/vm_sources.gni`。
- 根仓库有未提交改动：`scripts/test_vendor_vm_runtime.sh`、`plans/phase_e_dart_vm.md`、`handoff.md`。
- `vendor/flutter` 外层未修改。
- `runtime/vm/fcb_patch_runtime_vm.cc` 仍约 1548 行，后续应继续拆分。

**下一步**
1. 提交 embedded Dart，建议 `fix: support fcb await completed futures`。
2. 提交根仓库脚本/文档，建议 `docs: update phase e await progress` 或拆成脚本与 docs 两个提交。
3. 修复/刷新 depot_tools bootstrap 后 rebuilt `run_vm_tests`，执行新增 AOT generic 和 await isolate tests。
4. 继续 async suspend/resume：pending/chained Future、error Future、await 周围 finally。

**完整计划仍缺**
- rebuilt precompiler/AOT 真机端到端验证 generic static-call stub。
- VM stack/resource guard 命中转真正 Dart `StackOverflowError` unwinder。
- 真实 async suspend/resume 与 `_FutureImpl`/continuation 集成。
- await error、pending/chained Future、await 周围 finally、`ReThrow` stack trace 保留、VM stack trace 注入。
- debugger breakpoint/step/pause 与 async resume 后逻辑栈。
