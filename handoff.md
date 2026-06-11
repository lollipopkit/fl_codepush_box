**目标**
继续按 review comment 逐条验真并最小修复 `fl_codepush_box` MVP。当前约束仍是 `server` 用 Go/Fiber，`cli` 和 `updater` 用 Rust。

**硬约束**
- 先验真再修改；已不存在的问题只在最终说明中标记跳过。
- 不提交 ignored/generated 产物：`.fcb/`、`fcb.yaml`、`target/`、Flutter `.dart_tool/`、`packages/fcb_code_push/native/`、`android/src/main/jniLibs/`。
- 当前未 push；如需继续 PR，先看 `git status --short` 和 PR 状态。

**本轮已完成**
- `packages/fcb_code_push/tool/build_android_native.sh`：`rm -rf` 前校验 `OUT_DIR`/`ABI`/`TARGET`，并使用 `rm -rf -- "$TARGET"`。
- `updater/src/lib.rs`：配置变更会清空 `runtime.last_check`；`public_key_pem` 支持 PEM/SPKI DER 或 32-byte raw public-key base64 并统一保存为 raw key base64；读写 C 指针的 exported FFI 改为 `pub unsafe extern "C" fn` 并补 `# Safety`。
- `crates/fcb_core/src/state.rs`：installed 修剪保留 `current_patch_number` 和 `pending_patch_number`，新增回归测试。
- `server/main.go`：createPatch 校验 payload key 必须等于服务端 canonical key，拒绝覆盖已存在 payload；manifest/payload URL 使用 Host header 保留端口，新增测试。
- `engine_patch/android/fcb_engine_hook_test.cc`：给测试 linker stub 加注释。
- `examples/counter_app/lib/main.dart`：示例 counter 改为 state + FAB 递增。
- `packages/fcb_code_push/android/build.gradle`：移除库模块 buildscript/AGP classpath。
- `packages/fcb_code_push/lib/fcb_code_push.dart`：configure 前置输入校验；candidate native library paths 增加维护注释和 debug-only logging。
- `packages/fcb_code_push/test/fcb_code_push_test.dart`：测试 public key 改为合法 32-byte base64。

**已验证**
- `cargo test`: 通过。
- `go test ./...` in `server/`: 通过。
- `flutter test` in `packages/fcb_code_push`: 通过。
- `flutter analyze` in `packages/fcb_code_push`: 通过。
- `flutter analyze` in `examples/counter_app`: 通过。
- `c++ -std=c++17 -Wall -Wextra -Werror -Iengine_patch/android engine_patch/android/fcb_engine_hook.cc engine_patch/android/fcb_engine_hook_test.cc -o /tmp/fcb_engine_hook_test && /tmp/fcb_engine_hook_test`: 通过。
- `sh -n packages/fcb_code_push/tool/build_android_native.sh && packages/fcb_code_push/tool/build_android_native.sh arm64-v8a`: 通过。
- `cargo fmt --all -- --check && git diff --check`: 通过。

**跳过/已不存在**
- `server/writeFileAtomic` 已经使用 `os.CreateTemp`、`Sync`、`Close` 和 `Rename`，无需再改。
- `PLAN.md` line 339-341 当前函数名是普通文本/代码块片段，未见 MD037 所指强调符号空格问题，未修改。

**当前状态**
- 工作树有本轮源码改动和 `Cargo.lock` 变更，尚未 commit。
- Android native build 重新生成了 ignored 的 `packages/fcb_code_push/native/android` 和 `android/src/main/jniLibs` 产物；不要提交。

**下一步**
1. 如用户要求，审查 `git diff` 后 commit，建议 commit msg：`fix: address updater and server review findings`。
2. 如继续 PR，push 当前分支并查看 PR checks。
