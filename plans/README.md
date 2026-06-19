# FCB 攻坚计划索引

面向开发者 / agent。每个 Phase 一份计划文件,描述目标、子阶段、任务、关键文件与验收。

| Phase | 文件 | 工作量 | 依赖 |
|-------|------|--------|------|
| A 基础闭环 | — | — | — |
| B Android snapshot_replace | — | — | — |
| C iOS bytecode 桩 | — | — | — |
| D 自动 patch 推导 | — | — | — |
| E Dart VM 真可用 | [phase_e_dart_vm.md](phase_e_dart_vm.md) | 6–10 月 | 无 |
| F Server 多租户 | [phase_f_server_multitenancy.md](phase_f_server_multitenancy.md) | 2–3 月 | 无 |
| G 客户端健壮性 | [phase_g_client_resilience.md](phase_g_client_resilience.md) | 1–2 月 | 无 |
| H Vendor + CI + 真机 | [phase_h_vendor_ci_devices.md](phase_h_vendor_ci_devices.md) | 1 月 | E、G |

架构决策见 [`../docs/architecture_decisions.md`](../docs/architecture_decisions.md)、
[`../docs/key_rotation_design.md`](../docs/key_rotation_design.md)、
[`../docs/backends.md`](../docs/backends.md)。

## 推荐并行策略

```
G（客户端健壮性）   ──┐
F（server 多租户）  ──┤── 三条并行
E（Dart VM 真可用）  ──┘
H（vendor + CI + 真机 + TestFlight）  ← 依赖 E、G,串行
```

关键路径:E（Dart VM ObjectPtr + opcode 集 + 编译器 Dart 化 + 最大化 AOT 复用）。

## 文件约定

- 每个 phase 文件包含:目标、现状、子阶段（含任务 / 关键文件 / 验收）、风险、退出标准。
- 子阶段命名 `EN`、`FN`、`GN`、`HN`,便于在 issue/PR 里引用（例如 "fix E2: call_dynamic dispatch"）。
