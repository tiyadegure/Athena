# GLM Audit Agent — Coding Agent Workflow v5

> v5：整合 v3/v4 全部成果 + 三个新 idea，形成完整 Demo 流程
>
> v4：`workflows/v4-frontier-tech.md`（前沿技术测试合约）
> v3：`workflows/v3-new-ideas.md`（5 个 idea + 前端 + 新技术）
> v2：`workflows/v2-nft-generative.md`（NFT generative trait）
> v1：`workflows/v1-phase1-3.md`（Phase 1-3.3）

---

## 1. 项目目标

构建一个 **Web3 智能合约安全审计 Agent**，驱动模型为 GLM-5.1。

**核心叙事**：GLM-5.1 的长程任务能力

> 别的 AI：读一个合约 → 找一个 bug
> 我们：理解整个协议 → 生成攻击脚本 → 多轮修复验证 → 增量审计 → 链上认证 → 铸造 NFT

**技术栈**：
- **Skill（方法论）**：自建 `glm-audit-skill` — 12 个专项审计 agent 并行扫描
- **MCP（工具链）**：自建 9 个无状态工具
- **驱动模型**：GLM-5.1（200K 上下文 + Interleaved Thinking）
- **链上认证**：EAS attestation + uPEG 风格 generative 雅典娜 NFT（12,000 种组合）

---

## 2. Demo 流程（完整 8 步闭环）

每一步都展示 GLM-5.1 的长程任务能力，v3/v4 的成果全部串联：

```
输入：一个 DeFi 协议目录（10+ 合约）
  ↓
┌─────────────────────────────────────────────────────────┐
│ Step 1: 协议级审计                                       │
│   - 自动发现所有合约，分析调用关系                          │
│   - 12 个 agent 并行扫描（glm-audit-skill）               │
│   - 输出：跨合约漏洞报告（5+ 个 findings）                 │
│   - 展示：理解整个协议架构，不是单合约                      │
│                                                         │
│   v3/v4 产物：contracts/multi-contract/ (Token+Oracle+Vault) │
│   新增：协议级扫描逻辑                                    │
└─────────────────────────────────────────────────────────┘
  ↓
┌─────────────────────────────────────────────────────────┐
│ Step 2: 攻击模拟                                         │
│   - 基于 Step 1 的 findings，选择最严重的漏洞              │
│   - 生成完整端到端 exploit script                         │
│   - 支持：闪电贷+重入+预言机操纵+权限提升                   │
│   - 输出：Foundry .s.sol 脚本，可在 fork 环境执行          │
│   - 展示：不只是找 bug，还能证明 bug 可被利用               │
│                                                         │
│   v3/v4 产物：mcp/tools/exploit_simulator.py              │
│              contracts/test-cases/poc/*.s.sol             │
└─────────────────────────────────────────────────────────┘
  ↓
┌─────────────────────────────────────────────────────────┐
│ Step 3: 多轮修复验证                                      │
│   - Agent 给出修复建议                                    │
│   - 应用修复到合约                                        │
│   - 重新审计修复后的版本                                   │
│   - 对比前后差异（漏洞数、严重性、覆盖面）                   │
│   - 输出：修复验证报告                                     │
│   - 展示：迭代能力，不是一次性的                            │
│                                                         │
│   v3/v4 产物：contracts/test-cases/fixes/Reentrancy-fixed.sol │
│   新增：多轮修复流程逻辑                                   │
└─────────────────────────────────────────────────────────┘
  ↓
┌─────────────────────────────────────────────────────────┐
│ Step 4: 增量审计                                         │
│   - 模拟合约升级（修改 Vault 的某个函数）                   │
│   - Agent 只审计变化部分，复用上次的审计上下文               │
│   - 输出：增量审计报告（只列出新增/变化的 findings）         │
│   - 展示：上下文延续能力，200K 上下文的实际价值              │
│                                                         │
│   新增：增量审计逻辑 + 变化检测                             │
└─────────────────────────────────────────────────────────┘
  ↓
┌─────────────────────────────────────────────────────────┐
│ Step 5: 真实被黑合约验证                                   │
│   - 用 Curve / Hundred Finance 的被黑合约做验证            │
│   - Agent 审计这些合约                                    │
│   - 对比 Agent 的发现与实际攻击路径                         │
│   - 输出：验证报告（Agent 发现了哪些真实漏洞）               │
│   - 展示：Agent 能力经过真实事件验证                        │
│                                                         │
│   v3/v4 产物：contracts/real-world/                       │
│              (curve-pool.sol, hundred-finance.sol)        │
└─────────────────────────────────────────────────────────┘
  ↓
┌─────────────────────────────────────────────────────────┐
│ Step 6: 审计证据链上链                                     │
│   - 前 5 步每步的输入/输出哈希构建 Merkle tree              │
│   - 提交 EAS attestation（含 Merkle root）                │
│   - 任何人都可验证任意中间步骤                              │
│   - 输出：链上 attestation UID                            │
│   - 展示：审计过程完全透明可验证                            │
│                                                         │
│   v3/v4 产物：contracts/AuditEvidenceChain.sol            │
│              mcp/tools/evidence_chain.py                  │
└─────────────────────────────────────────────────────────┘
  ↓
┌─────────────────────────────────────────────────────────┐
│ Step 7: NFT 证书铸造                                      │
│   - 基于 Merkle root 确定 NFT tier（A/B/C）               │
│   - uPEG 风格 generative trait 系统（12,000 种组合）       │
│   - 链上 SVG，雅典娜女神形象                               │
│   - 输出：NFT token ID                                    │
│   - 展示：审计结果的永久链上存证                            │
│                                                         │
│   v3/v4 产物：contracts/AuditCertificate.sol              │
│              demo/nft-preview.html                        │
└─────────────────────────────────────────────────────────┘
  ↓
┌─────────────────────────────────────────────────────────┐
│ Step 8: 前端展示                                         │
│   - 极简 Web 界面（纯文字+细线框+monospace）               │
│   - 展示完整审计流程：findings → verification → attestation │
│   - MetaMask 连接，一键铸造 NFT                           │
│   - 展示：产品完整度                                      │
│                                                         │
│   v3/v4 产物：frontend/ (index.html + style.css + app.js) │
└─────────────────────────────────────────────────────────┘
```

---

## 3. v3/v4 产物对应表

每一样东西都在 Demo 流程中有明确位置：

| v3/v4 产物 | 对应 Demo Step | 展示能力 |
|-----------|---------------|---------|
| `contracts/multi-contract/` | Step 1 协议级审计 | 跨合约理解 |
| `mcp/tools/exploit_simulator.py` | Step 2 攻击模拟 | 端到端攻击链 |
| `contracts/test-cases/poc/*.s.sol` | Step 2 攻击模拟 | exploit 脚本生成 |
| `contracts/test-cases/fixes/` | Step 3 多轮修复 | 迭代验证 |
| `contracts/real-world/` | Step 5 真实验证 | 真实漏洞发现 |
| `contracts/AuditEvidenceChain.sol` | Step 6 证据链 | 每步可验证 |
| `mcp/tools/evidence_chain.py` | Step 6 证据链 | Merkle 聚合 |
| `mcp/tools/halmos_runner.py` | Step 1 协议级审计 | 形式化验证 |
| `contracts/AuditCertificate.sol` | Step 7 NFT 铸造 | 链上存证 |
| `demo/nft-preview.html` | Step 8 前端 | NFT 预览 |
| `frontend/` | Step 8 前端 | 产品完整度 |
| `contracts/test-cases/ReadOnlyReentrancy.sol` | Step 5 真实验证 | 新型攻击向量 |
| `contracts/options-index/` | Step 1 协议级审计 | 复杂数学理解 |

---

## 4. 新增内容（Phase 5）

### 4.1 协议级审计扫描逻辑

**目标**：自动发现目录下所有合约，分析调用关系，生成调用图。

**实现**：
- 输入：一个目录路径
- 自动发现所有 .sol 文件
- 分析 import、调用关系，生成 call graph
- 识别跨合约攻击面
- 输出：协议架构图 + 跨合约漏洞报告

**新增文件**：
```
mcp/tools/protocol_scanner.py              # 协议级扫描 MCP 工具
```

---

### 4.2 多轮修复验证

**目标**：Agent 审计 → 给建议 → 审计修复后版本 → 对比差异。

**流程**：
1. 初始审计，输出 findings
2. 生成修复建议（代码 diff）
3. 应用修复
4. 重新审计
5. 对比前后：漏洞数、严重性、覆盖面

**新增文件**：
```
mcp/tools/repair_validator.py              # 修复验证 MCP 工具
```

---

### 4.3 增量审计

**目标**：合约升级后只审变化部分，复用上次审计上下文。

**流程**：
1. 对比新旧合约代码，检测变化
2. 加载上次审计上下文（200K 上下文的实际价值）
3. 只审计变化部分 + 受影响的调用链
4. 输出：增量审计报告

**新增文件**：
```
mcp/tools/incremental_auditor.py           # 增量审计 MCP 工具
contracts/multi-contract/Vault-v2.sol      # 升级版 Vault（用于增量审计演示）
```

---

### 4.4 前沿技术测试合约（v4 已完成）

| 优先级 | 技术 | 状态 |
|--------|------|------|
| P0 | 期权合成资产 (Vitalik) | ✅ 完成 |
| P0 | pERC20 隐私代币 | ✅ 完成 |
| P0 | Agent-to-Agent Escrow | ✅ 完成 |
| P1 | GEV 分析器 | ✅ 完成 |
| P1 | Agent Identity | ✅ 完成 |
| P1 | Multi-Party Block | ⬜ 待实现 |
| P2 | Cross-Domain Sync | ⬜ 待实现 |
| P2 | Governance Verification | ⬜ 待实现 |

---

## 5. 实施优先级

| 优先级 | 任务 | 预估时间 | 理由 |
|--------|------|---------|------|
| P0 | 协议级扫描逻辑 | 2 天 | Demo Step 1 核心 |
| P0 | 多轮修复验证 | 2 天 | Demo Step 3 核心 |
| P0 | 增量审计 | 2 天 | Demo Step 4 核心，展示 200K 上下文价值 |
| P0 | 期权合成资产 | 3 天 | Vitalik 最新，展示复杂数学理解 |
| P1 | pERC20 隐私代币 | 2 天 | EIP Draft，隐私赛道热点 |
| P1 | Agent Escrow | 1 天 | AI Agent 叙事核心 |
| P1 | GEV 分析器 | 2 天 | MEV 安全新框架 |
| P2 | 其他前沿测试合约 | 5 天 | 扩展覆盖面 |
| P2 | AI Agent Standards 文档 | 1 天 | 标准集成 |

**总预估时间**：20 天（还有 21 天，buffer 1 天）

---

## 6. MCP 工具清单（完整）

| 工具 | 功能 | 来源 |
|------|------|------|
| `slither_runner.py` | 静态分析 | Phase 1 |
| `aderyn_runner.py` | Rust 静态分析 | Phase 1 |
| `poc_generator.py` | PoC 生成 | Phase 1 |
| `fuzz_runner.py` | Foundry fuzz 测试 | Phase 1 |
| `knowledge_base.py` | RAG 知识库 | Phase 1 |
| `eas_attest.py` | EAS 链上认证 | Phase 1 |
| `exploit_simulator.py` | 攻击模拟器 | v3 |
| `evidence_chain.py` | 审计证据链 | v3 |
| `halmos_runner.py` | 形式化验证 | v3 |
| `protocol_scanner.py` | 协议级扫描 | v5 新增 ✅ |
| `repair_validator.py` | 修复验证 | v5 新增 ✅ |
| `incremental_auditor.py` | 增量审计 | v5 新增 ✅ |

---

## 7. 技术参考

| 资源 | 日期 | 用途 |
|------|------|------|
| Vitalik 期权论文 | 2026-06-01 | Idea 10 |
| EIP-8287 pERC20 | 2026-06-03 | 隐私代币 |
| Agent Escrow EIP | 2026-06-05 | AI Agent 托管 |
| GEV 框架 | 2026-05-25 | MEV 新理论 |
| Multi-Party Block | 2026-05-27 | MEV 基础设施 |
| Cross-Domain Sync | 2026-06-02 | 跨链安全 |
| Governance Verification | 2026-06-07 | 治理安全 |
| Vitalik 形式化验证 | 2026-05-18 | Halmos 集成 |
| OCP v1.0.0 | 2026-04-06 | 链上认证 |
| ERC-8004+8263 | 2026-05-28 | AI Agent 标准 |

---

## 8. 开发约束

1. **测试网 Only** — Sepolia，不消耗真实 ETH
2. **先验证再报告** — 每个漏洞必须有 PoC 或 fuzz 验证
3. **工具独立** — 每个 MCP 工具无状态
4. **阶段性提交** — 每完成一个功能点就 git commit + push
5. **所有工具自建** — 不依赖第三方项目归属
6. **前端极简** — 禁止 emoji、大面积色块、JS 框架
7. **v3/v4 产物必须展示** — 每一样东西都在 Demo 流程中有位置
