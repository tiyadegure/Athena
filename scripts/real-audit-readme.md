# Athena 真实审计脚本

## 使用方法

```bash
# 运行审计脚本
./scripts/real-audit.sh
```

## 脚本流程

### Step 1: 读取合约代码
- 读取 `contracts/test-cases/Reentrancy.sol`
- 展示 VulnerableBank 合约

### Step 2: Slither 静态分析
- 使用 Slither 进行静态分析
- 如果 Slither 未安装，使用 GLM-5.1 分析

### Step 3: Aderyn 深度分析
- 使用 Aderyn 进行二次扫描
- 如果 Aderyn 未安装，使用 GLM-5.1 深度分析

### Step 4: 生成 PoC
- 生成 `ReentrancyExploit.t.sol`
- 使用 GLM-5.1 生成攻击合约

### Step 5: 运行 Foundry 测试
- 运行 PoC 测试
- 验证漏洞可利用性

### Step 6: 生成审计报告
- 生成 `demo/report.json`
- 包含漏洞发现和修复建议

### Step 7: 生成修复建议
- 使用 GLM-5.1 生成修复代码
- 提供 checks-effects-interactions 模式

### Step 8: 展示 NFT 铸造信息
- 展示合约地址
- 展示铸造命令

## 产物

### 文件
- `contracts/test-cases/poc/ReentrancyExploit.t.sol` — PoC 测试
- `demo/report.json` — 审计报告

### 链上验证
- Etherscan: https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5
- EAS: https://sepolia.easscan.org

## Demo 录屏

### 准备工作
1. 打开终端，进入项目目录
2. 打开浏览器标签页：
   - GitHub 仓库
   - Etherscan 合约
   - EAS 认证
   - 前端页面

### 录屏流程
1. 运行脚本：`./scripts/real-audit.sh`
2. 边跑边录屏（5 分钟）
3. 展示每个步骤的输出
4. 最后展示链上验证

### 关键展示点
- GLM-5.1 执行 8 步审计
- 调用 MCP 工具（Slither、Aderyn）
- 生成 PoC 并测试通过
- 生成审计报告
- 链上认证和 NFT 铸造

## 备用方案

如果 GLM-5.1 执行失败，使用备用方案：

### 备用方案 1：手动执行步骤
```bash
# 手动执行每个步骤
cat contracts/test-cases/Reentrancy.sol
forge test --match-contract ReentrancyExploit -vvv
cat demo/report.json
```

### 备用方案 2：使用现有产物
```bash
# 展示现有审计报告
cat demo/report.json

# 展示 PoC 测试
forge test --match-contract ReentrancyExploit -vvv
```

## 时间估算

- Step 1-3: 1-2 分钟（静态分析）
- Step 4-5: 1-2 分钟（PoC 生成和测试）
- Step 6-8: 1-2 分钟（报告和修复建议）

**总计：3-6 分钟**
