# Workflow — 真实协议审计

> 用 Athena 8 步 pipeline 审计真实被黑协议，对比 Agent 发现与实际攻击路径。
> 基于完成状态（ZK + Escrow + ERC-7512 已部署），新增真实协议审计能力。

---

## 目标

让 Athena Agent 审计 **真实被黑过的 DeFi 协议**，验证：
1. Agent 能否独立发现真实漏洞
2. Agent 发现与实际攻击路径的重合度
3. 8 步 pipeline 在真实代码上的表现

## 审计目标协议

| 协议 | 漏洞类型 | 实际损失 | 年份 | 难度 |
|------|---------|---------|------|------|
| Curve V2 | Read-Only Reentrancy | $70M | 2023 | ⭐⭐⭐ |
| Hundred Finance | Reentrancy + Oracle | $7M | 2023 | ⭐⭐⭐ |
| Euler Finance | Flash Loan + Logic | $197M | 2023 | ⭐⭐⭐⭐ |
| Aave v3 | 价格预言机操纵 | 模拟 | 2024 | ⭐⭐⭐ |
| Balancer | LP 价格操纵 | $900K | 2023 | ⭐⭐⭐ |
| SushiSwap | Route 操纵 | $3.3M | 2023 | ⭐⭐ |

## Phase 1：获取真实合约源码

### 来源
- Etherscan / Arbiscan / Polygonscan API
- 直接 fork 主网 bytecode（无源码的合约）

### 工具
```bash
# 从 Etherscan 获取源码
curl "https://api.etherscan.io/api?module=contract&action=getsourcecode&address=0x...&apikey=$ETHERSCAN_API_KEY"

# 从主网 fork bytecode
cast code 0x... --rpc-url https://eth.llamarpc.com
```

### 存储
```
contracts/real-world/
├── curve-v2/
│   ├── CurveV2Pool.sol              # 从 Etherscan 拉取
│   ├── CurveV2PoolProxy.sol         # 代理合约
│   └── audit-results/               # Agent 审计结果
├── euler/
│   ├── Euler.sol
│   ├── EulerMarkets.sol
│   └── audit-results/
├── hundred-finance/
│   ├── hundred-finance.sol          # ✅ 已有（简化版）
│   └── audit-results/               # ✅ 已有
└── aave-v3/
    ├── Pool.sol
    ├── PriceOracle.sol
    └── audit-results/
```

---

## Phase 2：Agent 审计（8 步 pipeline）

### 对每个真实协议执行完整 8 步：

```
Step 1: 需求理解
  → 识别协议类型（AMM/Lending/Bridge/Derivative）
  → 分析合约架构（Proxy/Implementation/Library）
  → 识别攻击面（外部调用、状态变更、权限）

Step 2: 双引擎扫描
  → Slither 静态分析
  → Aderyn Rust 静态分析
  → 交叉验证，标记已知漏洞模式

Step 3: RAG 知识增强
  → 检索知识库中类似协议的漏洞案例
  → 匹配历史攻击模式（闪电贷、重入、预言机操纵）
  → 增强漏洞判断

Step 4: PoC 生成
  → 基于发现生成 Foundry .s.sol 脚本
  → 支持 fork 主网环境测试
  → 模拟实际攻击路径

Step 5: Foundry Fuzz 验证
  → 在 fork 环境运行 fuzz 测试
  → 验证 PoC 可复现性
  → 计算攻击收益

Step 6: 修复建议
  → 基于漏洞类型生成修复方案
  → 对比实际修复方案（如果协议已修复）

Step 7: EAS 上链认证
  → 审计结果上链
  → 记录 Agent 发现 vs 实际攻击

Step 8: 铸造 NFT 证书
  → 根据审计质量铸造 S/A/B/C 级 NFT
```

---

## Phase 3：对比验证

### Agent 发现 vs 实际攻击对比

对每个协议生成对比报告：

```json
{
  "protocol": "Curve V2",
  "audit_date": "2026-06-12",
  "agent": "GLM-5.1 + Athena",
  "actual_attack": {
    "date": "2023-07-30",
    "loss": "$70M",
    "vulnerability": "Read-Only Reentrancy",
    "attack_vector": "addLiquidity callback → getVirtualPrice() stale"
  },
  "agent_findings": {
    "total_findings": 5,
    "critical": 1,
    "high": 2,
    "medium": 1,
    "low": 1,
    "matched_actual": true,
    "finding_detail": "Read-only reentrancy in getVirtualPrice() during addLiquidity()",
    "match_score": "95%"
  },
  "comparison": {
    "vulnerability_detected": true,
    "root_cause_identified": true,
    "attack_vector_reproduced": true,
    "fix_suggestion_matches": true,
    "overall_match": "95%"
  }
}
```

### 评分标准

| 指标 | 权重 | 说明 |
|------|------|------|
| 漏洞检测 | 40% | 是否发现实际漏洞 |
| 根因分析 | 25% | 是否正确识别根因 |
| 攻击复现 | 20% | PoC 是否可执行 |
| 修复建议 | 15% | 修复方案是否合理 |

---

## Phase 4：审计报告生成

### 每个协议生成标准化报告

```
contracts/real-world/<protocol>/audit-results/
├── agent-report.json              # Agent 审计结果
├── comparison.json                # 与实际攻击对比
├── poc/                           # PoC 测试合约
│   └── Exploit.s.sol
└── summary.md                     # 人类可读摘要
```

### 汇总报告

```
demo/real-world-audit-summary.json
{
  "protocols_audited": 6,
  "total_findings": 28,
  "critical_found": 8,
  "actual_vulnerabilities_matched": 5,
  "match_rate": "83%",
  "best_detection": "Curve V2 Read-Only Reentrancy (95%)",
  "worst_detection": "SushiSwap Route Manipulation (60%)"
}
```

---

## Phase 5：Demo 展示

### 录屏脚本

```
scripts/demo-real-protocol-audit.sh
```

### Demo 流程
1. 选择目标协议（如 Curve V2）
2. 从 Etherscan 获取源码
3. Agent 执行 8 步审计
4. 展示 Agent 发现 vs 实际攻击对比
5. 展示 PoC 执行结果
6. 链上验证（EAS + NFT）

### 产出
- 6 个真实协议的审计报告
- Agent 准确率统计
- Demo 视频素材

---

## 实现路径

### 新增文件

```
contracts/real-world/
├── curve-v2/                      # 从 Etherscan 获取
├── euler/                         # 从 Etherscan 获取
├── aave-v3/                       # 从 Etherscan 获取
├── balancer/                      # 从 Etherscan 获取
└── sushiswap/                     # 从 Etherscan 获取

mcp/tools/
├── etherscan_fetcher.py           # 从 Etherscan 获取源码
└── real_protocol_auditor.py       # 真实协议审计编排

scripts/
├── fetch-real-contracts.sh        # 批量获取真实合约
└── demo-real-protocol-audit.sh    # Demo 录屏脚本

demo/
└── real-world-audit-summary.json  # 汇总报告
```

### 依赖
- Etherscan API Key（免费 tier 足够）
- Foundry fork 测试（需要 RPC endpoint）
- 主网 RPC（如 llamarpc.com 免费）

---

## 执行顺序

```
Step 1: 获取真实合约源码（1 天）
  → Etherscan API 拉取 6 个协议
  → 存储到 contracts/real-world/<protocol>/

Step 2: Agent 审计（2-3 天）
  → 对每个协议执行 8 步 pipeline
  → 生成审计报告 + PoC

Step 3: 对比验证（1 天）
  → 对比 Agent 发现 vs 实际攻击
  → 计算匹配率

Step 4: 汇总 + Demo（1 天）
  → 生成汇总报告
  → 录制 Demo 视频
```

---

## 与之前工作的关系

```
之前已完成：
  ├─ ZK 可验证审计 ✅
  ├─ Agent Escrow v2 ✅
  ├─ 多链部署 ⬜
  └─ ERC-7512 标准 ✅

新增：
  └─ 真实协议审计
      ├─ Phase 1: 获取真实合约源码
      ├─ Phase 2: Agent 8 步审计
      ├─ Phase 3: 对比验证
      ├─ Phase 4: 报告生成
      └─ Phase 5: Demo 展示
```

真实协议审计是之前的自然延伸 — 用已部署的 ZK/Escrow/ERC-7512 基础设施审计真实协议。
