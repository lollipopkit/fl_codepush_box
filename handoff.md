**目标**
继续完整实现 Phase E Dart VM runtime。当前已完成 FCBM v3 元数据、同步 finally、PatchError/DartException 分层、逃出 interpreter 的 `Exceptions::Throw` bridge，以及递归固定 64 上限移除；async suspend/resume、泛型类型实参、debugger pause/evaluate 仍未完成。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库不要把 vendor 当 submodule 使用。
- generated evidence 只放 `target/fcb/evidence/*` 或 `target/fcb/*`；不要把生成证据放回 `tests/e2e`。
- 不要 force push；除非用户明确要求，最多自动 commit。

**已完成**
- 根仓库已提交到 `8f450d1`；embedded Dart 已提交到 `09ad0d22886`。
- 本轮 embedded Dart 未提交：`PatchRuntimeOptions::max_call_depth`，默认 4096；`InterpretFunction` 使用可配置 runaway guard，错误包含 function id、depth、max。
- 本轮 embedded Dart 未提交：`fcb_patch_runtime_test.cc` 增加 96 层递归通过测试，以及低 guard 下清晰失败测试。
- 本轮根仓库未提交：`plans/phase_e_dart_vm.md` 和 `handoff.md` 更新递归策略进度。

**已验证**
- `scripts/test_vendor_vm_runtime.sh`: 通过，覆盖新增递归测试。

**当前状态**
- 根仓库：`main...origin/main [ahead 4]`，未提交 `plans/phase_e_dart_vm.md`、`handoff.md`。
- embedded Dart：detached HEAD，未提交 `runtime/vm/fcb_patch_runtime.cc`、`runtime/vm/fcb_patch_runtime.h`、`runtime/vm/fcb_patch_runtime_test.cc`。
- `vendor/flutter` 外层仍未修改。
- 当前实现仍不是完整 Phase E；async await 仍 fail-closed，generic type args 与 debugger 完整停靠仍缺。

**下一步**
1. 跑 `cargo fmt --check`、`cargo test -p fcb_core bytecode`、diff check。
2. 提交 embedded Dart 本轮改动，建议 `fix: make fcb recursion guard configurable`。
3. 提交根仓库文档，建议 `docs: update phase e recursion progress`。
4. 后续推进 async `Await` suspend/resume、generic type args、debugger pause/evaluate，并补 rebuilt VM test 验证 AOT caller catch interpreted throw。
