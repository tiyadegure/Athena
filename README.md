# GLM Audit Agent

**Web3 智能合约安全审计 Agent** — 基于 GLM-5.1 长程任务能力，结合 pashov 方法论与自建 MCP 工具链，实现从漏洞发现到链上认证的完整闭环。

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
8. **铸造 NFT 证书** — 雅典娜女神像素风 NFT（ERC-1155 分级：A/B/C）

## 技术栈

| 组件 | 来源 | 作用 |
|------|------|------|
| **GLM-5.1** | Z.AI Coding Plan | 驱动 Agent，处理长程任务 |
| **pashov solidity-auditor skill** | pashov/skills | 审计方法论（10 轮检查流程） |
| **MCP 工具链** | 自建 | PoC 生成、fuzz 测试、知识库、EAS 认证 |
| **Foundry** | foundry-rs | 合约编译、测试、fuzz |
| **EAS** | Ethereum Attestation Service | 链上审计认证 |
| **ERC-1155** | OpenZeppelin | 分级 NFT 审计证书 |

## 项目结构

```
glm-code/
├── PLAN.md                          # 项目计划与执行步骤
├── TESTING-PLAN.md                  # 测试方案
├── GLM-5.1-TECHNICAL-PROFILE.md     # GLM-5.1 技术特征
├── smart-contract-audit-agents-comparison.md  # 竞品调研（20 个项目）
├── skills/                          # pashov 审计 skill
├── mcp/                             # MCP 工具服务（自建）
├── contracts/                       # NFT 合约 + 测试合约
├── benchmarks/                      # 审计评测
└── demo/                            # Demo 录屏素材
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
- **测试网**：Sepolia 测试网，无需真实发币

## 审计证书 NFT

铸造条件基于审计结果分级：

| 等级 | 条件 | NFT |
|------|------|-----|
| **A 级** | 发现严重漏洞 + PoC 验证通过 | 金雅典娜 |
| **B 级** | 发现中等漏洞 + 修复建议 | 银雅典娜 |
| **C 级** | 完成基本扫描 + 报告 | 铜雅典娜 |

图像风格：uPEG 像素独角兽底图 + 雅典娜女神形象。

## 竞品对比

详见 [smart-contract-audit-agents-comparison.md](./smart-contract-audit-agents-comparison.md)

核心优势：**自建 MCP 工具链同时拥有 RAG 知识库、PoC 生成、Foundry fuzz 验证和 EAS 链上认证，配合 GLM-5.1 的长程能力驱动从漏洞发现到链上证书的完整闭环。**

## 路线图

- [x] 竞品调研（20 个项目）
- [x] 项目规划与技术选型
- [ ] Phase 1：集成 Skill 与工具
- [ ] Phase 2：搭建测试环境
- [ ] Phase 3：开发与调试
- [ ] Phase 4：评测与 Demo

## 许可证

MIT License
