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
- 多链部署：Sepolia + Base Sepolia（零成本验证）

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

真实协议审计结果：

Curve V2 — Read-Only Reentrancy（$70M 损失, 2023）
- Agent 发现：5 个漏洞（1 Critical + 2 High + 1 Medium + 1 Low）
- 匹配率：95%（与实际攻击路径高度吻合）
- 根因：addLiquidity callback → getVirtualPrice() stale

Hundred Finance — Reentrancy + Oracle Manipulation（$7M 损失, 2023）
- Agent 发现：4 个漏洞（1 Critical + 2 High + 1 Medium）
- 匹配率：88%
- 根因：CToken.redeem() external call + spot price oracle flash-loan

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

链上验证（多链）：
- Sepolia NFT: 0x3247d57d37bd1878479f03a077aba807649dbaf5
- Base Sepolia NFT: 0xb8f167a84816b5b9373997337119a2186c6e3708
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

已完成：
- ✅ ZK 可验证审计（AuditTrail + Groth16Verifier）
- ✅ 多链部署（Sepolia + Base Sepolia，共 9 个合约）
- ✅ 真实协议审计（Curve V2 $70M + Hundred Finance $7M）
- ✅ Agent Escrow v2（EAS 自动释放）
- ✅ ERC-7512 审计元数据标准

Roadmap：
- Agent 审计市场（Agent ↔ Agent 交易）
- 隐私审计模式（加密合约 → 审计 → 解锁）
- 真实协议扩展（Euler $197M, Aave, Balancer）

感谢 Z.AI 赛道支持！

---

联系我们：
- GitHub: https://github.com/tiyadegure/Athena
- X/Twitter: https://x.com/AthenaAudit
- Landing Page: https://athena.degure.me
- EAS Attestation: https://sepolia.easscan.org/attestation/view/0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9
- NFT (Sepolia): https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5
- NFT (Base): https://sepolia.basescan.org/address/0xb8f167a84816b5b9373997337119a2186c6e3708

---

---

## 扩展功能（已完成）

### Slide 11 — ZK 可验证审计 + Agent Escrow

标题：Athena — 可验证审计 + Agent 自主交易

已完成：
- ZK 可验证审计：AuditTrail + Groth16Verifier（链上 ZK proof 验证）
- Agent Escrow v2：EAS 自动释放托管（审计完成 → 自动付款）
- ERC-7512 审计元数据标准（链上可查询）
- 真实协议审计（Curve V2 + Hundred Finance）

合约（Sepolia）：
- AgentEscrowV2: 0x7102b7252dea80529278c8bffc441b96ff24421e
- ERC7512AuditMetadata: 0x0dd8f8f5b755912aa3b955044d1eff496a65e657
- AuditTrail (ZK): 0xd7913e7749595a9238883bdf0b2dad599f4d0bf0
- Groth16Verifier: 0xf0c9ec42fe603a53af3e6248e874bbbb3064e498

合约（Base Sepolia）：
- AuditCertificate: 0xb8f167a84816b5b9373997337119a2186c6e3708
- ERC7512AuditMetadata: 0x5e99f144d3e512f525d24077d4626a064899e177
- AuditTrail (ZK): 0x83bfbc0901c9a6481a26ec2dc649487768ec8a99
- Groth16Verifier: 0x636b3af9630e1b26b02ba488a5b8ab6ce75d6721

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
