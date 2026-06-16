**目标**
`PLAN-now.md` 的自动推导 Patch 计划已按当前仓库状态落地；本轮补上 E：bytecode pipeline 不跑 platform-specific `flutter build ios/apk`，改跑 `flutter build bundle` 生成真实 `app.dill` 供 Kernel inventory/linker 使用。

**硬约束**
- 不要 stage/commit 未跟踪的 `vendor/depot_tools/`、`vendor/flutter/`、`vendor/sdk/`。
- `PLAN-now.md` 是目标来源但当前未跟踪，未修改。
- 输出中文；单源码文件当前均低于 1500 行。

**已完成**
- `cli/src/auto.rs`：`run_flutter_build(platform, arch, backend, build)` 按 backend 分流；`bytecode` 走 `flutter build bundle --target-platform ...`，`snapshot_replace` 继续只支持 Android `flutter build apk`。
- `cli/src/auto.rs`：bytecode build-output hash 改为 bundle 产物语义：assets 取 `build/flutter_assets/AssetManifest.bin.json|bin|json`，native 固定 `missing`，plugins 取项目根 `.flutter-plugins-dependencies`。
- `crates/fcb_core/src/build_info.rs`：`BUILD_INFO_SCHEMA_VERSION` bump 到 3，避免旧 release cache 与 bundle hash 语义混用。
- `cli/src/main.rs`：release/patch 都统一调用 backend-aware build，不再用 `requires_platform_build`。
- `tool/fcb_kernel_manifest.dart`：project root 使用 resolved symlink path，修复 macOS `/tmp -> /private/tmp` 导致 file URI 前缀匹配失败、inventory 为空的问题。
- `tests/e2e/test_e2e.sh`：fake Flutter 增加 `bundle` 分支，真实 `dart compile kernel --no-link-platform` 编译 `lib/main.dart` 到 `.dart_tool/flutter_build/<hash>/app.dill`；fixture 增加 `main()`，确保 `mainValue` 进入 Kernel inventory。

**已验证**
- `bash -n tests/e2e/test_e2e.sh`: pass。
- `cargo fmt --check`: pass。
- `cargo test`: pass，46 个测试通过。
- `FCB_BIN=target/debug/fcb SERVER_BIN=./fcb_server tests/e2e/test_e2e.sh`: pass，包含 Android snapshot diff、iOS bytecode `bytecode_module` patch、promote/check/install/rollback、多 app isolation。

**当前状态**
- 待提交相关修改：`cli/src/auto.rs`、`cli/src/main.rs`、`crates/fcb_core/src/build_info.rs`、`tests/e2e/test_e2e.sh`、`tool/fcb_kernel_manifest.dart`、`handoff.md`。
- 未跟踪且不要碰：`PLAN-now.md`、`vendor/depot_tools/`、`vendor/flutter/`、`vendor/sdk/`。

**后续建议**
1. 如需文档化 bytecode plugin 边界，可在正式计划/README 中补一句：bytecode patch 信任 `pubspec.lock` 与 `.flutter-plugins-dependencies` 作为 plugin 边界，不做平台 framework/native artifact hash。
2. `_resolveDill` 仍按最新 `.dart_tool/flutter_build/**/app.dill` 选择，已有 warning；后续可加 build config key 精确匹配。
