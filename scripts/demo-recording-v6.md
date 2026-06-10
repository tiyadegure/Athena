# Athena Demo 录屏脚本（v6 完整版）

## 核心叙事

**GLM-5.1 的长程任务能力**

> 别的 AI：读一个合约 → 找一个 bug
> 我们：理解整个协议 → 生成攻击脚本 → 多轮修复验证 → 增量审计 → 链上认证 → 铸造 NFT（S/A/B/C 四级）

---

## 项目产物（完整）

### 合约（24 个）
- **核心合约**：AuditCertificate.sol（S/A/B/C 四级 NFT）、AuditEvidenceChain.sol
- **多合约**：Token.sol、Oracle.sol、Vault.sol、Vault-v2.sol（增量审计）
- **期权**：OptionsIndexTracker.sol、RebalancingStrategy.sol、SyntheticOption.sol
- **真实协议**：curve-pool.sol、hundred-finance.sol
- **测试合约**：17 个（Reentrancy、FlashLoan、AccessControl、IntegerOverflow 等）
- **PoC**：ReentrancyExploit.s.sol、FlashLoanExploit.s.sol、Reentrancy.t.sol
- **修复**：Reentrancy-fixed.sol

### MCP 工具（13 个）
- slither_runner.py、aderyn_runner.py、poc_generator.py、fuzz_runner.py
- knowledge_base.py、eas_attest.py、exploit_simulator.py、evidence_chain.py
- halmos_runner.py、protocol_scanner.py、repair_validator.py、incremental_auditor.py、gev_analyzer.py

### 前端
- frontend/index.html + app.js + style.css
- demo/nft-preview.html（S/A/B/C 四级预览）
- demo/report.json

### 脚本
- scripts/real-audit-v6.sh（GLM-5.1 驱动的完整审计脚本）

### PPT 素材（14 个）
- architecture.svg、skill-agents.svg、mcp-tools.svg
- audit-report.svg、onchain-verification.svg
- nft-preview.png、nft-preview-full.png、nft-gold.png、nft-silver.png
- frontend-screenshot.png、report.json、test-results.txt
- ppt-outline.md、README.md

### 链上部署
- NFT 合约：0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c
- 证据链合约：0x5e99f144D3e512f525d24077D4626a064899E177
- EAS 合约：0xC2679fBD37d54388Ce493F1DB75320D236e1815e
- 网络：Sepolia 测试网

### 测试状态
- 23/23 测试通过
- 2 个测试套件

### NFT 等级（v6）
- **S 级（炫彩）**：100 分 + Critical，彩虹渐变 + 动态光晕，最稀有
- **A 级（金）**：80-99 分，金色雅典娜
- **B 级（银）**：60-79 分，银色雅典娜
- **C 级（铜）**：<60 分，铜色雅典娜
- 总组合：262,144 种（4^9 seed-based）

---

## Demo 流程（5 分钟）

### [0:00-0:30] 开场 — 展示项目结构

**终端操作：**
```bash
cd /root/projects/glm-code
tree -L 2 -I 'node_modules|.pi|lib|out|cache'
```

**讲解：**
> "这是 Athena，一个基于 GLM-5.1 的 Web3 安全审计系统。项目包含 24 个合约、13 个 MCP 工具、14 个 PPT 素材。"

---

### [0:30-1:00] 展示待审计合约

**终端操作：**
```bash
cat contracts/multi-contract/Token.sol
cat contracts/multi-contract/Oracle.sol
cat contracts/multi-contract/Vault.sol
```

**讲解：**
> "这是一个 DeFi 协议，包含 Token、Oracle、Vault 三个合约。它们有跨合约依赖关系。现在让我们用 GLM-5.1 来审计它。"

---

### [1:00-2:30] 启动 GLM-5.1 审计脚本

**终端操作：**
```bash
chmod +x scripts/real-audit-v6.sh
./scripts/real-audit-v6.sh
```

**讲解：**
> "现在启动 GLM-5.1 审计脚本。GLM-5.1 会作为 LLM 层，协调 13 个 MCP 工具执行完整的 8 步审计流程。"

**关键展示点：**
- GLM-5.1 分析合约结构（protocol_scanner）
- GLM-5.1 调用 Slither（slither_runner）
- GLM-5.1 调用 Aderyn（aderyn_runner）
- GLM-5.1 查询知识库（knowledge_base）
- GLM-5.1 生成攻击模拟（exploit_simulator）
- GLM-5.1 生成 PoC（poc_generator）
- GLM-5.1 运行 Fuzz 测试（fuzz_runner）
- GLM-5.1 生成审计报告

**注意：**
- 如果 GLM-5.1 执行时间过长，可以剪辑加速
- 重点展示 GLM-5.1 调用 MCP 工具的过程
- 重点展示漏洞发现和 PoC 生成

---

### [2:30-3:00] 展示审计结果

**终端操作：**
```bash
# 展示生成的 PoC
cat contracts/test-cases/poc/Reentrancy.t.sol

# 展示测试结果
forge test -vv | tail -30

# 展示审计报告
cat demo/report.json
```

**讲解：**
> "审计完成！GLM-5.1 发现了 5 个漏洞，其中 1 个 Critical 级别的 reentrancy 漏洞。它还生成了 PoC 测试合约，并通过了 Foundry 验证。"

---

### [3:00-3:30] 链上认证 — EAS Attestation

**浏览器操作：**
- 打开 EAS 认证页面：`https://sepolia.easscan.org`
- 搜索 EAS UID，展示认证记录

**讲解：**
> "审计结果通过 EAS 认证记录在链上，不可篡改。"

---

### [3:30-4:00] NFT 铸造 — S/A/B/C 四级

**浏览器操作：**
- 打开 NFT 预览页面：`http://localhost:8765/nft-preview.html`
- 展示 4 个等级的 NFT：
  - **S 级（炫彩）**：彩虹渐变 + 动态光晕，最稀有
  - **A 级（金）**：金色雅典娜
  - **B 级（银）**：银色雅典娜
  - **C 级（铜）**：铜色雅典娜

**讲解：**
> "基于审计结果，铸造 uPEG 风格的 generative 雅典娜 NFT。有 4 个等级：S 级是最稀有的，需要 100 分审计 + Critical 漏洞才能获得，有彩虹渐变和动态光晕效果。总共有 262,144 种组合。"

---

### [4:00-4:30] 链上验证 — Etherscan

**浏览器操作：**
- 打开 Etherscan：`https://sepolia.etherscan.io/address/0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c`
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
[0:30-1:00] 终端：待审计合约（Token+Oracle+Vault）
     ↓
[1:00-2:30] 终端：运行审计脚本 ⭐
            ./scripts/real-audit-v6.sh
            GLM-5.1 实时执行 8 步审计
     ↓
[2:30-3:00] 终端：展示审计结果（PoC + 测试 + 报告）
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

1. **EAS 认证** — `https://sepolia.easscan.org`
2. **NFT 预览** — `http://localhost:8765/nft-preview.html`
3. **Etherscan 合约** — `https://sepolia.etherscan.io/address/0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c`
4. **GitHub 仓库** — `https://github.com/tiyadegure/glm-code`

---

## 终端窗口（提前准备）

- 工作目录：`/root/projects/glm-code`
- 已安装：Foundry、Node.js
- 审计脚本：`./scripts/real-audit-v6.sh`

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

### 5. NFT 分级系统（v6）
- **S 级（炫彩）**：100 分 + Critical，彩虹渐变 + 动态光晕，最稀有
- **A 级（金）**：80-99 分，金色雅典娜
- **B 级（银）**：60-79 分，银色雅典娜
- **C 级（铜）**：<60 分，铜色雅典娜
- 总组合：262,144 种（4^9 seed-based）

---

## NFT 等级详解（v6）

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
1. **删除等待时间**：审计脚本执行时的等待时间可以剪辑加速
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

如果审计脚本执行失败，使用备用方案：

### 备用方案 1：使用现有产物
```bash
# 展示现有审计报告
cat demo/report.json

# 展示 PoC 测试
forge test -vv | tail -30
```

### 备用方案 2：手动执行步骤
```bash
# 手动执行每个步骤
cat contracts/multi-contract/Token.sol
cat contracts/multi-contract/Oracle.sol
cat contracts/multi-contract/Vault.sol
forge test -vv | tail -30
cat demo/report.json
```

---

## 产物清单（完整）

### 合约（24 个）
- `contracts/AuditCertificate.sol` — NFT 合约（S/A/B/C 四级）
- `contracts/AuditEvidenceChain.sol` — 证据链合约
- `contracts/multi-contract/Token.sol` — ERC20 代币
- `contracts/multi-contract/Oracle.sol` — 预言机
- `contracts/multi-contract/Vault.sol` — 金库
- `contracts/multi-contract/Vault-v2.sol` — 升级版金库（增量审计）
- `contracts/options-index/OptionsIndexTracker.sol` — 期权指数追踪
- `contracts/options-index/RebalancingStrategy.sol` — 再平衡策略
- `contracts/options-index/SyntheticOption.sol` — 合成期权
- `contracts/real-world/curve-pool.sol` — Curve 真实协议
- `contracts/real-world/hundred-finance.sol` — Hundred Finance 真实协议
- `contracts/test-cases/AccessControl.sol` — 访问控制漏洞
- `contracts/test-cases/AgentEscrow.sol` — Agent 托管
- `contracts/test-cases/AgentIdentity.sol` — Agent 身份
- `contracts/test-cases/FlashLoan.sol` — 闪电贷漏洞
- `contracts/test-cases/GEVTest.sol` — GEV 测试
- `contracts/test-cases/IntegerOverflow.sol` — 整数溢出漏洞
- `contracts/test-cases/PrivacyToken.sol` — 隐私代币
- `contracts/test-cases/ReadOnlyReentrancy.sol` — 只读重入漏洞
- `contracts/test-cases/Reentrancy.sol` — 重入漏洞
- `contracts/test-cases/SafeContract.sol` — 安全合约（无漏洞）
- `contracts/test-cases/fixes/Reentrancy-fixed.sol` — 修复后的重入
- `contracts/test-cases/poc/ReentrancyExploit.s.sol` — 重入攻击脚本
- `contracts/test-cases/poc/FlashLoanExploit.s.sol` — 闪电贷攻击脚本
- `contracts/test-cases/poc/Reentrancy.t.sol` — 重入测试
- `contracts/test/AuditCertificate.t.sol` — NFT 测试

### MCP 工具（13 个）
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

### 审计脚本
- `scripts/real-audit-v6.sh` — GLM-5.1 驱动的完整审计脚本
- `scripts/real-audit-llm.sh` — 基础 LLM 审计脚本
- `scripts/real-audit.sh` — 基础审计脚本

### 前端
- `frontend/index.html` — 审计报告页面
- `frontend/app.js` — 逻辑
- `frontend/style.css` — 样式
- `demo/nft-preview.html` — NFT 预览页面（S/A/B/C 四级）
- `demo/report.json` — 审计报告示例

### PPT 素材（14 个）
- `ppt-assets/architecture.svg` — 架构图
- `ppt-assets/skill-agents.svg` — 12 Agent 结构
- `ppt-assets/mcp-tools.svg` — 13 MCP 工具
- `ppt-assets/audit-report.svg` — 审计报告
- `ppt-assets/onchain-verification.svg` — 链上验证
- `ppt-assets/nft-preview.png` — 3 等级 NFT
- `ppt-assets/nft-preview-full.png` — NFT 完整页面
- `ppt-assets/nft-gold.png` — 金级特写
- `ppt-assets/nft-silver.png` — 银级特写
- `ppt-assets/frontend-screenshot.png` — 前端页面
- `ppt-assets/report.json` — 审计数据
- `ppt-assets/test-results.txt` — 测试结果
- `ppt-assets/ppt-outline.md` — PPT 大纲
- `ppt-assets/README.md` — 素材说明

### 文档
- `workflows/v5-long-horizon.md` — 完整 8 步闭环设计
- `workflows/v6-s-tier-nft.md` — S 级 NFT 设计
- `workflows/project-feature-scan.md` — 项目特征查找
- `scripts/demo-recording-v6.md` — 本脚本
