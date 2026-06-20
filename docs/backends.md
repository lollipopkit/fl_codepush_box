# FCB Patch Backends

FCB 有两个 patch backend。它们的合规边界、生命周期、维护策略截然不同。

## bytecode —— 产品线（唯一上线路径）

- **平台**：Android + iOS。
- **下发内容**：签名的 FCB bytecode module(`FCBM` 容器),由 App 内置 Dart VM interpreter
  执行;未变函数继续跑原 AOT。
- **合规**：符合 Play / App Store 对"解释执行代码"的要求(不下发可执行机器码)。
- **状态**：**持续投入**。所有新语义/opcode/性能工作都在这条线上(见 `plans/phase_e_dart_vm.md`、
  `docs/architecture_decisions.md` ADR-A/C/#2/#4)。
- **默认**:iOS 始终用 bytecode;Android 在 bytecode 达生产可用后默认切到 bytecode。

## snapshot_replace —— enterprise/internal only（冻结）

- **平台**：仅 Android。
- **下发内容**：对 `libapp.so` 的 bsdiff+zstd 二进制差分,安装时重建 patched `.so`。
- **合规**：**不合规**。Play/App Store 都禁止从商店外下发/替换可执行机器码。
  仅可用于企业分发、内部分发、技术验证。
- **状态**：**冻结**。不再新增功能,只保持现有能力可用。
- **CLI 行为(合规闸)**：使用该 backend 时 `fcb release/patch` 会打印 enterprise/internal-only 警告,
  **并强制要求显式确认**——必须传 `--i-understand-store-policy`(或设 `FCB_ACK_STORE_POLICY=1`),
  否则命令直接报错退出,不产出补丁。这是为了把"是否上架"的判断与提醒义务显式落到使用者身上:

  ```bash
  # 未确认 -> 报错
  fcb patch android ...
  # 确认后 -> 允许(仅限企业/内部/侧载分发)
  fcb --i-understand-store-policy patch android ...
  ```

### 构建期排除(slim store 二进制)

snapshot_replace 在 `fcb_core` 是 **默认开启的 Cargo feature**,因此 dev/test/e2e 行为不变;
store 构建可关闭它,连带去掉 `bsdiff` / `zstd` 依赖:

```bash
# 默认(含 snapshot_replace,dev/test/e2e)
cargo build

# store 构建:排除 snapshot_replace 及其依赖
cargo build -p fcb_core --no-default-features
```

关闭后,`backend == "snapshot_replace"` 的安装路径返回明确错误
"snapshot_replace backend is not enabled in this build",不会半截执行。

### 已知剩余工作

- `cli` / `updater` 尚未完全 `--no-default-features` 化(它们仍以默认 feature 依赖 `fcb_core`),
  因此"完全不含 snapshot_replace 的端到端 store 构建"还需把 `cli` 的 snapshot 路径
  (`cli/src/main.rs` / `cli/src/auto.rs` 中 `diff::create_bsdiff_zstd` 等)也 cfg 化,
  并在 `.github/workflows/` 增加一个 `--no-default-features` 构建 job。
- Android 默认 backend 翻转到 bytecode(待 bytecode Android 生产可用)。

见 `docs/architecture_decisions.md` ADR-#3。
