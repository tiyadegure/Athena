# Athena Demo 录屏脚本（v6 版本）

## 核心叙事

**GLM-5.1 的长程任务能力**

> 别的 AI：读一个合约 → 找一个 bug
> 我们：理解整个协议 → 生成攻击脚本 → 多轮修复验证 → 增量审计 → 链上认证 → 铸造 NFT（S/A/B/C 四级）

---

## Demo 流程（5 分钟）

### [0:00-0:30] 开场 — 展示项目结构

**终端操作：**
```bash
cd /root/projects/glm-code
tree -L 2 -I 'node_modules|.pi|lib'
```

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

**讲解：**
> "Step 1: 协议级审计。GLM-5.1 不是只看一个合约，而是理解整个协议。它分析了 Token、Oracle、Vault 三个合约的调用关系，发现了跨合约漏洞。"

---

### [1:30-2:30] Step 2: 攻击模拟 — 展示端到端攻击链

**终端操作：**
```bash
# 展示 PoC 测试
cat contracts/test-cases/poc/ReentrancyExploit.t.sol

# 运行测试
forge test --match-contract ReentrancyExploit -vvv
```

**讲解：**
> "Step 2: 攻击模拟。GLM-5.1 不只是找 bug，还能证明 bug 可被利用。它生成了完整的 PoC 测试合约，并通过了 Foundry 验证。"

---

### [2:30-3:00] Step 3-5: 多轮修复验证 + 增量审计

**终端操作：**
```bash
# 展示修复后的合约
cat contracts/test-cases/fixes/Reentrancy-fixed.sol

# 展示增量审计
cat contracts/multi-contract/Vault-v2.sol
```

**讲解：**
> "Step 3-5: 多轮修复验证和增量审计。GLM-5.1 给出修复建议，应用修复后重新审计，对比前后差异。它还能在合约升级后只审计变化部分，复用上次的审计上下文。"

---

### [3:00-3:30] Step 6: 链上认证 — EAS Attestation

**浏览器操作：**
- 打开 EAS 认证页面：`https://sepolia.eas.xyz`
- 搜索 EAS UID，展示认证记录

**讲解：**
> "Step 6: 链上认证。所有审计结果都记录在链上，通过 EAS 认证，不可篡改。"

---

### [3:30-4:00] Step 7: NFT 铸造 — S/A/B/C 四级

**浏览器操作：**
- 打开 NFT 预览页面：`http://localhost:8765/nft-preview.html`
- 展示 4 个等级的 NFT：
  - **S 级（炫彩）**：彩虹渐变 + 动态光晕，最稀有
  - **A 级（金）**：金色雅典娜
  - **B 级（银）**：银色雅典娜
  - **C 级（铜）**：铜色雅典娜

**讲解：**
> "Step 7: NFT 铸造。uPEG 风格的 generative 雅典娜 NFT，有 4 个等级：S 级是最稀有的，需要 100 分审计 + Critical 漏洞才能获得，有彩虹渐变和动态光晕效果。总共有 12,064 种组合。"

---

### [4:00-4:30] Step 8: 链上验证 — Etherscan

**浏览器操作：**
- 打开 Etherscan：`https://sepolia.etherscan.io/address/0xcaA7faeA44C3513F629C6f260ad26EBB677E5E4E`
- 展示 NFT 铸造记录
- 展示合约代码

**讲解：**
> "所有数据都在链上可验证。这是 Etherscan 上的 NFT 铸造记录，这是合约代码。所有数据都是不可篡改的。"

---

### [4:30-5:00] 总结

**浏览器操作：**
- 打开 GitHub 仓库：`https://github.com/tiyadegure/glm-code`
- 展示项目结构

**讲解：**
> "Athena 展示了 GLM-5.1 的长程任务能力：单次会话完成 8 步审计闭环，协调 13 个 MCP 工具，生成可验证的链上产物。S 级 NFT 代表最高质量的审计成果，只有 100 分 + Critical 漏洞才能获得。这是 Web3 Agent 经济的雏形。"

---

## 操作流程图

```
[0:00-0:30] 终端：项目结构
     ↓
[0:30-1:30] 终端：合约代码（Token+Oracle+Vault）
     ↓
[1:30-2:30] 终端：PoC 代码 + 测试结果
     ↓
[2:30-3:00] 终端：修复后合约 + 增量审计
     ↓
[3:00-3:30] 浏览器：EAS 认证页面
     ↓
[3:30-4:00] 浏览器：NFT 预览页面（S/A/B/C）
     ↓
[4:00-4:30] 浏览器：Etherscan 合约页面
     ↓
[4:30-5:00] 浏览器：GitHub 仓库
```

---

## 浏览器标签页（提前打开）

1. **EAS 认证** — `https://sepolia.eas.xyz`
2. **NFT 预览** — `http://localhost:8765/nft-preview.html`
3. **Etherscan 合约** — `https://sepolia.etherscan.io/address/0xcaA7faeA44C3513F629C6f260ad26EBB677E5E4E`
4. **GitHub 仓库** — `https://github.com/tiyadegure/glm-code`

---

## 终端窗口（提前准备）

- 工作目录：`/root/projects/glm-code`
- 已安装：Foundry、Node.js

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

### 5. NFT 分级系统（v6 新增）
- **S 级（炫彩）**：100 分 + Critical 漏洞，彩虹渐变 + 动态光晕，最稀有
- **A 级（金）**：高分审计，金色雅典娜
- **B 级（银）**：中等审计，银色雅典娜
- **C 级（铜）**：基础审计，铜色雅典娜
- 总组合：12,064 种（12,000 + 64 S 级）

---

## NFT 等级详解（v6 新增）

### S 级（炫彩）
- **触发条件**：审计得分 100 分 + Critical 漏洞
- **视觉效果**：彩虹渐变背景 + 动态光晕 + 特殊边框
- **稀有度**：最稀有，每 1000 次审计约 1-5 次
- **新增 trait**：aura（光晕）、crown（头饰）、wings（翅膀）

### A 级（金）
- **触发条件**：高分审计（80-99 分）
- **视觉效果**：金色雅典娜
- **稀有度**：稀有

### B 级（银）
- **触发条件**：中等审计（60-79 分）
- **视觉效果**：银色雅典娜
- **稀有度**：中等

### C 级（铜）
- **触发条件**：基础审计（<60 分）
- **视觉效果**：铜色雅典娜
- **稀有度**：普通

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
4. **突出 S 级 NFT**：在 Step 7 处添加特效说明

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
- `contracts/AuditCertificate.sol` — NFT 合约（v6: S/A/B/C 四级）
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
- `demo/nft-preview.html` — NFT 预览页面（v6: S/A/B/C 四级）

### 文档
- `workflows/v5-long-horizon.md` — 完整 8 步闭环设计
- `workflows/v6-s-tier-nft.md` — S 级 NFT 设计
- `scripts/demo-recording-v6.md` — 本脚本
