# Phase X — 全平台热更新后端策略(iOS / Android / Windows / Linux / macOS)

**目标**:一份补丁、各平台一致、商店可合规;在允许的平台上再提供 native 加速后端。

## 架构决策(已定)—— 三 backend 模型

1. **bytecode 解释器 = 全平台统一默认**。它在共享 fork Dart VM 里
   (`vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime*`,各架构 dispatch stub 已就位),
   **写一次,5 平台行为一致**,且是 iOS / Google Play / Mac App Store 唯一合规路径(解释执行,无运行时机器码生成)。
2. **dart_vm = 桌面官方 VM 后端**(macOS / Linux / Windows)。桌面 release **保留官方 Dart VM 的
   JIT/kernel 能力(release 不裁切)**,patch 是更新后的 kernel `.dill`,由官方 VM 运行。
   **推荐机制:整程序 kernel 替换**——App 从 kernel blob 启动,下次启动替换 `app.dill`,VM JIT 跑新代码
   (概念=snapshot_replace 的 kernel 版);可承载任意改动、回滚退回内置 `.dill`。备选:复用 hot-reload
   (`reloadSources`)喂增量 kernel,patch 更小但受 hot-reload 限制 + 部分失败留不一致状态。
   **iOS 永不提供**(Apple 禁运行时机器码生成);Android 不走此 backend。
3. **snapshot_replace = 每平台 opt-in 的「native 快速 / 非商店」后端**(Android 侧载/企业 + Windows/Linux/macOS 自分发)。
   默认关闭,启用需经合规警示。**iOS 永不提供**(Apple 禁下发原生可执行代码)。

> 注:早期本 plan 曾决策"不做 JIT 路径"。现已修订:桌面以官方 VM(dart_vm backend)承载 JIT/kernel
> 执行,作为桌面自分发场景的第三 backend。bytecode 仍是全平台合规默认与跨平台一致性真源;dart_vm
> 仅限桌面、不参与跨平台一致性门禁。

### 平台能力矩阵

| 平台 | bytecode(默认) | dart_vm(官方 VM,opt-in) | snapshot_replace(opt-in) |
|---|---|---|---|
| iOS | ✅ 唯一 / 合规 | ❌ Apple 禁 | ❌ Apple 禁 |
| Android | ✅ Play 例外允许 | ✗ 不做(走 bytecode/snapshot_replace) | ⚠️ native;非 Play(侧载/企业)+ 警示 |
| Windows | ✅ | ✅ 自分发(kernel/JIT,release 不裁切) | ✅ 自分发 |
| Linux | ✅ | ✅ 自分发(kernel/JIT,release 不裁切) | ✅ 自分发 |
| macOS | ✅(含 MAS) | ✅ 自分发(非 MAS) | ✅ 自分发(非 MAS) |

## 现状(已读代码确认)

- engine hook 已存在:Android(`shell/platform/android/fcb/`)、iOS(`shell/platform/darwin/ios/fcb/`)。
- 桌面三平台:**无 hook**(greenfield)。但执行引擎(解释器)在共享 VM 里,桌面**不需要新执行代码**。
- updater(`updater/`,Rust C ABI)、Dart FFI(`packages/fcb_code_push/lib/fcb_code_push.dart`)目前覆盖 Android/iOS。
- snapshot_replace 后端在 `crates/fcb_core`(bsdiff+zstd)已实现,vendor fork 仅 bytecode 路径接线;snapshot_replace 在 vendor 引擎未接 native 加载。

## 子阶段

### X1 — 桌面解释器接通(macOS / Windows / Linux)（每平台 ~1 周）

**进度(本会话,代码已写;桌面引擎构建未跑)**
- ✅ 共享桌面 bridge:`shell/platform/embedder/fcb/fcb_embedder_vm_patch_bridge.{h,cc}`
  ——一份覆盖 mac/win/linux(走 embedder 的 `flutter::Settings`),复用 Android 的平台中立 C ABI。
- ✅ `embedder.cc` 接线:`FlutterEngineInitialize` 里 `#if defined(FCB_ENABLE_CODE_PUSH)` 调 bridge,链在
  embedder 自己的 `root_isolate_create_callback` 之后。
- ✅ `embedder/BUILD.gn`:`declare_args fcb_enable_code_push/fcb_updater_staticlib`;开启时加 bridge +
  `../android/fcb/fcb_engine_hook.cc` 源 + `FCB_ENABLE_CODE_PUSH` define + 链 updater staticlib。
- ✅ Dart FFI:`fcb_code_push` 桌面已有 `.dylib/.so/.dll` 解析;本会话对齐桌面 cache dir 为
  `(FCB_CACHE_DIR ?? <systemTemp>/fcb-cache)/fcb`,与 bridge 的 `ResolveCacheDir` 一致。
- ✅ updater 桌面构建:`crate-type` 已含 cdylib+staticlib;`scripts/build_desktop_updater.sh` 新增并验证
  (host macOS 产出 libfcb_updater.dylib + .a;`cargo test -p fcb_core bytecode` 39 绿)。
- ⏳ 剩余(需桌面构建环境):用 gn 参数构建 FCB 桌面引擎(mac/win/linux 各一次)、
  `flutter create --platforms=macos,linux,windows examples/counter_app` 生成 runner、放置 dylib + 设
  `FCB_CACHE_DIR`、跑 baseline→patch→restart→rollback。FFI 路径不需要插件桌面 native 代码
  (直接 `DynamicLibrary.open`,桌面不走 MethodChannel)。


**任务（每平台一份,照抄 Android/iOS 的 `fcb/`）**
- engine 启动 hook：`shell/platform/{darwin/macos,windows,linux}/fcb/fcb_engine_hook.{cc,h}`，
  在 isolate 启动时调 `LoadPatchRuntimeForIsolateGroup` / `fcb_get_launch_patch`，mark launch success 钩子。
- updater 桌面构建：`libfcb_updater`(macos dylib / windows dll / linux so);CI 产物。
- Dart FFI 桌面分支：`fcb_code_push.dart` 的 `platformPaths` / 库名解析加 macos/windows/linux。
- example app 桌面 target 跑通 baseline→patch→restart→rollback。

**关键文件**：`shell/platform/{macos,windows,linux}/fcb/*`、`updater/`、`packages/fcb_code_push/lib/fcb_code_push.dart`、
`examples/counter_app/{macos,windows,linux}/`。

**验收**：每个桌面平台 baseline 启动 + bytecode patch 生效 + crash 回滚,本地跑通。

### X2 — snapshot_replace opt-in 后端 + 合规闸（Android 优先,1–2 周）

**任务**
- vendor 引擎接 snapshot_replace native 加载（Android 先做：启动时若有 LKG snapshot 则加载替换 AOT artifact）。
- CLI/server：backend 选择显式化；`fcb release/patch --backend snapshot_replace` 需要 `--i-understand-store-policy`
  之类显式确认 flag，否则拒绝；patch_manifest 标记 backend 与合规等级。
- 文档化警示义务：README / CLI 输出明确 Play/MAS 风险与适用场景（侧载/企业/自分发）。
- 桌面 snapshot_replace（Win/Linux/macOS 自分发）后置在 X1 之后。

**关键文件**：vendor 引擎 fcb hook（snapshot 加载分支）、`cli/src/main.rs`、`server/`、`crates/fcb_core`（已具备 diff）。

**验收**：Android snapshot_replace opt-in 路径端到端（release→diff→下发→重启加载新 AOT→回滚）；无显式确认 flag 时拒绝。

### X3 — 跨平台一致性与 CI 矩阵（1–2 周）

**任务**
- 同一补丁源在 5 平台解释器后端产出**同一 bytecode module**，跨平台执行结果一致性测试。
- CI：android_emulator / ios_simulator 已有；新增 macos / linux / windows runner 跑解释器 e2e。
- 后端选择策略文档：默认 bytecode；snapshot_replace 仅在 opt-in + 平台允许时。

**验收**：5 平台 CI 各跑通解释器 e2e；snapshot_replace 后端的 Android CI 单独门控。

### X4 — dart_vm 桌面官方 VM 后端(macOS / Linux / Windows,opt-in,greenfield)

**任务**
- 桌面 release 以 **JIT-runtime 引擎**出包(保留官方 VM kernel/JIT;release 不裁切),而非默认 AOT。
- 启动加载:**推荐整程序 kernel 替换**——若有 LKG patch `.dill` 则下次启动以其替换内置 `app.dill`,
  由官方 VM JIT 运行;坏 `.dill` → 退回内置 `.dill`(回滚语义与其它 backend 一致)。
  备选:复用 hot-reload `reloadSources` 在首帧前喂增量 kernel(受 hot-reload 限制,后置评估)。
- CLI/server:`fcb release/patch --backend dart_vm` 仅桌面合法;manifest 标记 backend;patch 产物为
  kernel `.dill`(复用既有 Kernel 流水线产物,不经 bytecode 编译)。
- 客户端:`fcb_code_push` 桌面分支识别 dart_vm backend,管理 `.dill` 下载/校验/原子替换/回滚。

**关键文件**:vendor 桌面 engine 构建配置(JIT runtime mode)、桌面 `fcb/` 启动 hook(kernel 加载分支)、
`cli/src/main.rs`、`server/`、`packages/fcb_code_push/lib/fcb_code_push.dart`。

**验收**:macOS/Linux/Windows 各跑通 baseline(JIT 引擎)→ dart_vm patch(替换 `.dill`)→ restart 生效
→ 坏 patch 回滚;与同源 bytecode patch 的可观测行为一致。

## 依赖与排期

| 阶段 | 内容 | 估时 | 依赖 |
|---|---|---|---|
| X1 | 桌面解释器 hook ×3 | 各 ~1 周 | Phase E P0(VM 编译验收) |
| X2 | snapshot_replace opt-in + 合规闸 | 1–2 周 | 无强依赖,可并行 |
| X3 | 一致性 + CI 矩阵 | 1–2 周 | X1 |
| X4 | dart_vm 桌面官方 VM 后端 | 2–3 周 | 桌面 JIT 引擎出包(可与 X1 并行) |

**关键前置**：`phase_e_frontend_and_generators.md` 的 **P0(VM 编译验收)** 必须先过——解释器没编译验收前,谈不上多平台铺开。
X1 是"全平台"的主线(execution engine 免费,只接胶水);X2 是 opt-in 加速的旁路。

## 风险

| 风险 | 缓解 |
|---|---|
| 桌面各平台 engine 集成细节差异 | 严格照抄 Android/iOS `fcb/` 模式;每平台独立 X1 子任务,先 macOS（与 iOS 同 darwin 工具链）再 Win/Linux |
| snapshot_replace 误用上架被拒 | 强制 `--i-understand-store-policy` 确认 + manifest 标记 + 文档警示;默认关闭 |
| 补丁跨平台不一致 | 后端唯一真源 = bytecode;X3 跨平台一致性测试为门禁 |

## 不在本 plan
- Android/iOS 上的 JIT(iOS 禁;Android 不做,诉求由 snapshot_replace 覆盖)。dart_vm 仅限桌面。
- Phase E 的 VM/前端工作(见 `phase_e_frontend_and_generators.md`)。
- 根工作树无关改动不纳入提交。
