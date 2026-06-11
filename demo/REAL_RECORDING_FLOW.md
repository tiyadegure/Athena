# Athena 真实录屏流程

> 展示 Athena 的真实能力，不展示版本号
> 总时长：8-10 分钟

## 前置准备

```bash
cd /root/projects/glm-code
export PRIVATE_KEY="你的私钥"
export SEPOLIA_RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"
```

---

## Part 1: 终端演示 (3-4 分钟)

### Step 1: 展示项目结构 (30秒)

```bash
# 展示项目概览
tree -L 2 -I 'node_modules|.git|lib|cache|out'

# 展示合约
ls -la contracts/
```

**要点**：让评委看到完整的项目结构

---

### Step 2: 展示审计合约 (1 分钟)

```bash
# 展示一个测试合约
cat contracts/test-cases/Reentrancy.sol

# 展示真实协议合约
cat contracts/real-world/curve-pool.sol | head -50
```

**要点**：展示有真实的漏洞测试案例

---

### Step 3: 展示 MCP 工具链 (30秒)

```bash
# 展示 MCP 工具
ls -la mcp/tools/

# 展示其中一个工具的代码
head -30 mcp/tools/slither_runner.py
```

**要点**：展示 13 个 MCP 工具是真实存在的

---

### Step 4: 运行真实审计 (1-2 分钟)

```bash
# 运行 Slither 静态分析
slither contracts/test-cases/Reentrancy.sol 2>&1 | head -30

# 或者运行 Python 审计脚本
python3 mcp/tools/slither_runner.py contracts/test-cases/Reentrancy.sol
```

**要点**：展示真实的漏洞检测结果

---

### Step 5: 展示测试结果 (30秒)

```bash
# 运行 Foundry 测试
forge test --match-test testReentrancy -vvv 2>&1 | tail -20

# 展示测试通过
forge test 2>&1 | tail -10
```

**要点**：展示合约测试是通过的

---

## Part 2: 浏览器演示 (3-4 分钟)

### Step 6: Landing Page (1 分钟)

打开浏览器，访问：`https://athena.degure.me`

**展示内容**：
1. 滚动页面，展示 8 步审计流程
2. 展示 Features 区域（12 Agents, 13 MCP Tools, EAS）
3. 展示 NFT 证书（S/A/B/C 四级）
4. 展示 Real Protocol Audits（Curve V2, Hundred Finance）

**要点**：让评委快速了解项目价值

---

### Step 7: 链上验证 (1-2 分钟)

**EAS Attestation（审计证明）**：
- 访问：`https://sepolia.easscan.org/attestation/view/0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9`
- 展示：Attestation 详情、时间戳、Schema

**NFT 合约（审计证书）**：
- 访问：`https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5`
- 展示：合约代码、Token ID 1、持有人

**多链部署**：
- 访问：`https://sepolia.basescan.org/address/0xb8f167a84816b5b9373997337119a2186c6e3708`
- 展示：Base Sepolia 也已部署

**要点**：展示所有成果都已上链，可验证

---

### Step 8: 展示报告 (30秒)

访问：`https://athena.degure.me/report.json` 或 `https://athena.degure.me/docs.html`

**展示内容**：
- 审计报告 JSON 结构
- 发现的漏洞类型
- 匹配率（95%, 88%）

---

## Part 3: 收尾 (1 分钟)

### Step 9: 展示 GitHub 仓库

访问：`https://github.com/tiyadegure/Athena`

**展示内容**：
- README（架构图、部署地址、路线图）
- 合约代码
- MCP 工具代码
- 测试用例

---

### Step 10: 总结

**关键信息**：
- GLM-5.1 驱动的 8 步审计闭环
- 13 个 MCP 工具 + 12 个 Agent
- 多链部署（Sepolia + Base Sepolia）
- 真实协议审计（Curve V2, Hundred Finance）
- 链上可验证（EAS + NFT）

---

## 录制工具

### 方法 A：OBS（推荐）

```bash
# 安装
sudo apt install obs-studio

# 录制
# 1. 打开 OBS
# 2. 设置场景：全屏捕获
# 3. 开始录制
# 4. 按照上面的流程操作
# 5. 停止录制
```

### 方法 B：asciinema（终端）

```bash
# 录制终端部分
asciinema rec athena-demo.cast -c "bash"
# 执行上面的终端命令
# exit 退出录制
```

### 方法 C：ffmpeg + 屏幕录制

```bash
# 录制屏幕
ffmpeg -f x11grab -r 30 -s 1920x1080 -i :0.0 -c:v libx264 -preset ultrafast output.mp4
```

---

## 注意事项

1. **不要展示版本号**：评委不需要知道 "v9"、"v9.1"
2. **展示真实结果**：不要用预先写好的输出
3. **突出价值**：GLM-5.1 长程任务能力、多链部署、真实协议审计
4. **链上验证**：所有成果都可验证，这是最大的亮点
5. **时间控制**：终端 3-4 分钟，浏览器 3-4 分钟，收尾 1 分钟

---

## 提交材料清单

- [ ] Demo 视频（8-10 分钟）
- [ ] GitHub 仓库（公开）
- [ ] Landing Page（https://athena.degure.me）
- [ ] README（中文 + 英文）
- [ ] 团队信息（Tiya Degurechaff）
- [ ] 链上证据（合约地址、EAS UID）
