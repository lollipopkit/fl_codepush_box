**目标**
继续完成 `plans/phase_e_dart_vm.md`。Phase E 仍未完成；剩余硬项是 Dart `_Closure` 暴露、真正挂起的 `await` continuation / `_FutureImpl` state-machine、exception handler unwinder / 完整 captured context scope metadata + pause/evaluate 可停靠帧。

**硬约束**
- Dart VM / engine 逻辑唯一真源：`vendor/flutter/engine/src/flutter/third_party/dart`。
- 不要恢复 `engine_patch/`、`dart_sdk_patch/`、`scripts/sync_dart_vm_patch.sh`。
- 顶层 `vendor/sdk/` 暂不删除，除非用户明确允许。
- 工作树很脏且可能有并行 agent；不要 revert 无关改动，不要整理暂存区。
- 单源码文件尽量不超过 1500 行；当前 `fcb_patch_runtime.cc` 1500 行，`fcb_patch_runtime_test.cc` 1500 行，`fcb_patch_runtime_vm.cc` 1501 行，`debugger.cc` 5416 行。后续逻辑继续拆 helper，避免继续堆主文件。

**已完成**
- bytecode install 生产路径已修复：Rust schema/reader 下沉到 `crates/fcb_core/src/bytecode.rs`，updater install 支持 binary FCBM + JSON，只做 envelope-level 校验，未知 opcode 留给 VM。
- 本轮修复 ADR-#4 binary 前向兼容缺口：`FORMAT_VERSION=2`、`MIN_SUPPORTED_MODULE_VERSION=1`；Rust reader/writer、Dart binary writer、VM binary loader 都按 version gate 处理 `debug_locals`，v1 binary 保持旧布局，v2 才读写 `debug_locals`。
- `tool/fcb_kernel_manifest.dart` 现在产出 bytecode module version 2；`tests/e2e/test_kernel_compile_from_plan.sh` 已同步断言 JSON/binary FCBM version 2。
- Rust canonical `OpCode` 已补齐 `Throw 0x60` / `TryBegin 0x61`，`validate_bytecode` 与 VM 对齐校验 `TryBegin` 的 `current < handler < end < code.len()` 和 instruction-boundary；当前又补齐 `CallClosure` named metadata 常量校验，以及 `LoadArg` / `LoadLocal` / `StoreLocal` 越界校验，避免 CLI/authoring full validation 与 VM runtime 分叉。
- VM `ValidateModule` 也已补齐 `MakeClosure` / `NewObject` string operand 校验和 `CallClosure` metadata 校验；新增 `runtime/vm/fcb_patch_runtime_loader_test.cc` standalone 回归覆盖 missing string operand、bad/missing `CallClosure` metadata。
- `docs/architecture_decisions.md` 与 `plans/phase_e_dart_vm.md` 已同步记录 v1/v2 format 修复和验证证据。
- 本轮继续推进 debugger/unwinder 安全边界：`runtime/vm/debugger.cc::ActivationFrame::HandlesException()` 对 `ActivationFrame::kFcbPatch` 直接返回 false；`runtime/vm/fcb_patch_runtime_debugger_test.cc::FcbPatchDebuggerStackTraceFromStringFrame` 新增 `HandlesException()` / `GetHandlerFrame()` 断言，防止 service exception pause / handler-frame 查找把 FCB pseudo frame 当普通 Dart catch handler 并访问 `code().exception_handlers()`。
- 既有进展仍有效：`_Future.value<T>` 同步 async 子集已完成；bytecode closure 不能物化为 Dart `_Closure` 时 fail-closed；`debug_locals` 源码变量名 metadata 已贯通到 debugger active frame；`fcbPatchScope` / `fcbPatchVars` 已暴露基础变量 metadata；caught VM helper exception 不泄漏 FCB patch stack locations。

**已验证**
- 本轮复核 `crates/fcb_core/src/bytecode.rs` binary 前向兼容修复仍成立：v1 legacy binary 不读 `debug_locals`，v2 round-trip 保留 `debug_locals`，writer 即使输入 module.version=1 也固定产当前 `FORMAT_VERSION=2`。
- `cargo test -p fcb_core`：通过，73 unit tests + 2 schema tests；覆盖 v1 legacy binary 可读、v2 `debug_locals` round-trip、modern opcode binary install、unknown opcode install、`Throw`/`TryBegin` full validation、`CallClosure` metadata 和 arg/local bounds validation。
- `cargo test -p fcb_core bytecode`：通过，35 个 bytecode/state/linker 相关筛选测试。
- `cargo test -p fcb_updater concurrent_check_for_update_uses_single_inflight_request`：通过；用于复核一次 `cargo test --workspace` 中该并发测试的偶发 `WouldBlock`。
- `cargo test --workspace`：最终重跑通过。
- `DART_BIN=vendor/flutter/bin/dart tests/e2e/test_kernel_compile_from_plan.sh`：通过；JSON/binary compile-from-plan drill 均通过，binary FCBM version 为 2。
- `scripts/test_vendor_vm_runtime.sh`：通过；standalone VM loader 覆盖 v1 FCBM source_map 与 v2 FCBM `debug_locals`。
- 本轮重跑 `scripts/test_vendor_vm_runtime.sh`：通过；覆盖新增 VM `ValidateModule` operand/metadata 回归。
- 本轮再次重跑 `scripts/test_vendor_vm_runtime.sh`：通过；覆盖新增 FCB pseudo frame handler lookup fail-closed 断言。
- `cargo fmt --check`：通过。
- `git diff --check -- docs/architecture_decisions.md plans/phase_e_dart_vm.md handoff.md crates/fcb_core/src/bytecode.rs crates/fcb_core/src/state_tests.rs tool/fcb_binary_module_writer.dart tool/fcb_kernel_manifest.dart tests/e2e/test_kernel_compile_from_plan.sh vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.cc vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_loader.cc vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime_test.cc`：通过。

**当前状态**
- 根仓库仍有 staged/unstaged 混合：`crates/fcb_core/src/bytecode.rs`、`crates/fcb_core/src/state_tests.rs`、`docs/architecture_decisions.md`、`handoff.md`、`plans/phase_e_dart_vm.md`、`tests/e2e/test_kernel_compile_from_plan.sh`、`tool/fcb_binary_module_writer.dart`、`tool/fcb_kernel_manifest.dart` 等为 `MM` 或 modified；不要整理暂存区。
- `vendor/flutter/` 在根仓库仍是 untracked；内部 Dart checkout 有大量既有 VM 改动。本轮新增/修改重点是 `runtime/vm/debugger.cc` 和 `runtime/vm/fcb_patch_runtime_debugger_test.cc`。注意 `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --stat runtime/vm/debugger.cc` 会显示大量既有 debugger 改动，不全是本轮新增。
- `_Closure` 暴露仍未实现：`runtime/vm/fcb_patch_runtime_closure.cc` 仍是 fail-closed。不要重复 synthetic native implicit closure 方案；更可行方向是 VM-supported trampoline/code install 或真实 Dart patch/private external trampoline。

**下一步**
1. 继续 debugger/unwinder：当前 FCB pseudo frame 在 handler lookup 中已 fail-closed；下一步仍需决定并实现 FCB bytecode handler 是否/如何参与 VM exception unwinder，以及真正 pause/evaluate 可停靠帧。
2. 继续 Dart `_Closure` 暴露：从 VM-supported trampoline/code install 或真实 Dart patch/private external trampoline 入手。
3. 继续真正挂起 await：实现 `_FutureImpl` / continuation / suspend-resume state machine，不要扩大 `_Future.value<T>` 同步子集冒充完成。
