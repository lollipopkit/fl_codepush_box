# FCB Server Operations

## 部署

推荐 self-hosted 单二进制 + SQLite：

```bash
FCB_SERVER_DB=/var/lib/fcb/fcb.sqlite \
FCB_SERVER_ADDR=127.0.0.1:8080 \
./fcb_server
```

对象默认存储在 SQLite 同目录的 `objects/`。可用 `FCB_STORAGE_DRIVER` 切换 driver：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `FCB_STORAGE_DRIVER` | `fs` | `fs` 或 `s3` |
| `FCB_S3_BUCKET` | 无 | S3 driver 必填 |
| `FCB_S3_REGION` | `us-east-1` | S3 region |
| `FCB_S3_ENDPOINT` | 无 | 可选；设置后启用 path-style，兼容 MinIO/R2 |
| `FCB_S3_ACCESS_KEY_ID` | SDK 默认链 | 可选静态凭据 |
| `FCB_S3_SECRET_ACCESS_KEY` | SDK 默认链 | 可选静态凭据，需与 access key 同时设置 |
| `FCB_EVENT_RETENTION_DAYS` | `90` | `patch_events` 保留天数；server 启动后立即清理一次，之后每日清理 |

S3 示例：

```bash
FCB_SERVER_DB=/var/lib/fcb/fcb.sqlite \
FCB_STORAGE_DRIVER=s3 \
FCB_S3_BUCKET=fcb-payloads \
FCB_S3_REGION=us-east-1 \
FCB_S3_ENDPOINT=http://127.0.0.1:9000 \
FCB_S3_ACCESS_KEY_ID=minioadmin \
FCB_S3_SECRET_ACCESS_KEY=minioadmin \
./fcb_server
```

本地 MinIO 端到端验收：

```bash
scripts/test_s3_storage.sh
```

该脚本会启动临时 MinIO container 和临时 FCB server，执行 app/release/patch 创建、promote、patch check、presigned payload 下载与 hash 校验。
成功后会写入 `target/fcb/s3-storage/summary.txt`，供 `make audit-plan-completion` 复用。

## 健康检查与监控

- `GET /healthz`：SQLite ping 成功返回 `{"status":"ok"}`。
- `GET /metrics`：Prometheus text format，目前包含：
  - `fcb_patch_check_requests_total`
  - `fcb_patch_event_writes_total`
  - `fcb_storage_errors_total`

Prometheus scrape 示例：

```yaml
scrape_configs:
  - job_name: fcb-server
    static_configs:
      - targets: ['127.0.0.1:8080']
```

## 多租户

首次启动会创建 `default` org，旧数据库里的 apps 与 CLI tokens 会自动回填到该 org，旧 `/api/admin/apps` 和 `/api/admin/tokens` 路由保持兼容。

新增 org-scoped admin 路由：

- `GET /api/admin/orgs`
- `POST /api/admin/orgs`
- `GET /api/admin/orgs/:org/members`
- `POST /api/admin/orgs/:org/members`
- `GET /api/admin/orgs/:org/apps`
- `POST /api/admin/orgs/:org/apps`
- `POST /api/admin/orgs/:org/cli-tokens`
- `GET /api/admin/orgs/:org/cli-tokens`

Org-scoped admin 路由会校验 membership：`member` 可读，`owner` 可创建/更新/删除 apps、members 与 CLI tokens。创建 org 的 session 用户会自动成为该 org owner。系统会阻止移除或降级最后一个 owner。

CLI bearer token 会绑定到一个 org；`/v1/apps`、`/v1/releases`、`/v1/patches` 的资源查询按 token org 隔离。

## Rollout 语义

Patch rollout 使用 sticky cohort：server 根据 `(app_id, release_version, client_id)` 计算 0..9999 的 cohort，同一个 release 下不同 patch 共享同一 cohort，不把 `patch_number` 纳入 hash。这样把 rollout 从 10% 提高到 30% 时，原先 10% 命中的客户端仍然命中，新增客户端只来自 10%..30% 区间。

将 active rollout 调到 `0%` 会停止向尚未安装该 patch 的客户端下发。已经安装并上报了较高 `current_patch_number` 的客户端不会被 server “召回”；如需回退已安装客户端，应使用 rollback patch 或发布新的修复 patch，而不是依赖缩小 rollout。

## 备份

```bash
scripts/server_backup.sh /var/lib/fcb/fcb.sqlite /var/backups/fcb /var/lib/fcb/objects
```

脚本优先使用 `sqlite3 .backup` 在线备份；若本机没有 `sqlite3`，会退化为文件 copy。fs object store 会通过 `rsync -a` 同步到备份目录。

本地备份/还原 drill：

```bash
scripts/test_backup_restore.sh
```

该脚本会创建临时 SQLite 与 object store，执行 backup、删除源数据、restore，并校验数据库 row 与 payload object 内容。

## 还原

先停止 `fcb_server`，再执行：

```bash
scripts/server_restore.sh /var/backups/fcb/fcb-backup-YYYYmmddTHHMMSSZ /var/lib/fcb/fcb.sqlite /var/lib/fcb/objects
```

还原后启动服务，并验证：

```bash
curl -f http://127.0.0.1:8080/healthz
curl -f http://127.0.0.1:8080/metrics
```

## 升级与回滚

- 服务启动时自动运行 SQLite migrations。
- 升级前先运行一次 backup。
- 如迁移后发现问题，停止服务，使用最近备份执行 restore，再回退二进制。

## 当前状态与限制

- Admin UI 已有 org switcher、成员添加、角色修改与移除。
- Patch stats 已显示总量、7 天 install/success/failure 柱状图、top failures。
- S3/MinIO 端到端 drill 已有脚本覆盖。
- `patch_events` 会按 `FCB_EVENT_RETENTION_DAYS` 自动清理。
- `make test-admin-runtime` 会启动真实 Go server、使用 built WebUI、创建两个 org 下的同名 app/patch，并验证 stats 与 payload URL 都保持 org-scoped；可作为部署前的 admin runtime smoke。
- 多租户客户端需配置 org：CLI 会在 token resolve app 后自动把 `org_id` 传给 patch check，fake e2e 已覆盖非 default org token 下的 release/patch/promote/check；Flutter SDK 可在 `FcbCodePush.configure(orgId: 'acme', ...)` 中显式指定，事件上报也会写入同一 org。
- `snapshot_replace` 仍只建议 internal/enterprise 使用；商店合规路线应使用 bytecode backend。
