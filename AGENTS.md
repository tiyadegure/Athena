# Athena 项目规范

## 项目目标

构建基于 GLM-5.1 的 Web3 智能合约安全审计 Agent，实现从漏洞发现到链上认证的完整闭环。

## 核心工作流

审计任务链（8 步）：
1. 需求理解 → 2. 双引擎扫描 (Slither+Aderyn) → 3. RAG 知识增强 → 4. PoC 生成 → 5. Foundry fuzz 验证 → 6. 修复建议 → 7. EAS 上链认证 → 8. 铸造雅典娜 NFT 证书

## 技术架构

### Skill（方法论）
- **athena-audit-skill**（目录名 `glm-audit-skill`）— 自建 12 agent 并行审计方法论
- 10 轮检查流程：scope → architecture → access control → math → ... → report

### MCP（工具链）— 13 个工具
自建 MCP 工具：
- `slither` — 静态分析
- `aderyn` — Rust 重写的静态分析
- `poc_generator` — PoC 生成
- `fuzz_runner` — Foundry fuzz 测试
- `knowledge_base` — 漏洞知识库 (ChromaDB)
- `eas_attest` — EAS 链上认证
- `exploit_simulator` — 攻击模拟器
- `evidence_chain` — 审计证据链
- `halmos_runner` — 形式化验证
- `protocol_scanner` — 协议级扫描
- `repair_validator` — 修复验证
- `incremental_auditor` — 增量审计
- `gev_analyzer` — GEV 分析

### 驱动模型
- **GLM-5.1** — 长程任务能力，200K 上下文
- **开发阶段**：Claude（proxy 调试）
- **评测阶段**：GLM-5.1（Coding Plan）

## 开发规则

### 1. 先检索再编码
编写新代码前，先搜索项目中是否已有类似实现，避免重复。

### 2. 使用 Foundry
合约开发和测试统一使用 Foundry 框架：
```bash
forge build    # 编译
forge test     # 测试
forge fuzz     # 模糊测试
```

### 3. 测试网优先
所有链上操作使用 Sepolia 测试网，不消耗真实 ETH。

### 4. 阶段性提交
每完成一个功能点就 git commit + push，保持历史清晰。

## 项目结构

```
glm-code/
├── PLAN.md                          # 项目计划
├── TESTING-PLAN.md                  # 测试方案
├── GLM-5.1-TECHNICAL-PROFILE.md     # GLM-5.1 技术特征
├── smart-contract-audit-agents-comparison.md  # 竞品调研
├── skills/
│   └── glm-audit-skill/             # 自建审计 Skill（athena-audit-skill）
├── mcp/
│   ├── tools/                       # 13 个独立 MCP 工具
│   ├── servers.json                 # MCP 服务器注册
│   └── README.md
├── contracts/
│   ├── AuditCertificate.sol         # ERC-1155（generative 12,000 种组合）
│   ├── AuditEvidenceChain.sol       # 审计证据链
│   ├── test-cases/                  # 17 个测试合约
│   ├── real-world/                  # 真实协议测试数据
│   └── options-index/               # 期权指数测试数据
├── prompts/                         # 系统 prompt
├── frontend/                        # 审计报告前端
├── demo/                            # NFT 预览 + Demo
├── workflows/                       # 开发工作流记录
├── docs/                            # 文档
├── benchmarks/                      # 审计评测
└── foundry.toml                     # Foundry 配置
```

## NFT 审计证书

- 形象：Generative 雅典娜女神（12,000 种 trait 组合）
- 标准：ERC-1155（分级：A/B/C）
- 图像：链上 SVG，6 个 trait 维度动态生成
- 铸造条件：基于 EAS attestation 的审计结果

## 评测标准

### 功能测试（17 个测试合约）
1. Reentrancy — 应检测到并生成 PoC
2. Integer Overflow — 应检测到并建议修复
3. Access Control — 应检测到权限问题
4. Flash Loan Attack — 应生成完整攻击 PoC
5. Safe Contract — 无漏洞，不应误报
6. PriceOracle — 预言机操纵
7. OverflowToken — 溢出代币
8. VulnerableBank — 脆弱银行
9. AgentEscrow — Agent 托管合约
10. AgentIdentity — Agent 身份合约
11. GEVTest — GEV 测试合约
12. PrivacyToken — 隐私代币
13. ReadOnlyReentrancy — 只读重入
14. FlashLoanAttacker — 闪电贷攻击者
15. OracleManipulator — 操纵预言机
16. GovernanceAttack — 治理攻击
17. BridgeExploit — 跨桥攻击

### 对比评测
- GLM-5.1 vs Claude：相同任务，对比审计质量

## 当前阶段

**v5 Demo 流程**
- [x] 构建 athena-audit-skill
- [x] 构建 13 个独立 MCP 工具
- [x] 设计 Generative NFT（12,000 种组合）
- [ ] 部署审计合约到 Sepolia 测试网
- [ ] 跑通 ①→⑧ 完整审计链路
- [ ] GLM-5.1 vs Claude 对比评测
- [ ] 录制 Demo 视频
