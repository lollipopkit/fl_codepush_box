# FCB 攻坚计划索引

每个 Phase 一份详细计划文件。状态对应 `PLAN.md` 第 0.1 节快照。

| Phase | 文件 | 工作量 | 依赖 | 状态 |
|-------|------|--------|------|------|
| A 基础闭环 | — | — | — | ✅ 完成 |
| B Android snapshot_replace | — | — | — | ✅ 完成（arm64 真机待 H3） |
| C iOS bytecode 桩 | — | — | — | ✅ 完成（语义待 E 补全） |
| D 自动 patch 推导 | `../PLAN-now.md` | — | — | ✅ 完成 |
| **E Dart VM 真可用** | [phase_e_dart_vm.md](phase_e_dart_vm.md) | 6–10 月 | 无 | 🟡 skeleton |
| **F Server 多租户** | [phase_f_server_multitenancy.md](phase_f_server_multitenancy.md) | 2–3 月 | 无 | ❌ |
| **G 客户端健壮性** | [phase_g_client_resilience.md](phase_g_client_resilience.md) | 1–2 月 | 无 | ❌ |
| **H Vendor + CI + 真机** | [phase_h_vendor_ci_devices.md](phase_h_vendor_ci_devices.md) | 1 月 | E、G | ❌ |

## 推荐并行策略

```
month 1–2:  G（客户端健壮性）     ──┐
month 1–3:  F（server 多租户）   ──┤── 三条并行
month 1–10: E（Dart VM 真可用）   ──┘
month 11:   H（vendor + CI + 真机 + TestFlight）  ← 串行
```

**最早可上线时间**：约 11 个月。
**关键路径**：E（Dart VM ObjectPtr + opcode + 编译器 Dart 化）。

## 文件约定

- 每个 phase 文件包含：目标、现状、子阶段（含任务/关键文件/验收）、风险、退出标准。
- 子阶段命名 `EN`、`FN`、`GN`、`HN`，便于在 issue/PR 里引用（例如 "fix E2: call_dynamic dispatch"）。
- 状态变更同步更新 PLAN.md 第 0.1 节快照与本 README 表格。
