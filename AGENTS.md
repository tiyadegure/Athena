# GLM Audit Agent 项目规范

## 项目目标

构建基于 GLM-5.1 的 Web3 智能合约安全审计 Agent，实现从漏洞发现到链上认证的完整闭环。

## 核心工作流

审计任务链（8 步）：
1. 需求理解 → 2. 双引擎扫描 (Slither+Aderyn) → 3. RAG 知识增强 → 4. PoC 生成 → 5. Foundry fuzz 验证 → 6. 修复建议 → 7. EAS 上链认证 → 8. 铸造雅典娜 NFT 证书

## 技术架构

### Skill（方法论）
- **pashov solidity-auditor** — 业界最认可的审计方法论
- 10 轮检查流程：scope → architecture → access control → math → ... → report
- GitHub: [pashov/skills](https://github.com/pashov/skills)

### MCP（工具链）
从 AuditAI 拆解出的独立工具：
- `slither` — 静态分析
- `aderyn` — Rust 重写的静态分析
- `poC` — PoC 生成
- `concrete_execution` — Foundry fuzz 测试
- `knowledge_base` — 漏洞知识库 (ChromaDB)
- `eas` — EAS 链上认证

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
├── skills/                          # pashov 审计 skill
├── mcp/                             # 工具 MCP 服务
├── contracts/                       # 合约（NFT + 测试用例）
├── benchmarks/                      # 审计评测
└── demo/                            # Demo 录屏
```

## NFT 审计证书

- 形象：uPEG 像素风雅典娜女神
- 标准：ERC-1155（分级：A/B/C）
- 图像：链上 SVG，金色/银色/铜色主题
- 铸造条件：基于 EAS attestation 的审计结果

## 评测标准

### 功能测试（5 个测试合约）
1. Reentrancy — 应检测到并生成 PoC
2. Integer Overflow — 应检测到并建议修复
3. Access Control — 应检测到权限问题
4. Flash Loan Attack — 应生成完整攻击 PoC
5. Safe Contract — 无漏洞，不应误报

### 对比评测
- GLM-5.1 vs Claude：相同任务，对比审计质量

## 当前阶段

**Phase 1：集成 Skill 与工具**
- [ ] 集成 pashov solidity-auditor skill
- [ ] 从 AuditAI 拆解独立工具 MCP
- [ ] 配置开发环境
