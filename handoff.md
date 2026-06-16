**目标**
`PLAN-now.md` 的自动推导 Patch 计划已按当前仓库状态落地：release/patch 自动流、snapshot_replace 与 bytecode pipeline 分离、Kernel AST inventory、report、测试和 e2e 均已覆盖。

**硬约束**
- 不要 stage/commit 未跟踪的 `vendor/depot_tools/`、`vendor/flutter/`、`vendor/sdk/`。
- `PLAN-now.md` 是目标来源但当前未跟踪，未修改。
- 单源码文件当前均低于 1500 行。

**已完成**
- `cli/src/auto.rs`：release/patch build config、release cache v2、build_info/hash、Kernel tool snapshot 缓存、工具路径和 SDK 路径解析。
- `cli/src/main.rs`：自动 patch payload、manual `--payload` escape hatch、no-op/reject/success `patch_report.json`、`app add`。
- `crates/fcb_core/src/build_info.rs`：hard fail/warn 比较，dart-define warn-only/ignore keys，project_hash 不阻塞 Dart code patch。
- `crates/fcb_core/src/linker.rs`：`LinkerPlan { unchanged, interpret, reject }`，无 `fcb_bytecode` 依赖，class/field/function reject reason。
- `tool/fcb_kernel_manifest.dart`：基于 `.dill` / `package:kernel` 的 Kernel AST inventory，输出 `functions/classes/top_level_fields`，body hash 来自 Kernel text view，不 hash `.dill` 字节；纯 Dart fallback 通过临时 wrapper 生成 `.dill`。
- `tests/e2e/test_e2e.sh`：Android snapshot 自动 binary diff、iOS bytecode 自动 patch、Kernel inventory stability fixture、multi-app isolation。

**已验证**
- `cargo fmt --check`: pass。
- `cargo test`: pass。
- `cargo build -p fcb && FCB_BIN=target/debug/fcb SERVER_BIN=./fcb_server tests/e2e/test_e2e.sh`: pass。
- `vendor/flutter/bin/cache/dart-sdk/bin/dart tool/fcb_kernel_manifest.dart --project examples/counter_app --target lib/main.dart >/tmp/fcb_inventory.json && jq ...`: pass，`inventory_source=kernel_ast`，functions=24，classes=4，top_level_fields=9。

**当前状态**
- 待提交相关修改：`cli/src/auto.rs`、`cli/src/main.rs`、`crates/fcb_core/src/build_info.rs`、`crates/fcb_core/src/linker.rs`、`crates/fcb_core/src/state.rs`、`tests/e2e/test_e2e.sh`、`tool/fcb_kernel_manifest.dart`、`handoff.md`。
- 未跟踪且不要碰：`PLAN-now.md`、`vendor/depot_tools/`、`vendor/flutter/`、`vendor/sdk/`。

**后续建议**
1. 如需更严格审计，可继续补 CLI integration tests 覆盖 missing release cache/mismatched build_info 的 stderr 文案。
2. 后续可以把 `tool/fcb_kernel_manifest.dart` 的内嵌 reader 拆成独立文件，但当前单文件 410 行，未超过限制。
