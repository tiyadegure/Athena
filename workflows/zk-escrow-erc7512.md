# Roadmap Workflow — Athena 下一步扩展

> 基于 v1-v8 完成状态，更新 4 个方向的实际进度。
> 大部分基础工作已在 v3/v4 完成，剩余的是进阶/扩展。

---

## 当前完成状态总览

| 方向 | 基础 | 进阶 | 部署 |
|------|------|------|------|
| ZK 可验证审计 | ✅ 审计证据链 | ⬜ ZK proof | ⬜ 未部署 |
| Agent Escrow | ✅ 合约 + 测试 | ⬜ 自动结算闭环 | ⬜ 未部署 |
| 多链部署 | ⬜ 未开始 | ⬜ 未开始 | ⬜ 仅 Sepolia |
| AI Agent 标准 | ✅ AgentIdentity | ⬜ ERC-8004/8263/OCP | ⬜ 未部署 |

---

## 方向 1：ZK 可验证审计

### 已完成（v3/v4/v5）

- [x] `contracts/AuditEvidenceChain.sol` — Merkle 树审计证据链
  - recordStep()：记录每步输入/输出哈希
  - calculateMerkleRoot()：聚合所有步骤
  - finalizeAudit()：最终 EAS attestation
  - verifyStep()：Merkle proof 验证单步
- [x] `mcp/tools/evidence_chain.py` — MCP 工具实现
  - create_audit_chain / record_audit_step / calculate_merkle_root / verify_step
- [x] `docs/ZK-INSPIRATION.md` — ZK 启发文档
  - 方向 A：可验证 AI 审计（Verifiable AI Audit）
  - 方向 B：隐私审计（付费模式）
  - 方向 C：ZK-SNARK 审计证明
- [x] v5 workflow Step 6 已集成到 8 步 pipeline

### 待做

- [ ] ZK proof 生成（circom/snarkjs 或 Nova/IVC）
- [ ] 链上 Groth16 verifier 合约
- [ ] EAS attestation 嵌入 proof hash
- [ ] 隐私审计模式（加密合约 → 审计 → 结果解锁）
- [ ] AuditEvidenceChain 部署到 Sepolia

### 实现路径

```
contracts/
├── AuditEvidenceChain.sol     # ✅ 已有，Merkle 证据链
├── ZKAuditVerifier.sol        # ⬜ 链上 Groth16 verifier
└── PrivateAudit.sol           # ⬜ 加密合约提交 + 结果解锁

mcp/tools/
├── evidence_chain.py          # ✅ 已有，Merkle 聚合
├── zk_trace_recorder.py       # ⬜ 记录执行 trace
└── zk_proof_generator.py      # ⬜ 生成 Groth16 proof
```

---

## 方向 2：Agent Escrow 自动结算

### 已完成（v4）

- [x] `contracts/test-cases/AgentEscrow.sol`（205 行）
  - 完整的 Native-ETH 托管合约
  - EscrowState: Created → Funded → Completed/Disputed/Refunded
  - buyer/seller Agent 地址绑定
  - 截止时间 + 元数据 + 仲裁者
  - Events: EscrowCreated/Funded/Completed/Disputed/Refunded
- [x] `contracts/test-cases/AgentIdentity.sol`（229 行）
  - AI Agent 身份注册 + 威胁报告
  - AgentData: owner/name/metadata/identityHash/reputation
  - ThreatRegistry: reporter/agent/threatType/severity
  - 治理 + 验证者机制

### 待做

- [ ] AgentEscrow 升级为 v2（集成 EAS attestation 验证）
- [ ] 审计完成 → EAS attestation → 自动释放 ETH 闭环
- [ ] AgentMarketplace 合约（注册 + 报价 + 竞价）
- [ ] AgentReputation 合约（基于历史 NFT 的声誉系统）
- [ ] MCP 工具：escrow_manager.py / marketplace_client.py
- [ ] 部署到 Sepolia

### 实现路径

```
contracts/
├── AgentEscrow.sol            # ✅ 已有，升级为 v2
├── AgentIdentity.sol          # ✅ 已有，升级为 ERC-8004
├── AgentMarketplace.sol       # ⬜ Agent 市场注册 + 报价
├── AgentReputation.sol        # ⬜ 基于 NFT 的声誉系统
└── AuditBounty.sol            # ⬜ 审计悬赏

mcp/tools/
├── escrow_manager.py          # ⬜ 托管创建/释放/退款
├── marketplace_client.py      # ⬜ Agent 市场交互
└── reputation_checker.py      # ⬜ 声誉查询
```

---

## 方向 3：多链部署

### 已完成

- [ ] 无（仅 Sepolia）

### 待做

- [ ] AuditCertificate 部署到 Base Sepolia (84532)
- [ ] AuditCertificate 部署到 Arbitrum Sepolia (421614)
- [ ] EAS Schema 在目标链注册
- [ ] 跨链 attestation 同步（独立部署 或 LayerZero）
- [ ] MCP 工具支持多链 RPC
- [ ] 多链审计演示

### 目标链

| 链 | Chain ID | 优先级 | 状态 |
|---|---|---|---|
| Ethereum Sepolia | 11155111 | P0 | ✅ 已部署 |
| Base Sepolia | 84532 | P1 | ⬜ |
| Arbitrum Sepolia | 421614 | P1 | ⬜ |
| Polygon Amoy | 80002 | P2 | ⬜ |
| BSC Testnet | 97 | P2 | ⬜ |

### 实现路径

```
contracts/
├── MultiChainRegistry.sol     # ⬜ 多链合约注册
├── CrossChainAttestation.sol  # ⬜ 跨链 attestation 同步
└── deploy-multichain.sh       # ⬜ 多链部署脚本

mcp/tools/
├── multichain_rpc.py          # ⬜ 多链 RPC 管理
├── cross_chain_attest.py      # ⬜ 跨链 attestation
└── chain_config.json          # ⬜ 链配置
```

---

## 方向 4：AI Agent 标准集成

### 已完成（v4）

- [x] `contracts/test-cases/AgentIdentity.sol`（229 行）
  - Agent 注册 + 威胁报告 + 治理验证
  - 对应 ERC-8004 AI Agent 基础标准
- [x] ERC-7512 链上审计元数据
  - 已集成到 EAS schema
  - 状态：✅ 已完成（v4 workflow 记录）
- [x] `docs/` 中有标准文档框架
- [x] v4 workflow 5.1 记录了 ERC-8004 + ERC-8263 + OCP 集成方案

### 待做

- [ ] AgentIdentity 升级为完整 ERC-8004 实现
- [ ] ERC-8263 Agent 间通信标准
- [ ] OCP (Observation Commitment Protocol) 集成
- [ ] AgentServiceDescriptor 合约（服务描述：范围/定价/SLA）
- [ ] MCP 工具：agent_registry.py / service_descriptor.py
- [ ] 部署到 Sepolia

### 实现路径

```
contracts/
├── AgentIdentity.sol          # ✅ 已有，升级为 ERC-8004
├── ERC7512AuditMetadata.sol   # ⬜ 审计元数据标准（独立合约）
├── AgentServiceDescriptor.sol # ⬜ ERC-8263 服务描述
└── OCPContribution.sol        # ⬜ 开放贡献协议

mcp/tools/
├── erc7512_encoder.py         # ⬜ 编码 ERC-7512 元数据
├── agent_registry.py          # ⬜ Agent 注册中心
├── service_descriptor.py      # ⬜ 服务描述
└── ocp_client.py              # ⬜ OCP 交互

docs/
├── AI-AGENT-STANDARDS.md      # ⬜ 标准集成文档
```

---

## 与 v1-v8 的关系

```
v1-v3：基础架构 + NFT + 新 idea
  └─ 产出：AgentEscrow, AgentIdentity, AuditEvidenceChain, PrivacyToken

v4：前沿技术集成
  └─ 产出：pERC20, GEV, ERC-7512, Halmos, Read-Only Reentrancy, 期权合成资产

v5：完整 Demo 流程
  └─ 产出：8 步 pipeline, 13 MCP 工具, 12 Agent Skill

v6：S 级 NFT + 262,144 组合
v7：uPEG 技术借鉴
v8：产物生成（PPT + SVG）

扩展方向（基于已有基础）
  ├─ ZK：AuditEvidenceChain + ZK proof（⬆️ 进阶）
  ├─ Escrow：AgentEscrow + 自动结算闭环（⬆️ 进阶）
  ├─ 多链：Sepolia → Base/Arbitrum（🆕 新做）
  └─ 标准：AgentIdentity + ERC-8004/8263/OCP（⬆️ 进阶）
```

---

## 推荐执行顺序

```
Step 1：部署已有合约到 Sepolia
  - AuditEvidenceChain.sol
  - AgentEscrow.sol
  - AgentIdentity.sol

Step 2：多链部署（最简单）
  - AuditCertificate 部署到 Base Sepolia + Arbitrum Sepolia
  - EAS Schema 注册

Step 3：Agent Escrow 闭环（最有商业价值）
  - AgentEscrow v2 + EAS 验证
  - 审计完成 → 自动释放 ETH

Step 4：ZK proof（技术含量最高）
  - circom 电路设计
  - Groth16 proof 生成
  - 链上验证

Step 5：AI Agent 标准（长期价值）
  - ERC-8004 完整实现
  - Agent 服务市场
```
