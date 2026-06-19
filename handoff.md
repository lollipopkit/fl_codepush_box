**目标**
继续完成 Phase E Dart VM runtime 缺口。当前轮已落地 FCBM v3 格式、async/finally opcode 元数据和 runtime fail-closed 基础层；真正 suspend/resume、VM unwinder 级异常、泛型类型实参、递归策略、debugger pause/evaluate 仍未完成。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库不要把 vendor 当 submodule 使用。
- generated evidence 只放 `target/fcb/evidence/*` 或 `target/fcb/*`；不要把生成证据放回 `tests/e2e`。
- 不要 force push；除非用户明确要求，最多自动 commit。

**已完成**
- 根仓库：`crates/fcb_core/src/bytecode.rs` 升级 `FORMAT_VERSION = 3`，新增 `AsyncKind` 和 `Await/AsyncReturn/Yield/TryFinally/EndFinally/Rethrow` opcode。
- 根仓库：binary FCBM v3 读写 `async_kind`；JSON 仍兼容旧字段默认 `sync`。
- 根仓库：`tool/fcb_kernel_manifest.dart` / `tool/fcb_binary_module_writer.dart` 输出 v3 和 `async_kind`；e2e 断言 async Future.value fast-path 标记为 `async_future`。
- 根仓库：`bytecode.rs` 内联测试拆到 `crates/fcb_core/src/bytecode_tests.rs`，避免单文件超过 1500 行。
- embedded Dart：runtime loader 接受 FCBM v3，读取 `async_kind`；解释器对 v3 async/finally/unwinder opcode 明确返回 unsupported error，避免伪执行。
- 文档：`plans/phase_e_dart_vm.md` 更新为当前真实缺口与 E6 closure 计划。

**已验证**
- `cargo fmt --check`: 通过。
- `dart format --set-exit-if-changed tool/fcb_binary_module_writer.dart tool/fcb_kernel_manifest.dart`: 通过。
- `cargo test -p fcb_core bytecode`: 通过，39 tests passed。
- `tests/e2e/test_kernel_compile_from_plan.sh`: 通过；需要提权，因为 Flutter SDK 写 `/Users/lk/env/flutter/bin/cache`。
- `scripts/test_vendor_vm_runtime.sh`: 通过，摘要在 `target/fcb/vendor-vm-test/summary.txt`。

**当前状态**
- 根仓库工作树未提交：`crates/fcb_core/src/bytecode.rs`, `crates/fcb_core/src/bytecode_tests.rs`, `crates/fcb_core/src/state_tests.rs`, `plans/phase_e_dart_vm.md`, `tests/e2e/test_kernel_compile_from_plan.sh`, `tool/fcb_binary_module_writer.dart`, `tool/fcb_kernel_manifest.dart`, `handoff.md`。
- embedded Dart 工作树未提交：`runtime/vm/fcb_patch_runtime.cc`, `runtime/vm/fcb_patch_runtime.h`, `runtime/vm/fcb_patch_runtime_loader.cc`, `runtime/vm/fcb_patch_runtime_loader_test.cc`。
- 当前实现是第一批基础层，不等于 Phase E 全部缺口完成。

**下一步**
1. 检查 diff 后分别在 embedded Dart 和根仓库 commit；建议 embedded Dart 用 `fix: accept fcbm v3 async metadata`，根仓库用 `fix: add fcbm v3 async metadata`。
2. 若继续实现 Phase E，优先补真正 `Await` suspend/resume 与 `_FutureImpl` continuation 集成。
3. 后续再推进 VM unwinder 级 throw/finally、泛型 type arguments、递归策略、debugger pause/evaluate，并为每项补 standalone + run_vm_tests/e2e 覆盖。
