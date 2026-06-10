# GLM-5.1 真实审计流程

## 目标

使用 GLM-5.1 执行一次真实的智能合约审计，生成可验证的审计产物。

## 审计目标

**合约：** `contracts/test-cases/Reentrancy.sol` (VulnerableBank)

**已知漏洞：**
- Reentrancy：withdraw() 函数在状态更新前进行外部调用
- 严重性：Critical
- 影响：攻击者可以清空合约余额

## 审计流程（8 步）

### Step 1: 需求理解
```
输入：Reentrancy.sol 合约代码
输出：理解合约功能、识别关键函数
```

### Step 2: 双引擎扫描
```
工具：slither + aderyn
输入：Reentrancy.sol
输出：静态分析结果
```

### Step 3: RAG 知识增强
```
工具：knowledge_base
输入：reentrancy 漏洞模式
输出：相关漏洞知识
```

### Step 4: PoC 生成
```
工具：poc_generator
输入：Reentrancy.sol + 漏洞描述
输出：ReentrancyExploit.t.sol
```

### Step 5: Foundry Fuzz 验证
```
工具：fuzz_runner
输入：ReentrancyExploit.t.sol
输出：测试结果（256 runs）
```

### Step 6: 修复建议
```
工具：无（LLM 生成）
输入：漏洞描述
输出：修复代码建议
```

### Step 7: EAS 上链认证
```
工具：eas_attest
输入：审计结果
输出：EAS UID
```

### Step 8: 铸造 NFT 证书
```
工具：无（合约调用）
输入：EAS UID
输出：NFT Token ID
```

## 执行命令

### 1. 启动 MCP 服务器
```bash
cd /root/projects/glm-code
npm run mcp:start
```

### 2. 执行 GLM-5.1 审计
```bash
# 使用 GLM-5.1 执行审计
pi -p --thinking xhigh "
请审计以下智能合约，执行完整的 8 步审计流程：

1. 读取 contracts/test-cases/Reentrancy.sol
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

### 3. 验证审计产物
```bash
# 检查 PoC 是否通过
forge test --match-contract ReentrancyExploit -vvv

# 检查 EAS 认证
cast call 0xC2679fBD37d54388Ce493F1DB75320D236e1815e \
  "getAttestation(bytes32)(bool)" \
  <EAS_UID>

# 检查 NFT 铸造
cast call 0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c \
  "balanceOf(address,uint256)(uint256)" \
  <wallet_address> <token_id>
```

## 预期产物

1. **审计报告 JSON** — 包含漏洞发现、严重性、PoC 验证
2. **PoC 测试合约** — ReentrancyExploit.t.sol
3. **测试结果** — Foundry 256 runs 通过
4. **EAS 认证** — 链上 UID
5. **NFT 证书** — ERC-1155 Token

## 产物验证

所有产物都可以在 Sepolia 测试网上验证：
- EAS: https://sepolia.easscan.org
- NFT: https://sepolia.etherscan.io/token/0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c
