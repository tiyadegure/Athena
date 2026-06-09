# Athena

**Athena** — Web3 智能合约安全审计 Agent，基于 GLM-5.1 长程任务能力，结合自建审计 Skill 与 MCP 工具链，实现从漏洞发现到链上认证的完整闭环。

## 项目定位

这是一个 **Web3 × Long-Horizon Task** 项目，展示 GLM-5.1 在复杂、多步骤、需要持续自主执行的 Agent 任务中的能力。

核心链路（8 步）：
1. **需求理解** — 解析审计目标
2. **双引擎扫描** — Slither + Aderyn 静态分析
3. **RAG 知识增强** — 从漏洞知识库检索相关案例
4. **PoC 生成** — 自动生成概念验证代码
5. **Foundry fuzz 验证** — 模糊测试确认漏洞
6. **修复建议** — 生成修复方案
7. **EAS 上链认证** — 通过 Ethereum Attestation Service 上链记录审计结果
8. **铸造 NFT 证书** — 雅典娜女神 Generative NFT（ERC-1155，12,000 种 trait 组合）

## 技术栈

| 组件 | 来源 | 作用 |
|------|------|------|
| **GLM-5.1** | Z.AI Coding Plan | 驱动 Agent，处理长程任务 |
| **athena-audit-skill** | 自建 | 12 个专项 agent 并行审计方法论 |
| **MCP 工具链（13 个）** | 自建 | 静态分析、PoC 生成、fuzz 测试、知识库、链上认证等 |
| **Foundry** | foundry-rs | 合约编译、测试、fuzz |
| **EAS** | Ethereum Attestation Service | 链上审计认证 |
| **ERC-1155** | OpenZeppelin | 分级 NFT 审计证书 |

### MCP 工具（13 个）

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
| Protocol Scanner | `protocol_scanner.py` | 协议级扫描 |
| Repair Validator | `repair_validator.py` | 修复验证 |
| Incremental Auditor | `incremental_auditor.py` | 增量审计 |
| GEV Analyzer | `gev_analyzer.py` | GEV 分析 |

## 项目结构

```
glm-code/
├── PLAN.md                          # 项目计划与执行步骤
├── TESTING-PLAN.md                  # 测试方案
├── GLM-5.1-TECHNICAL-PROFILE.md     # GLM-5.1 技术特征
├── smart-contract-audit-agents-comparison.md  # 竞品调研（20 个项目）
├── skills/
│   └── glm-audit-skill/             # 自建审计 Skill（12 agent 并行方法论）
├── mcp/
│   ├── tools/                       # 13 个独立 MCP 工具服务
│   ├── servers.json                 # MCP 服务器注册配置
│   └── README.md
├── contracts/
│   ├── AuditCertificate.sol         # ERC-1155 审计证书（generative 12,000 种组合）
│   ├── AuditEvidenceChain.sol       # 审计证据链
│   ├── test-cases/                  # 17 个测试合约 + expected-results.json
│   ├── real-world/                  # 真实协议测试数据
│   └── options-index/               # 期权指数测试数据
├── prompts/
│   ├── audit-system.md              # 审计系统 prompt
│   └── system.md                    # 通用系统 prompt
├── frontend/                        # 审计报告前端
├── demo/                            # NFT 预览 + Demo 录屏素材
├── docs/
│   └── ZK-INSPIRATION.md            # ZK 启发文档
├── workflows/                       # 开发工作流记录
├── benchmarks/                      # 审计评测
├── script/                          # Foundry 部署脚本
├── data/knowledge/                  # RAG 知识库数据
└── foundry.toml                     # Foundry 配置
```

## 快速开始

### 前置条件

- Node.js 18+
- Foundry (`curl -L https://foundry.paradigm.xyz | bash`)
- Z.AI Coding Plan（包含 GLM-5.1 访问权限）

### 安装

```bash
git clone https://github.com/tiyadegure/glm-code.git
cd glm-code
npm install
pip install -r requirements.txt
```

### 配置

```bash
# Z.AI API Key（评测阶段使用）
export GLM_API_KEY="your-zai-api-key"

# 或使用 Claude（开发阶段调试用）
export ANTHROPIC_API_KEY="your-anthropic-key"
```

### 运行审计

```bash
# 使用 GLM-5.1 执行审计
glm audit contracts/Example.sol

# 使用 Claude 调试（开发阶段）
glm audit contracts/Example.sol --provider anthropic
```

## 开发策略

- **开发阶段**：使用 Claude（已配好 proxy）调试，快速迭代
- **评测阶段**：切换到 GLM-5.1（Coding Plan），展示长程任务能力
- **测试网**：Sepolia 测试网，无需真实 ETH

## 审计证书 NFT

Generative Trait 系统，12,000 种唯一组合：

| 维度 | 变体数 | 示例 |
|------|--------|------|
| Helmet（头盔） | 5 | 羽饰/双角/冠冕/头巾/经典 |
| Shield（盾牌） | 5 | 猫头鹰/蛇发/橄榄枝/闪电/空白 |
| Color（配色） | 8 | 金/银/铜/紫/绿/蓝/红/黑 |
| Weapon（武器） | 3 | 长矛/弓箭/剑 |
| Background（背景） | 5 | 星空/火焰/海洋/森林/极光 |
| Eyes（瞳色） | 4 | 蓝/绿/金/红 |

**5 × 5 × 8 × 3 × 5 × 4 = 12,000 种组合**

铸造条件基于审计结果分级：

| 等级 | 条件 | NFT |
|------|------|-----|
| **A 级** | 发现严重漏洞 + PoC 验证通过 | 金色雅典娜 |
| **B 级** | 发现中等漏洞 + 修复建议 | 银色雅典娜 |
| **C 级** | 完成基本扫描 + 报告 | 铜色雅典娜 |

所有 SVG 图像完全链上生成，不依赖 IPFS。

## 竞品对比

详见 [smart-contract-audit-agents-comparison.md](./smart-contract-audit-agents-comparison.md)

核心优势：**自建 13 个 MCP 工具同时拥有 RAG 知识库、PoC 生成、Foundry fuzz 验证、攻击模拟、形式化验证和 EAS 链上认证，配合 GLM-5.1 的长程能力驱动从漏洞发现到链上证书的完整闭环。**

## 路线图

### v5 Demo 流程（8 步闭环）

- [x] 竞品调研（20 个项目）
- [x] 项目规划与技术选型
- [x] 构建 athena-audit-skill（12 agent 并行审计）
- [x] 构建 13 个独立 MCP 工具
- [x] 设计 Generative NFT（12,000 种 trait 组合）
- [x] 部署审计合约到 Sepolia 测试网
  - AuditCertificate (NFT): `0x636B3Af9630e1b26b02BA488a5b8Ab6cE75d6721`
  - AuditEvidenceChain: `0x5e99f144D3e512f525d24077D4626a064899E177`
  - 测试 NFT 已铸造 (Gold tier)
- [ ] 跑通 ①→⑧ 完整审计链路
- [ ] GLM-5.1 vs Claude 对比评测（17 个测试合约）
- [ ] 录制 Demo 视频
- [ ] 提交黑客松

## 许可证

MIT License
