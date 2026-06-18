# FCB 签名密钥轮换 / 吊销设计（Design only，未实现）

状态：设计草案（2026-06-18）。本文件只描述设计，不含代码改动。
范围：patch manifest 签名密钥的多 key 信任、按 `key_id` 选择、吊销、轮换。

## 0. 目标与威胁模型

目标：
- 设备能信任**一组**签名公钥，而不是单把。
- 能**吊销**某把已泄露/退役的 key，使其签出的 patch 即使签名数学有效也被拒。
- 能**轮换** patch 签名密钥（PSK）。Tier 2 目标是轮换/吊销 PSK **无需发版**。

不在范围：
- TLS / 传输层安全（已由 HTTPS 承担）。
- payload 内容加密（payload 不是机密，见 PLAN「app_id 不是 secret」）。

威胁：
- 单把签名私钥泄露 → 攻击者可签恶意 patch。当前无法补救（设备只认那把 key）。
- 回滚攻击：把设备退回到一个仍信任已吊销 key 的旧信任集 / 旧 bundle。
- 降级攻击：攻击者在 manifest 里挑一把弱/旧 key。

## 1. 现状（被修复对象）

- `crates/fcb_core/src/manifest.rs::verify_patch_manifest(manifest, public_key_b64)`：只接受**单把** key，且**完全忽略** `manifest.signature.key_id`。
- `PatchSignature { algorithm, key_id, value }`：`key_id` 字段已存在但从未用于选择。
- 设备侧 `updater` 经 `FcbInitParams.public_key_pem` 注入**单把** key（`normalize_public_key_b64`）。
- `crates/fcb_core/src/config.rs`：单 `public_key`。
- `server/types.go::App.PublicKey`：单把。

→ 无法吊销、无法轮换。这是 D 项要修的安全漏洞。

## 2. 统一数据模型（Tier 1 与 Tier 2 共用，保证不返工）

核心抽象：**TrustedKey** 与 **TrustedKeySet**。Tier 1 的"设备本地信任集"与 Tier 2 的"KSK 签名 bundle 内容"用**同一结构**，这样 Tier 1→Tier 2 是叠加而非重写。

```
TrustedKey {
  key_id:      String,        // 稳定标识，如 "prod-ed25519-2026-01"
  public_key:  String,        // base64 raw ed25519 (32B)，与现有 normalize 输出一致
  status:      "active" | "revoked",
  not_before?: RFC3339,       // 可选生效时间
  not_after?:  RFC3339,       // 可选过期时间
}

TrustedKeySet {
  keys: Vec<TrustedKey>,
}
```

manifest 不变（`key_id` 已在 `PatchSignature` 内）。这意味着 **Tier 1 不需要改 manifest 格式**。

## 3. Tier 1 — 多 key + key_id 选择 + 吊销（PSK 轮换需发版）

### 3.1 验签算法（替换 `verify_patch_manifest`）

```
verify(manifest, key_set, now):
  if manifest.signature.algorithm != "ed25519": reject "unsupported algorithm"
  kid = manifest.signature.key_id
  key = key_set.find(kid)                 // 按 key_id 精确选择
  if key is None:        reject "unknown key_id"      // 不 try-all：未知即拒
  if key.status==revoked:reject "revoked key_id"      // 吊销优先于签名校验
  if now < not_before or now > not_after: reject "key not in validity window"
  crypto::verify_b64(key.public_key, canonical_json(unsigned_manifest), value)
```

要点：
- **按 key_id 选择，不要"逐把尝试"**。逐把尝试会让吊销失效（攻击者用没吊销的别的 key），也掩盖配置错误。
- **吊销检查在签名校验之前**：revoked key 即使签名有效也拒。
- 兼容旧 manifest：`key_id == ""` 映射到 `key_set` 中一把标记为 legacy 的 key（迁移期），后续要求所有新 manifest 带非空 key_id。

### 3.2 签名（CLI）

- `fcb` 签名时，私钥与其 `key_id` 一起配置（fcb.yaml `security.signing_key_id` + 私钥来源），写入 `manifest.signature.key_id`。
- 同一 app 可有多把签名私钥；CLI 用"当前 active 的签名 key"签。

### 3.3 配置 / 存储改动面（仅列出，**不实现**）

- `fcb.yaml`：`security.public_key`（单）→ `security.keys: [{key_id, public_key, status}]`（保留单字段做向后兼容解析，内部归一为列表）。
- `crates/fcb_core/src/config.rs`：`public_key: String` → `keys: Vec<TrustedKey>`（解析旧单字段为 `key_id:"legacy"` 一项）。
- `server/types.go::App`：`PublicKey string` → `Keys []TrustedKey`；DB migration v6：新增 `app_keys(org_id, app_id, key_id, public_key, status, not_before, not_after)`，把现有 `apps.public_key` 迁成一行 `key_id="legacy", status=active`。
- 设备/updater：`FcbInitParams.public_key_pem`（单）保留做兼容；新增 `fcb_set_trusted_keys(const char* json)` 传入 `TrustedKeySet` JSON。`Runtime.public_key_b64: String` → `trusted_keys: TrustedKeySet`。
- `install_payload*` / `download_and_install`：把 `&public_key_b64` 换成 `&TrustedKeySet`。

### 3.4 轮换 / 吊销操作流程（Tier 1）

- **新增 key**：发 App 新版本（信任锚在包里）→ 新 key 进 `security.keys`。之后 CLI 可用新 key 签。
- **退役旧 key**：把旧 key `status=revoked` 写进下一个 App 版本。已装旧版的设备在升级前仍信任它（Tier 1 的固有局限）。
- 局限：**任何信任集变更都要发版**。这违反 FCB「不强制发版」精神，所以 Tier 1 只是止血，Tier 2 才是终态。

### 3.5 测试（Tier 1）

- 正确 key_id + active → 通过。
- 正确签名但 key_id=revoked → 拒。
- 未知 key_id → 拒（即使 payload/hash 都对）。
- 过期/未生效窗口 → 拒。
- 旧 manifest（key_id="" 映射 legacy）→ 通过（迁移兼容）。
- 跨 org/app 的 key 不串（沿用现有隔离）。

## 4. Tier 2 — KSK 根密钥 + KSK 签名的 PSK bundle（PSK 轮换/吊销免发版）

在 Tier 1 之上加一层间接：设备只焊死极少变动的**根密钥 KSK**，由 KSK 签发"当前有效 PSK 列表"的 **bundle**，随 patch check 下发。

### 4.1 角色

- **KSK（Key-Signing Key）**：根信任锚，私钥离线保管，极少轮换。其**公钥焊进 App 包**（可多把以支持 KSK 自身轮换）。
- **PSK（Patch-Signing Key）**：实际给 patch manifest 签名的 key。可频繁轮换/吊销。

### 4.2 bundle 格式

```
KeyBundle {
  bundle_version: u64,        // 单调递增，回滚保护
  issued_at:      RFC3339,
  not_after:      RFC3339,    // 强制刷新窗口（缓解离线吊销滞后）
  keys:           Vec<TrustedKey>,   // 复用 §2 结构 = Tier 1 的信任集
}
SignedKeyBundle {
  bundle: KeyBundle,
  signature: { ksk_key_id: String, value: base64 },   // KSK 对 canonical_json(bundle) 的签名
}
```

设备焊死：`baked_ksks: Vec<{ksk_key_id, ksk_public_key}>`。

### 4.3 分发与缓存

- check 响应里带当前 `SignedKeyBundle`（或 `bundle_url` + `bundle_hash`，体积大时）。
- 设备缓存"见过的最高 `bundle_version`"（与 state 同级持久化）。
- **回滚保护**：拒绝 `bundle_version < 已缓存版本` 的 bundle（防止把设备退回到仍含已吊销 PSK 的旧 bundle）。
- **新鲜度**：`not_after` 过期的缓存 bundle 视为不可用，强制刷新（缓解"离线设备仍信任已吊销 PSK"）。

### 4.4 验签算法（Tier 2）

```
load_bundle(signed, baked_ksks, cached_version, now):
  ksk = baked_ksks.find(signed.signature.ksk_key_id)
  if ksk is None: reject "unknown KSK"
  verify(ksk.public_key, canonical_json(signed.bundle), signed.signature.value) or reject
  if signed.bundle.bundle_version < cached_version: reject "stale bundle (rollback)"
  if now > signed.bundle.not_after: reject "expired bundle"
  persist cached_version = max(cached_version, signed.bundle.bundle_version)
  return signed.bundle.keys  // -> TrustedKeySet

verify_patch(manifest, bundle_keys, now):
  // 与 Tier 1 §3.1 完全相同，只是 key_set 来自 bundle 而非本地包
```

### 4.5 轮换 / 吊销流程（Tier 2）

- **轮换 PSK**：用 KSK 签一个新 bundle（version+1），新 PSK active、旧 PSK 仍 active（重叠期）→ 下发。**不发版。**
- **吊销 PSK**：新 bundle 把该 PSK `status=revoked`（或直接移除）→ 下发。设备刷新后即拒。**不发版。**
- **轮换 KSK**：发 App 新版本，往 `baked_ksks` 加新 KSK；新 bundle 改用新 KSK 签。仅此一项需发版（极少）。

### 4.6 测试（Tier 2）

- KSK 签名有效的 bundle → 接受并用其 keys 验 patch。
- 未知 KSK 签的 bundle → 拒。
- bundle_version 低于缓存 → 拒（回滚保护）。
- bundle 过期（now>not_after）→ 拒。
- bundle 内 PSK=revoked → 对应 patch 拒。
- KSK 轮换：旧 KSK 签的 bundle 在加入新 KSK 后仍被接受（重叠期）。

## 5. Tier 1 → Tier 2 迁移（为什么不返工）

- Tier 1 的 `TrustedKeySet` == Tier 2 bundle 内的 `keys`。Tier 1 的"本地包内信任集"可视为"一个本地的、隐式 version=0 的 bundle"。
- Tier 2 上线后：设备优先用"KSK 验证过、version 更高"的远端 bundle；远端不可用/未配置时回落到本地 Tier 1 信任集。
- 因此 manifest（已带 key_id）、CLI 签名、server 的 `app_keys` 表在两层间**不变**；Tier 2 只新增 KSK 焊死项、bundle 签发/下发/缓存。

## 6. 决策点 / 待确认

- KSK 数量与保管：离线 HSM？几把 KSK 同时焊入以支持平滑轮换？
- bundle 下发通道：复用 `/v1/patches/check` 响应内嵌，还是独立 `/v1/keys/bundle` 端点？体积/缓存权衡。
- `not_after` 时长：太短增加 check 依赖与离线脆弱性，太长延长吊销滞后。建议 7–30 天 + check 时机会性刷新。
- 离线吊销滞后是 CRL 类系统的固有问题；本设计用 `bundle_version` 单调 + `not_after` 兜底，不追求即时吊销。

## 7. 影响文件清单（实现时参考，本文件不改它们）

- `crates/fcb_core/src/manifest.rs`（verify 签名改为 key_set）
- `crates/fcb_core/src/config.rs`（keys 列表 + 旧单字段兼容）
- `crates/fcb_core/src/state.rs` / `updater/src/lib.rs`（install/verify 传 key_set；新增 `fcb_set_trusted_keys`；Tier 2 加 bundle 缓存/校验）
- `server/types.go` + `server/store.go`（`app_keys` 表，migration v6；Tier 2 加 bundle 签发/存储/下发）
- `cli`（签名带 key_id；key 管理子命令；Tier 2 的 KSK 签 bundle 工具）
- `tests/e2e/test_e2e.sh` + 单测（§3.5 / §4.6）
</content>
