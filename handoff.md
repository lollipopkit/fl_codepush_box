**目标**
继续完整实现 Phase E Dart VM runtime。当前已完成 FCBM v3 元数据、同步 finally、PatchError/DartException 分层，并把逃出 interpreter 的业务 DartException 接到 VM `Exceptions::Throw`；async suspend/resume、泛型类型实参、递归策略、debugger pause/evaluate 仍未完成。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库不要把 vendor 当 submodule 使用。
- generated evidence 只放 `target/fcb/evidence/*` 或 `target/fcb/*`；不要把生成证据放回 `tests/e2e`。
- 不要 force push；除非用户明确要求，最多自动 commit。

**已完成**
- 根仓库已提交：`f6016d2`、`3e99ec4`、`04117d7`。
- embedded Dart 已提交到 `b69fdc757b0`，包含 FCBM v3、sync finally、PatchError/DartException 分层和 helper 拆分。
- 本轮 embedded Dart 未提交：`runtime/vm/fcb_patch_entry.cc` 对 `InterpretResultKind::kDartException` materialize Dart object 并调用 `Exceptions::Throw`；普通 entry、bytecode closure entry、unique-by-arity entry 都已接线。
- 本轮根仓库未提交：`plans/phase_e_dart_vm.md` 和 `handoff.md` 更新 VM exception bridge 进度。

**已验证**
- `scripts/test_vendor_vm_runtime.sh`: 通过，覆盖 runtime core/standalone，不覆盖 `fcb_patch_entry.cc`。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/fcb_patch_entry.cc`: 通过，验证 entry 层语法和 include 依赖。
- `git diff --check`: 通过。
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`: 通过。

**当前状态**
- 根仓库：`main...origin/main [ahead 3]`，未提交 `plans/phase_e_dart_vm.md`、`handoff.md`。
- embedded Dart：detached HEAD，未提交 `runtime/vm/fcb_patch_entry.cc`。
- `vendor/flutter` 外层仍未修改。
- 当前实现仍不是完整 Phase E；`Exceptions::Throw` bridge 需要 rebuilt `run_vm_tests` 真执行验证，async await 仍 fail-closed。

**下一步**
1. 跑 `cargo fmt --check`、`cargo test -p fcb_core bytecode`。
2. 提交 embedded Dart 本轮改动，建议 `fix: throw escaped fcb dart exceptions`。
3. 提交根仓库文档，建议 `docs: update phase e vm exception bridge`。
4. 后续补 rebuilt VM test：AOT Dart caller `try/catch` 捕获 interpreted uncaught throw。
5. 继续 async `Await` suspend/resume、generic type args、递归 guard、debugger pause/evaluate。
