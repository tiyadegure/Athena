# Athena Demo 录屏脚本（完整版）

## 核心叙事

**GLM-5.1 的长程任务能力**

> 别的 AI：读一个合约 → 找一个 bug
> 我们：理解整个协议 → 生成攻击脚本 → 多轮修复验证 → 增量审计 → 链上认证 → 铸造 NFT

---

## Demo 流程（5 分钟）

### [0:00-0:30] 开场 — 展示项目结构

**终端操作：**
```bash
cd /root/projects/glm-code
tree -L 2 -I 'node_modules|.pi|lib'
```

**浏览器操作：**
- 打开 GitHub 仓库：`https://github.com/tiyadegure/glm-code`

**讲解：**
> "这是 Athena，一个基于 GLM-5.1 的 Web3 安全审计系统。项目包含 12 个审计 Agent、13 个 MCP 工具、17 个测试合约。"

---

### [0:30-1:30] Step 1: 协议级审计 — 展示跨合约理解能力

**终端操作：**
```bash
# 展示多合约目录
cat contracts/multi-contract/Token.sol
cat contracts/multi-contract/Oracle.sol
cat contracts/multi-contract/Vault.sol
```

**浏览器操作：**
- 打开前端页面：`http://localhost:8765`
- 展示审计报告中的跨合约漏洞

**讲解：**
> "Step 1: 协议级审计。GLM-5.1 不是只看一个合约，而是理解整个协议。它分析了 Token、Oracle、Vault 三个合约的调用关系，发现了跨合约漏洞。"

**关键点：**
- 展示 3 个合约的依赖关系
- 展示 12 个 Agent 并行扫描
- 展示跨合约漏洞发现

---

### [1:30-2:30] Step 2: 攻击模拟 — 展示端到端攻击链

**终端操作：**
```bash
# 展示 PoC 测试
cat contracts/test-cases/poc/ReentrancyExploit.t.sol

# 运行测试
forge test --match-contract ReentrancyExploit -vvv
```

**浏览器操作：**
- 打开前端页面，展示攻击模拟结果
- 展示预计损失：$2.3M

**讲解：**
> "Step 2: 攻击模拟。GLM-5.1 不只是找 bug，还能证明 bug 可被利用。它生成了完整的 PoC 测试合约，并通过了 Foundry 验证。"

**关键点：**
- 展示 PoC 代码
- 展示测试通过
- 展示攻击模拟结果

---

### [2:30-3:30] Step 3-5: 多轮修复验证 + 增量审计

**终端操作：**
```bash
# 展示修复后的合约
cat contracts/test-cases/fixes/Reentrancy-fixed.sol

# 展示增量审计
cat contracts/multi-contract/Vault-v2.sol
```

**浏览器操作：**
- 打开前端页面，展示修复验证结果
- 展示增量审计报告

**讲解：**
> "Step 3-5: 多轮修复验证和增量审计。GLM-5.1 给出修复建议，应用修复后重新审计，对比前后差异。它还能在合约升级后只审计变化部分，复用上次的审计上下文。"

**关键点：**
- 展示修复建议
- 展示修复后重新审计
- 展示增量审计能力

---

### [3:30-4:30] Step 6-7: 链上认证 + NFT 铸造

**浏览器操作：**
1. 打开 EAS 认证页面：`https://sepolia.easscan.org`
2. 搜索 EAS UID，展示认证记录
3. 打开 NFT 预览页面：`http://localhost:8765/nft-preview.html`
4. 展示 3 个等级的 NFT（Gold, Silver, Bronze）
5. 打开 Etherscan：`https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5`
6. 展示 NFT 铸造记录

**讲解：**
> "Step 6-7: 链上认证和 NFT 铸造。所有审计结果都记录在链上，通过 EAS 认证，铸造 uPEG 风格的 generative 雅典娜 NFT，有 12,000 种组合。"

**关键点：**
- 展示 EAS 认证
- 展示 NFT 铸造
- 展示链上数据不可篡改

---

### [4:30-5:00] Step 8: 前端展示 + 总结

**浏览器操作：**
1. 打开前端页面：`http://localhost:8765`
2. 展示完整审计流程：findings → verification → attestation
3. 展示 MetaMask 连接（如果可用）
4. 展示 NFT 铸造按钮

**讲解：**
> "Step 8: 前端展示。极简 Web 界面，展示完整审计流程。所有数据都是真实的，所有步骤都是 GLM-5.1 自主完成的。"

**总结：**
> "Athena 展示了 GLM-5.1 的长程任务能力：单次会话完成 8 步审计闭环，协调 13 个 MCP 工具，生成可验证的链上产物。这是 Web3 Agent 经济的雏形。"

---

## 浏览器标签页（提前打开）

1. **GitHub 仓库** — `https://github.com/tiyadegure/glm-code`
2. **前端页面** — `http://localhost:8765`
3. **NFT 预览** — `http://localhost:8765/nft-preview.html`
4. **Etherscan 合约** — `https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5`
5. **EAS 认证** — `https://sepolia.easscan.org`

---

## 终端窗口（提前准备）

- 工作目录：`/root/projects/glm-code`
- 已安装：Foundry、Node.js
- 已启动：前端服务器（`python3 -m http.server 8765`）

---

## 关键展示点

### 1. GLM-5.1 长程任务能力
- 单次会话完成 8 步审计
- 协调 13 个 MCP 工具
- 跨步骤传递上下文（200K 上下文）

### 2. Agent 自主生产
- 自动发现漏洞
- 自动生成 PoC
- 自动上链认证
- 自动铸造 NFT

### 3. 链上可验证
- EAS 认证
- NFT 铸造
- 所有数据不可篡改

### 4. 产品完整度
- 极简前端（纯文字+细线框+monospace）
- 完整审计流程
- 一键铸造 NFT

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

## 剪辑建议

### 剪辑软件
- **macOS**：iMovie（免费）
- **Windows**：Clipchamp（免费）
- **跨平台**：DaVinci Resolve（免费）

### 剪辑要点
1. **删除等待时间**：终端输出可以 2x 加速
2. **添加字幕**：关键步骤添加字幕
3. **添加背景音乐**：轻音乐，不要有歌词

### 视频格式
- 分辨率：1920x1080
- 帧率：30fps
- 格式：MP4
- 时长：3-5 分钟

---

## 备用方案

如果某个步骤失败，使用备用方案：

### 备用方案 1：使用现有产物
```bash
# 展示现有审计报告
cat demo/report.json

# 展示 PoC 测试
forge test --match-contract ReentrancyExploit -vvv
```

### 备用方案 2：手动执行步骤
```bash
# 手动执行每个步骤
cat contracts/test-cases/Reentrancy.sol
forge test --match-contract ReentrancyExploit -vvv
cat demo/report.json
```

---

## 产物清单

### 合约
- `contracts/multi-contract/` — Token+Oracle+Vault（跨合约漏洞）
- `contracts/test-cases/` — 17 个测试合约
- `contracts/test-cases/poc/` — PoC 测试
- `contracts/test-cases/fixes/` — 修复后的合约
- `contracts/AuditCertificate.sol` — NFT 合约
- `contracts/AuditEvidenceChain.sol` — 证据链合约

### MCP 工具
- `mcp/tools/slither_runner.py` — 静态分析
- `mcp/tools/aderyn_runner.py` — Rust 静态分析
- `mcp/tools/poc_generator.py` — PoC 生成
- `mcp/tools/fuzz_runner.py` — Foundry fuzz 测试
- `mcp/tools/knowledge_base.py` — RAG 知识库
- `mcp/tools/eas_attest.py` — EAS 链上认证
- `mcp/tools/exploit_simulator.py` — 攻击模拟器
- `mcp/tools/evidence_chain.py` — 审计证据链
- `mcp/tools/halmos_runner.py` — 形式化验证
- `mcp/tools/protocol_scanner.py` — 协议级扫描
- `mcp/tools/repair_validator.py` — 修复验证
- `mcp/tools/incremental_auditor.py` — 增量审计
- `mcp/tools/gev_analyzer.py` — GEV 分析

### 前端
- `frontend/index.html` — 审计报告页面
- `frontend/style.css` — 样式
- `frontend/app.js` — 逻辑
- `demo/nft-preview.html` — NFT 预览页面

### 文档
- `workflows/v5-long-horizon.md` — 完整 8 步闭环设计
- `scripts/demo-recording-detailed.md` — 详细 Demo 脚本
