# GLM Audit Agent — Coding Agent Workflow v4

> v4：整合 2026.5-6 月最新区块链技术 + AI Agent 标准
>
> v3：`workflows/v3-new-ideas.md`（5 个 idea + 前端 + 新技术）
> v2：`workflows/v2-nft-generative.md`（NFT generative trait）
> v1：`workflows/v1-phase1-3.md`（Phase 1-3.3）

---

## 1. 项目目标

构建一个 **Web3 智能合约安全审计 Agent**，驱动模型为 GLM-5.1。

核心卖点：
- **Skill（方法论）**：自建 `glm-audit-skill` — 12 个专项审计 agent 并行扫描
- **MCP（工具链）**：自建 8 个无状态工具（slither, aderyn, PoC, fuzz, RAG, EAS, exploit_simulator, evidence_chain, halmos）
- **长程任务**：GLM-5.1 的 200K 上下文 + Interleaved Thinking，驱动 8 步审计闭环
- **链上认证**：EAS attestation + uPEG 风格 generative 雅典娜 NFT（12,000 种组合）
- **攻击模拟器**：端到端 exploit script 生成（多步骤、跨合约、含 fork 部署）
- **审计前端**：极简 Web 界面展示审计结果 + NFT 铸造
- **前沿技术覆盖**：覆盖 2026.5-6 月最新 EIP、MEV、隐私、AI Agent 标准

---

## 2. 当前进度

- [x] Phase 1：集成 glm-audit-skill + 自建 MCP 工具
- [x] Phase 2：搭建测试环境（5 个测试合约）
- [x] Phase 3：端到端审计验证 + NFT generative trait
- [x] Phase 4：5 个新 idea 实现（Idea 1/3/4/8/9 + Halmos + Read-Only Reentrancy）
- [x] Phase 5：前沿技术测试合约 + Idea 10 期权合成资产
- [ ] Phase 6：GLM-5.1 评测 + Demo 录屏

---

## 3. Phase 5：前沿技术测试合约

### 3.1 EIP-8287：Privacy-Native Fungible Token (pERC20)

**来源**：ethresear.ch 2026-06-03 + GitHub PR #1796
**链接**：https://ethereum-magicians.org/t/eip-8287

**核心创新**：隐私原生 ERC20 代币标准，支持隐私转账。

**安全审计重点**：
1. 隐私机制的正确性（零知识证明 or 混币）
2. 双花攻击防护
3. 余额隐私泄露
4. 与现有 DeFi 协议的兼容性
5. gas 优化

**新增测试合约**：
```
contracts/test-cases/PrivacyToken.sol        # pERC20 实现
contracts/test-cases/audit-results/privacy-token-audit.md
```

---

### 3.2 Native-ETH Agent-to-Agent Escrow

**来源**：GitHub PR 2026-06-05
**链接**：https://github.com/ethereum/EIPs/pull/9547

**核心创新**：AI Agent 之间的原生 ETH 托管合约，支持自动化交易。

**安全审计重点**：
1. 托管资金安全（agent 恶意行为）
2. 超时/退款机制
3. 重入攻击
4. 权限控制（谁能触发释放）
5. MEV 提取风险

**新增测试合约**：
```
contracts/test-cases/AgentEscrow.sol         # Agent 托管合约
contracts/test-cases/audit-results/agent-escrow-audit.md
```

---

### 3.3 AI Agent Identity and Threat Registry

**来源**：GitHub PR 2026-06-05
**链接**：https://github.com/ethereum/EIPs/pull/9545

**核心创新**：AI Agent 身份注册 + 威胁数据库，可与审计系统集成。

**安全审计重点**：
1. 身份伪造攻击
2. 注册表操纵
3. 威胁报告的可信度
4. 治理攻击（恶意更新）

**新增测试合约**：
```
contracts/test-cases/AgentIdentity.sol       # Agent 身份注册
contracts/test-cases/audit-results/agent-identity-audit.md
```

---

### 3.4 GEV (Generalized Extractable Value) 框架

**来源**：ethresear.ch 2026-05-25 "Extraction Is Conserved: From MEV to GEV"
**链接**：https://ethresear.ch/t/24953

**核心创新**：MEV 概念太窄，应该用 GEV。提取价值在不同层面守恒。

**安全审计重点**：
1. 跨层价值提取（L1 → L2 → 应用层）
2. 隐性 MEV（如预言机操纵、治理攻击）
3. 价值守恒验证

**集成方式**：
- 攻击模拟器新增 GEV 模板
- 审计 Agent 增加 GEV 分析维度

**新增文件**：
```
mcp/tools/gev_analyzer.py                   # GEV 分析工具
contracts/test-cases/GEVTest.sol             # GEV 测试合约
```

---

### 3.5 Multi-Party Block Construction

**来源**：ethresear.ch 2026-05-27 | 11 赞
**链接**：https://ethresear.ch/t/24975

**核心创新**：多方参与区块构建，解决 MEV 结构性问题。

**安全审计重点**：
1. 多方协议的正确性
2. 拜占庭容错
3. MEV 重新分配的安全性
4. 抗审查性

**新增测试合约**：
```
contracts/test-cases/MultiPartyBlock.sol     # 多方区块构建
```

---

### 3.6 Cross-Domain State Synchronization

**来源**：ethresear.ch 2026-06-02 | 3 赞
**链接**：https://ethresear.ch/t/25065

**核心创新**：跨域原子状态同步的形式化证明。

**安全审计重点**：
1. 原子性保证（跨域要么全成功要么全失败）
2. 状态不一致攻击
3. 桥接安全

**新增测试合约**：
```
contracts/test-cases/CrossDomainSync.sol     # 跨域同步
```

---

### 3.7 Idea 10：期权合成资产（Options-Based Index Tracking）

**来源**：Vitalik Buterin, 2026-06-01 | 24 赞
**论文**：https://ethresear.ch/t/25036

**核心创新**：用期权代替债务构建指数追踪合成资产，消除清算机制。

**机制**：
- 将 1 ETH 拆分为 P（看涨）+ N（看跌）
- 参数：ticker T（如 USD/ETH）、strike S、maturity M
- 到期：P = min(1, S/x)，N = max(0, 1-S/x)
- P + N = 1 恒成立，无需清算

**安全审计重点**：
1. 期权拆分/合并数学正确性
2. 预言机操纵攻击（到期时）
3. 再平衡策略的 MEV 风险
4. 流动性提供者的无常损失
5. 跨合约依赖安全性

**新增测试合约**：
```
contracts/options-index/
├── OptionsIndexTracker.sol      # 期权拆分/合并
├── SyntheticOption.sol          # P/N 期权代币
├── RebalancingStrategy.sol      # 自动再平衡
└── audit-results/options-index-audit.md
```

---

### 3.8 Deterministic Governance Verification

**来源**：ethresear.ch 2026-06-07
**链接**：https://ethresear.ch/t/25116

**核心创新**：确定性治理验证，可重放稳定的权威验证架构。

**安全审计重点**：
1. 治理提案的可验证性
2. 执行重建的安全性
3. 治理一致性验证

**新增测试合约**：
```
contracts/test-cases/GovernanceVerification.sol
```

---

## 4. 最新区块链技术集成（v3 已有）

### 4.1 Halmos 形式化验证
- 状态：✅ 已完成
- 文件：`mcp/tools/halmos_runner.py`

### 4.2 ERC-7512 链上审计元数据
- 状态：✅ 已集成到 EAS schema

### 4.3 Read-Only Reentrancy
- 状态：✅ 已完成
- 文件：`contracts/test-cases/ReadOnlyReentrancy.sol`

### 4.4 期权合成资产
- 状态：⬜ 待实现（见 3.7）

---

## 5. AI Agent 标准集成

### 5.1 ERC-8004 + ERC-8263 + OCP 组合

**来源**：ethresear.ch 2026-05-28
**链接**：https://ethresear.ch/t/24995

**核心**：AI Agent 验证栈的参考实现
- ERC-8004：AI Agent 基础标准
- ERC-8263：Agent 间通信
- OCP：Observation Commitment Protocol

**集成方式**：
- 审计 Agent 遵循 ERC-8004 身份标准
- 审计结果通过 OCP 上链认证
- Agent 间协作遵循 ERC-8263

**新增文件**：
```
docs/AI-AGENT-STANDARDS.md                  # AI Agent 标准集成文档
```

---

## 6. 实施优先级

| 优先级 | 任务 | 预估时间 | 理由 |
|--------|------|---------|------|
| P0 | Idea 10：期权合成资产 | 3 天 | Vitalik 最新研究，最有影响力 |
| P0 | pERC20 隐私代币 | 2 天 | EIP Draft，隐私赛道热点 |
| P0 | Agent Escrow | 1 天 | AI Agent 叙事核心 |
| P1 | GEV 分析器 | 2 天 | MEV 安全新框架 |
| P1 | Agent Identity | 1 天 | AI Agent 身份标准 |
| P1 | Multi-Party Block | 2 天 | MEV 基础设施 |
| P2 | Cross-Domain Sync | 2 天 | 跨链安全 |
| P2 | Governance Verification | 1 天 | 治理安全 |
| P2 | AI Agent Standards 文档 | 1 天 | 标准集成 |

**总预估时间**：15 天（还有 21 天，buffer 6 天）

---

## 7. 技术参考

| 资源 | 日期 | 用途 |
|------|------|------|
| Vitalik 期权论文 | 2026-06-01 | 合成资产新范式 |
| EIP-8287 pERC20 | 2026-06-03 | 隐私代币标准 |
| Agent Escrow EIP | 2026-06-05 | AI Agent 托管 |
| Agent Identity EIP | 2026-06-05 | AI Agent 身份 |
| GEV 框架 | 2026-05-25 | MEV 新理论 |
| Multi-Party Block | 2026-05-27 | MEV 基础设施 |
| Cross-Domain Sync | 2026-06-02 | 跨链安全 |
| Governance Verification | 2026-06-07 | 治理安全 |
| Vitalik 形式化验证 | 2026-05-18 | 审计方法论 |
| OCP v1.0.0 | 2026-04-06 | 链上认证 |
| ERC-8004+8263 | 2026-05-28 | AI Agent 标准 |

---

## 8. 开发约束

1. **测试网 Only** — Sepolia，不消耗真实 ETH
2. **先验证再报告** — 每个漏洞必须有 PoC 或 fuzz 验证
3. **工具独立** — 每个 MCP 工具无状态
4. **阶段性提交** — 每完成一个功能点就 git commit + push
5. **所有工具自建** — 不依赖第三方项目归属
6. **前端极简** — 禁止 emoji、大面积色块、JS 框架
7. **AI Agent 标准** — 遵循 ERC-8004/8263/OCP

---

## 9. 外部资源索引

### ethresear.ch 关键帖子

| ID | 日期 | 标题 | 赞 |
|----|------|------|-----|
| 25036 | 2026-06-01 | Options-based index tracking (Vitalik) | 24 |
| 24975 | 2026-05-27 | Multi-Party Block Construction | 11 |
| 25040 | 2026-06-01 | Post-Quantum Key Registry | 13 |
| 24964 | 2026-05-26 | Permissionless TEEs | 5 |
| 25065 | 2026-06-02 | Cross-Domain State Sync | 3 |
| 24953 | 2026-05-25 | MEV to GEV | 4 |
| 25089 | 2026-06-04 | pERC20 Privacy Token | 4 |
| 24995 | 2026-05-28 | AI Agent Verification Stack | 3 |
| 25116 | 2026-06-07 | Governance Verification | 2 |
| 25012 | 2026-05-31 | OCP CROPS Direction | 7 |

### GitHub EIPs

| PR | 日期 | 标题 |
|----|------|------|
| #9547 | 2026-06-05 | Native-ETH Agent-to-Agent Escrow |
| #9545 | 2026-06-05 | AI Agent Identity and Threat Registry |
| #9553 | 2026-06-07 | Multi-block Access List Warming |
| #9549 | 2026-06-05 | PQ sig and STARK aggregation (Vitalik) |
| #9543 | 2026-06-03 | Builder Execution Requests |

### Vitalik 博客

| 日期 | 标题 | 相关性 |
|------|------|--------|
| 2026-06-01 | Options-based index tracking | Idea 10 |
| 2026-05-18 | Formal verification | Halmos 集成 |
