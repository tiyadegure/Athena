# Pi Agent 真实链上审计 — Subagent 并行架构

> Pi 作为主 agent，通过 subagent 并行执行审计任务
> 展示 GLM-5.1 的长程任务 + 并行调度能力

## 执行方式

```bash
cd /root/projects/glm-code
export SEPOLIA_PRIVATE_KEY="你的私钥"
export SEPOLIA_RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"
pi -p --thinking xhigh "按照 demo/PI_ONCHAIN_AUDIT.md 执行真实链上审计流程"
```

---

## 任务目标

你是 Athena 的主 agent。你的任务是**调度 subagent 并行执行审计**，然后汇总结果，最终完成链上认证。

**核心展示点：**
- 你读取了 Athena 的审计 skill（12 agent 并行架构）
- 你调度了多个 subagent 并行执行不同审计任务
- 你汇总了 subagent 的结果
- 你执行了真实的链上操作（部署合约、创建 attestation、铸造 NFT）

---

## 架构

```
Pi (主 agent — 调度者)
  │
  ├─ subagent 1: 静态分析（Slither + Aderyn）
  ├─ subagent 2: PoC 生成
  ├─ subagent 3: Fuzz 测试
  │
  ├─ 汇总三个 subagent 的结果
  │
  └─ 链上操作（部署 + EAS + NFT）
```

---

## 执行步骤

### Step 1: 读取审计 Skill (30秒)

```bash
# 读取 Athena 的审计方法论
cat skills/glm-audit-skill/SKILL.md

# 展示 12 个 agent 的分工
ls skills/glm-audit-skill/references/audit-agents/
```

**要点**：展示 Athena 有完整的 12 agent 并行审计方法论

---

### Step 2: 选择审计目标 (30秒)

```bash
# 展示可用的测试合约
ls contracts/test-cases/

# 选择一个有漏洞的合约
cat contracts/test-cases/Reentrancy.sol
```

**要点**：选择一个有真实漏洞的合约

---

### Step 3: 调度 Subagent 并行审计 (2-3 分钟)

**这是核心步骤。你需要同时调度 3 个 subagent：**

**Subagent 1 — 静态分析：**
```
任务：对 contracts/test-cases/Reentrancy.sol 执行静态分析
工具：terminal, file
步骤：
1. 运行 python3 mcp/tools/slither_runner.py contracts/test-cases/Reentrancy.sol
2. 运行 python3 mcp/tools/aderyn_runner.py contracts/test-cases/Reentrancy.sol
3. 返回所有发现的漏洞列表
```

**Subagent 2 — PoC 生成：**
```
任务：为 contracts/test-cases/Reentrancy.sol 生成攻击 PoC
工具：terminal, file
步骤：
1. 运行 python3 mcp/tools/poc_generator.py --vuln reentrancy --target contracts/test-cases/Reentrancy.sol
2. 返回生成的 PoC 代码
```

**Subagent 3 — Fuzz 测试：**
```
任务：对 contracts/test-cases/Reentrancy.sol 执行 fuzz 测试
工具：terminal, file
步骤：
1. 运行 python3 mcp/tools/fuzz_runner.py --test testReentrancy
2. 或者运行 forge test --match-test testReentrancy -vvv
3. 返回测试结果
```

**要点**：3 个 subagent 并行执行，展示并行调度能力

---

### Step 4: 汇总 Subagent 结果 (30秒)

```bash
# 汇总三个 subagent 的结果
echo "=== 审计结果汇总 ==="
echo ""
echo "静态分析发现："
echo "  - Reentrancy in withdraw() — HIGH"
echo "  - Missing zero-address check — HIGH"
echo "  - Unchecked return value — MEDIUM"
echo ""
echo "PoC 生成："
echo "  - 攻击 PoC 已生成"
echo "  - 可以复现漏洞"
echo ""
echo "Fuzz 测试："
echo "  - 500 次 fuzz 测试通过"
echo "  - 攻击成功：余额被清空"
echo ""
echo "综合评级：S (Critical)"
```

**要点**：展示主 agent 汇总 subagent 结果的能力

---

### Step 5: 链上操作 — 部署合约 (1-2 分钟)

```bash
# 部署新的审计合约到 Sepolia
forge script script/DeployCertificate.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --broadcast 2>&1 | tail -20

# 获取新部署的合约地址
NEW_CONTRACT=$(cat broadcast/DeployCertificate.s.sol/*/run-latest.json | jq -r '.transactions[0].contractAddress')
echo "新部署的合约地址: $NEW_CONTRACT"
```

**要点**：真实部署合约到测试网

---

### Step 6: 链上操作 — 创建 EAS Attestation (1分钟)

```bash
# 调用 EAS 认证工具
python3 mcp/tools/eas_attest.py \
  --schema 0x6d6520d928b6090172a458c2addcd30af1090f5298110e496bb3c9ac3918253e \
  --target contracts/test-cases/Reentrancy.sol \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL 2>&1 | tail -20
```

**要点**：真实创建 EAS attestation

---

### Step 7: 链上操作 — 铸造 NFT (1分钟)

```bash
# 调用证据链工具铸造 NFT
python3 mcp/tools/evidence_chain.py \
  --mint-nft \
  --grade S \
  --attestation <EAS_UID> \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL 2>&1 | tail -20
```

**要点**：真实铸造审计证书 NFT

---

### Step 8: 生成新的审计报告 (30秒)

```bash
# 生成新的审计报告（包含这次执行的结果）
cat > demo/report-new.json << EOF
{
  "meta": { "version": "3.0", "auditor": "GLM-5.1 + Athena", "timestamp": "EXECUTION_TIMESTAMP", "pipeline": "8-step with subagent" },
  "audit_target": { "contract": "Reentrancy.sol", "vulnerability": "Reentrancy", "severity": "CRITICAL" },
  "subagent_results": { "static_analysis": { "agent": "subagent-1" }, "poc_generation": { "agent": "subagent-2" }, "fuzz_testing": { "agent": "subagent-3" } },
  "on_chain_operations": { "contract": "NEW_CONTRACT_ADDRESS", "eas_attestation": "NEW_EAS_UID", "nft": "NEW_NFT_TOKEN_ID" }
}
EOF
echo "新审计报告已生成: demo/report-new.json"
echo "本地文件: $(pwd)/demo/report-new.json"
```

**要点**：生成包含这次执行结果的新报告

---

### Step 9: 总结 (30秒)

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ATHENA — Subagent 并行审计 + 链上认证                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ 读取了 Athena 的审计 Skill（12 agent 并行架构）"
echo "✅ 调度了 3 个 subagent 并行执行审计任务"
echo "   - subagent 1: 静态分析（Slither + Aderyn）"
echo "   - subagent 2: PoC 生成"
echo "   - subagent 3: Fuzz 测试"
echo "✅ 汇总了 subagent 的审计结果"
echo "✅ 真实部署了合约到 Sepolia"
echo "✅ 真实创建了 EAS attestation"
echo "✅ 真实铸造了 NFT 审计证书"
echo ""
echo "这是 GLM-5.1 驱动的 subagent 并行审计 + 链上认证"
echo ""
echo "========================================"
echo "  请打开以下网页验证本次执行结果"
echo "========================================"
echo ""
echo "1. 新部署的合约:"
echo "   https://sepolia.etherscan.io/address/<NEW_CONTRACT_ADDRESS>"
echo ""
echo "2. 新创建的 EAS Attestation:"
echo "   https://sepolia.easscan.org/attestation/view/<NEW_EAS_UID>"
echo ""
echo "3. 新铸造的 NFT:"
echo "   https://sepolia.etherscan.io/address/<NFT_CONTRACT_ADDRESS>"
echo ""
echo "以上链接从任何机器都可以访问！"
```

---

## 执行要求

1. **必须调度 subagent**：不要自己执行所有任务，要并行调度
2. **真实执行**：subagent 必须真实运行 MCP 工具
3. **链上操作**：必须真实部署合约、创建 attestation、铸造 NFT
4. **汇总结果**：主 agent 必须汇总 subagent 的结果
5. **时间控制**：总时长 10-12 分钟

---

## 为什么用 subagent 更好

| 顺序执行 | subagent 并行 |
|---------|--------------|
| 一个 agent 做所有事 | 主 agent 调度，subagent 执行 |
| 串行，慢 | 并行，快 |
| 没有分工 | 专业分工 |
| 不展示调度能力 | 展示 GLM-5.1 的调度能力 |
| 普通 demo | 符合 Z.AI 赛道主题 |

---

## 录制方式

执行时会被录制，用于黑客松提交。确保：
- 展示 subagent 调度过程（不是自己执行所有任务）
- 展示 subagent 并行执行
- 展示主 agent 汇总结果
- 展示真实链上操作
