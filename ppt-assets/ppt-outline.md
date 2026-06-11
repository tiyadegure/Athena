Athena 黑客松 PPT 大纲（10 页）
================================

Slide 1 — 封面
---------------
标题：Athena
副标题：基于 GLM-5.1 长程任务能力的 Web3 安全审计闭环
赛道：Z.AI
团队：Tiya Degurechaff
素材：frontend/images/nft-s-tier.png (S 级 NFT 证书)
      frontend/images/avatar.png (品牌头像)

---

Slide 2 — 问题
---------------
标题：Web3 安全审计的现状

- 人工审计：慢（2-4周）、贵（$5万+）、易遗漏
- AI 审计：单步推理、无链上验证、无证据链
- Agent 经济雏形：AI Agent 可以自主完成审计，但缺乏闭环

核心问题：如何让 AI Agent 完成从漏洞发现到链上认证的完整闭环？

---

Slide 3 — 核心创新：GLM-5.1 长程任务能力
------------------------------------------
标题：为什么是 GLM-5.1？

普通 LLM（单步推理）：
- 需要多次人工介入
- 无法跨步骤传递上下文
- 无法协调多个工具

GLM-5.1（长程推理）：
- ✅ 单次会话完成 8 步审计闭环
- ✅ 200K 上下文，跨步骤记忆
- ✅ 协调 13 个 MCP 工具
- ✅ 驱动 12 个并行 Agent

对比：GLM-5.1 vs Claude（评测数据）

---

Slide 4 — 架构总览
-------------------
标题：8 步审计闭环架构
素材：ppt-assets/architecture.svg

核心组件：
- GLM-5.1 推理引擎（中央协调）
- 12 Agent 审计 Skill（并行执行）
- 13 MCP 工具（链上+链下）
- Sepolia 测试网（零成本验证）

---

Slide 5 — Agent 生产：12 Agent 审计 Skill
-----------------------------------------
标题：Agent 如何自主审计？
素材：ppt-assets/skill-agents.svg

12 个 Agent 并行执行：
- 4 基础分析（Scope、Architecture、Access Control、Math）
- 4 漏洞猎手（Reentrancy、Oracle、Flash Loan、Logic）
- 4 辅助/输出（Gas、Frontend、PoC、Report）

10 轮检查流程，GLM-5.1 协调

---

Slide 6 — Agent 工具：13 MCP 工具
-----------------------------------
标题：Agent 的工具链
素材：ppt-assets/mcp-tools.svg

4 大类：
- 静态分析（Slither + Aderyn + Halmos）
- 攻击模拟（PoC + Exploit + Fuzz）
- 链上操作（EAS + Evidence Chain）
- 高级功能（Protocol Scanner + Repair + Incremental + GEV）

---

Slide 7 — Agent 认证：审计报告 + 链上验证
-----------------------------------------
标题：Agent 的产出
素材：ppt-assets/audit-report.svg
      ppt-assets/onchain-verification.svg

真实审计报告（demo/report.json — DeFi Protocol on Sepolia）：
- 5 个漏洞发现（1 Critical + 2 High + 1 Medium + 1 Low）
- 审计评分：2/10
- 审计者：GLM-5.1 + Athena Audit Engine
- 测试通过：30/30 (Foundry)
- 报告结构：meta → target → summary → findings → verification

链上认证（EAS on Sepolia）：
- Schema UID: 0x6d6520d928b6090172a458c2addcd30af1090f5298110e496bb3c9ac3918253e
- Attestation UID: 0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9
- EAS 链接: https://sepolia.easscan.org/attestation/view/0xd02800c9...
- Status: Valid ✅ | Revocable: Yes | Expiration: Never

---

Slide 8 — Agent 铸造：Seed-based Generative NFT 证书
-------------------------------------------------------
标题：Agent 的经济产出
素材：frontend/images/nft-s-tier.png (S 级 NFT 特写)
      frontend/images/nft-all-tiers.png (四级对比)


uPEG 启发 Seed-based Generative 雅典娜：
- uint256 18-bit seed → 9 traits x 2 bits → 4^9 = 262,144 种组合
- 动态稀有度：OpenRarity Information Content 算法
- S/A/B/C 四级：分数 → 稀有度等级自动映射
- SVG 缓存机制：首次生成后存储，减少 gas

链上验证（Sepolia）：
- NFT 合约: 0x3247d57d37bd1878479f03a077aba807649dbaf5
- Etherscan: https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5
- EAS 认证 + ERC-1155 NFT
- uri() 返回完整 JSON+SVG（含 9 个 trait attributes）
- Gold NFT 已铸造给 deployer 钱包

---

Slide 9 — Agent 经济雏形
--------------------------
标题：Agent 经济的完整闭环

当前模式（人类触发）：
1. 项目方提交合约 → Agent 自主审计
2. 审计完成 → 结果自动上链（EAS）
3. NFT 自动铸造给项目方
4. 项目方支付费用

未来模式（Agent 自主）：
1. Agent 监控链上新合约 → 自动审计
2. 审计完成 → 结果自动上链
3. NFT 自动铸造 → 挂单 OpenSea
4. 收入自动进入 Agent 钱包
5. Agent 用收入购买其他 Agent 服务

这是 Web3 Agent 经济的雏形。

---

Slide 10 — 总结 & Roadmap
---------------------------
标题：Athena 的价值

核心价值：
- GLM-5.1 长程任务能力 → Agent 可以自主完成复杂任务
- Web3 审计闭环 → Agent 经济的完整展示
- 链上认证 → Agent 产出可验证、可交易

已验证的链上产物：
- NFT 合约: 0x3247d57d (Sepolia) ✅
- EAS Attestation: 0xd02800c9... ✅
- Gold NFT: Token ID 1 ✅
- 测试: 30/30 passing ✅
- Landing Page: https://athena.degure.me ✅
- 审计报告: demo/report.json ✅

Roadmap：
- ZK 隐私审计（v2）
- 多链部署（Ethereum、Base、Arbitrum）
- Agent 审计市场（Agent ↔ Agent 交易）
- 真实协议审计（Curve、Aave）

感谢 Z.AI 赛道支持！

---

联系我们：
- GitHub: https://github.com/tiyadegure/glm-code
- X/Twitter: https://x.com/AthenaAudit
- Landing Page: https://athena.degure.me
- EAS Attestation: https://sepolia.easscan.org/attestation/view/0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9
- NFT 合约: https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5

---

## v8 Workflow 产物清单

| 产物 | 路径 | 说明 |
|------|------|------|
| 审计报告 | `demo/report.json` | 完整 JSON 审计报告（5 findings） |
| 测试结果 | `ppt-assets/test-results.txt` | 30/30 通过 |
| Landing Page | `frontend/landing.html` | 极简黑底白字 + 品牌头像 |
| 前端应用 | `frontend/index.html` + `app.js` + `style.css` | 审计报告展示 + 钱包连接 + NFT 铸造 |
| NFT 预览 | `frontend/nft-preview.html` | S/A/B/C 四级 SVG 预览 |
| 架构图 | `ppt-assets/architecture.svg` | 系统架构 |
| MCP 工具图 | `ppt-assets/mcp-tools.svg` | 13 个工具 |
| Skill 图 | `ppt-assets/skill-agents.svg` | 12 个 agents |
| 审计报告图 | `ppt-assets/audit-report.svg` | 报告结构 |
| 链上验证图 | `ppt-assets/onchain-verification.svg` | 验证流程 |
| 品牌头像 | `frontend/images/avatar.png` | 希腊战士 Athena |
| S 级 NFT | `frontend/images/nft-s-tier.png` | S-TIER 特写 |
| NFT 全览 | `frontend/images/nft-all-tiers.png` | 四级对比 |
