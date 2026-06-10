# Athena — Web3 安全审计 Agent 工作流

## 定位

> 为 Web3 安全审计构建一套可复用的 Agent 工作流——知识（Skill）+ 工具（MCP）——然后证明 GLM-5.1 在长程任务上比其他模型更适合驱动这套工作流。

## 市场调研结论（20 个项目分析）

完整报告：`/root/smart-contract-audit-agents-comparison.md`

```
已有竞品格局：
├── athena-audit-skill = 自建方法论，12 agent 并行
├── Plamen (244⭐)    = 最全面（多链+RAG+PoC+fuzz），无链上认证
├── SolidityGuard(95⭐) = 最多工具集成（9个），无链上认证
├── RugProof (7⭐)     = 最多功能，但已删库
└── 我们的项目       = 自建 13 个 MCP 工具链：RAG + PoC + Fuzz + 链上认证
```

**核心发现：链上认证几乎是空白。20 个项目里只有 RugProof 有（已删库）。**

## 架构

```
┌─────────────────────────────────────────────────────────┐
│                    GLM-5.1 (via Coding Plan)             │
│              (harness，不修改底层)                        │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              Skill 层                              │  │
│  │  athena-audit-skill (自建，12 agent 并行方法论)   │  │
│  │  ├── senior-auditor-sop.md (Feynman/Inversion)    │  │
│  │  ├── 12 hacking agents (并行扫描)                 │  │
│  │  ├── judging.md (4 道验证门)                      │  │
│  │  └── report-formatting.md (标准化输出)            │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              MCP 工具层（13 个）                   │  │
│  │  slither           — 静态分析 (Trail of Bits)     │  │
│  │  aderyn            — 安全扫描 (Cyfrin)            │  │
│  │  poc_generator     — PoC 生成（自建）             │  │
│  │  fuzz_runner       — Foundry fuzz（自建）         │  │
│  │  knowledge_base    — RAG 查询（自建）             │  │
│  │  eas_attest        — 链上认证（自建）             │  │
│  │  exploit_simulator — 攻击模拟器                   │  │
│  │  evidence_chain    — 审计证据链                   │  │
│  │  halmos_runner     — 形式化验证                   │  │
│  │  protocol_scanner  — 协议级扫描                   │  │
│  │  repair_validator  — 修复验证                     │  │
│  │  incremental_auditor — 增量审计                   │  │
│  │  gev_analyzer      — GEV 分析                     │  │
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

## 链上审计证书 NFT（雅典娜）

### 设计

```
审计完成
    ↓
EAS Attestation（已有）→ 记录漏洞、修复、评分
    ↓
NFT Certificate（ERC-1155）→ 雅典娜女神 + 审计元数据
    ↓
链上可验证：任何人看到 NFT 就知道这个合约被审计过
```

### Generative Trait 系统（12,000 种组合）

```
审计完成 → EAS 上链 → 简单调用合约
→ 根据 attestationUID 确定性生成 6 个 trait
  Helmet(5) × Shield(5) × Color(8) × Weapon(3) × Background(5) × Eyes(4)
  = 12,000 种唯一组合
→ 根据评分铸造对应等级的 NFT
  S 级 → 金色雅典娜（稀缺）
  A 级 → 银色雅典娜
  B 级 → 铜色雅典娜
```

### NFT Metadata

```json
{
  "name": "Athena Audit Certificate #1234",
  "description": "A 级 (Gold) - Rarity: 42/100",
  "image": "data:image/svg+xml;base64,...",
  "attributes": [
    { "trait_type": "Tier", "value": "A 级 (Gold)" },
    { "trait_type": "Helmet", "value": "Feathered" },
    { "trait_type": "Shield", "value": "Owl" },
    { "trait_type": "Color", "value": "Gold" },
    { "trait_type": "Weapon", "value": "Spear" },
    { "trait_type": "Background", "value": "Starry Sky" },
    { "trait_type": "Eyes", "value": "Blue" },
    { "display_type": "number", "trait_type": "Rarity Score", "value": 42 }
  ]
}
```

### 图像：链上 SVG + Generative

```
底图：Athena 女神像素风（8-bit 复古风）
  + 6 个 trait 维度动态组合
    ├── 头盔样式（5 种）
    ├── 盾牌图案（5 种）
    ├── 配色方案（8 种）
    ├── 武器类型（3 种）
    ├── 背景场景（5 种）
    └── 瞳色（4 种）
→ 全部 SVG，直接存链上，不依赖 IPFS
→ 每个 attestationUID 确定性生成唯一组合
```

### 链上认证闭环

```
完整的审计链路：

  ① 读取合约 → 识别协议
  ② slither + aderyn 双引擎扫描
  ③ RAG 知识库交叉验证
  ④ PoC exploit 生成
  ⑤ Foundry fuzz 验证
  ⑥ 生成修复补丁
  ⑦ EAS Sepolia 链上认证    ← 已有
  ⑧ 铸造雅典娜 NFT 证书    ← 新增
```

### 链上技术细节

**EAS Attestation（第 ⑦ 步）**

```
合约：EAS (Sepolia) — 0xC2679fBD37d54388Ce493F1DB75320D236e1815e
Schema：定义审计结果的结构化数据
  → 合约地址、审计时间、评分、漏洞数量、修复状态
调用：eas_attest.py（自建）
产物：attestation UID（链上可查）
验证：https://sepolia.eas.xyz/attestation/{UID}
```

**ERC-1155 NFT（第 ⑧ 步）**

```
合约：AuditCertificate (Sepolia) — `0xcb85A20d0CD307926e9cbC9Ae78867529BD12671`
Token IDs：
  → 1 = S 级（金色雅典娜，generative traits）
  → 2 = A 级（银色雅典娜，generative traits）
  → 3 = B 级（铜色雅典娜，generative traits）

证据链：AuditEvidenceChain — `0x5e99f144D3e512f525d24077D4626a064899E177`

铸造条件：需要有效的 EAS attestation UID（或 owner 调用 mintTest 测试）
  → 合约内部验证 attestation 存在且有效
  → 根据 attestation 中的评分决定 token ID

Metadata（链上 SVG）：
  → generateMetadata() 返回 data:application/json;base64,...
  → 12,000 种 trait 组合，完全链上生成
  → 不依赖 IPFS

展示：
  → OpenSea 测试网：https://testnets.opensea.io/...
  → Etherscan：https://sepolia.etherscan.io/token/{contract}/{id}
```

**成本**

```
全部在 Sepolia 测试网，0 成本：
├── 测试 ETH：sepoliafaucet.com 免费领
├── EAS attestation：免费
├── NFT 部署：免费（测试网 gas）
└── NFT 铸造：免费（测试网 gas）
```

## 差异化叙事

> "20 个开源审计项目里，只有 2 个有 RAG，只有 1 个有链上认证（已删库）。
> 我们是唯一同时拥有 RAG + PoC + Fuzz + 链上认证 + 审计 NFT 证书的工作流。
> GLM-5.1 的长程能力驱动从漏洞发现到链上认证的完整闭环。
> 每个被审计的合约都获得一个链上可验证的雅典娜 NFT 证书（12,000 种 generative 组合）。"

## 测试方案

### 测试集（17 个合约）

```
test-suite/
├── contracts/
│   ├── Reentrancy.sol           — 重入攻击
│   ├── IntegerOverflow.sol      — 整数溢出
│   ├── AccessControl.sol        — 权限绕过
│   ├── FlashLoan.sol            — 闪电贷攻击
│   ├── SafeContract.sol         — 安全合约（无漏洞基准）
│   ├── PriceOracle.sol          — 预言机操纵
│   ├── OverflowToken.sol        — 溢出代币
│   ├── VulnerableBank.sol       — 脆弱银行
│   ├── AgentEscrow.sol          — Agent 托管合约
│   ├── AgentIdentity.sol        — Agent 身份合约
│   ├── GEVTest.sol              — GEV 测试合约
│   ├── PrivacyToken.sol         — 隐私代币
│   ├── ReadOnlyReentrancy.sol   — 只读重入
│   ├── FlashLoanAttacker.sol    — 闪电贷攻击者
│   ├── OracleManipulator.sol    — 操纵预言机
│   ├── GovernanceAttack.sol     — 治理攻击
│   └── BridgeExploit.sol        — 跨桥攻击
├── expected-results.json        — 已知漏洞清单（17 个合约）
└── run.sh                       — 评测脚本
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
│ Reentrancy   │ X/X      │ X/X      │                 │
│ Overflow     │ X/X      │ X/X      │                 │
│ AccessCtrl   │ X/X      │ X/X      │                 │
│ FlashLoan    │ X/X      │ X/X      │                 │
│ SafeContract │ 0/0 ✅   │ 0/0 ✅   │ 无漏洞基准      │
│ ...          │ X/X      │ X/X      │ （共 17 个合约）│
├──────────────┼──────────┼──────────┼─────────────────┤
│ 漏洞发现率    │ XX%      │ XX%      │                 │
│ 链路完成率    │ X/X      │ X/X      │ GLM 长程更稳    │
│ 平均 Token    │ XXXX     │ XXXX     │                 │
└──────────────┴──────────┴──────────┴─────────────────┘
```

## 执行计划

### 开发模型策略

```
开发阶段：Claude（proxy 已配好，无限调试）
  → 搭建 Skill + MCP + 测试合约 + NFT 合约
  → 大量调试，跑通完整链路
  → 产出：可运行的工作流

评测阶段：GLM-5.1（Coding Plan，精打细算）
  → 只跑最终版本
  → 17 个测试合约 + 录屏
  → 产出：评测数据 + Demo 视频
```

### v5 Demo 流程

- [x] 构建 athena-audit-skill（12 agent 并行审计）
- [x] 构建 13 个独立 MCP 工具
- [x] 设计 Generative NFT（12,000 种 trait 组合）
- [x] 验证：Claude + athena-audit-skill + MCP 工具 能跑通
- [ ] 准备 17 个测试合约 + expected-results.json
- [x] 部署审计合约到 Sepolia 测试网
- [ ] 跑通 ①→⑧ 完整审计链路
- [ ] GLM-5.1 跑 17 个测试合约
- [ ] Claude 跑同一组合约（对比数据）
- [ ] 录屏：GLM-5.1 完整审计链路
- [ ] 录屏：Claude 同一合约（对比用）
- [ ] 对比分析
- [ ] 提交黑客松

## 项目结构（最终）

```
glm-code/
├── skills/
│   └── glm-audit-skill/        # 自建审计 Skill（athena-audit-skill）
├── mcp/
│   ├── tools/                  # 13 个独立 MCP 工具
│   ├── servers.json            # MCP 服务器注册
│   └── README.md
├── contracts/
│   ├── AuditCertificate.sol    # ERC-1155（generative 12,000 种组合）
│   ├── AuditEvidenceChain.sol  # 审计证据链
│   ├── test-cases/             # 17 个测试合约
│   ├── real-world/             # 真实协议测试数据
│   └── options-index/          # 期权指数测试数据
├── prompts/
│   ├── audit-system.md
│   └── system.md
├── frontend/                   # 审计报告前端
├── demo/                       # NFT 预览 + Demo
├── workflows/                  # 开发工作流记录
├── docs/                       # 文档
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
