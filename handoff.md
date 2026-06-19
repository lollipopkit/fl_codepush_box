**目标**
继续完整实现 Phase E Dart VM runtime。当前已完成大部分同步 runtime 语义，但完整 Phase E 仍未闭合。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库、`vendor/flutter`、embedded Dart 是不同 git 状态；提交要分开。
- generated evidence 只放 `target/fcb/*` 或 `target/fcb/evidence/*`；不要放回 `tests/e2e`。
- 不要 force push；除非用户明确要求，最多自动 commit。

**已完成**
- FCBM v3、同步 finally、PatchError/DartException 分层、VM exception bridge、递归 guard 已在前序提交完成。
- 泛型 resolver 已支持 `RuntimeTypeEnvironment` 下的 `T` / `List<T>`。
- bytecode closure trampoline 已 threading closure invocation type args。
- 本轮完成 VM `DartEntry` 普通 generic function entry type args threading：
  - `runtime/vm/fcb_patch_entry.cc` 新增 descriptor-aware `TryInvokePatchedFunction` overload。
  - `runtime/vm/dart_entry.cc` 传入 `arguments_descriptor`。
  - `runtime/vm/fcb_patch_runtime_type_test.cc` 增加 `FcbPatchEntryThreadsGenericFunctionTypeArguments`。
- `plans/phase_e_dart_vm.md` 已更新：DartEntry generic 完成；AOT generic static call 仍未完成。

**已验证**
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/fcb_patch_entry.cc`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/dart_entry.cc`: 通过。
- `scripts/test_vendor_vm_runtime.sh`: 通过。
- `cargo fmt --check`: 通过。
- `cargo test -p fcb_core bytecode`: 39 个 bytecode 相关测试通过。

**当前状态**
- embedded Dart 有未提交改动：`runtime/vm/dart_entry.cc`、`runtime/vm/fcb_patch_entry.{cc,h}`、`runtime/vm/fcb_patch_runtime_type_test.cc`。
- 根仓库有未提交改动：`plans/phase_e_dart_vm.md`、`handoff.md`。
- `vendor/flutter` 外层未修改。
- `runtime/vm/fcb_patch_runtime_vm.cc` 仍约 1548 行，后续应拆分。

**下一步**
1. 提交 embedded Dart，建议 `fix: thread fcb generic entry type arguments`。
2. 提交根仓库文档，建议 `docs: update phase e generic entry progress`。
3. 继续 AOT generic static-call probe：先设计并验证 type args ABI，再改 `precompiler.cc` 和各 arch stub。
4. 推进 async `Await` suspend/resume、await 周围 finally、debugger pause/step/evaluate。

**完整计划仍缺**
- AOT generic static call type args threading。
- 真实 async suspend/resume 与 `_FutureImpl`/continuation 集成。
- await suspension 周围 finally、`ReThrow` stack trace 保留、VM stack trace 注入。
- debugger breakpoint/step/pause 与 async resume 后逻辑栈。
