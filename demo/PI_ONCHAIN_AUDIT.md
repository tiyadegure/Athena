# Pi Agent 真实链上操作 Athena

> 让 Pi 真实执行链上操作：部署合约、创建 EAS attestation、铸造 NFT
> 完全真实，不是演示

## 执行方式

```bash
cd /root/projects/glm-code

# 设置环境变量
export SEPOLIA_PRIVATE_KEY="你的私钥"
export SEPOLIA_RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"

# 执行真实审计 + 链上操作
pi -p --thinking xhigh "按照 demo/PI_ONCHAIN_AUDIT.md 执行真实链上审计流程"
```

---

## 任务目标

你是一个 AI agent，需要**真实执行链上操作**来完成一次完整的安全审计。这不是演示，而是真实的链上交易。

**核心展示点：**
- 你真实部署了合约
- 你真实创建了 EAS attestation
- 你真实铸造了 NFT
- 你真实调用了 MCP 工具

---

## 执行步骤

### Step 1: 检查环境 (30秒)

```bash
# 检查环境变量
echo "=== 环境检查 ==="
echo "PRIVATE_KEY: ${SEPOLIA_PRIVATE_KEY:0:10}..."
echo "RPC_URL: $SEPOLIA_RPC_URL"

# 检查钱包余额
cast balance $(cast wallet address --private-key $SEPOLIA_PRIVATE_KEY) --rpc-url $SEPOLIA_RPC_URL
```

**要点**：确保有足够的测试网 ETH

---

### Step 2: 读取审计 Skill (30秒)

```bash
# 读取 Athena 的审计方法论
cat skills/glm-audit-skill/SKILL.md | head -50

# 理解 12 个 agent 的分工
ls skills/glm-audit-skill/references/audit-agents/
```

**要点**：展示 Athena 有完整的审计方法论

---

### Step 3: 选择审计目标 (30秒)

```bash
# 展示可用的测试合约
ls contracts/test-cases/

# 选择一个有漏洞的合约
cat contracts/test-cases/Reentrancy.sol
```

**要点**：选择一个有真实漏洞的合约进行审计

---

### Step 4: 调用 MCP 工具 - 静态分析 (1分钟)

```bash
# 调用 Slither 静态分析工具
python3 mcp/tools/slither_runner.py contracts/test-cases/Reentrancy.sol 2>&1 | head -30

# 调用 Aderyn 静态分析工具
python3 mcp/tools/aderyn_runner.py contracts/test-cases/Reentrancy.sol 2>&1 | head -30
```

**要点**：真正调用 MCP 工具，获取真实漏洞检测结果

---

### Step 5: 调用 MCP 工具 - PoC 生成 (1分钟)

```bash
# 调用 PoC 生成工具
python3 mcp/tools/poc_generator.py --vuln reentrancy --target contracts/test-cases/Reentrancy.sol 2>&1 | head -50
```

**要点**：展示自动生成攻击 PoC 的能力

---

### Step 6: 部署新合约 (1-2分钟)

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

**要点**：真实部署新合约到测试网

---

### Step 7: 创建 EAS Attestation (1分钟)

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

### Step 8: 铸造 NFT (1分钟)

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

### Step 9: 展示完整审计报告 (30秒)

```bash
# 生成审计报告
python3 mcp/tools/evidence_chain.py --generate-report 2>&1 | head -50

# 展示链上交易记录
echo "=== 链上交易记录 ==="
echo "合约部署: <TX_HASH>"
echo "EAS Attestation: <EAS_UID>"
echo "NFT 铸造: <TX_HASH>"
```

**要点**：展示完整的审计报告和链上记录

---

### Step 10: 总结 (30秒)

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ATHENA — 真实链上审计流程                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ 真实调用了 Athena 的 MCP 工具"
echo "✅ 真实部署了合约到 Sepolia"
echo "✅ 真实创建了 EAS attestation"
echo "✅ 真实铸造了 NFT 审计证书"
echo "✅ 生成了完整的审计报告"
echo ""
echo "这是 GLM-5.1 驱动的真实链上审计"
echo "Powered by GLM-5.1 Long-Horizon Task"
```

---

## 执行要求

1. **真实执行**：必须真实运行命令，不是 echo
2. **链上操作**：必须真实部署合约、创建 attestation、铸造 NFT
3. **处理错误**：如果某个命令失败，记录错误并继续
4. **时间控制**：总时长 10-12 分钟
5. **输出清晰**：确保输出可读，不要被截断

---

## 与之前 workflow 的区别

| 之前的 workflow | 这个 workflow |
|---------------|--------------|
| echo 命令 | 真实执行 |
| 展示已有成果 | 创建新成果 |
| 演示脚本 | 真实链上操作 |
| 展示能力 | 证明能力 |

---

## 录制方式

执行时会被录制，用于黑客松提交。确保：
- 真实执行所有命令（不是 echo）
- 展示真实链上交易（合约地址、tx hash）
- 突出 GLM-5.1 的长程任务能力
- 展示 Athena 的真实能力

---

## 风险提示

- 需要消耗测试网 ETH（约 0.1 ETH）
- 需要私钥环境变量
- 链上操作不可逆
- 建议先在本地测试
