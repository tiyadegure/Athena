# 项目特征查找 Workflow（内部使用）

## 目的

在编写 Demo 脚本、审计脚本、PPT 大纲之前，先完整了解项目的所有产物和特性，避免遗漏。

## 步骤

### Step 1: 扫描项目结构

```bash
# 获取完整文件树（排除 node_modules、lib、out）
find . -maxdepth 3 -type f \( -name '*.sol' -o -name '*.py' -o -name '*.js' -o -name '*.html' -o -name '*.sh' -o -name '*.json' -o -name '*.md' \) | grep -v node_modules | grep -v .pi | grep -v lib | sort
```

### Step 2: 分类产物

**合约（contracts/）：**
- `AuditCertificate.sol` — NFT 合约（S/A/B/C 四级，262,144 种组合）
- `AuditEvidenceChain.sol` — 证据链合约
- `multi-contract/` — Token+Oracle+Vault（跨合约漏洞）
- `multi-contract/Vault-v2.sol` — 升级版 Vault（增量审计）
- `options-index/` — 期权合成资产（前沿技术）
- `real-world/` — 真实协议（Curve、Hundred Finance）
- `test-cases/` — 17 个测试合约
- `test-cases/poc/` — PoC 测试
- `test-cases/fixes/` — 修复后的合约
- `test/AuditCertificate.t.sol` — NFT 测试

**MCP 工具（mcp/tools/）：**
- `slither_runner.py` — 静态分析
- `aderyn_runner.py` — Rust 静态分析
- `poc_generator.py` — PoC 生成
- `fuzz_runner.py` — Foundry fuzz 测试
- `knowledge_base.py` — RAG 知识库
- `eas_attest.py` — EAS 链上认证
- `exploit_simulator.py` — 攻击模拟器
- `evidence_chain.py` — 审计证据链
- `halmos_runner.py` — 形式化验证
- `protocol_scanner.py` — 协议级扫描
- `repair_validator.py` — 修复验证
- `incremental_auditor.py` — 增量审计
- `gev_analyzer.py` — GEV 分析

**Skill（skills/）：**
- `glm-audit-skill/SKILL.md` — 12 Agent 审计方法论

**前端（frontend/）：**
- `index.html` — 审计报告页面
- `app.js` — 逻辑
- `style.css` — 样式

**Demo（demo/）：**
- `nft-preview.html` — NFT 预览（S/A/B/C 四级）
- `report.json` — 审计报告示例

**脚本（scripts/）：**
- `real-audit-llm.sh` — GLM-5.1 驱动的审计脚本
- `real-audit.sh` — 基础审计脚本

**PPT 素材（ppt-assets/）：**
- `architecture.svg` — 架构图
- `skill-agents.svg` — 12 Agent 结构
- `mcp-tools.svg` — 13 MCP 工具
- `audit-report.svg` — 审计报告
- `onchain-verification.svg` — 链上验证
- `nft-preview.png` — 3 等级 NFT
- `nft-preview-full.png` — NFT 完整页面
- `nft-gold.png` — 金级特写
- `nft-silver.png` — 银级特写
- `frontend-screenshot.png` — 前端页面
- `ppt-outline.md` — PPT 大纲

**文档（workflows/）：**
- `v5-long-horizon.md` — 完整 8 步闭环设计
- `v6-s-tier-nft.md` — S 级 NFT 设计
- `v5.1-cleanup.md` — 清理
- `v5.2-frontend-demo.md` — 前端
- `v5.3-deploy-sepolia.md` — 部署
- `v5.4-redeploy.md` — 重新部署

**部署信息：**
- NFT 合约：`0x3247d57d37bd1878479f03a077aba807649dbaf5`
- 证据链合约：`0x5e99f144D3e512f525d24077D4626a064899E177`
- EAS 合约：`0xC2679fBD37d54388Ce493F1DB75320D236e1815e`
- 网络：Sepolia 测试网
- 部署钱包：`0x7b5538AAd3b048bAe0EFF2b457C59B8FE98032B8`

### Step 3: 检查测试状态

```bash
# 运行测试
forge test

# 预期结果：23/23 通过
```

### Step 4: 检查前端状态

```bash
# 启动前端
cd frontend && python3 -m http.server 8765

# 访问 http://localhost:8765
```

### Step 5: 检查 NFT 预览

```bash
# 访问 http://localhost:8765/nft-preview.html
# 检查 S/A/B/C 四级是否都有展示
```

### Step 6: 检查链上状态

```bash
# 检查 NFT 合约
cast code 0x3247d57d37bd1878479f03a077aba807649dbaf5 --rpc-url https://ethereum-sepolia-rpc.publicnode.com

# 检查 EAS 合约
cast code 0xC2679fBD37d54388Ce493F1DB75320D236e1815e --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

### Step 7: 记录发现

将发现的产物和特性记录到 memory 或 workflow 文件中，供后续使用。

---

## 产物清单（完整）

### 合约（24 个）
1. `AuditCertificate.sol` — NFT 合约（S/A/B/C 四级）
2. `AuditEvidenceChain.sol` — 证据链合约
3. `Token.sol` — ERC20 代币
4. `Oracle.sol` — 预言机
5. `Vault.sol` — 金库
6. `Vault-v2.sol` — 升级版金库（增量审计）
7. `OptionsIndexTracker.sol` — 期权指数追踪
8. `RebalancingStrategy.sol` — 再平衡策略
9. `SyntheticOption.sol` — 合成期权
10. `curve-pool.sol` — Curve 真实协议
11. `hundred-finance.sol` — Hundred Finance 真实协议
12. `AccessControl.sol` — 访问控制漏洞
13. `AgentEscrow.sol` — Agent 托管
14. `AgentIdentity.sol` — Agent 身份
15. `FlashLoan.sol` — 闪电贷漏洞
16. `GEVTest.sol` — GEV 测试
17. `IntegerOverflow.sol` — 整数溢出漏洞
18. `PrivacyToken.sol` — 隐私代币
19. `ReadOnlyReentrancy.sol` — 只读重入漏洞
20. `Reentrancy.sol` — 重入漏洞
21. `SafeContract.sol` — 安全合约（无漏洞）
22. `Reentrancy-fixed.sol` — 修复后的重入
23. `ReentrancyExploit.s.sol` — 重入攻击脚本
24. `FlashLoanExploit.s.sol` — 闪电贷攻击脚本

### MCP 工具（13 个）
1. `slither_runner.py` — 静态分析
2. `aderyn_runner.py` — Rust 静态分析
3. `poc_generator.py` — PoC 生成
4. `fuzz_runner.py` — Foundry fuzz 测试
5. `knowledge_base.py` — RAG 知识库
6. `eas_attest.py` — EAS 链上认证
7. `exploit_simulator.py` — 攻击模拟器
8. `evidence_chain.py` — 审计证据链
9. `halmos_runner.py` — 形式化验证
10. `protocol_scanner.py` — 协议级扫描
11. `repair_validator.py` — 修复验证
12. `incremental_auditor.py` — 增量审计
13. `gev_analyzer.py` — GEV 分析

### 前端
1. `frontend/index.html` — 审计报告页面
2. `frontend/app.js` — 逻辑
3. `frontend/style.css` — 样式
4. `demo/nft-preview.html` — NFT 预览（S/A/B/C 四级）
5. `demo/report.json` — 审计报告示例

### 脚本
1. `scripts/real-audit-llm.sh` — GLM-5.1 驱动的审计脚本
2. `scripts/real-audit.sh` — 基础审计脚本

### PPT 素材（14 个）
1. `ppt-assets/architecture.svg` — 架构图
2. `ppt-assets/skill-agents.svg` — 12 Agent 结构
3. `ppt-assets/mcp-tools.svg` — 13 MCP 工具
4. `ppt-assets/audit-report.svg` — 审计报告
5. `ppt-assets/onchain-verification.svg` — 链上验证
6. `ppt-assets/nft-preview.png` — 3 等级 NFT
7. `ppt-assets/nft-preview-full.png` — NFT 完整页面
8. `ppt-assets/nft-gold.png` — 金级特写
9. `ppt-assets/nft-silver.png` — 银级特写
10. `ppt-assets/frontend-screenshot.png` — 前端页面
11. `ppt-assets/report.json` — 审计数据
12. `ppt-assets/test-results.txt` — 测试结果
13. `ppt-assets/ppt-outline.md` — PPT 大纲
14. `ppt-assets/README.md` — 素材说明

### 链上部署
- NFT 合约：`0x3247d57d37bd1878479f03a077aba807649dbaf5`
- 证据链合约：`0x5e99f144D3e512f525d24077D4626a064899E177`
- EAS 合约：`0xC2679fBD37d54388Ce493F1DB75320D236e1815e`
- 网络：Sepolia 测试网
- 部署钱包：`0x7b5538AAd3b048bAe0EFF2b457C59B8FE98032B8`

### 测试状态
- 23/23 测试通过
- 2 个测试套件：AuditCertificateTest + ReentrancyExploitTest

### NFT 等级（v6）
- **S 级（炫彩）**：100 分 + Critical 漏洞，彩虹渐变 + 动态光晕，最稀有
- **A 级（金）**：高分审计（80-99 分），金色雅典娜
- **B 级（银）**：中等审计（60-79 分），银色雅典娜
- **C 级（铜）**：基础审计（<60 分），铜色雅典娜
- 总组合：262,144 种（4^9 seed-based）
