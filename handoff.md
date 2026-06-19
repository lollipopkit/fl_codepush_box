**目标**
继续完整实现 Phase E Dart VM runtime。当前已完成 FCBM v3 元数据、同步 finally 控制流，并开始拆分 exception result 语义；async suspend/resume、VM unwinder 级 Dart exception、泛型类型实参、递归策略、debugger pause/evaluate 仍未完成。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库不要把 vendor 当 submodule 使用。
- generated evidence 只放 `target/fcb/evidence/*` 或 `target/fcb/*`；不要把生成证据放回 `tests/e2e`。
- 不要 force push；除非用户明确要求，最多自动 commit。

**已完成**
- 根仓库已提交：`f6016d2 fix: add fcbm v3 async metadata`、`3e99ec4 docs: update phase e finally progress`。
- embedded Dart 已提交：`7e57cccdb10 fix: accept fcbm v3 async metadata`、`3853594a24b fix: run sync finally handlers in fcb runtime`。
- 本轮 embedded Dart 未提交：新增 `runtime/vm/fcb_patch_runtime_helpers.{h,cc}`，把 opcode/helper 逻辑从 `fcb_patch_runtime.cc` 拆出；主文件从 1795 行降到约 1250 行。
- 本轮 embedded Dart 未提交：`InterpretResult` 增加 `InterpretResultKind`，区分 `kPatchError` 与 `kDartException`；`CallStatic` 和 bytecode closure 只把业务 `DartException` 送入 catch handler。
- 本轮 embedded Dart 未提交：`fcb_patch_runtime_try_test.cc` 增加回归测试，证明 callee 内部 patch error 不会被 caller catch handler 吞掉。
- 本轮根仓库未提交：`scripts/test_vendor_vm_runtime.sh` 编译新 helper；`plans/phase_e_dart_vm.md`、`handoff.md` 更新进度。

**已验证**
- `scripts/test_vendor_vm_runtime.sh`: 通过，摘要在 `target/fcb/vendor-vm-test/summary.txt`。

**当前状态**
- 根仓库：`main...origin/main [ahead 2]`，未提交 `scripts/test_vendor_vm_runtime.sh`、`plans/phase_e_dart_vm.md`、`handoff.md`。
- embedded Dart：detached HEAD，未提交 `runtime/vm/fcb_patch_runtime.cc`, `runtime/vm/fcb_patch_runtime.h`, `runtime/vm/fcb_patch_runtime_helpers.{h,cc}`, `runtime/vm/fcb_patch_runtime_try_test.cc`, `runtime/vm/vm_sources.gni`。
- `vendor/flutter` 外层仍未修改。
- 当前实现仍不是完整 Phase E；top-level interpreted throw 仍未调用 VM `Exceptions::Throw`，async await 仍 fail-closed。

**下一步**
1. 跑 `git diff --check`、`git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`、`cargo fmt --check`、`cargo test -p fcb_core bytecode`。
2. 提交 embedded Dart 本轮改动，建议 `fix: separate fcb patch errors from dart exceptions`。
3. 提交根仓库脚本/文档更新，建议 `docs: update phase e exception progress`。
4. 继续实现 VM unwinder 级 `Throw`/`Rethrow`，让 uncaught interpreted throw 成为真正 Dart exception，可被 AOT caller catch。
