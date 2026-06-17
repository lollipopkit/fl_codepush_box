# Phase F — Server 多租户 + 生产化

**所属阶段**：production-ready 必做
**预计工作量**：2–3 人月
**前置依赖**：无（与 E/G/H 完全独立）
**并行性**：可与 E、G 并行

## 目标

把当前单租户 SQLite server 升级为：

1. Schema 与路由原生支持多 org，self-hosted 部署默认创建 `default` org 收容现有数据。
2. 对象存储抽象，本地 fs / S3 driver 通过配置切换。
3. Rollout 改 sticky cohort 单向递增，避免回收已分发用户。
4. `patch_events` 持久化客户端 install / launch_success / launch_failure / crash_rollback，admin 页面加可视化。
5. 备份/还原脚本与运维文档。

## 现状

`server/` 当前 1700 行 Go：

| 文件 | 行数 | 角色 |
|------|------|------|
| `main.go` | 128 | 路由组装 + 启动 |
| `handlers.go` | 393 | 24 个 handler，含 admin / v1 两套 |
| `store.go` | 697 | DB + 文件 IO；GORM SQLite |
| `auth.go` | 183 | session + bearer token |
| `util.go` | 140 | rollout/url 工具 |
| `types.go` | 142 | DTO |
| `webui.go` + `webui/` | 31 + 静态 | 嵌入 admin UI |

关键短板：
- `apps` 表无 org_id（store.go:75, 89, 224）
- `payloads/` 直接落本地磁盘（store.go 中 `os.WriteFile`），无抽象
- `util.go:48` rollout 用 `(app + release + patch_num + client) % 100`，缩 rollout 会回收用户
- `patch_events` 表已有定义（store.go:108）但 `event` handler（handlers.go:206）只 log 不持久化
- admin UI 不支持 org 切换

## 子阶段

### F1 — Schema 迁移 + org 路由（3 周）

**任务**

- DB migration 新增 `organizations` / `org_memberships`，apps 加 `org_id` 外键。已存在 apps 自动写入 `default` org。GORM auto-migrate + 手动 SQL 兜底。
- `cli_tokens` 已存在（store.go:117），加 `org_id` 列。token 创建/验证流程绑 org。
- 现存路由分两层：
  - `/api/admin/orgs` / `/api/admin/orgs/:org/members` / `/api/admin/orgs/:org/cli-tokens` — session 鉴权 + 角色检查
  - `/v1/apps`、`/v1/releases`、`/v1/patches/*` — bearer token，自动从 token 拿到 org 上下文
- 资源查询全部加 `WHERE org_id = ?` 过滤。
- admin UI 顶部加 org switcher dropdown，选择当前 org。

**关键文件**

- `server/store.go:60–230`（migration block）
- `server/auth.go`（token 验证返回 `Context{user, org}`）
- `server/handlers.go`（所有查询加 org 过滤）
- `server/webui/`（前端 org switcher）

**验收**

- 创建 2 个 org `acme` 与 `widgets`，各自创建 app，互相不可见。
- 已存在数据库升级后所有 app 在 `default` org 下，CLI 仍能照常工作。
- 单元测试：跨 org 资源访问返回 404 而不是 403（避免泄漏存在性）。

---

### F2 — 对象存储抽象（2 周）

**任务**

- 新建 `server/storage/` 包，定义 interface：

```go
type Storage interface {
    Put(ctx context.Context, key string, body io.Reader, size int64) error
    Get(ctx context.Context, key string) (io.ReadCloser, int64, error)
    SignedURL(ctx context.Context, key string, ttl time.Duration) (string, error)
    Delete(ctx context.Context, key string) error
}
```

- 实现 `LocalFSStorage`（迁移当前 `store.go` 里的 `os.WriteFile` / `os.Open` 逻辑），实现 `S3Storage`（用 `aws-sdk-go-v2`，最小集：PutObject、GetObject、PresignGetObject、DeleteObject）。
- 配置：`FCB_STORAGE_DRIVER=fs|s3`，s3 driver 读 `FCB_S3_BUCKET / FCB_S3_REGION / FCB_S3_ENDPOINT`（兼容 MinIO/R2）。
- patch payload 下载 URL：fs driver 走 `/v1/patches/payload?key=...` 内部代理；s3 driver 返回 presigned URL。
- `Storage` 注入 `Server` struct。

**关键文件**

- 新建 `server/storage/{storage.go, fs.go, s3.go}`
- `server/store.go`（删除 `payloadPath` / `os.WriteFile`，改调 `Storage`）
- `server/handlers.go:171`（`patchPayload` handler 改为代理或 redirect）
- `server/util.go:84`（`payloadURL` 适配两种 driver）

**验收**

- 默认 fs driver 与现状行为一致，e2e 通过。
- 启动时配 minio + s3 driver，能 upload/download patch payload。

---

### F3 — Rollout cohort 改造（1 周）

**任务**

- 引入 `(app_id, release_version, client_id) → cohort` 映射。新算法：

```go
func cohort(appID, releaseVersion, clientID string) int {
    h := fnv.New32a()
    h.Write([]byte(appID + "|" + releaseVersion + "|" + clientID))
    return int(h.Sum32() % 10000)  // 0..9999
}

func eligible(appID, releaseVersion, clientID string, rolloutPercent int) bool {
    return cohort(appID, releaseVersion, clientID) < rolloutPercent*100
}
```

- `util.go:48` 的旧函数完全替换，没有 patch_number 参与 → 同一 release 下不同 patch 的 rollout 都依同一 cohort。
- 文档化语义：「rollout 只能增不能减；缩 rollout 不收回已分发用户，仅停止新分发」。
- 单元测试：
  - sticky：同 (app, release, client) 多次调用 cohort 结果稳定。
  - 单向递增：rollout 10% 的客户端集合 ⊂ rollout 30% 的集合。
  - 不同 release_version → cohort 不同。

**关键文件**

- `server/util.go:48-58`
- `server/main_test.go:17-30`（更新现有 rollout 测试）

**验收**

- 单元测试覆盖 sticky + 单调递增。
- 手动测：rollout 10% 时一批客户端命中，提到 30% 后原 10% 全部仍命中（不掉用户）。

---

### F4 — 事件持久化 + admin 仪表盘（3 周）

**任务**

- `event` handler（handlers.go:206）改为写入 `patch_events` 表。事件类型：
  - `install`：客户端首次落盘 patch
  - `launch_success`：mark_success 调用后
  - `launch_failure`：mark_failure 显式上报
  - `crash_rollback`：客户端 boot_attempts 超阈值自动回滚（Phase G 触发）
- payload 字段（JSONB）存：app version、device model、错误消息、bytecode_offset、interpreter_ratio 等性能指标。
- `client_id_hash` 用 sha256(client_id + app_id) 避免暴露原 client_id。
- 新增 admin API：
  - `GET /api/admin/orgs/:org/apps/:id/patches/:patch_id/stats` — 返回总下发、安装、成功、失败计数 + 7 天分布
- admin UI patch 详情页加：
  - 柱状图：每日 install / success / failure
  - 表格：top 10 失败原因（按 event.payload.error_message 聚合）
- 索引：`(app_id, patch_number, event_type, created_at)`。
- 清理任务：每天删除 90 天前的 event（可配置）。

**关键文件**

- `server/handlers.go:206`（event handler）
- `server/store.go`（patch_events 写入 + 查询）
- `server/webui/`（patch 详情页 + 图表，复用 admin UI 现有 framework）

**验收**

- 端到端：客户端跑一次 install/success/failure 流程，admin UI 三种事件计数正确。
- 跨 org 隔离：org A 的事件查询不返回 org B 的数据。

---

### F5 — 备份 + 运维文档（1 周）

**任务**

- `scripts/server_backup.sh`：
  - SQLite 用 `.backup` online backup，避免锁库。
  - fs driver：rsync `payloads/` 到目标目录。
  - s3 driver：留 hook（用户自行配置 bucket cross-region replication，不在脚本内做）。
- `scripts/server_restore.sh`：反向恢复。
- `docs/operations.md`：
  - 部署步骤（单二进制 + systemd unit）
  - 配置项清单（`FCB_*` 环境变量）
  - 升级流程（migration 自动执行 + 手动 rollback 步骤）
  - 监控：暴露 `/healthz` + Prometheus `/metrics`（patch check QPS、event 写入 rate、storage error rate）
- 简单 Prometheus exporter：用 `github.com/prometheus/client_golang` 注册 3–5 个核心指标。

**关键文件**

- 新建 `scripts/server_backup.sh` / `server_restore.sh`
- 新建 `docs/operations.md`
- `server/main.go`（注册 `/healthz` + `/metrics`）

**验收**

- 一次完整 backup → 销毁 SQLite → restore，数据无丢失。
- Prometheus scrape 能拿到指标。

## 风险与缓解

| 风险 | 严重性 | 缓解 |
|------|--------|------|
| Migration 在已部署 self-host 上失败 | 高 | F1 实施前先在 e2e fixture 准备一个 v0 schema dump，验证自动迁移路径 |
| s3 driver 在小型 self-host 上无意义增加复杂度 | 中 | 默认 fs driver，s3 仅在配置时启用，文档明确"s3 是企业可选" |
| event 写入打爆 SQLite | 中 | 批量写（每 100 条 flush）+ WAL mode + 索引；监控 write rate |
| 多 org 暴露给单用户场景过度复杂 | 中 | UI 在 org 数量 == 1 时隐藏 org switcher |

## 退出标准

- 2+ org 可创建，资源隔离正确。
- fs/s3 双 driver 通过 e2e。
- cohort rollout 单调递增可验证。
- admin UI 显示每 patch 的安装/成功/失败统计。
- backup/restore 脚本经过一次完整 drill。
