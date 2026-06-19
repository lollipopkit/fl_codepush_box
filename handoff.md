**目标**
继续完整实现 Phase E Dart VM runtime。当前同步解释器能力继续推进中，但完整 Phase E 仍未闭合。

**硬约束**
- Dart VM 真源是 `vendor/flutter/engine/src/flutter/third_party/dart`；不要恢复顶层 `vendor/dart`。
- 根仓库、`vendor/flutter`、embedded Dart 是不同 git 状态；提交要分开。
- generated evidence 只放 `target/fcb/*` 或 `target/fcb/evidence/*`；不要放回 `tests/e2e`。
- 不要 force push；除非用户明确要求，最多自动 commit。

**已完成**
- FCBM v3、同步 finally、PatchError/DartException 分层、VM exception bridge、递归 guard 已在前序提交完成。
- 泛型 resolver 已支持 `RuntimeTypeEnvironment` 下的 `T` / `List<T>`。
- bytecode closure trampoline 和 VM `DartEntry` 普通 generic function entry 已 threading invocation type args。
- 本轮完成 arm64/x64 AOT generic static-call bridge：
  - `runtime/vm/compiler/aot/precompiler.cc` 允许 generic fixed-arity target 进入 FCB probe，并按 `user_arg_count + 1` 选择 raw slot stub。
  - `runtime/vm/compiler/stub_code_compiler_{arm64,x64}.cc` 把真实 `ARGS_DESC_REG` 传给 FCB AOT runtime entry。
  - `runtime/vm/runtime_entry.cc` 根据 descriptor 跳过 raw `TypeArguments` slot。
  - `runtime/vm/fcb_patch_entry.{cc,h}` 新增 AOT overload，把 raw `TypeArguments` 转成 interpreter type environment。
  - `runtime/vm/fcb_patch_runtime_type_test.cc` 增加 AOT bridge generic type args 覆盖。
- `plans/phase_e_dart_vm.md` 已更新：AOT generic bridge 完成；4 user args generic AOT 和 rebuilt AOT 端到端仍未完成。

**已验证**
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/fcb_patch_entry.cc`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/runtime_entry.cc`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/compiler/aot/precompiler.cc`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/compiler/stub_code_compiler_arm64.cc`: 通过。
- `clang++ -std=c++20 -fsyntax-only ... runtime/vm/compiler/stub_code_compiler_x64.cc`: 通过。
- `scripts/test_vendor_vm_runtime.sh`: 通过。
- `cargo fmt --check`: 通过。
- `cargo test -p fcb_core bytecode`: 39 个 bytecode 相关测试通过。

**当前状态**
- embedded Dart 有未提交改动：`runtime/vm/compiler/aot/precompiler.cc`、`runtime/vm/compiler/stub_code_compiler_{arm64,x64}.cc`、`runtime/vm/runtime_entry.cc`、`runtime/vm/fcb_patch_entry.{cc,h}`、`runtime/vm/fcb_patch_runtime_type_test.cc`。
- 根仓库有未提交改动：`plans/phase_e_dart_vm.md`、`handoff.md`。
- `vendor/flutter` 外层未修改。
- `runtime/vm/fcb_patch_runtime_vm.cc` 仍约 1548 行，后续应拆分。

**下一步**
1. 提交 embedded Dart，建议 `fix: thread fcb aot generic type arguments`。
2. 提交根仓库文档，建议 `docs: update phase e aot generic progress`。
3. 后续若要完全闭合 AOT generic：新增/扩展 runtime entry 支持 `TypeArguments + 4 user args` 五个 raw slots，并 rebuilt precompiler/AOT 真机验证。
4. 推进 async `Await` suspend/resume、await 周围 finally、debugger pause/step/evaluate。

**完整计划仍缺**
- generic AOT target 带 4 个 user args 的 raw slot 支持。
- 真实 async suspend/resume 与 `_FutureImpl`/continuation 集成。
- await suspension 周围 finally、`ReThrow` stack trace 保留、VM stack trace 注入。
- debugger breakpoint/step/pause 与 async resume 后逻辑栈。
