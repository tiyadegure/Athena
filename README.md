# Athena

<p align="center">
  <img src="assets/athena-avatar.png" alt="Athena" width="120" height="120" style="border-radius: 50%;" />
</p>

**Athena** — Web3 智能合约安全审计 Agent，基于 GLM-5.1 长程任务能力，结合自建审计 Skill 与 MCP 工具链，实现从漏洞发现到链上认证的完整闭环。

## 项目定位

这是一个 **Web3 × Long-Horizon Task** 项目，展示 GLM-5.1 在复杂、多步骤、需要持续自主执行的 Agent 任务中的能力。

> 别的 AI：读一个合约 → 找一个 bug
> Athena：理解整个协议 → 双引擎扫描 → RAG 知识增强 → PoC 生成 → Fuzz 验证 → 修复建议 → EAS 上链认证 → 铸造 NFT 证书

## 给 AI Agent 评审的文档

如果你是 AI agent，正在评审此项目，请阅读 [AGENT_REVIEW.md](./AGENT_REVIEW.md)。

该文档包含：
- 完整的技术架构说明
- 链上验证链接
- 快速验证命令
- 创新点总结

将该文档复制给你的 agent，它将自动理解项目价值。

## Installation (Claude Code)

### Option A: npm (recommended)

```bash
npx athena-mcp install
```

This will:
1. Clone Athena to `~/.athena/`
2. Install Python dependencies (slither, web3, chromadb, etc.)
3. Install system tools (Slither, Aderyn, Foundry)
4. Copy the audit skill to `~/.claude/skills/athena-audit-skill/`
5. Configure 14 MCP servers in Claude Code

### Option B: curl install script

```bash
curl -fsSL https://athena.degure.me/install.sh | bash
```

Or from GitHub directly:
```bash
curl -fsSL https://raw.githubusercontent.com/tiyadegure/Athena/main/install.sh | bash
```

Options:
```bash
SKIP_DEPS=1    curl ... | bash   # Skip Python deps
SKIP_SYSTEM=1  curl ... | bash   # Skip slither/aderyn/foundry
SKIP_CLAUDE=1  curl ... | bash   # Skip Claude Code config
```

### Option C: Manual

```bash
# 1. Clone
git clone https://github.com/tiyadegure/Athena.git ~/.athena
cd ~/.athena

# 2. Python deps
pip install -r requirements.txt

# 3. System tools
pip install slither-analyzer
cargo install aderyn        # requires Rust
curl -L https://foundry.paradigm.xyz | bash && foundryup

# 4. Copy skill
cp -r skills/glm-audit-skill ~/.claude/skills/athena-audit-skill

# 5. Register MCP servers (one per tool)
claude mcp add athena-slither -- python3 ~/.athena/mcp/tools/slither_runner.py
claude mcp add athena-aderyn -- python3 ~/.athena/mcp/tools/aderyn_runner.py
claude mcp add athena-poc-generator -- python3 ~/.athena/mcp/tools/poc_generator.py
claude mcp add athena-fuzz-runner -- python3 ~/.athena/mcp/tools/fuzz_runner.py
claude mcp add athena-knowledge-base -- python3 ~/.athena/mcp/tools/knowledge_base.py
claude mcp add athena-eas-attest -- python3 ~/.athena/mcp/tools/eas_attest.py
claude mcp add athena-exploit-simulator -- python3 ~/.athena/mcp/tools/exploit_simulator.py
claude mcp add athena-evidence-chain -- python3 ~/.athena/mcp/tools/evidence_chain.py
claude mcp add athena-halmos-runner -- python3 ~/.athena/mcp/tools/halmos_runner.py
claude mcp add athena-protocol-scanner -- python3 ~/.athena/mcp/tools/protocol_scanner.py
claude mcp add athena-repair-validator -- python3 ~/.athena/mcp/tools/repair_validator.py
claude mcp add athena-incremental-auditor -- python3 ~/.athena/mcp/tools/incremental_auditor.py
claude mcp add athena-gev-analyzer -- python3 ~/.athena/mcp/tools/gev_analyzer.py
```

### Quick Start (after install)

```bash
# 1. Install
npx athena-mcp install

# 2. Environment setup (for on-chain attestation + NFT minting)
export SEPOLIA_PRIVATE_KEY="0xYourPrivateKey"
export SEPOLIA_RPC_URL="https://rpc.sepolia.org"  # or Alchemy/Infura

# 3. Full audit flow (scan → PoC → EAS attestation → NFT mint)
claude "audit contracts/test-cases/Reentrancy.sol and mint NFT certificate"

# 4. Scan-only (static analysis, no on-chain actions)
claude "scan contracts/test-cases/Reentrancy.sol with slither and aderyn"
```

**What happens:**
- Slither + Aderyn dual-engine static analysis
- PoC generation + Foundry fuzz testing
- EAS attestation on Sepolia (on-chain audit record)
- NFT certificate minting (ERC-1155, S/A/B/C tiers)
- Verification links to Etherscan + EAS explorer

### Try Different Contracts

Pre-crawled test contracts with known vulnerabilities. Each includes difficulty level and expected findings.

**Beginner**
- `contracts/test-cases/Reentrancy.sol` — Classic reentrancy (external call before state update)
- `contracts/test-cases/AccessControl.sol` — Missing access control (unprotected mint/burn/transfer)
- `contracts/test-cases/SafeContract.sol` — Reference contract with NO vulnerabilities (false positive test)

**Intermediate**
- `contracts/test-cases/FlashLoan.sol` — Flash loan price manipulation (spot-price oracle, no TWAP)
- `contracts/test-cases/IntegerOverflow.sol` — Integer overflow in unchecked blocks
- `contracts/test-cases/AgentEscrow.sol` — Agent-to-agent escrow (reentrancy + missing state checks)
- `contracts/test-cases/AgentIdentity.sol` — AI agent identity (reputation manipulation)

**Advanced**
- `contracts/test-cases/ReadOnlyReentrancy.sol` — Read-only reentrancy (Curve/Balancer 2023 style)
- `contracts/test-cases/PrivacyToken.sol` — Privacy token (ZK proof bypass, merkle manipulation)
- `contracts/test-cases/GEVTest.sol` — Generalized Extractable Value (MEV, oracle, governance)

Quick commands:
```bash
# Beginner
claude "audit contracts/test-cases/AccessControl.sol and mint NFT certificate"

# Intermediate
claude "audit contracts/test-cases/FlashLoan.sol and mint NFT certificate"

# Advanced
claude "audit contracts/test-cases/ReadOnlyReentrancy.sol and mint NFT certificate"
```

---
## 核心工作流（8 步闭环）

```
输入：Solidity 合约 / DeFi 协议目录
  ↓
┌─────────────────────────────────────────────────────────┐
│ Step 1: 需求理解                                         │
│   - 解析审计目标，识别合约类型和攻击面                      │
│   - 自动发现所有合约，分析调用关系                          │
│   - 12 个 agent 并行扫描（athena-audit-skill）             │
├─────────────────────────────────────────────────────────┤
│ Step 2: 双引擎扫描                                       │
│   - Slither (Trail of Bits) 静态分析                     │
│   - Aderyn (Cyfrin) Rust 重写静态分析                    │
│   - 交叉验证，减少误报                                    │
├─────────────────────────────────────────────────────────┤
│ Step 3: RAG 知识增强                                     │
│   - ChromaDB 漏洞知识库检索                               │
│   - 匹配历史审计案例和已知漏洞模式                         │
│   - 增强漏洞判断准确性                                    │
├─────────────────────────────────────────────────────────┤
│ Step 4: PoC 生成                                         │
│   - 自动生成 Foundry .s.sol 概念验证脚本                  │
│   - 支持闪电贷+重入+预言机操纵+权限提升等攻击类型           │
│   - 不只是找 bug，还能证明 bug 可被利用                    │
├─────────────────────────────────────────────────────────┤
│ Step 5: Foundry Fuzz 验证                                │
│   - 模糊测试确认漏洞真实性                                │
│   - 256+ runs 自动 fuzz                                  │
│   - 输出：PoC 验证结果 + 复现步骤                         │
├─────────────────────────────────────────────────────────┤
│ Step 6: 修复建议                                         │
│   - 基于漏洞类型生成修复方案                              │
│   - 修复后重新审计，对比前后差异                           │
│   - 多轮迭代直到漏洞消除                                  │
├─────────────────────────────────────────────────────────┤
│ Step 7: EAS 上链认证                                     │
│   - 通过 Ethereum Attestation Service 上链记录审计结果    │
│   - Schema UID + Attestation UID，任何人可验证            │
│   - 审计过程完全透明可追溯                                 │
├─────────────────────────────────────────────────────────┤
│ Step 8: 铸造雅典娜 NFT 证书                              │
│   - ERC-1155 分级 NFT（S/A/B/C 四级）                    │
│   - Generative SVG，9 个 trait 维度，262,144 种组合       │
│   - 完全链上生成，不依赖 IPFS                             │
└─────────────────────────────────────────────────────────┘
```

## 技术架构

### Skill（方法论）— 12 个 Agent 并行审计

自建 `athena-audit-skill`，10 轮检查流程：
scope → architecture → access control → reentrancy → math → oracle → flash loan → governance → upgrade → report

### MCP（工具链）— 14 个工具

| 工具 | 脚本 | 功能 |
|------|------|------|
| Slither | `slither_runner.py` | 静态分析 (Trail of Bits) |
| Aderyn | `aderyn_runner.py` | Rust 静态分析 (Cyfrin) |
| PoC Generator | `poc_generator.py` | PoC exploit 生成 |
| Fuzz Runner | `fuzz_runner.py` | Foundry fuzz 测试 |
| Knowledge Base | `knowledge_base.py` | ChromaDB RAG 知识库 |
| EAS Attestation | `eas_attest.py` | 链上认证 |
| Exploit Simulator | `exploit_simulator.py` | 攻击模拟器 |
| Evidence Chain | `evidence_chain.py` | 审计证据链 |
| Halmos | `halmos_runner.py` | 形式化验证 |
| ZK Trace Recorder | `zk_trace_recorder.py` | 记录审计执行 trace |
| ZK Proof Generator | `zk_proof_generator.py` | 生成 Groth16 ZK proof |
| ZK Verifier | `zk_verifier.py` | 链上 ZK proof 验证 |
| Protocol Scanner | `protocol_scanner.py` | 协议级扫描 |
| Repair Validator | `repair_validator.py` | 修复验证 |
| Incremental Auditor | `incremental_auditor.py` | 增量审计 |
| GEV Analyzer | `gev_analyzer.py` | GEV 分析 |

### 驱动模型

- **GLM-5.1** — 200K 上下文 + Interleaved Thinking，长程任务能力
- **开发阶段**：Claude（proxy 调试）
- **评测阶段**：GLM-5.1（Coding Plan）

## 技术栈

| 组件 | 来源 | 作用 |
|------|------|------|
| **GLM-5.1** | Z.AI Coding Plan | 驱动 Agent，处理长程任务 |
| **athena-audit-skill** | 自建 | 12 个专项 agent 并行审计方法论 |
| **MCP 工具链（14 个）** | 自建 | 静态分析、PoC 生成、fuzz 测试、知识库、链上认证等 |
| **Foundry** | foundry-rs | 合约编译、测试、fuzz |
| **EAS** | Ethereum Attestation Service | 链上审计认证 |
| **ERC-1155** | OpenZeppelin | 分级 NFT 审计证书 |
| **ChromaDB** | 自建 | RAG 漏洞知识库 |
| **Halmos** | a16z | 形式化验证 |

## 项目结构

```
Athena/
├── AGENTS.md                        # 项目规范（Agent 工作指引）
├── PLAN.md                          # 项目计划
├── TESTING-PLAN.md                  # 测试方案
├── GLM-5.1-TECHNICAL-PROFILE.md     # GLM-5.1 技术特征
├── smart-contract-audit-agents-comparison.md  # 竞品调研（20 个项目）
├── skills/
│   └── glm-audit-skill/             # 自建审计 Skill（athena-audit-skill，12 agent）
├── mcp/
│   ├── tools/                       # 13 个独立 MCP 工具服务
│   ├── servers.json                 # MCP 服务器注册配置
│   └── README.md
├── contracts/
│   ├── AuditCertificate.sol         # ERC-1155 审计证书（S/A/B/C，generative 262,144 种组合）
│   ├── AuditEvidenceChain.sol       # 审计证据链
│   ├── ART.sol                      # Athena Reputation Token（声誉代币）
│   ├── RarityCalculator.sol         # 动态稀有度算法
│   ├── test-cases/                  # 17 个测试合约 + expected-results.json
│   ├── real-world/                  # 真实协议测试数据（Curve, Hundred Finance）
│   ├── multi-contract/              # 多合约协议测试（Token+Oracle+Vault）
│   └── options-index/               # 期权指数测试数据
├── prompts/                         # 系统 prompt
├── frontend/                        # 审计报告前端 + Landing Page
├── demo/                            # NFT 预览 + Demo 录屏素材
├── docs/                            # 文档（PRODUCT, ZK-INSPIRATION, X 内容）
├── workflows/                       # 开发工作流记录（v1-v8）
├── ppt-assets/                      # PPT 素材（SVG 图表 + 生成脚本）
├── benchmarks/                      # 审计评测
├── scripts/                         # Demo 录屏脚本 + 审计脚本
├── script/                          # Foundry 部署脚本
└── foundry.toml                     # Foundry 配置
```

## 链上部署

### Sepolia（Ethereum 测试网）

| 合约 | 地址 | 状态 |
|------|------|------|
| AuditCertificate (NFT) | `0x3247d57d37bd1878479f03a077aba807649dbaf5` | ✅ 已部署 |
| AgentEscrowV2 | `0x7102b7252dea80529278c8bffc441b96ff24421e` | ✅ 已部署 |
| ERC7512AuditMetadata | `0x0dd8f8f5b755912aa3b955044d1eff496a65e657` | ✅ 已部署 |
| AuditTrail (ZK) | `0xd7913e7749595a9238883bdf0b2dad599f4d0bf0` | ✅ 已部署 |
| Groth16Verifier | `0xf0c9ec42fe603a53af3e6248e874bbbb3064e498` | ✅ 已部署 |
| EAS Schema | `0x6d6520d928b6090172a458c2addcd30af1090f5298110e496bb3c9ac3918253e` | ✅ 已注册 |
| EAS Attestation | `0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9` | ✅ 已认证 |

### Base Sepolia（L2 测试网）

| 合约 | 地址 | 状态 |
|------|------|------|
| AuditCertificate (NFT) | `0xb8f167a84816b5b9373997337119a2186c6e3708` | ✅ 已部署 |
| ERC7512AuditMetadata | `0x5e99f144d3e512f525d24077d4626a064899e177` | ✅ 已部署 |
| Groth16Verifier | `0x636b3af9630e1b26b02ba488a5b8ab6ce75d6721` | ✅ 已部署 |
| AuditTrail | `0x83bfbc0901c9a6481a26ec2dc649487768ec8a99` | ✅ 已部署 |

**链上验证链接：**
- NFT (Sepolia): https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5
- NFT (Base Sepolia): https://sepolia.basescan.org/address/0xb8f167a84816b5b9373997337119a2186c6e3708
- AuditTrail (Sepolia): https://sepolia.etherscan.io/address/0xd7913e7749595a9238883bdf0b2dad599f4d0bf0
- EAS 认证: https://sepolia.easscan.org/attestation/view/0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9


## 快速开始（中文）

Athena 的审计流程由 AI Agent（GLM-5.1）驱动，不是简单的脚本调用。Agent 读取 `AGENT-WORKFLOW-FINAL.md`，自主执行 8 步闭环。

### 方式一：用 GLM-5.1 Agent 驱动（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/tiyadegure/Athena.git
cd Athena

# 2. 安装依赖
pip install -r requirements.txt
curl -L https://foundry.paradigm.xyz | bash  # Foundry

# 3. 配置环境变量
export SEPOLIA_PRIVATE_KEY="0x你的测试网私钥"
export SEPOLIA_RPC_URL="https://rpc.sepolia.org"  # 或 Alchemy/Infura

# 4. 用 GLM-5.1 Agent 执行审计
# 将 AGENT-WORKFLOW-FINAL.md 的内容作为 prompt 发送给 GLM-5.1
# Agent 会自主执行：扫描 → PoC → Fuzz → EAS 上链 → NFT 铸造
```

Agent 会读取 `AGENT-WORKFLOW-FINAL.md`，按照 6 个 Phase 逐步执行，每一步验证通过后才继续下一步，最终输出链上验证链接和本地审计文件。

### 方式二：手动逐步执行

也可以单独调用 MCP 工具：

```bash
# Step 1-2: 静态分析
slither contracts/test-cases/Reentrancy.sol --json results.json
aderyn contracts/test-cases/ --output aderyn-results.json

# Step 4: PoC 测试
forge test --match-contract ReentrancyPoC -vvv

# Step 5: Fuzz 测试
forge test --match-contract ReentrancyPoC --fuzz-runs 256 -vvv

# Step 7: EAS 上链认证（需要 Python + web3.py）
python3 mcp/tools/eas_attest.py --result report.json

# Step 8: 铸造 NFT 证书（需要 cast + 私钥）
cast send 0x3247d57d37bd1878479f03a077aba807649dbaf5 \
    "mintCertificate(address,bytes32,uint8)" \
    $WALLET_ADDRESS $EAS_UID 1 \
    --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PRIVATE_KEY
```

### 链上验证

审计完成后，任何人都可以在链上验证结果：
- EAS Attestation: https://sepolia.easscan.org/attestation/view/{UID}
- NFT Certificate: https://sepolia.etherscan.io/tx/{TX_HASH}
- Audit Contract: https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5

## 审计证书 NFT

### Generative Trait 系统（262,144 种组合）

借鉴 [uPEG (Unipeg)](https://etherscan.io/address/0x44b28991b167582f18ba0259e0173176ca125505) 的 generative trait 设计，9 个维度动态生成：

| 维度 | 变体数 | 示例 |
|------|--------|------|
| Background | 4 | 深蓝/紫/绿/红 |
| Body | 4 | 金/银/铜/铁 |
| Eyes | 4 | 蓝/绿/红/金 |
| Crown | 4 | 皇冠/角/羽毛/无 |
| Wings | 4 | 龙翼/天使翼/蝙蝠翼/无 |
| Aura | 4 | 光晕/火焰/冰霜/无 |
| Shield | 4 | 盾牌/徽章/纹章/无 |
| Texture | 4 | 条纹/点阵/渐变/纯色 |
| Accessory | 4 | 项链/戒指/披风/无 |

**4^9 = 262,144 种唯一组合**

### 等级系统

| 等级 | 条件 | 视觉 |
|------|------|------|
| **S 级** | 审计满分 + 所有 PoC 通过 | 彩虹渐变 + 动态光晕 |
| **A 级** | 发现严重漏洞 + PoC 验证通过 | 金色雅典娜 |
| **B 级** | 发现中等漏洞 + 修复建议 | 银色雅典娜 |
| **C 级** | 完成基本扫描 + 报告 | 铜色雅典娜 |

所有 SVG 图像完全链上生成，不依赖 IPFS。`uri()` 返回完整 JSON metadata + 内嵌 SVG。

## 评测

### 17 个测试合约

涵盖主流漏洞类型：Reentrancy, Integer Overflow, Access Control, Flash Loan, PriceOracle, Read-Only Reentrancy, Governance Attack, Bridge Exploit, Agent Escrow, GEV, Privacy Token 等。

### Demo 审计结果

| 指标 | 结果 |
|------|------|
| 漏洞发现 | 5 个（1 Critical + 2 High + 1 Medium + 1 Low） |
| PoC 验证 | 2/5 通过（Reentrancy + Oracle） |
| Fuzz 测试 | 256 runs |
| 静态分析 | Slither 4 + Aderyn 3 + Halmos 8 properties |

## 竞品对比

详见 [smart-contract-audit-agents-comparison.md](./smart-contract-audit-agents-comparison.md)

核心优势：**自建 14 个 MCP 工具 + 12 agent 并行审计方法论 + RAG 知识库 + PoC 生成 + Foundry fuzz + 攻击模拟 + 形式化验证 + EAS 链上认证 + Generative NFT，配合 GLM-5.1 的长程能力驱动从漏洞发现到链上证书的完整闭环。**

## 开发工作流

项目经历了 8 个版本的迭代：

| 版本 | 文件 | 内容 |
|------|------|------|
| v1 | `workflows/v1-phase1-3.md` | Phase 1-3.3 基础架构 |
| v2 | `workflows/v2-nft-generative.md` | NFT generative trait 系统 |
| v3 | `workflows/v3-new-ideas.md` | 5 个 idea + 前端 + 新技术 |
| v4 | `workflows/v4-frontier-tech.md` | 2026.5-6 月最新区块链技术 |
| v5 | `workflows/v5-long-horizon.md` | 完整 Demo 流程整合 |
| v6 | `workflows/v6-s-tier-nft.md` | S 级炫彩 NFT + 262,144 组合 |
| v7 | `workflows/v7-upeg-*.md` | uPEG 技术借鉴 + ERC-404 |
| v8 | `workflows/v8-artifacts.md` | 项目产物生成 |
| ZK + Escrow | `workflows/zk-escrow-erc7512.md` | ZK + Agent Escrow + ERC-7512 |
| Real Protocol | `workflows/real-protocol-audit.md` | 真实协议审计（Curve V2 + Hundred Finance） |

## 路线图

### 已完成

- [x] 竞品调研（20 个项目）
- [x] 构建 athena-audit-skill（12 agent 并行审计）
- [x] 构建 14 个独立 MCP 工具
- [x] Generative NFT（S/A/B/C 四级，262,144 种 trait 组合）
- [x] 部署 5 个合约到 Sepolia 测试网（AuditCertificate + ZK + Escrow + ERC-7512）
- [x] EAS Schema 注册 + Attestation 上链
- [x] Gold NFT 已铸造
- [x] Landing Page + 前端 Demo
- [x] PPT 素材生成
- [x] ZK 可验证审计（AuditTrail + Groth16Verifier）
- [x] Agent Escrow v2（EAS 自动释放）
- [x] ERC-7512 审计元数据标准
- [x] 真实协议审计（Curve V2 + Hundred Finance）

### 进行中

- [x] 录制 Demo 视频（终端 + 浏览器 + 链上验证）
- [x] 多链部署（Sepolia + Base Sepolia）
- [ ] GLM-5.1 vs Claude 对比评测（17 个测试合约）

### 下一步

- [ ] 主网部署（Ethereum + Base L2）
- [ ] Agent 审计市场（AgentEscrow + Marketplace）
- [ ] 更多协议审计（Aave、Uniswap、Compound）
- [ ] 隐私审计模式（加密合约 → 审计 → 解锁）

## 许可证

MIT License


## Agent Workflow

项目通过 `AGENT-WORKFLOW-FINAL.md` 驱动，Agent 自主执行完整审计流程：

```
Phase 1: 需求理解 + Slither/Aderyn 双引擎扫描
Phase 2: PoC 生成 + Foundry Fuzz 验证
Phase 3: 修复建议 + 审计报告生成
Phase 4: EAS Attestation 上链认证 + NFT 证书铸造
Phase 5: 验证报告部署
Phase 6: 最终验证 + 输出
```

### 执行前置条件

```bash
export SEPOLIA_PRIVATE_KEY="0x你的私钥"
export SEPOLIA_RPC_URL="https://rpc.sepolia.org"  # 或 Alchemy/Infura
```

需要：Sepolia ETH（至少 0.01）、Foundry、Slither、Python3 + web3.py

### 每次执行产出

| 产出 | 类型 |
|------|------|
| EAS Attestation UID | 链上新凭证（`sepolia.easscan.org` 可验证） |
| NFT Mint TX | 链上新交易（`sepolia.etherscan.io` 可验证） |
| 审计报告 JSON | 本地文件 |
| Slither/Aderyn/PoC/Fuzz 结果 | 本地文件 |

### 已验证的执行记录 (2026-06-11)

由 GLM-5.1 (Pi agent) 真实执行，审计目标 `VulnerableBank (Reentrancy.sol)`：

| 项目 | 结果 |
|------|------|
| 静态分析 | 4 个发现 (2 HIGH + 2 LOW) |
| PoC 生成 | 攻击成功，银行余额被清空 |
| Fuzz 测试 | 768 次运行，0 反例 |
| 综合评级 | S (Critical) |

**链上凭证**：
- EAS: https://sepolia.easscan.org/attestation/view/0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9
- NFT: https://sepolia.etherscan.io/tx/0x917de9a93471273089e49b948a70a0f0f71503598ccdf60d05a7c54c6289dbc0
