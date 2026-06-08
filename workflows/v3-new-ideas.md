# GLM Audit Agent — Coding Agent Workflow v3

> v3：新增 5 个 idea + 前端设计 + 最新区块链技术集成
>
> v2：`workflows/v2-nft-generative.md`（NFT generative trait）
> v1：`workflows/v1-phase1-3.md`（Phase 1-3.3）

---

## 1. 项目目标

构建一个 **Web3 智能合约安全审计 Agent**，驱动模型为 GLM-5.1。

核心卖点：
- **Skill（方法论）**：自建 `glm-audit-skill` — 12 个专项审计 agent 并行扫描
- **MCP（工具链）**：自建 6 个无状态工具（slither, PoC, fuzz, RAG, EAS）
- **长程任务**：GLM-5.1 的 200K 上下文 + Interleaved Thinking，驱动 8 步审计闭环
- **链上认证**：EAS attestation + uPEG 风格 generative 雅典娜 NFT（12,000 种组合）
- **攻击模拟器**：端到端 exploit script 生成（多步骤、跨合约、含 fork 部署）
- **审计前端**：极简 Web 界面展示审计结果 + NFT 铸造

---

## 2. 当前进度

- [x] Phase 1：集成 glm-audit-skill + 自建 MCP 工具
- [x] Phase 2：搭建测试环境（5 个测试合约）
- [x] Phase 3：端到端审计验证 + NFT generative trait
- [ ] Phase 4：5 个新 idea 实现
- [ ] Phase 5：GLM-5.1 评测 + Demo 录屏

---

## 3. Phase 4：5 个新 Idea

### Idea 1：多合约审计（Multi-Contract Protocol Audit）

**目标**：不只审计单个 .sol 文件，而是整个 DeFi 协议的全套合约。

**实现**：
- 输入：一个目录（如 `contracts/uniswap-v2/`）
- Agent 自动发现所有合约文件，分析合约间的调用关系
- 生成调用图（call graph），识别跨合约攻击面
- 输出：跨合约漏洞报告（如"合约 A 的函数 X 调用合约 B 的函数 Y，但 B 未验证 A 的权限"）

**测试用例**：
- 准备一个多合约项目（2-3 个互相调用的合约）
- 预期：能检测到跨合约权限问题和重入

**新增文件**：
```
contracts/multi-contract/
├── Vault.sol           # 金库合约（调用 Oracle）
├── Oracle.sol          # 价格预言机（被 Vault 调用）
├── Token.sol           # ERC20 代币
└── expected-results.json
```

---

### Idea 3：攻击模拟器（Exploit Simulator）

**目标**：不只是生成单个 PoC，而是生成完整的端到端攻击脚本。

**与现有 PoC 生成的区别**：

| | 现有 PoC 生成 | 攻击模拟器 |
|---|---|---|
| 范围 | 单合约单漏洞 | 多步骤攻击链 |
| 输出 | Foundry 测试 | Foundry script（含 fork 部署） |
| 场景 | 单一漏洞 | 组合攻击（闪电贷+重入+价格操纵） |
| 验证 | `forge test` | `forge script --fork-url mainnet` |
| 利润计算 | 无 | 自动计算攻击者利润 |

**实现**：
- MCP 工具：`mcp/tools/exploit_simulator.py`
- 输入：审计报告（漏洞列表）+ 合约地址
- 输出：完整的 Foundry exploit script
- 攻击模板库：
  - 闪电贷 + 价格操纵
  - 重入 + 资金提取
  - 权限提升 + 合约接管
  - 预言机操纵 + 清算套利

**测试用例**：
- 用 Reentrancy.sol 生成完整攻击脚本
- 用 FlashLoan.sol 生成闪电贷攻击脚本
- 预期：`forge script` 能在 fork 环境中执行成功

**新增文件**：
```
mcp/tools/exploit_simulator.py
contracts/test-cases/poc/FlashLoanExploit.s.sol
contracts/test-cases/poc/ReentrancyExploit.s.sol
```

---

### Idea 4：审计报告 Web 前端

**目标**：极简 Web 界面，展示审计结果 + NFT 铸造入口。

**设计约束**：
- **禁止 emoji**
- **禁止大面积色块**
- 风格：纯文字 + 细线框 + 单色调（黑/白/灰）
- 字体：等宽字体（monospace）
- 布局：单栏，信息密度高

**页面结构**：

```
┌─────────────────────────────────────────┐
│ GLM AUDIT                               │
│ Smart Contract Security Analysis        │
├─────────────────────────────────────────┤
│                                         │
│ CONTRACT: VulnerableBank.sol            │
│ STATUS:   1 Critical · 0 High · 0 Med  │
│ SCORE:    2/10                           │
│                                         │
│ ─────────────────────────────────────── │
│                                         │
│ FINDING #1                              │
│ Reentrancy in withdraw()                │
│ Confidence: 95                          │
│ Severity:   Critical                    │
│                                         │
│ Contract: VulnerableBank                │
│ Function: withdraw()                    │
│ Location:   line 14-18                  │
│                                         │
│ The withdraw() function sends ETH       │
│ before updating balances...             │
│                                         │
│ [View PoC]  [View Fix]                  │
│                                         │
│ ─────────────────────────────────────── │
│                                         │
│ VERIFICATION                            │
│ Static Analysis:  Pass (Slither)        │
│ PoC Execution:    Pass (Foundry)        │
│ Fuzz Testing:     Pass (256 runs)       │
│                                         │
│ ─────────────────────────────────────── │
│                                         │
│ ON-CHAIN ATTESTATION                    │
│ EAS UID: 0x1234...abcd                  │
│ Etherscan: [view]                       │
│                                         │
│ NFT CERTIFICATE                         │
│ Tier: Gold                              │
│ [Mint Certificate]                      │
│                                         │
└─────────────────────────────────────────┘
```

**技术栈**：
- 纯 HTML + CSS（无框架，无 JS 构建工具）
- 数据从 JSON 文件读取（审计报告 JSON）
- NFT 铸造通过 ethers.js 调用合约
- 单文件 `index.html`，可直接打开

**新增文件**：
```
frontend/
├── index.html          # 主页面
├── style.css           # 样式（极简）
└── app.js              # 数据加载 + NFT 铸造
```

---

### Idea 8：真实被黑合约审计

**目标**：用已知被黑过的合约做测试，证明 Agent 能发现真实漏洞。

**选择的合约**（选 2-3 个）：

| 合约 | 事件 | 漏洞类型 | 损失 |
|------|------|---------|------|
| The DAO | 2016 | 重入攻击 | $60M |
| Parity Wallet | 2017 | 权限控制 | $150M |
| Euler Finance | 2023 | 闪电贷+逻辑缺陷 | $197M |
| Curve (read-only reentrancy) | 2023 | 只读重入 | $70M |
| Hundred Finance | 2023 | 重入+预言机操纵 | $7M |

**实现**：
- 从 Etherscan 获取被黑合约的源代码
- 用 Agent 审计这些合约
- 对比 Agent 的发现与实际攻击路径
- 输出：验证报告（Agent 发现了哪些真实漏洞）

**测试用例**：
- 用 Curve 的 read-only reentrancy 合约
- 预期：Agent 能检测到只读重入漏洞

**新增文件**：
```
contracts/real-world/
├── curve-pool.sol          # Curve V2 LP Pool（被黑版本）
├── hundred-finance.sol     # Hundred Finance（被黑版本）
└── audit-results/
    ├── curve-audit.md
    └── hundred-audit.md
```

---

### Idea 9：审计证据链（Audit Evidence Chain）

**目标**：用 EAS + Merkle proof 构建轻量级审计证据链，每一步审计操作都可验证。

**与现有 EAS attestation 的区别**：

| | 现有 EAS | 审计证据链 |
|---|---|---|
| 粒度 | 最终结果一条 attestation | 每步操作一条 attestation |
| 内容 | 审计分数 + 合约地址 | 每步的输入/输出哈希 |
| 可验证性 | 只能验证最终结果 | 可验证任意中间步骤 |
| Merkle 聚合 | 无 | 所有步骤聚合成 Merkle root |

**证据链结构**：

```
Step 1: 需求理解 → attestation(hash(scope))
Step 2: Slither 扫描 → attestation(hash(slither_output))
Step 3: Aderyn 扫描 → attestation(hash(aderyn_output))
Step 4: PoC 生成 → attestation(hash(poc_code))
Step 5: Fuzz 验证 → attestation(hash(fuzz_result))
Step 6: 修复建议 → attestation(hash(fix_diff))
Step 7: 最终报告 → attestation(hash(report))
     └── Merkle Root = hash(all step hashes)
Step 8: NFT 铸造 ← 基于 Merkle Root
```

**实现**：
- 每步审计操作完成后，提交一条 EAS attestation
- 最终用所有步骤的哈希构建 Merkle tree
- Merkle root 记录在最终 attestation 中
- NFT 铸造基于 Merkle root（而非单条 attestation）
- 任何人都可以验证某个步骤是否在证据链中

**新增文件**：
```
contracts/AuditEvidenceChain.sol   # Merkle 证据链合约
mcp/tools/evidence_chain.py        # 证据链 MCP 工具
```

---

## 4. 最新区块链技术集成

### 4.1 已确定集成的技术

| 技术 | 用途 | 集成方式 |
|------|------|---------|
| **Halmos** (a16z) | 形式化验证 | 作为第 3 个分析引擎（Slither + Aderyn + Halmos） |
| **ERC-7512** | 链上审计元数据标准 | EAS attestation 的 schema 参考 ERC-7512 格式 |
| **Read-Only Reentrancy** | 新型攻击向量 | 新增测试合约 + 攻击模拟器模板 |

### 4.2 Halmos 集成

**Halmos** 是 a16z 的符号测试工具，用 Z3 SMT 求解器验证合约属性。

**集成方式**：
- 新增 MCP 工具：`mcp/tools/halmos_runner.py`
- 功能：对合约进行符号执行，验证关键属性（如"余额永远不会为负"）
- 与 Slither/Aderyn 互补：静态分析发现模式，Halmos 验证属性

```python
# halmos_runner.py 工具定义
{
    "name": "halmos_verify",
    "description": "Run symbolic verification on Solidity contracts using Halmos",
    "inputSchema": {
        "properties": {
            "contract_path": {"type": "string"},
            "properties": {"type": "array", "items": {"type": "string"},
                          "description": "Properties to verify (e.g., 'balance >= 0')"}
        }
    }
}
```

### 4.3 ERC-7512 参考

**ERC-7512** 是链上审计结果的标准格式。我们的 EAS schema 应参考这个标准：

```
// ERC-7512 风格的审计元数据
struct AuditMetadata {
    address auditor;          // 审计者地址
    bytes32 reportHash;       // 审计报告哈希
    uint8 severity;           // 最高严重性
    uint256 findingsCount;    // 发现数量
    uint256 timestamp;        // 审计时间
    string standard;          // "ERC-7512"
}
```

### 4.4 Read-Only Reentrancy 测试

**Read-Only Reentrancy** 是 2023 年出现的新型攻击向量（Balancer/Curve 事件）：
- 攻击者重入 view/getter 函数（不是状态变更函数）
- 操纵价格预言机读数
- 在流动性变化期间触发

**新增测试合约**：
```
contracts/test-cases/ReadOnlyReentrancy.sol
```

---

## 5. 实施优先级

| 优先级 | Idea | 预估时间 | 理由 |
|--------|------|---------|------|
| P0 | Idea 8：真实被黑合约 | 2 天 | 最有说服力的 demo 素材 |
| P0 | Idea 3：攻击模拟器 | 3 天 | 展示深度技术能力 |
| P1 | Idea 1：多合约审计 | 2 天 | 展示长程任务能力 |
| P1 | Idea 4：Web 前端 | 2 天 | 展示产品完整度 |
| P2 | Idea 9：审计证据链 | 3 天 | 展示链上创新（可选） |
| P2 | Halmos 集成 | 1 天 | 工具链增强 |
| P2 | Read-Only Reentrancy | 1 天 | 新型攻击向量覆盖 |

**总预估时间**：14 天（还有 21 天，buffer 充足）

---

## 6. 技术参考

| 资源 | 用途 |
|------|------|
| Halmos (a16z) | 形式化验证 |
| ERC-7512 | 链上审计元数据标准 |
| Read-Only Reentrancy | 新型攻击向量 |
| Succinct SP1 | ZK 虚拟机（v2 方向） |
| ZK Email | 链上邮件验证（v2 方向） |
| Account Abstraction (ERC-4337) | 智能钱包标准 |
| Foundry Book | 合约测试框架 |
| EAS Docs | 链上认证 |

---

## 7. 开发约束

1. **测试网 Only** — Sepolia，不消耗真实 ETH
2. **先验证再报告** — 每个漏洞必须有 PoC 或 fuzz 验证
3. **工具独立** — 每个 MCP 工具无状态
4. **阶段性提交** — 每完成一个功能点就 git commit + push
5. **所有工具自建** — 不依赖第三方项目归属
6. **前端极简** — 禁止 emoji、大面积色块、JS 框架
