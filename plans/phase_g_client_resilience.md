# Phase G — 客户端 crash 自动回滚 + 网络健壮性

**所属阶段**：production-ready 必做
**预计工作量**：1–2 人月
**前置依赖**：无（与 E/F/H 完全独立）
**并行性**：可与 E、F 并行

## 目标

让 updater 在生产环境中具备：

1. **Crash-loop 防护**：连续 N 次启动未确认成功 → 自动判 bad，回到 last_known_good。
2. **LKG 持久化**：state 记录上次 mark_success 的 patch_number，回滚优先回它而不是 baseline。
3. **网络层健壮**：断点续传、指数退避、并发单飞、取消传播。
4. **可观测**：客户端把 crash_rollback / launch_success / launch_failure 上报 server `/v1/events`（消费方 = Phase F 的事件持久化）。
5. **Dart 端 API**：业务可读取 `lastKnownGoodPatchNumber()` 与 `crashRollbackHistory()`。

## 现状

| 文件 | 行数 | 当前状态 |
|------|------|---------|
| `crates/fcb_core/src/state.rs` | 1126 | Atomic state.json 读写；single-attempt 防护（pending_success 状态再启动一次即标 bad） |
| `updater/src/lib.rs` | 802 | C ABI 完整；网络层简单 blocking + 全局 `Mutex<Runtime>` |
| `crates/fcb_core/src/server_api.rs` | 234 | HTTP client 用 `ureq`，无重试无超时退避 |
| `packages/fcb_code_push/lib/fcb_code_push.dart` | 529 | API 表面齐全；缺 LKG / history 观测点 |

关键缺陷：
- state.rs 没有 `boot_attempts` 计数（只能检测"上次进程没活到 mark_success"，不能区分"启动 1 次失败"和"启动 3 次失败"）。
- 没有 `last_known_good_patch_number`，回滚只能回 baseline，等于丢掉所有已成功的 patch。
- 多 patch 安装目录无保护，可能清理掉 LKG 对应的 patch payload。
- updater 全局 `Mutex<Runtime>`，但下载没有取消、并发 check 没有单飞。
- 没有上报 crash_rollback 事件到 server。

## 子阶段

### G1 — state.json schema v2 + LKG 持久化（2 周）

**任务**

- `state.rs` 的 `State` struct 加字段：
  - `boot_attempts: u32`（默认 0）
  - `last_known_good_patch_number: Option<u32>`（默认 None）
- schema 版本从 v1 升到 v2，加 migration：v1 读到时把 `current_patch_number > 0` 的当成 LKG 写入。
- `launch_patch()`（state.rs:153）改造：
  1. 选 patch 时优先级：`pending` → `current` → `last_known_good` → baseline。
  2. 选中后 `boot_attempts += 1`，写盘。
  3. `pending_success` 状态发现 + `boot_attempts >= 3` → 加 bad、清 last_launch、若 current == bad patch 则 current = lkg、再选下一轮。
- `mark_success()`（state.rs:229）改造：
  - 设 `current_patch_number = last.patch_number`
  - 设 `last_known_good_patch_number = last.patch_number`
  - 清 `boot_attempts = 0`
- `prune_installed()`：清理时跳过 `last_known_good_patch_number` 对应的目录。

**关键文件**

- `crates/fcb_core/src/state.rs:153, 229, 240`
- 新增 schema v1 → v2 migration 函数
- `crates/fcb_core/src/state.rs` 测试块（已有，扩展覆盖 LKG 路径）

**验收**

- 单元测试覆盖：
  - 启动 3 次 pending_success → 第 3 次 launch_patch 返回 None 且 bad_patches 含该 patch
  - mark_success 后 LKG 更新
  - 升级 v1 state.json 到 v2 时 current_patch_number 被搬到 LKG
- e2e：故意做一个首帧前 abort 的 patch，模拟 3 次启动后 state 显示 patch 在 bad_patches、current_patch_number 回到 LKG。

---

### G2 — 网络层重试 + 单飞 + 断点续传（3 周）

**任务**

- 替换 `ureq` 为 `reqwest` blocking + `tokio` runtime（或保留 `ureq` + 手写重试，看 binary size 取舍；arm64 真机包大小敏感时优先 ureq + 手写）。
- 实现 `RetryPolicy`：
  - 指数退避：50ms / 200ms / 800ms / 3200ms（4 次重试）
  - jitter：±25%
  - 仅对 5xx 与连接错误重试，4xx 立即失败
- 实现单飞锁：`OnceCell<Mutex<Option<JoinHandle>>>` 包 `check_for_update`，并发 5 次只触发 1 次 HTTP。
- 下载支持断点续传：
  - 每次写 `patches/<n>/payload.bin.part`，记录已写字节数到 `patches/<n>/.progress`。
  - 重连后 `Range: bytes=<offset>-` 续传。
  - 校验完整 payload sha256 后再 rename 为 `payload.bin`。
- 实现 `fcb_cancel_pending_operations()` C ABI，让 Dart 端可取消下载（用 `Arc<AtomicBool>` + 检查点轮询）。

**关键文件**

- `crates/fcb_core/src/server_api.rs:1-234`
- `updater/src/lib.rs:281`（`fcb_download_and_install_blocking`）
- `updater/src/lib.rs` 新增 `fcb_cancel_pending_operations`

**验收**

- 单元测试 mock HTTP server：
  - 第 1/2 次返回 503，第 3 次成功 → updater 自动重试通过
  - 连续 5 次并发 check → 后端只收到 1 次请求
- 集成测试：模拟下载中途 kill 网络，恢复后续传完成，sha256 校验通过。

---

### G3 — Crash rollback 上报（1 周）

**任务**

- `state.rs` 在 `launch_patch` 触发自动回滚分支时收集 `(patch_number, attempts, last_known_good)`。
- updater 新增 C ABI：

```c
void fcb_drain_rollback_events(void (*cb)(const char* json));
```

- 主初始化路径调 drain，把事件 POST 到 `/v1/events`（type = `crash_rollback`）。
- 网络失败时事件保留在本地 `events.log`，下次启动重试上报，最多保留 50 条。
- 事件 payload：`{ patch_number, boot_attempts, last_known_good_patch_number, last_error?, fcb_sdk_version, platform }`。

**关键文件**

- `crates/fcb_core/src/state.rs`（rollback 时往 `events.log` 追加）
- `crates/fcb_core/src/server_api.rs`（事件 POST 接口）
- `updater/src/lib.rs`（drain + 上报）

**验收**

- 触发 G1 场景的回滚 → server `patch_events` 表收到 `crash_rollback` 行 + 完整 payload。
- 离线触发回滚 → 下次有网时延迟上报。

---

### G4 — Dart 端 API 与业务观测（1 周）

**任务**

- `packages/fcb_code_push/lib/fcb_code_push.dart` 新增：

```dart
Future<int?> lastKnownGoodPatchNumber();
Future<List<CrashRollbackEvent>> crashRollbackHistory({int limit = 10});
Future<InterpreterStats?> interpreterStats();  // 来自 Phase E5
```

- `CrashRollbackEvent` 包含 patch_number、boot_attempts、timestamp、is_reported。
- FFI 侧 `updater/src/lib.rs` 暴露对应 C 函数。
- counter_app 增加 debug overlay：显示 current / pending / LKG patch，最近 5 次 crash event。

**关键文件**

- `packages/fcb_code_push/lib/fcb_code_push.dart`
- `updater/src/lib.rs`（暴露 stats）
- `examples/counter_app/lib/main.dart`（debug overlay）

**验收**

- counter_app debug overlay 正确显示状态。
- API 测试覆盖 LKG / history。

## 风险与缓解

| 风险 | 严重性 | 缓解 |
|------|--------|------|
| reqwest 增加 binary size 显著 | 中 | 先 benchmark `ureq` + 手写重试 vs `reqwest`，arm64 包多 > 500KB 就回 ureq |
| state.json migration 在 corrupted 文件上崩 | 高 | 任何 schema 检测失败 → 备份当前文件、重置到空 state，记录事件 |
| 下载断点续传的 .progress 文件与实际 partial 大小不一致 | 中 | 续传前先 stat 实际大小，取较小值 |
| boot_attempts 阈值过低误杀（用户手动 kill） | 中 | 阈值默认 3，但要求 `pending_success` 状态——用户手动 kill 时进程一般跑过首帧已 mark_success，不算 |

## 退出标准

- counter_app 故意 crash patch → 3 次启动后自动回 LKG，App 可用。
- 网络抖动场景下下载完整成功率 > 99%（mock 测试）。
- crash_rollback 事件在 server 端可见，含完整 payload。
- Dart API 暴露 LKG + history，业务侧可读。
