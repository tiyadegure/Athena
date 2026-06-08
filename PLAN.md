# GLM Audit — Web3 安全审计 Agent 工作流

## 定位

> 为 Web3 安全审计构建一套可复用的 Agent 工作流——知识（Skill）+ 工具（MCP）——然后证明 GLM-5.1 在长程任务上比其他模型更适合驱动这套工作流。

## 市场调研结论（20 个项目分析）

完整报告：`/root/smart-contract-audit-agents-comparison.md`

```
已有竞品格局：
├── pashov (819⭐)    = 最强方法论，零工具
├── Plamen (244⭐)    = 最全面（多链+RAG+PoC+fuzz），无链上认证
├── SolidityGuard(95⭐) = 最多工具集成（9个），无链上认证
├── RugProof (7⭐)     = 最多功能，但已删库
└── AuditAI (我们)     = 唯一同时有 RAG + PoC + Fuzz + 链上认证
```

**核心发现：链上认证几乎是空白。20 个项目里只有 RugProof 有（已删库）。**

## 架构

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code                          │
│              (harness，不修改底层)                        │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              Skill 层                              │  │
│  │  pashov solidity-auditor (819⭐，12 agent 方法论)  │  │
│  │  ├── senior-auditor-sop.md (Feynman/Inversion)    │  │
│  │  ├── 12 hacking agents (并行扫描)                 │  │
│  │  ├── judging.md (4 道验证门)                      │  │
│  │  └── report-formatting.md (标准化输出)            │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              MCP 工具层                            │  │
│  │  slither_mcp     — 静态分析 (Trail of Bits)       │  │
│  │  aderyn          — 安全扫描 (Cyfrin)              │  │
│  │  exploit_gen     — PoC 生成 (AuditAI)             │  │
│  │  concrete_exec   — Foundry fuzz (AuditAI)         │  │
│  │  knowledge_base  — RAG 查询 (AuditAI)             │  │
│  │  eas_attest      — 链上认证 (AuditAI)             │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              GLM-5.1 (via Coding Plan)             │  │
│  │  · 长程任务决策                                    │  │
│  │  · 12 agent 并行编排                               │  │
│  │  · 自我纠错 (judging gates)                        │  │
│  │  · 200K context (DSA 无损)                         │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 差异化叙事

> "20 个开源审计项目里，只有 2 个有 RAG，只有 1 个有链上认证（已删库）。
> 我们是唯一同时拥有 RAG + PoC + Fuzz + 链上认证的工作流。
> GLM-5.1 的长程能力驱动从漏洞发现到链上认证的完整闭环。"

## 测试方案

### 测试集

```
test-suite/
├── contracts/
│   ├── VulnerableBank.sol      — 重入攻击
│   ├── PriceOracle.sol         — 预言机操纵
│   ├── AccessControl.sol       — 权限绕过
│   ├── OverflowToken.sol       — 整数溢出
│   └── FlashLoan.sol           — 闪电贷攻击
├── expected-results.json       — 已知漏洞清单
└── run.sh                      — 评测脚本
```

来源：Damn Vulnerable DeFi / Ethernaut / 自建

### 对比设计

```
同一套 Skill + MCP，不同模型驱动：
  GLM-5.1 (via Coding Plan)  vs  Claude (via proxy)
```

### 评测指标

| 指标 | 说明 |
|------|------|
| 漏洞发现率 | 找到了多少真实漏洞 / 已知漏洞总数 |
| 误报率 | 报了多少假漏洞 |
| 链路完成率 | 从扫描到 EAS 上链走了几步 |
| 偏离率 | 是否中途跑偏 |
| 纠错能力 | 遇到错误能否恢复 |
| Token 消耗 | 完成任务的 token 数 |
| MCP 调用正确率 | 工具是否被正确调用 |

### 产出表格

```
┌──────────────────────────────────────────────────────┐
│       同一 Skill + MCP，不同模型驱动                   │
├──────────────┬──────────┬──────────┬─────────────────┤
│ 合约          │ GLM-5.1  │ Claude   │ 说明            │
├──────────────┼──────────┼──────────┼─────────────────┤
│ vulnerable   │ 3/3 ✅   │ 3/3 ✅   │                 │
│ price-oracle │ 2/3 ⚠️   │ 3/3 ✅   │                 │
│ access-ctrl  │ 3/3 ✅   │ 2/3 ⚠️   │                 │
│ overflow     │ 2/2 ✅   │ 2/2 ✅   │                 │
│ flash-loan   │ 2/4 ⚠️   │ 3/4      │                 │
├──────────────┼──────────┼──────────┼─────────────────┤
│ 漏洞发现率    │ 12/15    │ 13/15    │                 │
│ 链路完成率    │ 5/5      │ 4/5      │ GLM 长程更稳    │
│ 平均 Token    │ XXXX     │ XXXX     │                 │
└──────────────┴──────────┴──────────┴─────────────────┘
```

## 执行计划

### Phase 1: 接入 + 跑通（Day 1-2）

- [ ] 克隆 pashov/skills，安装到 Claude Code
- [ ] 配置 AuditAI MCP（拆成独立工具，不调 analyze_contract）
- [ ] 验证：Claude Code + GLM-5.1 + pashov Skill + AuditAI 工具 能跑通
- [ ] 准备 5 个测试合约

### Phase 2: 测试 + 优化（Day 3-4）

- [ ] GLM-5.1 跑 5 个测试合约
- [ ] Claude 跑同一组合约
- [ ] 对比数据，分析差距
- [ ] 根据结果调整 Skill 或工具

### Phase 3: Demo 录制（Day 5）

- [ ] 选一个最有代表性的合约
- [ ] 录屏：GLM-5.1 走完 完整审计链路
- [ ] 录屏：Claude 走同一合约（对比用）

### Phase 4: 提交（Day 6）

- [ ] 测试对比表
- [ ] README 更新
- [ ] Demo 视频
- [ ] GitHub repo 整理
- [ ] 提交到黑客松

## 项目结构（最终）

```
glm-audit/
├── skills/
│   └── solidity-auditor/       # 从 pashov/skills 安装
├── mcp/
│   ├── exploit_gen/            # PoC 生成
│   ├── concrete_execution/     # Foundry fuzz
│   ├── knowledge_base/         # RAG 查询
│   └── eas_attest/             # 链上认证
├── test-suite/
│   ├── contracts/              # 5 个测试合约
│   ├── expected-results.json   # 标准答案
│   └── run.sh                  # 评测脚本
├── results/                    # 评测结果
├── PLAN.md
├── TESTING-PLAN.md
├── GLM-5.1-TECHNICAL-PROFILE.md
└── README.md
```

## 长期方向

黑客松之后，如果 Skill 效果不够好：

- [ ] 做 audit-context-manager（过滤噪音、保留攻击假设）
- [ ] 做 GLM-5.1 专属的 thinking mode 控制（复杂任务开 interleaved）
- [ ] 做审计专用的 token 分配策略
- [ ] 扩展到 Solana/Move/TON 等多链
