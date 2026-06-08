# GLM Audit Agent — Coding Agent Workflow v2

> v2 更新：Skill 重命名、NFT 升级为 generative trait、MCP 工具自建。
>
> v1 历史：`workflows/v1-phase1-3.md`（Phase 1-3.3 已完成）

---

## 1. 项目目标

构建一个 **Web3 智能合约安全审计 Agent**，驱动模型为 GLM-5.1。

核心卖点：
- **Skill（方法论）**：自建 `glm-audit-skill` — 12 个专项审计 agent 并行扫描
- **MCP（工具链）**：自建 6 个无状态工具（slither, PoC, fuzz, RAG, EAS）
- **长程任务**：GLM-5.1 的 200K 上下文 + Interleaved Thinking，驱动 8 步审计闭环
- **链上认证**：EAS attestation + uPEG 风格 generative 雅典娜 NFT（12,000 种组合）

一句话描述：
> "自建 MCP 工具链同时拥有 RAG 知识库、PoC 生成、Foundry fuzz 验证和 EAS 链上认证，配合 GLM-5.1 的长程能力驱动从漏洞发现到链上证书的完整闭环。"

---

## 2. 当前进度

- [x] 竞品调研（20 个项目）
- [x] 项目规划与技术选型
- [x] GLM-5.1 技术特征调研
- [x] 测试方案设计
- [x] Phase 1：集成 glm-audit-skill + 自建 MCP 工具
- [x] Phase 2：搭建测试环境（5 个测试合约）
- [x] Phase 3.1：安装工具链（slither, forge, aderyn）
- [x] Phase 3.2：验证 MCP 工具
- [x] Phase 3.3：端到端审计验证（Reentrancy.sol 完整闭环）
- [x] Phase 3.4：NFT 合约初版（AuditCertificate.sol）
- [ ] Phase 3.5：NFT 升级为 uPEG 风格 generative trait ⬅️ 当前
- [ ] Phase 4：GLM-5.1 评测 + Demo 录屏

---

## 3. Phase 3.5：NFT Generative Trait 升级

### 3.1 改动范围

需要重写的文件：
- `contracts/AuditCertificate.sol` — 重写 SVG 生成逻辑
- `contracts/test/AuditCertificate.t.sol` — 更新测试

不需要改的文件：
- `mcp/tools/*` — MCP 工具不变
- `contracts/test-cases/*` — 测试合约不变
- `skills/glm-audit-skill/*` — Skill 不变（已重命名）

### 3.2 Skill 目录结构（已重命名）

```
skills/glm-audit-skill/
├── SKILL.md                              # 主 Skill 文件
├── references/
│   ├── audit-agents/                     # 12 个专项审计 agent（原 hacking-agents）
│   │   ├── shared-rules.md
│   │   ├── access-control-agent.md
│   │   ├── asymmetry-agent.md
│   │   ├── boundary-agent.md
│   │   ├── economic-security-agent.md
│   │   ├── execution-trace-agent.md
│   │   ├── first-principles-agent.md
│   │   ├── flow-gap-agent.md
│   │   ├── invariant-agent.md
│   │   ├── math-precision-agent.md
│   │   ├── numerical-gap-agent.md
│   │   ├── periphery-agent.md
│   │   └── trust-gap-agent.md
│   ├── judging.md
│   ├── report-formatting.md
│   └── senior-auditor-sop.md
```

### 3.3 Generative Trait 系统

详见 v1 文档 Section 9.2。核心参数：

| 维度 | 选项数 | 描述 |
|------|--------|------|
| 🪖 头盔 | 5 | 羽饰/双角/冠冕/头巾/经典 |
| 🛡️ 盾牌 | 5 | 猫头鹰/蛇发/橄榄枝/闪电/空白 |
| 🎨 主色 | 8 | 金/银/铜/紫/绿/蓝/红/黑 |
| ⚔️ 武器 | 3 | 长矛/弓箭/剑 |
| 🌌 背景 | 5 | 星空/火焰/海洋/森林/极光 |
| 👁️ 眼睛 | 4 | 蓝/绿/金/红 |

组合数：12,000 种独特雅典娜。

### 3.4 实现步骤

1. **`_selectTraits(bytes32 attestationUID)`** — keccak256 哈希确定性选择 6 个 trait
2. **`_colorScheme(uint8 colorId)`** — 8 色映射 (primary/secondary/accent)
3. **6 个图层函数**：
   - `_svgBackground(uint8 bg, string primary)` — 5 种背景
   - `_svgBody(string primary, string secondary)` — 身体+长袍
   - `_svgHelmet(uint8 style, string primary, string accent)` — 5 种头盔
   - `_svgShield(uint8 pattern, string primary, string secondary)` — 5 种盾牌
   - `_svgWeapon(uint8 type, string primary, string accent)` — 3 种武器
   - `_svgEyes(uint8 color, string primary)` — 4 种眼睛
4. **`_generateAthenaSVG()`** — 组合所有图层
5. **`_rarityScore()`** — 稀有度计算
6. **更新 `uri()`** — 返回完整 attributes JSON
7. **存储 trait 到链上** — `mapping(bytes32 => TraitData)`
8. **测试** — 不同 UID 生成不同雅典娜，同一 UID 生成相同雅典娜

### 3.5 合约关键改动

```solidity
// 新增 trait 数据结构
struct TraitData {
    uint8 helmet;
    uint8 shield;
    uint8 color;
    uint8 weapon;
    uint8 background;
    uint8 eyes;
    uint256 rarityScore;
}

// 铸造时存储 trait
mapping(bytes32 => TraitData) public traitData;

// mintCertificate 中新增：
TraitData memory traits = _selectTraits(attestationUID);
traitData[attestationUID] = traits;
```

### 3.6 完成标准

- [ ] 合约编译通过（`forge build`）
- [ ] 所有测试通过（`forge test`）
- [ ] 12,000 种组合 — 不同 UID 生成不同雅典娜
- [ ] 每个 trait 维度至少 3 种有明显视觉差异的 SVG 图层
- [ ] 稀有度计算正确
- [ ] uri() 返回完整 JSON metadata（含所有 trait attributes）
- [ ] EAS 验证逻辑正确
- [ ] 防重复铸造生效

---

## 4. Phase 4：评测与 Demo（下一阶段）

### 4.1 GLM-5.1 评测

```bash
export GLM_API_KEY="your...nexport GLM_ENDPOINT="https://api.z.ai/api/coding/paas/v4"
# 对 5 个测试合约执行审计，记录结果
```

### 4.2 录屏 Demo

1. 展示项目架构（Skill + MCP + GLM-5.1）
2. 对一个合约执行完整审计流程
3. 展示 EAS attestation（Etherscan）
4. 展示铸造的 generative NFT（OpenSea 测试网）

### 4.3 评测指标

| 指标 | 目标 |
|------|------|
| 漏洞检测率 | ≥ 90%（4/5 正确检测） |
| 误报率 | 0%（SafeContract 不误报） |
| PoC 可执行率 | ≥ 75%（3/4 能触发漏洞） |
| 完整闭环 | Step 1-8 全流程 |

---

## 5. 技术参考

| 资源 | 用途 |
|------|------|
| Foundry Book | 合约测试框架 |
| EAS Docs | 链上认证 |
| OpenZeppelin | ERC-1155 参考 |
| GLM-5.1 论文 (arxiv:2602.15763) | 模型技术细节 |
| Z.AI API | API 接入 |
| Damn Vulnerable DeFi | 测试用例参考 |

---

## 6. 开发约束

1. **测试网 Only** — Sepolia，不消耗真实 ETH
2. **先验证再报告** — 每个漏洞必须有 PoC 或 fuzz 验证
3. **工具独立** — 每个 MCP 工具无状态，不把 LLM 调用放进工具里
4. **阶段性提交** — 每完成一个功能点就 git commit + push
5. **所有工具自建** — 不依赖第三方项目归属
