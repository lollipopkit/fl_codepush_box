**目标**
继续完整实现 Phase E Dart VM runtime。当前已完成 FCBM v3、同步 finally、PatchError/DartException 分层、VM exception bridge、递归 guard、泛型 resolver，以及 bytecode closure type args threading；async suspend/resume、普通 generic method/static entry type args threading、debugger pause/evaluate 仍未完成。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库不要把 vendor 当 submodule 使用。
- generated evidence 只放 `target/fcb/evidence/*` 或 `target/fcb/*`；不要把生成证据放回 `tests/e2e`。
- 不要 force push；除非用户明确要求，最多自动 commit。

**已完成**
- 根仓库已提交到 `236690c`；embedded Dart 已提交到 `59eaacecc07`。
- 本轮 embedded Dart 未提交：`PatchRuntime::Interpret` 接收 `RuntimeTypeEnvironment`，并把 env 传给 `DartIsType`。
- 本轮 embedded Dart 未提交：bytecode closure trampoline 从 closure invocation `TypeArguments` 构建 `T`/`T0` 映射，传入 interpreter。
- 本轮 embedded Dart 未提交：generic escaping closure body 增加 `AsType T`，现有 `FcbPatchEntryMaterializesGenericBytecodeClosure` 可验证真实 type args threading。
- 本轮根仓库未提交：`plans/phase_e_dart_vm.md` 和 `handoff.md` 更新泛型 threading 进度。

**已验证**
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/fcb_patch_entry.cc`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/fcb_patch_runtime_vm.cc`: 通过。
- `scripts/test_vendor_vm_runtime.sh`: 通过。

**当前状态**
- 根仓库：`main...origin/main [ahead 6]`，未提交 `plans/phase_e_dart_vm.md`、`handoff.md`。
- embedded Dart：detached HEAD，未提交 `runtime/vm/fcb_patch_entry.cc`、`runtime/vm/fcb_patch_runtime.cc`、`runtime/vm/fcb_patch_runtime.h`、`runtime/vm/fcb_patch_runtime_bytecode_closure_test.cc`。
- `vendor/flutter` 外层仍未修改。
- 当前实现仍不是完整 Phase E；普通 generic static/method entry type args 尚未 threaded，async await 仍 fail-closed。

**下一步**
1. 跑 `cargo fmt --check`、`cargo test -p fcb_core bytecode`、diff check。
2. 提交 embedded Dart 本轮改动，建议 `fix: thread fcb closure type arguments`。
3. 提交根仓库文档，建议 `docs: update phase e type argument threading`。
4. 后续接普通 patched static/generic method entry type args，再推进 async `Await` suspend/resume 和 debugger pause/evaluate。
