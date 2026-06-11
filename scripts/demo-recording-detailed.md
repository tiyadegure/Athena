# Demo 录屏脚本（详细版）

## 准备工作

### 浏览器标签页（提前打开）
1. **GitHub 仓库** — `https://github.com/tiyadegure/Athena`
2. **Etherscan 合约** — `https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5`
3. **EAS 认证** — `https://sepolia.easscan.org`
4. **前端页面** — `http://localhost:8765`（本地服务器）

### 终端窗口
- 工作目录：`/root/projects/glm-code`
- 已安装：Foundry、Node.js、GLM-5.1

---

## Demo 流程（5 分钟）

### [0:00-0:30] 开场 — 展示合约代码

**终端操作：**
```bash
cd /root/projects/glm-code
cat contracts/test-cases/Reentrancy.sol
```

**讲解：**
> "这是我们要审计的智能合约 — VulnerableBank。它有一个经典的 reentrancy 漏洞。让我们看看 GLM-5.1 能否自动发现它。"

**屏幕焦点：** 终端，显示合约代码

---

### [0:30-2:00] 启动 GLM-5.1 审计

**终端操作：**
```bash
# 启动 MCP 服务器（如果需要）
npm run mcp:start

# 执行 GLM-5.1 审计
pi -p --thinking xhigh "
请审计 contracts/test-cases/Reentrancy.sol，执行完整 8 步审计流程：
1. 读取合约代码
2. 使用 slither 工具进行静态分析
3. 使用 aderyn 工具进行二次扫描
4. 查询知识库中关于 reentrancy 的漏洞模式
5. 生成 PoC 测试合约
6. 运行 Foundry fuzz 测试
7. 生成修复建议
8. 调用 eas_attest 工具进行链上认证
9. 返回完整的审计报告（JSON 格式）
"
```

**讲解：**
> "现在启动 GLM-5.1，它会执行完整的 8 步审计流程。注意看，它会调用多个 MCP 工具，包括 slither、aderyn、poc_generator 等。"

**屏幕焦点：** 终端，显示 GLM-5.1 执行过程

**关键点：**
- 展示 GLM-5.1 调用 MCP 工具的过程
- 展示漏洞发现过程
- 展示 PoC 生成过程

---

### [2:00-3:00] 展示审计报告

**浏览器操作：**
1. 打开前端页面：`http://localhost:8765`
2. 点击 "Details" 按钮，展开漏洞详情
3. 展示攻击模拟结果

**讲解：**
> "审计完成！GLM-5.1 发现了 5 个漏洞，其中 1 个 Critical 级别的 reentrancy 漏洞。看，它还生成了攻击模拟，预计损失 $2.3M。"

**屏幕焦点：** 浏览器，显示审计报告页面

**关键点：**
- 展示漏洞列表（5 个漏洞）
- 展示严重性分布（1 Critical, 2 High, 1 Medium, 1 Low）
- 展示攻击模拟（$2.3M 预计损失）

---

### [3:00-3:30] 展示 PoC 测试通过

**终端操作：**
```bash
# 运行 PoC 测试
forge test --match-contract ReentrancyExploit -vvv
```

**讲解：**
> "GLM-5.1 还生成了 PoC 测试合约。看，测试通过了！这证明漏洞是真实存在的。"

**屏幕焦点：** 终端，显示测试结果

**关键点：**
- 展示测试通过（PASS）
- 展示 gas 消耗
- 展示测试详情

---

### [3:30-4:30] 展示 NFT 铸造

**浏览器操作：**
1. 打开 NFT 预览页面：`http://localhost:8765/nft-preview.html`
2. 展示 3 个等级的 NFT（Gold, Silver, Bronze）
3. 点击 "Mint Certificate NFT" 按钮

**讲解：**
> "审计完成后，GLM-5.1 会自动铸造 NFT 证书。看，这是 uPEG 风格的 generative 雅典娜女神，有 12,000 种组合。"

**屏幕焦点：** 浏览器，显示 NFT 预览页面

**关键点：**
- 展示 3 个等级的 NFT
- 展示 trait 组合（helmet, shield, color, weapon, background, eyes）
- 展示稀有度（rarity score）

---

### [4:30-5:00] 展示链上验证

**浏览器操作：**
1. 打开 Etherscan：`https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5`
2. 点击 "Token" 标签，展示 NFT 铸造记录
3. 打开 EAS：`https://sepolia.easscan.org`
4. 搜索 EAS UID，展示认证记录

**讲解：**
> "所有审计结果都记录在链上。看，这是 Etherscan 上的 NFT 铸造记录，这是 EAS 上的认证记录。所有数据都是不可篡改的。"

**屏幕焦点：** 浏览器，显示 Etherscan 和 EAS 页面

**关键点：**
- 展示 NFT 铸造记录
- 展示 EAS 认证记录
- 展示链上数据不可篡改

---

## 录屏软件设置

### macOS 自带录屏
1. 按 `Cmd + Shift + 5`
2. 选择 "录制整个屏幕" 或 "录制所选部分"
3. 点击 "录制" 按钮
4. 开始 Demo

### OBS（推荐）
1. 下载 OBS：https://obsproject.com
2. 设置：
   - 场景：屏幕录制
   - 来源：显示器捕获
   - 输出：MP4，1920x1080，30fps
3. 开始录制

---

## 关键展示点

### 1. GLM-5.1 长程任务能力
- 单次会话完成 8 步审计
- 协调 13 个 MCP 工具
- 跨步骤传递上下文

### 2. Agent 自主生产
- 自动发现漏洞
- 自动生成 PoC
- 自动上链认证
- 自动铸造 NFT

### 3. 链上可验证
- EAS 认证
- NFT 铸造
- 所有数据不可篡改

---

## 备用方案

如果 GLM-5.1 审计失败，使用备用方案：

**备用方案 1：使用现有 report.json**
```bash
# 展示现有审计报告
cat demo/report.json
```

**备用方案 2：手动执行步骤**
```bash
# 手动执行每个步骤
forge test --match-contract ReentrancyExploit -vvv
```

---

## 剪辑建议

### 剪辑软件
- **macOS**：iMovie（免费）
- **Windows**：Clipchamp（免费）
- **跨平台**：DaVinci Resolve（免费）

### 剪辑要点
1. **删除等待时间**：GLM-5.1 执行时的等待时间可以剪掉
2. **加速终端输出**：终端输出可以 2x 加速
3. **添加字幕**：关键步骤添加字幕
4. **添加背景音乐**：轻音乐，不要有歌词

### 视频格式
- 分辨率：1920x1080
- 帧率：30fps
- 格式：MP4
- 时长：3-5 分钟
