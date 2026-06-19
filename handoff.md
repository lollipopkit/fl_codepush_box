**目标**
继续完整实现 Phase E Dart VM runtime。当前已完成 FCBM v3 元数据基础层，并在本轮实现同步 `TryFinally`/`EndFinally`/`Rethrow` 控制流；async suspend/resume、VM unwinder 级 Dart exception、泛型类型实参、递归策略、debugger pause/evaluate 仍未完成。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库不要把 vendor 当 submodule 使用。
- generated evidence 只放 `target/fcb/evidence/*` 或 `target/fcb/*`；不要把生成证据放回 `tests/e2e`。
- 不要 force push；除非用户明确要求，最多自动 commit。

**已完成**
- 已提交根仓库 `f6016d2 fix: add fcbm v3 async metadata`：FCBM v3、`async_kind`、v3 opcode 元数据、writer/manifest/e2e、测试拆分。
- 已提交 embedded Dart `7e57cccdb10 fix: accept fcbm v3 async metadata`：runtime loader 接受 v3，读取 `async_kind`。
- 本轮 embedded Dart 未提交改动：`runtime/vm/fcb_patch_runtime.cc` 把控制流 handler 扩展为 catch/finally，支持 pending `continue`/`jump`/`return`/`throw`。
- 本轮 embedded Dart 未提交改动：`runtime/vm/fcb_patch_runtime_try_test.cc` 覆盖 normal jump 执行 finally、finally return 覆盖 try return、throw 经 finally `Rethrow` 后被外层 catch 捕获。
- 本轮根仓库未提交改动：`plans/phase_e_dart_vm.md` 和 `handoff.md` 更新同步 finally 进度。

**已验证**
- `scripts/test_vendor_vm_runtime.sh`: 通过，摘要在 `target/fcb/vendor-vm-test/summary.txt`。
- `cargo fmt --check`: 通过。
- `cargo test -p fcb_core bytecode`: 通过，39 tests passed。
- `git diff --check`: 通过。
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`: 通过。

**当前状态**
- 根仓库：`main...origin/main [ahead 1]`，另有未提交 `plans/phase_e_dart_vm.md`、`handoff.md`。
- embedded Dart：detached HEAD，另有未提交 `runtime/vm/fcb_patch_runtime.cc`、`runtime/vm/fcb_patch_runtime_try_test.cc`。
- `vendor/flutter` 外层仍干净。
- 当前实现仍不是完整 Phase E；同步 finally 比上一轮前进，但 escape 到 AOT caller 的 Dart exception 和 await/finally 还没闭合。

**下一步**
1. 提交 embedded Dart 本轮改动，建议 `fix: run sync finally handlers in fcb runtime`。
2. 提交根仓库文档/handoff，建议 `docs: update phase e finally progress`。
3. 继续实现 VM unwinder 级 `Throw`/`Rethrow`，让 uncaught interpreted throw 成为真正 Dart exception，可被 AOT caller catch。
4. 再推进 async `Await` suspend/resume、generic type args、递归 guard、debugger pause/evaluate。
