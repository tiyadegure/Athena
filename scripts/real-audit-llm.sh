#!/bin/bash
# Athena 真实审计脚本（LLM 驱动版本）
# GLM-5.1 作为 LLM 层，协调 MCP 工具执行审计

set -e

PROJECT_DIR="/root/projects/glm-code"
CONTRACT="$PROJECT_DIR/contracts/test-cases/Reentrancy.sol"

echo "=========================================="
echo "ATHENA — GLM-5.1 DRIVEN AUDIT"
echo "=========================================="
echo ""

# Step 1: 展示合约代码
echo "[Step 1/8] Reading contract code..."
echo ""
cat "$CONTRACT"
echo ""
echo "Contract loaded: Reentrancy.sol (VulnerableBank)"
echo ""

# Step 2-7: GLM-5.1 驱动审计
echo "[Step 2-7] GLM-5.1 orchestrating audit pipeline..."
echo ""
echo "GLM-5.1 will:"
echo "  1. Analyze contract structure"
echo "  2. Call Slither MCP tool for static analysis"
echo "  3. Call Aderyn MCP tool for deep analysis"
echo "  4. Query knowledge base for vulnerability patterns"
echo "  5. Generate PoC test contract"
echo "  6. Run Foundry fuzz tests"
echo "  7. Generate audit report"
echo ""

# 启动 GLM-5.1 审计
pi -p --thinking xhigh "
你是一个智能合约安全审计专家。请审计以下合约，执行完整的 8 步审计流程。

合约路径: contracts/test-cases/Reentrancy.sol

请按以下步骤执行：

Step 1: 读取并分析合约代码
- 读取合约文件
- 理解合约功能
- 识别关键函数

Step 2: 调用 Slither MCP 工具进行静态分析
- 使用 slither_runner 工具
- 检测常见漏洞模式
- 输出分析结果

Step 3: 调用 Aderyn MCP 工具进行深度分析
- 使用 aderyn_runner 工具
- 进行二次扫描
- 输出深度分析

Step 4: 查询知识库
- 使用 knowledge_base 工具
- 查询 reentrancy 漏洞模式
- 获取相关漏洞知识

Step 5: 生成 PoC 测试合约
- 使用 poc_generator 工具
- 生成 ReentrancyExploit.t.sol
- 包含攻击合约和测试

Step 6: 运行 Foundry fuzz 测试
- 使用 fuzz_runner 工具
- 运行 256 次 fuzz 测试
- 验证漏洞可利用性

Step 7: 生成审计报告
- 汇总所有发现
- 生成 JSON 格式报告
- 包含漏洞详情和修复建议

Step 8: 展示链上认证信息
- EAS 合约地址
- NFT 铸造命令
- 链上验证链接

请执行以上步骤，并输出详细结果。
" 2>&1

echo ""
echo "[Step 8/8] On-chain verification information"
echo ""
echo "EAS Contract: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e"
echo "NFT Contract: 0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c"
echo "Network: Sepolia Testnet"
echo ""
echo "To mint NFT certificate:"
echo "  cast send 0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c \\"
echo "    'mintCertificate(address,bytes32,uint8,uint256)' \\"
echo "    <wallet_address> <attestation_uid> <severity> <score>"
echo ""

echo "=========================================="
echo "AUDIT COMPLETE"
echo "=========================================="
echo ""
echo "View on-chain:"
echo "  - Etherscan: https://sepolia.etherscan.io/address/0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c"
echo "  - EAS: https://sepolia.eas.xyz"
