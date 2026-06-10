Athena 黑客松 PPT 大纲（10 页）
================================

Slide 1 — 封面
---------------
标题：Athena
副标题：基于 GLM-5.1 长程任务能力的 Web3 安全审计闭环
赛道：Z.AI
团队：Tiya Degurechaff

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
素材：architecture.svg

核心组件：
- GLM-5.1 推理引擎（中央协调）
- 12 Agent 审计 Skill（并行执行）
- 13 MCP 工具（链上+链下）
- Sepolia 测试网（零成本验证）

---

Slide 5 — Agent 生产：12 Agent 审计 Skill
-----------------------------------------
标题：Agent 如何自主审计？
素材：skill-agents.svg

12 个 Agent 并行执行：
- 4 基础分析（Scope、Architecture、Access Control、Math）
- 4 漏洞猎手（Reentrancy、Oracle、Flash Loan、Logic）
- 4 辅助/输出（Gas、Frontend、PoC、Report）

10 轮检查流程，GLM-5.1 协调

---

Slide 6 — Agent 工具：13 MCP 工具
-----------------------------------
标题：Agent 的工具链
素材：mcp-tools.svg

4 大类：
- 静态分析（Slither + Aderyn + Halmos）
- 攻击模拟（PoC + Exploit + Fuzz）
- 链上操作（EAS + Evidence Chain）
- 高级功能（Protocol Scanner + Repair + Incremental + GEV）

---

Slide 7 — Agent 认证：审计报告 + 链上验证
-----------------------------------------
标题：Agent 的产出
素材：audit-report.svg + frontend-screenshot.png

审计报告示例（DeFi Protocol）：
- 5 个漏洞发现（1 Critical + 2 High + 1 Medium + 1 Low）
- 攻击模拟：$2.3M 预计损失
- PoC 验证：Foundry 256 runs

链上认证（EAS）：
- 不可篡改
- 可验证
- 可追溯

---

Slide 8 — Agent 铸造：Generative NFT 证书
------------------------------------------
标题：Agent 的经济产出
素材：nft-preview-full.png

uPEG 风格 Generative 雅典娜：
- 12,000 种 trait 组合
- 3 等级：Gold（Critical）/ Silver（High）/ Bronze（Medium）
- 链上 SVG，6 个 trait 维度

铸造条件：
- Agent 完成审计 → 结果上链 → 自动触发铸造
- 人类仅需确认一次（未来可完全自动化）

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

Roadmap：
- ZK 隐私审计（v2）
- 多链部署（Ethereum、Base、Arbitrum）
- Agent 审计市场（Agent ↔ Agent 交易）
- 真实协议审计（Curve、Aave）

感谢 Z.AI 赛道支持！
