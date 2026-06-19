**目标**
继续完整实现 Phase E Dart VM runtime。当前已完成 FCBM v3、同步 finally、PatchError/DartException 分层、VM exception bridge、递归 guard，以及泛型 type resolver 的 `T/List<T>` 核心解析；async suspend/resume、generic entry type args threading、debugger pause/evaluate 仍未完成。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库不要把 vendor 当 submodule 使用。
- generated evidence 只放 `target/fcb/evidence/*` 或 `target/fcb/*`；不要把生成证据放回 `tests/e2e`。
- 不要 force push；除非用户明确要求，最多自动 commit。

**已完成**
- 根仓库已提交到 `2006a77`；embedded Dart 已提交到 `94ee5e6c4a1`。
- 本轮 embedded Dart 未提交：`RuntimeTypeEnvironment`，`DartIsType`/`ResolveType` 支持 `T`、`List<T>` 映射到 concrete type 后调用 `IsInstanceOf`。
- 本轮 embedded Dart 未提交：`fcb_patch_runtime_type_test.cc` 增加 `FcbPatchRuntimeTypeEnvironmentListT`，验证 `List<T>` 在 `T=String` 时 true、`T=int` 时 false。
- 本轮根仓库未提交：`plans/phase_e_dart_vm.md` 和 `handoff.md` 更新泛型 resolver 进度。

**已验证**
- `scripts/test_vendor_vm_runtime.sh`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/fcb_patch_runtime_vm.cc`: 通过。
- 直接 `-fsyntax-only fcb_patch_runtime_type_test.cc` 因 Dart `unit_test` 宏环境不足失败，需 rebuilt `run_vm_tests` 执行 isolate unit test。

**当前状态**
- 根仓库：`main...origin/main [ahead 5]`，未提交 `plans/phase_e_dart_vm.md`、`handoff.md`。
- embedded Dart：detached HEAD，未提交 `runtime/vm/fcb_patch_runtime_internal.h`、`runtime/vm/fcb_patch_runtime_vm.cc`、`runtime/vm/fcb_patch_runtime_type_test.cc`。
- `vendor/flutter` 外层仍未修改。
- 当前实现仍不是完整 Phase E；generic method/function 的真实 type args 尚未从 entry threaded 到 interpreter frame，async await 仍 fail-closed。

**下一步**
1. 跑 `cargo fmt --check`、`cargo test -p fcb_core bytecode`、diff check。
2. 提交 embedded Dart 本轮改动，建议 `fix: resolve fcb generic type parameters`。
3. 提交根仓库文档，建议 `docs: update phase e generic progress`。
4. 后续把 entry/closure invocation 的真实 function type args 填入 `RuntimeTypeEnvironment`，再推进 async `Await` suspend/resume 和 debugger pause/evaluate。
