**目标**
继续完成 `plans/phase_e_dart_vm.md`。生产 bytecode install 路径已修复；已完成 Future 的 async 子集继续扩展到语句级 if-return，以及 await-local 后接 if-return 且分支内 immediate await。Phase E 仍未完成，剩余重点是 Dart `_Closure` 暴露、真正挂起的 `await` continuation、VM unwinder 级 stack unwinding。

**硬约束**
- 单一真源：Dart VM / engine 逻辑只放在 `vendor/flutter/engine/src/flutter/third_party/dart`。
- 不要恢复 `engine_patch/`、`dart_sdk_patch/`、`scripts/sync_dart_vm_patch.sh`。
- 顶层 `vendor/sdk/` 暂不删除，除非用户明确允许。
- 工作树很脏且可能有并行 agent；不要 revert 无关改动，不要整理暂存区。
- 单源码文件最多 1500 行；`fcb_patch_runtime.cc` 1486 行，不要继续膨胀主解释器文件；`updater/src/tests.rs` 1509 行是既有超限，本轮未改。

**已完成**
- Rust bytecode schema/reader 已下沉到 `crates/fcb_core/src/bytecode.rs`；`crates/fcb_bytecode/src/format.rs` 重导出 `fcb_core::bytecode::*`。
- `crates/fcb_core/src/state.rs` 的 bytecode install contract 已改为 envelope-only：支持 binary FCBM + JSON，只做最小结构校验，未知 opcode 留给 VM fallback。
- `crates/fcb_core/src/state_tests.rs` 新增 binary FCBM install 测试，覆盖 `GetField 0x43` + `CallStatic 0x50`；新增 unknown opcode payload 安装成功测试。
- `tests/e2e/test_e2e.sh` 新增 iOS bytecode `promote` + updater `check --install --platform ios --arch arm64` 分支，真实 FCBM 经 updater install 落盘且没有 `artifact_path`。
- `tool/fcb_kernel_closure_audit.dart` 避免 fallback Kernel 下访问未绑定 `interfaceTarget`；`cli/src/auto.rs` 与 `tool/fcb_kernel_manifest.dart` 用 `FCB_KERNEL_TOOL_DIR` 固定 snapshot helper 目录。
- `_Closure` 边界本轮只做安全修复：`Value::List` / `Value::Map` 遇到内部 bytecode closure 不再递归 materialize 成含 `null` 的 Dart 容器；VM helper 参数转换走 `TryMaterializeDartObject`，遇到 `ValueKind::kBytecodeClosure` 显式失败并 fallback。
- `vendor/.../runtime/vm/fcb_patch_entry.cc` 已把 return conversion failure 纳入 bad patch fallback：解释器返回内部 bytecode closure 等无法转换回 Dart 的值时，disable patch、上报 interpret failure、记录 AOT call，并返回 false 给原 AOT/JIT，而不是向调用者返回 `ApiError`。
- `vendor/.../runtime/vm/fcb_patch_runtime_bytecode_closure_test.cc` 新增 `FcbPatchEntryFallsBackOnEscapingBytecodeClosure`，覆盖 escaping bytecode closure 返回 Dart 边界时 patch 进入 `kDisabledBadPatch`。
- `tool/fcb_kernel_async_expr.dart` 已支持 async 语句级 if-return 内部的 immediate await string interpolation：`if (enabled) return 'patched ${await Future.value('awaited')}'; return ...;` 会降级为 `JumpIfFalse 0x31` + `StringConcat 0x42` + `_Future.value<T>`，仍不支持真正挂起的 await continuation。
- `tests/e2e/test_kernel_compile_from_plan.sh` 用现有 `awaitedLabel(bool enabled)` 覆盖该形态。
- `tool/fcb_kernel_async_expr.dart` 的 await-local tail 现在走 async-aware tail helper；`awaitedLocalLabel()` 覆盖 `try { final prefix = await Future.value(...); if (...) return '$prefix ${await Future.value(...)}'; return ...; } catch (e) { ... }`，生成 `TryBegin 0x61`、`StoreLocal 0x04`、`JumpIfFalse 0x31`、`StringConcat 0x42` 与 `_Future.value<String>`。
- `scripts/test_vendor_vm_runtime.sh` standalone 编译源列表已加入 `fcb_patch_runtime_value.cc`，避免拆分 `Value` 实现后链接缺符号。
- `plans/phase_e_dart_vm.md` 已记录 bytecode install 三处分叉修复、bytecode closure materialization guard、return conversion fallback、语句级 if-return immediate await 与 await-local tail if-return；仍明确 Dart `_Closure` 暴露和真正挂起 await 未完成。

**已验证**
- `cargo test -p fcb_core`：通过。
- `cargo test --workspace`：通过。
- `cd server && go test ./...`：通过；仓库根 `go test ./...` 失败是预期，根目录不是 Go module。
- `cargo build -p fcb` 与 `cd server && go build -o ../target/debug/fcb_server .`：通过。
- `FCB_BIN=target/debug/fcb SERVER_BIN=target/debug/fcb_server tests/e2e/test_e2e.sh`：通过，含新增 iOS bytecode updater install 分支。
- `scripts/test_vendor_vm_runtime.sh`：通过，生成 `target/fcb/vendor-vm-test/summary.txt`。
- `VPYTHON_VIRTUALENV_ROOT=/private/tmp/fcb-vpython-root PATH="$PWD/vendor/depot_tools:$PATH" ninja -C vendor/flutter/engine/src/out/host_release_arm64 run_vm_tests`：通过，目标已最新。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeRejectsBytecodeClosureDartMaterialization`：通过。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchEntryFallsBackOnEscapingBytecodeClosure`：通过。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeCallClosureNamed`：通过。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeTryCatchesCallClosureException`：通过。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeReturningBytecodeClosureCapturesContext`：通过。
- `DART_BIN=vendor/flutter/bin/dart tests/e2e/test_kernel_compile_from_plan.sh`：通过，输出 `kernel compile-from-plan drill passed` 与 `kernel binary compile-from-plan drill passed`。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeNewObjectFutureValue`：通过。
- `git diff --check` 针对本轮相关文件：通过。

**当前状态**
- `fcb_bytecode` crate 仍存在以兼容现有 imports，但不再拥有 schema/opcode 实现。
- VM loader 侧仍有 C++ schema/loader，这是 runtime 权威；Rust 侧已消除 CLI/updater schema drift 和 install gate 断裂。
- `_Closure` 仍不能作为真实 Dart `_Closure` 暴露；当前只是避免错误地把 bytecode closure 当作 `null` 传入 Dart helper，或作为无法转换的返回值泄漏成 `ApiError`。
- async/await 仍不支持真正挂起 continuation；当前只覆盖 `_Future.value<T>` 可证明已完成的同步降级子集。
- 重要行数：`fcb_patch_runtime.cc` 1486，`fcb_patch_entry.cc` 835，`fcb_patch_runtime_vm.cc` 1286，`fcb_patch_runtime_value.cc` 109，`fcb_patch_runtime_bytecode_closure_test.cc` 622，`fcb_patch_runtime_call_closure_test.cc` 350，`tool/fcb_kernel_async_expr.dart` 339，`tests/e2e/test_kernel_compile_from_plan.sh` 1497，`crates/fcb_core/src/bytecode.rs` 952，`tests/e2e/test_e2e.sh` 444。

**下一步**
1. 设计并实现真正 Dart `_Closure` 暴露：需要 VM trampoline、Function/Closure/Context 协议、GC root 和 fallback 语义，不能用普通 Object/Map/null 伪装。
2. 推进真正挂起的 `await` continuation / `_FutureImpl` state-machine 恢复；当前只覆盖无 `await` async return、immediate `await Future.value(...)`、immediate await string interpolation、语句级 if-return immediate await、await-local 和 await-local tail if-return。
3. 推进 VM unwinder 级 Dart stack unwinding；当前仅有 `StackTrace::ToCString()` 文本层 `<fcb patch>` 多帧追加。

**完整计划仍缺**
- Dart `_Closure` 暴露。
- async/await continuation。
- VM unwinder 级 Dart stack unwinding。
