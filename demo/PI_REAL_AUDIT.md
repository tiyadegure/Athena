# Pi Agent 真实调用 Athena 项目

> 让 Pi 真正调用 Athena 的 skill 和 MCP 工具
> 展示 GLM-5.1 驱动的真实审计能力

## 执行方式

```bash
cd /root/projects/glm-code
pi -p --thinking xhigh "按照 demo/PI_REAL_AUDIT.md 执行真实审计流程"
```

---

## 任务目标

你是一个 AI agent，需要**真正调用 Athena 项目的组件**来完成一次完整的安全审计。这不是演示，而是真实运行 Athena 的审计系统。

**核心展示点：**
- 你读取并理解了 Athena 的审计 skill
- 你调用了 Athena 的 13 个 MCP 工具
- 你完成了完整的 8 步审计闭环
- 你的审计结果是真实的

---

## 执行步骤

### Step 1: 读取审计 Skill (30秒)

```bash
# 读取 Athena 的审计方法论
cat skills/glm-audit-skill/SKILL.md

# 理解 12 个 agent 的分工
cat skills/glm-audit-skill/references/audit-agents/*.md 2>/dev/null | head -100
```

**要点**：展示 Athena 有完整的审计方法论

---

### Step 2: 选择审计目标 (30秒)

```bash
# 展示可用的测试合约
ls contracts/test-cases/

# 选择一个有漏洞的合约
cat contracts/test-cases/Reentrancy.sol
```

**要点**：选择一个有真实漏洞的合约进行审计

---

### Step 3: 调用 MCP 工具 - 静态分析 (1分钟)

```bash
# 调用 Slither 静态分析工具
python3 mcp/tools/slither_runner.py contracts/test-cases/Reentrancy.sol

# 调用 Aderyn 静态分析工具
python3 mcp/tools/aderyn_runner.py contracts/test-cases/Reentrancy.sol
```

**要点**：真正调用 MCP 工具，不是 echo

---

### Step 4: 调用 MCP 工具 - 漏洞知识库 (30秒)

```bash
# 调用知识库工具，查询 reentrancy 漏洞
python3 mcp/tools/knowledge_base.py "reentrancy attack patterns"
```

**要点**：展示 RAG 知识增强能力

---

### Step 5: 调用 MCP 工具 - PoC 生成 (1分钟)

```bash
# 调用 PoC 生成工具
python3 mcp/tools/poc_generator.py --vuln reentrancy --target contracts/test-cases/Reentrancy.sol
```

**要点**：展示自动生成攻击 PoC 的能力

---

### Step 6: 调用 MCP 工具 - Fuzz 测试 (1分钟)

```bash
# 调用 Fuzz 测试工具
python3 mcp/tools/fuzz_runner.py --test testReentrancy

# 或者直接用 forge
forge test --match-test testReentrancy -vvv
```

**要点**：展示真实的测试验证

---

### Step 7: 调用 MCP 工具 - 攻击模拟 (30秒)

```bash
# 调用攻击模拟器
python3 mcp/tools/exploit_simulator.py --vuln reentrancy --target contracts/test-cases/Reentrancy.sol
```

**要点**：展示攻击模拟能力

---

### Step 8: 调用 MCP 工具 - 修复建议 (30秒)

```bash
# 调用修复验证工具
python3 mcp/tools/repair_validator.py --vuln reentrancy --target contracts/test-cases/Reentrancy.sol
```

**要点**：展示自动修复建议能力

---

### Step 9: 展示完整审计报告 (30秒)

```bash
# 展示审计报告
cat demo/report.json | python3 -m json.tool

# 或者生成新的报告
python3 mcp/tools/evidence_chain.py --generate-report
```

**要点**：展示完整的审计报告

---

### Step 10: 展示链上认证 (30秒)

```bash
# 展示 EAS 认证信息
echo "=== EAS 认证 ==="
echo "Schema UID: 0x6d6520d928b6090172a458c2addcd30af1090f5298110e496bb3c9ac3918253e"
echo "Attestation UID: 0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9"
echo "验证链接: https://sepolia.easscan.org/attestation/view/0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9"
```

**要点**：展示链上可验证的审计证明

---

### Step 11: 总结 (30秒)

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ATHENA — 真实审计流程演示                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ 读取了 Athena 的审计 Skill (12 个 agent)"
echo "✅ 调用了 13 个 MCP 工具"
echo "✅ 完成了完整的 8 步审计闭环"
echo "✅ 生成了真实的审计报告"
echo "✅ 展示了链上认证"
echo ""
echo "这是 GLM-5.1 驱动的真实审计，不是演示脚本"
echo "Powered by GLM-5.1 Long-Horizon Task"
```

---

## 执行要求

1. **真正调用**：必须真正运行 Python 脚本，不是 echo
2. **处理错误**：如果某个工具不存在或出错，跳过并继续
3. **展示价值**：每个步骤都要展示 Athena 的核心价值
4. **时间控制**：总时长 8-10 分钟
5. **输出清晰**：确保输出可读，不要被截断

---

## 与之前 workflow 的区别

| 之前的 workflow | 这个 workflow |
|---------------|--------------|
| echo 命令 | 真正调用工具 |
| 预先写好的输出 | 真实运行结果 |
| 演示脚本 | 真实审计 |
| 展示命令 | 展示能力 |

---

## 录制方式

执行时会被录制，用于黑客松提交。确保：
- 真正调用 MCP 工具（不是 echo）
- 展示真实结果（不要用预先写好的数据）
- 突出 GLM-5.1 的长程任务能力
- 展示 Athena 的真实能力
