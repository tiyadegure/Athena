# v9 Roadmap Workflow — Athena 下一步扩展

> 基于 v8 产物完成状态，规划 Athena 项目的 4 个扩展方向。
> 每个方向独立可执行，按优先级排序。

---

## 方向 1：ZK 可验证审计（优先级 P0）

### 目标
用零知识证明让审计过程可验证但不泄露细节 — 证明"我确实执行了完整审计"。

### 核心问题
当前 EAS attestation 只记录结果哈希，无法证明 Agent 是否真的跑了 Slither、生成了 PoC、做了 fuzz。Agent 可能"编造"报告。

### 技术方案

**Phase 1：执行路径证明**
- 把每个工具调用记录为执行 trace（Slither → PoC → Fuzz → Report）
- 用 Merkle tree 聚合所有步骤的输入/输出哈希
- 生成 Groth16 proof 证明 trace 的完整性
- EAS attestation 中嵌入 proof hash

**Phase 2：隐私审计（付费模式）**
- 项目方提交加密合约代码
- Agent 在 TEE 或 MPC 环境中执行审计
- 只公开审计结果（漏洞数量 + 严重性），不公开具体漏洞
- 项目方付费后解锁完整报告

### 实现路径
```
contracts/
├── ZKAuditVerifier.sol          # 链上 Groth16 verifier
├── AuditTrail.sol               # Merkle tree 执行路径存储
└── PrivateAudit.sol             # 加密合约提交 + 结果解锁

mcp/tools/
├── zk_trace_recorder.py         # 记录执行 trace
├── zk_proof_generator.py        # 生成 Groth16 proof
└── zk_verifier.py               # 链上验证
```

### 依赖
- circom/snarkjs（Groth16 证明系统）
- 或者用 Nova/IVC（增量可验证计算）更适合多步审计

### 产出
- ZK audit proof 在 Sepolia 验证通过
- EAS attestation 嵌入 proof hash
- 演示：提交合约 → 生成 proof → 链上验证

---

## 方向 2：Agent Escrow 自动结算（优先级 P1）

### 目标
AI Agent 之间自主交易 — 审计 Agent 完成工作后自动收款，无需人类介入。

### 当前状态
已有测试合约 `contracts/test-cases/AgentEscrow.sol`，实现了：
- Native-ETH 托管（Created → Funded → Completed/Disputed/Refunded）
- 买家/卖家 Agent 地址绑定
- 截止时间 + 元数据

### 技术方案

**Phase 1：审计-付费闭环**
```
1. 项目方调用 AgentEscrow.create() 创建托管
2. 项目方调用 AgentEscrow.fund() 存入 ETH
3. Athena Agent 执行完整 8 步审计
4. 审计结果上链（EAS attestation）
5. AgentEscrow 自动验证 EAS attestation
6. 验证通过 → 自动释放 ETH 给 Agent
7. 验证失败 → 退款给项目方
```

**Phase 2：Agent 市场**
- Agent 注册中心（AgentIdentity.sol 已有）
- Agent 声誉系统（基于历史审计 NFT）
- Agent 报价 + 竞价
- Agent ↔ Agent 交叉服务

### 实现路径
```
contracts/
├── AgentEscrow.sol              # 已有，升级为 v2
├── AgentMarketplace.sol         # Agent 市场注册 + 报价
├── AgentReputation.sol          # 基于 NFT 的声誉系统
└── AuditBounty.sol              # 审计悬赏

mcp/tools/
├── escrow_manager.py            # 托管创建/释放/退款
├── marketplace_client.py        # Agent 市场交互
└── reputation_checker.py        # 声誉查询
```

### 产出
- AgentEscrow v2 部署到 Sepolia
- 完整审计-付费闭环演示
- Agent 市场 MVP

---

## 方向 3：多链部署（优先级 P1）

### 目标
Athena 审计能力扩展到多链，支持 EVM 兼容链。

### 目标链
| 链 | Chain ID | 优先级 | 原因 |
|---|---|---|---|
| Ethereum Sepolia | 11155111 | P0 | 当前已部署 |
| Base Sepolia | 84532 | P1 | L2 低 gas |
| Arbitrum Sepolia | 421614 | P1 | L2 低 gas |
| Polygon Amoy | 80002 | P2 | 广泛使用 |
| BSC Testnet | 97 | P2 | 币安生态 |

### 技术方案

**Phase 1：跨链 EAS**
- 在目标链注册相同 EAS Schema
- 用跨链消息（LayerZero/Axelar）同步 attestation
- 或在每条链独立部署 EAS（EAS 已部署在多链）

**Phase 2：跨链 NFT**
- AuditCertificate 部署到多链
- 用 ERC-721 跨链桥接（LayerZero ONFT）
- 或在每条链独立铸造（简化方案）

**Phase 3：跨链审计**
- MCP 工具支持多链 RPC
- Slither/Aderyn 支持多链 bytecode
- PoC 支持多链 fork 测试

### 实现路径
```
contracts/
├── MultiChainRegistry.sol       # 多链合约注册
├── CrossChainAttestation.sol    # 跨链 attestation 同步
└── deploy-multichain.sh         # 多链部署脚本

mcp/tools/
├── multichain_rpc.py            # 多链 RPC 管理
├── cross_chain_attest.py        # 跨链 attestation
└── chain_config.json            # 链配置
```

### 产出
- AuditCertificate 部署到 3+ 条链
- 跨链 EAS attestation 同步
- 多链审计演示

---

## 方向 4：AI Agent 标准集成（优先级 P2）

### 目标
集成 2026 年最新的 AI Agent 标准，让 Athena 成为标准化的 AI Agent。

### 目标标准
| 标准 | 说明 | 状态 |
|------|------|------|
| ERC-7512 | 链上审计元数据标准 | 已有测试合约 |
| ERC-8004 | AI Agent 身份标准 | 已有 AgentIdentity |
| ERC-8263 | Agent 服务描述 | 需实现 |
| OCP | Open Contribution Protocol | 需实现 |

### 技术方案

**Phase 1：ERC-7512 审计元数据**
- 审计结果标准化为 ERC-7512 格式
- 链上可查询的审计元数据
- 与 EAS attestation 关联

**Phase 2：ERC-8004 Agent 身份**
- Athena 注册为标准化 AI Agent
- 身份包含：能力描述、历史审计、声誉评分
- 支持 Agent 发现和互操作

**Phase 3：Agent 服务描述**
- ERC-8263 标准化服务描述
- 支持：审计范围、定价、SLA
- Agent 市场可查询

**Phase 4：OCP 开放贡献协议**
- 开源审计知识库贡献
- Agent 协作审计
- 知识共享激励

### 实现路径
```
contracts/
├── ERC7512AuditMetadata.sol     # 审计元数据标准
├── AgentIdentity.sol            # 已有，升级为 ERC-8004
├── AgentServiceDescriptor.sol   # ERC-8263 服务描述
└── OCPContribution.sol          # 开放贡献协议

mcp/tools/
├── erc7512_encoder.py           # 编码 ERC-7512 元数据
├── agent_registry.py            # Agent 注册中心
├── service_descriptor.py        # 服务描述
└── ocp_client.py                # OCP 交互
```

### 产出
- ERC-7512 审计元数据在链上可查询
- Athena 注册为 ERC-8004 Agent
- Agent 服务描述标准化

---

## 执行优先级

```
P0（立即可做）：ZK 可验证审计
  → 核心卖点：可验证但不泄露
  → 技术栈：circom + snarkjs + EAS
  → 产出：ZK proof 在 Sepolia 验证

P1（黑客松后）：Agent Escrow + 多链
  → 核心卖点：Agent 自主交易 + 多链覆盖
  → 技术栈：LayerZero + 多链 RPC
  → 产出：跨链审计演示

P2（长期方向）：AI Agent 标准
  → 核心卖点：标准化 + 互操作
  → 技术栈：ERC-7512/8004/8263
  → 产出：标准化 Agent 注册
```

---

## 与 v8 的关系

```
v8（已完成）→ v9（扩展）
  │
  ├─ ZK：在 EAS attestation 基础上加 ZK proof
  ├─ Escrow：在审计闭环基础上加付费
  ├─ 多链：在 Sepolia 基础上扩展
  └─ 标准：在 Agent 身份基础上标准化
```

每个方向都是 v8 的自然延伸，不需要重写已有代码。

---

## 下一步

1. 选择一个方向开始（推荐 ZK）
2. 编写详细技术 spec
3. 实现 MVP
4. 部署到 Sepolia
5. 集成到 Athena 审计流程
