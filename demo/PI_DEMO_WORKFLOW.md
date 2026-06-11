# Pi Agent Demo Workflow

> 让 Pi agent 自主执行 Athena demo 流程
> 展示 GLM-5.1 的长程任务能力

## 执行方式

```bash
cd /root/projects/glm-code
pi -p --thinking xhigh "按照 demo/PI_DEMO_WORKFLOW.md 执行 Athena demo 流程，录制终端输出"
```

---

## 任务目标

你是一个 AI agent，需要自主完成 Athena 项目的完整演示流程。这个过程会被录制下来，展示给黑客松评委。

**核心展示点：**
- 你能自主规划和执行复杂任务
- 你能调用 13 个 MCP 工具
- 你能完成 8 步审计闭环
- 你能处理真实协议漏洞

---

## 执行步骤

### Step 1: 展示项目结构 (30秒)

```bash
cd /root/projects/glm-code
tree -L 2 -I 'node_modules|.git|lib|cache|out|__pycache__'
```

**要点**：展示完整的项目结构

---

### Step 2: 展示审计合约 (1分钟)

```bash
# 展示测试合约
cat contracts/test-cases/Reentrancy.sol

# 展示真实协议合约
head -50 contracts/real-world/curve-pool.sol
```

**要点**：展示有真实的漏洞测试案例

---

### Step 3: 展示 MCP 工具链 (30秒)

```bash
# 展示 MCP 工具
ls -la mcp/tools/

# 展示其中一个工具
head -30 mcp/tools/slither_runner.py
```

**要点**：展示 13 个 MCP 工具是真实存在的

---

### Step 4: 运行真实审计 (1-2分钟)

```bash
# 运行 Slither 静态分析
slither contracts/test-cases/Reentrancy.sol 2>&1 | head -50

# 如果 slither 未安装，运行 Python 审计脚本
python3 mcp/tools/slither_runner.py contracts/test-cases/Reentrancy.sol
```

**要点**：展示真实的漏洞检测结果

**备选**：如果 Slither 未安装，用 Python 脚本代替

---

### Step 5: 展示测试结果 (30秒)

```bash
# 运行 Foundry 测试
forge test --match-test testReentrancy -vvv 2>&1 | tail -30

# 展示测试通过
forge test 2>&1 | tail -15
```

**要点**：展示合约测试是通过的

**备选**：如果 Foundry 未安装，展示测试文件内容

---

### Step 6: 展示链上部署 (30秒)

```bash
# 展示已部署的合约地址
echo "=== Sepolia 部署 ==="
echo "AuditCertificate: 0x3247d57d37bd1878479f03a077aba807649dbaf5"
echo "AgentEscrowV2: 0x7102b7252dea80529278c8bffc441b96ff24421e"
echo "ERC7512Metadata: 0x0dd8f8f5b755912aa3b955044d1eff496a65e657"
echo "AuditTrail: 0xd7913e7749595a9238883bdf0b2dad599f4d0bf0"
echo "Groth16Verifier: 0xf0c9ec42fe603a53af3e6248e874bbbb3064e498"
echo ""
echo "=== Base Sepolia 部署 ==="
echo "AuditCertificate: 0xb8f167a84816b5b9373997337119a2186c6e3708"
echo "ERC7512Metadata: 0x5e99f144d3e512f525d24077d4626a064899e177"
echo "Groth16Verifier: 0x636b3af9630e1b26b02ba488a5b8ab6ce75d6721"
echo "AuditTrail: 0x83bfbc0901c9a6481a26ec2dc649487768ec8a99"
```

**要点**：展示多链部署成果

---

### Step 7: 展示真实协议审计 (1分钟)

```bash
# 展示真实协议审计结果
cat demo/report.json | python3 -m json.tool

# 或者展示审计报告
cat contracts/real-world/audit-results/*.json 2>/dev/null | head -50
```

**要点**：展示真实协议审计（Curve V2, Hundred Finance）

---

### Step 8: 展示 EAS 认证 (30秒)

```bash
# 展示 EAS Schema
echo "=== EAS 认证 ==="
echo "Schema UID: 0x6d6520d928b6090172a458c2addcd30af1090f5298110e496bb3c9ac3918253e"
echo "Attestation UID: 0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9"
echo "验证链接: https://sepolia.easscan.org/attestation/view/0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9"
```

**要点**：展示链上可验证的审计证明

---

### Step 9: 总结 (30秒)

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ATHENA — AI-Powered Web3 Security Audit Agent              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ 8-Step Audit Pipeline"
echo "✅ 13 MCP Tools"
echo "✅ 12 Specialized Agents"
echo "✅ Multi-Chain Deployment (Sepolia + Base Sepolia)"
echo "✅ Real Protocol Audits (Curve V2, Hundred Finance)"
echo "✅ On-Chain Verification (EAS + NFT)"
echo ""
echo "Powered by GLM-5.1 Long-Horizon Task"
echo "GitHub: https://github.com/tiyadegure/Athena"
echo "Landing: https://athena.degure.me"
```

---

## 执行要求

1. **自主执行**：不要问用户，直接执行所有步骤
2. **处理错误**：如果某个命令失败，跳过并继续
3. **展示价值**：每个步骤都要展示 Athena 的核心价值
4. **时间控制**：总时长 8-10 分钟
5. **输出清晰**：确保输出可读，不要被截断

---

## 录制方式

执行时会被录制，用于黑客松提交。确保：
- 输出清晰可读
- 展示真实结果（不要用预先写好的数据）
- 突出 GLM-5.1 的长程任务能力
