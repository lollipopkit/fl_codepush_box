# FCB 架构决策记录（ADR 汇总）

状态：设计为主（2026-06-18）。本文件记录已确认的架构方向。
密钥轮换单独见 [`key_rotation_design.md`](key_rotation_design.md)。

实现状态图例：✅ 已实现 / 🟡 部分 / 📐 仅设计（待实现，见末尾 Agent Prompt）。

---

## ADR-A：bytecode interpreter 支持子集 —— 接受无限累积，投资"可持续性"

**决策**：不给解释器划死"支持子集";接受数年持续扩展 Dart 语义覆盖(closures、
collection-if/for、spread、constructor、泛型、最终 async/await…)。

**因此必须投资让"每条新特性的边际成本不随特性数增长"**（📐）：
1. **opcode 表驱动、三端同源**：opcode 元数据(operand 形状、栈效应、是否可 fallback)
   集中成一张声明式表;Rust(`fcb_core::bytecode`)、C++ interpreter、Dart lowering
   三端从同一张表生成/校验。防止"三处各自漂移"(已发生过一次,见 phase_e 顶部修复记录)。
2. **AOT↔interpreter 差分 conformance corpus**：一份持续增长的 `.dart` 片段库,每片段
   同时跑 AOT 真值与 interpreter 结果并断言相等;每加一个特性加片段。这是把"数年累积"
   变成可回归的唯一手段——否则第 N 个特性会悄悄破坏第 M 个。
3. **bytecode fuzzing**：interpreter 执行下发字节,是攻击面。对 `from_slice_envelope`
   之后的解释路径做 `cargo fuzz`,要求畸形/恶意 module 只触发 fail-safe(disable+fallback),
   不崩、不越界。

---

## ADR-C：class 布局变更 —— 用 hot-restart 语义支持 append-only

**决策**：支持 class 布局变更,参考 Flutter hot-reload/hot-restart。

**关键洞察**：FCB 激活是 **next_restart(hot-restart 语义)**,不是 live hot-reload。
重启后 isolate 重建、`main()` 重跑、堆全新 → **不存在"旧布局活对象"**,因此 hot-reload
最难的 instance morphing(`become`/实例迁移)**FCB 不需要做**。剩下唯一真问题：

> AOT snapshot 里未变函数是机器码,field offset / instance size 编译期写死;patch 改了
> class C 的布局后,这些 AOT 代码仍按旧 offset/size 访问 C。

**设计**（📐，本质同 Shorebird linker）：
- **append-only 字段**：patch 只能在 C 已有字段**之后追加**;offset 0..N-1 不动(AOT 旧
  代码继续有效),新字段在 N.. 且只被解释器访问。删字段/改类型/改 superclass 链 → reject。
- **分配尺寸**：C 的所有实例须按新 `instance_size` 分配 → 布局可变 class 的构造/分配必须
  走解释器或读取 `Class.instance_size` 的 stub,不能用 AOT inline 死的尺寸。
- **复用 VM class-reload 原语**：VM 热重载已有"注册新 Field / bump instance_size"机制;
  restart 下只需其中"重塑 class shape"那半,不需要 instance morphing 那半。
- **linker 出 class-shape diff**：比较 base/patch class_table,分类 append-only-safe / reject
  (现有 `RejectReason::ClassShapeChanged` 应细分出"append-only 可接受"分支)。

**共用杠杆**：见 ADR-#2 的"patch-friendly release 构建模式"(关闭可 patch class 的 inline
分配),layout-change 与 call_original 共用同一个构建模式开关。

---

## ADR-#2：call_original / FunctionId 对 AOT tree-shaking 的依赖 —— fail-closed gate + patch-friendly build

**问题**：`plan_bytecode_link`(`crates/fcb_core/src/linker.rs`)只比对 **Kernel inventory**
(source 级),`unchanged` 仅凭 `body_hash` 相等就假设其在 AOT 中可执行。但 Kernel inventory
≠ AOT 产物——AOT 会 tree-shake 未用函数、inline 小函数。解释体对一个"已被 AOT 消除"的函数
`call_original` 会在**运行期**才暴露没有目标。现在靠 counter_app 手标 `@pragma('vm:entry-point')`
保留 entry point,不可扩展。

**真正要 gate 的集合**：被解释体引用、但自身不在解释集里的函数(= call_original 目标集);
linker 现在对它的 AOT 存在性一无所知。

**设计**（📐）：
1. **release cache 增加 AOT-presence 真值**：release 构建后从 AOT 产物(gen_snapshot 输出/
   符号表)导出"实际保留 entry point 的函数集",写进 release cache(区别于现有 Kernel 派生的
   `function_map`)。
2. **linker 新增 `RejectReason::OriginalTargetNotInAot`**：从解释体算引用图 → call_original
   目标集 → 逐个校验 AOT-presence,缺失即在 **patch 阶段 reject**(而非运行期空指针)。
   隐式依赖 → 显式、fail-closed。
3. **patch-friendly release 构建模式(长期杠杆,与 ADR-C 共用)**：用一个 build flag 让 release
   对一方代码(`package:app/**`)保留 entry point、关闭 inline(gen_snapshot/AOT flags),取代
   手标 pragma。这是 Shorebird engine fork 做的事,把 reject 面收窄到可接受。

**原则**：短期 fail-closed(宁可 patch 阶段拒,不可运行期炸);长期 patch-friendly build 把
可 patch 面打开。

**已实现（🟢 2026-06-19,端到端用真实 gen_snapshot 验证）**：
- **生成(真实 AOT,环境够)**:`cli/src/aot_entry_points.rs` 用 vendored `gen_snapshot
  --snapshot_kind=app-aot-elf --print_instructions_sizes_to=...` 在 release 的 `app.dill` 上跑出存活
  函数表,归一化(`{l,c,n}` 去 `[Optimized]/[Stub]` 前缀、剥私有 `@\d+`、跳 tear-off/anonymous,
  组 `lib::member` / `lib::class:Class.member`)写入 release cache `aot_entry_points.json`。在 bytecode
  release(`collect_release_artifact`)best-effort 调用,缺 gen_snapshot/dill 则 warn 跳过。
- **校验保护面(Part 2 broaden)**:gate 从只查 `CallOriginal` 扩到 **`CallStatic`(0x50)+`CallOriginal`
  (0x52)**(`BytecodeModule::aot_referenced_targets`)——automatic patch 引用未改函数走 CallStatic,
  现在也被保护。`NewObject`/`MakeClosure` 暂不纳入(构造器/tear-off 常被 inline,会误拒,待
  patch-friendly build)。
- `fcb_core::linker`:`RejectReason::OriginalTargetNotInAot`;`cli::gate_call_original_aot_presence`
  有 `aot_entry_points.json` 则强制、缺失写 patch_report.reject 并报错,无则 warn 跳过(旧 cache 兼容)。
- **验证**:`aot_entry_points` parser 单测 + `aot_gate_covers_call_static_targets` + `#[ignore]`
  真实集成测试 `aot_real_extraction_includes_counter_app_call_targets`(实跑 vendored gen_snapshot,
  断言 counter_app 的 `widgetTreeLabel`/`statusLabel` 在存活集、虚构函数不在)。default/store 两配置
  clippy `-D warnings` + test + fmt 全绿。
- **剩余(非阻塞)**:`NewObject`/`MakeClosure` 纳入需先解决构造器/tear-off inline 误拒;长期
  patch-friendly release 构建模式(对一方代码关闭 inline / 保留 entry point)以收窄 reject 面。

---

## ADR-#3：snapshot_replace 降格为 enterprise-only / frozen / feature-gated

**决策**：snapshot_replace(下发 .so binary diff)在 store 合规上是死路(Play/App Store 都不能
下发可执行码),且与 bytecode 平级共享 state/install/CLI/diff/engine-hook,每次改动都收税。
**bytecode 是唯一产品线**;snapshot_replace 隔离为内部分发/技术验证。

**设计**（📐，实现见 Agent Prompt —— 注意会波及 e2e/CI 矩阵,非简单 drop-in）：
1. **Cargo feature gate**：把 bsdiff/chained-diff/snapshot install 路径放到 `fcb_core`/`updater`
   的 `snapshot_replace` feature 后;**默认 store 构建不含它**,从默认测试/audit 矩阵与 store
   二进制中消失。CI 增加 `--features snapshot_replace` 单独 job 验证。
   ⚠️ 当前默认 e2e(`tests/e2e/test_e2e.sh`)用 snapshot_replace 装 android,feature 化后
   需把该 leg 移到带 feature 的 job,否则默认 e2e 断裂——这是它"不是小改"的原因。
2. **显式 opt-in + 响亮标注**：`fcb.yaml` 用 `backend: snapshot_replace` 时要求确认字段
   (如 `distribution: internal_only`);CLI release/patch 运行期 warn「enterprise/internal only,
   非 Play/App Store 合规」。
3. **冻结**：`docs/backends.md` 写明 snapshot_replace = frozen feature set,不再投入新功能,
   只保持可用;bytecode = 产品线(Android+iOS,store 合规)。
4. **默认值**：Android 默认 backend 在 bytecode Android 达生产可用后翻转为 `bytecode`。

**已实现（✅ 2026-06-19，store 构建可完全排除）**：
- `fcb_core` 加 `snapshot_replace` 默认 feature;`bsdiff`/`zstd` 改 optional 依赖,仅该 feature 启用。
  `diff` 模块与 `state.rs` 的 snapshot 安装链(`validate_payload_contract` 的 snapshot_replace arm、
  install 分支、`snapshot_replace_chained_diff`、`find_diff_base`)全部 cfg-gate;关闭后该 backend
  返回明确错误 "snapshot_replace backend is not enabled in this build"。
- **feature 级联全链路**:`fcb_bytecode`/`updater`/`cli` 均 `fcb_core = { default-features = false }`
  + 自身 `snapshot_replace` forwarding feature(cli/updater `default=["snapshot_replace"]`)。`cli`
  的 snapshot 路径(`diff` 用法、`automatic_snapshot_payload`、`manual_patch_payload` 分支、
  `snapshot_replace_diff_base`、`patch_artifact_path`、`android_app_so_path` import、warn helper)
  全部 cfg-gate;关闭后对应 patch 路径走 "unsupported / not enabled" 干净错误。
- snapshot 专属测试(`state_tests.rs` 的 3 个 install/reject 测试 + helper)cfg-gate,使
  `cargo test --workspace --no-default-features` 编译通过。
- **CI 两配置覆盖**(`.github/workflows/rust.yml`):default(clippy `-D warnings` + test,跑 snapshot 路径)
  与 store(`--no-default-features` clippy + test + build)都验。
- `cargo build --workspace`(含)与 `cargo build --workspace --no-default-features`(排除)均编译、
  clippy `-D warnings`、test 全绿且无警告;默认 e2e 全绿。
- CLI 用 snapshot_replace 时打印 enterprise/internal-only 警告;新增 `docs/backends.md`。
- **剩余(非阻塞)**:Android 默认 backend 翻转到 bytecode(待 bytecode Android 生产可用)。

---

## ADR-#4：版本兼容 —— 区间接受 + additive，分清"可 fail-safe"与"parse-or-die"

**决策**：把"容器/结构版本"与"内容特性"分开治理。

- 能 **per-unit fail-safe** 的维度 → 向前兼容(opcode、字段)。
- 只能 **parse-or-die** 的维度 → 区间接受 + additive(容器版本、schema)。
- **ABI 边界** → 精确相等(Dart/engine/flutter revision)。

**已实现**（✅）：bytecode 容器版本改为区间接受。
`crates/fcb_core/src/bytecode.rs`：新增 `MIN_SUPPORTED_MODULE_VERSION`,
`validate_envelope` 由 `version != FORMAT_VERSION` 改为
`version < MIN_SUPPORTED_MODULE_VERSION || version > FORMAT_VERSION`。当前
`MIN_SUPPORTED_MODULE_VERSION=1`,`FORMAT_VERSION=2`;旧 v1 patch 仍可解析,`>MAX` 的新容器
优雅跳过(baseline 仍跑)而非全网逼迫发版。测试 `module_version_accepts_inclusive_supported_range`。

**兼容矩阵**：

| 维度 | 兼容策略 | 不匹配后果 | 状态 |
|------|---------|-----------|------|
| opcode | 向前兼容:未知 opcode 照常安装,VM fail-safe | 该函数回 AOT,patch 其余生效 | ✅(envelope 不查 opcode) |
| module 容器 version | 设备接受区间 `[MIN_SUPPORTED, MAX_KNOWN]`;additive 不升破坏版本 | `>MAX_KNOWN`→不装该 patch(降级);需发版才能用新容器 | ✅ |
| constant tag / 新字段 | additive + skip-unknown,不升 version | 未知 tag→envelope 层 fail-safe 拒该 patch | 🟡(reader 严格,未做 skip-unknown) |
| manifest schema_version | 同样区间接受;加字段用 serde `default` | 超区间→拒该 patch(降级) | 📐 |
| source_map | 可选;缺失只退化 stack trace | 不影响执行 | ✅ |
| signing key (`key_id`) | 多 key 选择 + 轮换 | 未知/吊销→拒 | 📐(见 key_rotation_design) |
| class 布局 | append-only 兼容;其余 reject | 非 append-only→linker patch 阶段 reject | 📐(见 ADR-C) |
| Dart/engine/flutter revision | 精确相等(ABI) | 不等→CLI patch 阶段 hard fail,不上传 | ✅(build_info) |

### ✅ 已修复（2026-06-18）：`debug_locals` 段不再原地破坏 v1 二进制布局

原问题是 `FORMAT_VERSION=1` 时新增 `debug_locals` 段,导致新旧 reader/producer 发生
trailing-bytes 或 misparse。当前已采用推荐 A：
- `FORMAT_VERSION` 升到 2,`MIN_SUPPORTED_MODULE_VERSION` 保持 1。
- Rust `BytecodeModule::read_binary` 仅在 `version >= 2` 读取 `debug_locals`;
  `to_binary_vec` 始终写当前 `FORMAT_VERSION` 并产出 v2 布局;v1 binary 继续只作为
  legacy reader 输入保持旧布局。
- Dart `tool/fcb_binary_module_writer.dart` 默认产出 v2;生产 writer 不再用 v1 布局承载
  新字段。
- VM binary loader 同步接受 v1/v2,仅 v2 消费 `debug_locals`;VM `ValidateModule` 接受
  1..=2。
- 回归测试覆盖 v1 legacy binary 可读、v2 `debug_locals` round-trip、producer 生成 v2,
  以及 VM standalone loader 读取 v1/v2。

剩余长期缺口仍是 **函数自描述(skip-unknown)**：给每个函数加 byte-length 前缀,reader
读完已知字段后 `skip` 到函数边界,未知尾段忽略。它能一次性根治后续 additive 字段,
但当前修复已避免 `debug_locals` 对 v1 的破坏性改动。

---

## 待实现工作

- ADR-#2 剩余:release 端从真实 AOT 生成 `aot_entry_points.json`(需引擎构建)+ patch-friendly
  build(linker/CLI 的 fail-closed gate 已实现 🟡)。
- ADR-#3 ✅ 完成(store 构建可完全排除 snapshot_replace;CI 两配置覆盖)。剩余仅 Android 默认翻转。
- ADR-A 的可持续性基建(opcode 表驱动、conformance corpus、fuzzing)、ADR-C(append-only 布局)。
- ADR-#4 剩余:binary constant/section 的 skip-unknown(需函数 byte-length 前缀;manifest schema
  已通过 serde 默认前向兼容,无需改)。

## Agent Prompt（#2 与 #3 的实现指令，可直接交给 code agent）

```text
在 fl_codepush_box 仓库实现两项架构改动。设计依据见 docs/architecture_decisions.md
(ADR-#2、ADR-#3)。每项独立,各自一个 PR/分支。改完必须 cargo test --workspace、
cd server && go test ./...、以及 tests/e2e/test_e2e.sh 全绿。

=== 任务 1（ADR-#2）：call_original 的 AOT-presence fail-closed gate ===
背景:crates/fcb_core/src/linker.rs 的 plan_bytecode_link 只比对 Kernel inventory,
unchanged 仅凭 body_hash 相等就假设函数在 AOT 可执行。但 AOT 会 tree-shake/inline,
解释体对"已被 AOT 消除"的函数 call_original 会在运行期才空指针。现在靠手标
@pragma('vm:entry-point') 兜底,不可扩展。

实现:
1. release cache 增加 AOT-presence 真值:release 构建后,从 AOT 产物(gen_snapshot
   输出/符号表;入口见 cli/src/auto.rs 的 release 流程与 release cache 写入)导出
   "实际保留独立 entry point 的 function_id 集合",写进 release cache(与现有 Kernel
   派生 function_map 区分,例如 aot_entry_points.json)。
2. linker:新增 RejectReason::OriginalTargetNotInAot。从 interpret 集的 bytecode/
   Kernel 体计算"被引用但不在 interpret 集里的函数"(= call_original 目标集),逐个
   对 AOT-presence 校验;缺失则在 patch 阶段 push 到 plan.reject(进 patch_report),
   绝不放行到运行期。
3. 测试:linker 单测覆盖"目标在 AOT→放行""目标不在 AOT→OriginalTargetNotInAot";
   e2e 加一例引用被 tree-shake 函数的 patch,断言 patch 阶段被拒。
约束:fail-closed 优先——宁可 patch 阶段拒,不可运行期炸。先不做 engine 构建模式
(patch-friendly build / 关闭 inline)那一步,只做"显式拒绝"这层;构建模式作为后续。

=== 任务 2（ADR-#3）：snapshot_replace 降格为 feature-gated / frozen ===
背景:snapshot_replace 下发 .so,store 不合规,且与 bytecode 平级共享
state/install/diff/CLI/engine-hook,每次改动收税。bytecode 是唯一产品线。

实现:
1. Cargo feature `snapshot_replace`,默认关闭。把 bsdiff/chained-diff/snapshot
   install 路径用 #[cfg(feature="snapshot_replace")] 包起来:涉及
   crates/fcb_core/src/diff.rs、state.rs 的 validate_payload_contract +
   snapshot_replace_chained_diff + find_diff_base、updater 安装分支、CLI release/patch
   的 snapshot 路径。默认构建里 backend=="snapshot_replace" 走清晰的
   "feature not enabled" 错误,而非半截执行。
2. e2e/CI 矩阵(关键,别漏):tests/e2e/test_e2e.sh 当前用 snapshot_replace 装 android。
   把该 leg 拆成需要 --features snapshot_replace 的独立路径/job;默认 e2e 改用 bytecode
   验证安装闭环。.github/workflows/ 增加一个带 --features snapshot_replace 的 job。
3. 显式 opt-in + 警告:fcb.yaml 用 snapshot_replace 时要求 distribution: internal_only
   确认字段;CLI release/patch 运行期 stderr 警告"enterprise/internal only,非 store 合规"。
4. 文档:新建 docs/backends.md —— bytecode=产品线(Android+iOS,合规);
   snapshot_replace=frozen,内部分发/技术验证,不再加新功能。
约束:不要删除 snapshot_replace 能力,只隔离+冻结;两种 feature 配置都要能编译+测试通过。

=== 任务 3（ADR-#4 缺口）：bytecode 二进制格式的前向兼容（已完成 2026-06-18） ===
背景:crates/fcb_core/src/bytecode.rs 的 read_binary 不按 version 区分布局,且
reader.finish() 拒绝尾随字节。最近原地给每个函数加了 debug_locals 段(writer+reader
都无条件读写),在 FORMAT_VERSION 仍为 1 时破坏了 v1 二进制的跨版本兼容(新 patch→旧设备
trailing-bytes 报错;旧 patch→新设备 misparse)。当前因单一真源+未发布而潜伏。

实现(推荐 A,复用已加的 MIN_SUPPORTED_MODULE_VERSION..=FORMAT_VERSION):
1. FORMAT_VERSION 升到 2;read_binary 改为 version 感知:仅当 version >= 2 才读
   debug_locals 段;MIN_SUPPORTED_MODULE_VERSION 保持 1,使无 debug_locals 的旧 v1
   模块仍可解析。to_binary_vec 始终按当前 FORMAT_VERSION 写。
2. 建立规则与测试:今后任何"给二进制加可选尾段"都必须 (a) bump FORMAT_VERSION 且
   read_binary version-gate,或 (b) 走函数级 byte-length 前缀的 skip-unknown 布局。
   加测试:v1 模块(无 debug_locals)被新 reader 接受;v2 模块(含 debug_locals)round-trip;
   version > FORMAT_VERSION 优雅拒(已有 range 检查)。
3. (可选,根治)给每个函数加 byte-length 前缀,reader 读完已知字段 skip 到边界,
   未知尾段忽略——一次性解决后续所有 additive。
完成证据:当前实现已让 v1 与 v2 模块都能被 Rust reader 和 VM binary loader 正确解析;
`cargo test --workspace`、`DART_BIN=vendor/flutter/bin/dart tests/e2e/test_kernel_compile_from_plan.sh`
与 `scripts/test_vendor_vm_runtime.sh` 已通过。
```
