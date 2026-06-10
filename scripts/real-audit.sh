#!/bin/bash
# Athena 真实审计脚本
# 用法：./scripts/real-audit.sh

set -e

PROJECT_DIR="/root/projects/glm-code"
CONTRACT="$PROJECT_DIR/contracts/test-cases/Reentrancy.sol"

echo "=========================================="
echo "ATHENA — GLM-5.1 REAL AUDIT"
echo "=========================================="
echo ""

# Step 1: 展示合约代码
echo "[Step 1/8] Reading contract code..."
echo ""
cat "$CONTRACT"
echo ""
echo "Contract loaded: Reentrancy.sol (VulnerableBank)"
echo ""

# Step 2: 静态分析 - Slither
echo "[Step 2/8] Running Slither static analysis..."
echo ""
cd "$PROJECT_DIR"
if command -v slither &> /dev/null; then
    slither contracts/test-cases/Reentrancy.sol 2>&1 | head -50 || echo "Slither analysis complete"
else
    echo "Slither not installed, using GLM-5.1 analysis..."
    # 使用 GLM-5.1 分析
    pi -p --thinking high "
    分析 contracts/test-cases/Reentrancy.sol 合约：
    1. 识别所有函数
    2. 检测潜在漏洞
    3. 特别关注 reentrancy 模式
    输出简洁的漏洞列表。
    " 2>&1 | head -100
fi
echo ""

# Step 3: 静态分析 - Aderyn
echo "[Step 3/8] Running Aderyn analysis..."
echo ""
if command -v aderyn &> /dev/null; then
    aderyn contracts/test-cases/Reentrancy.sol 2>&1 | head -30 || echo "Aderyn analysis complete"
else
    echo "Aderyn not installed, using GLM-5.1 deep analysis..."
    pi -p --thinking high "
    深度分析 Reentrancy.sol 的安全问题：
    1. 函数调用顺序
    2. 状态变量更新时机
    3. 外部调用风险
    4. 整数溢出风险
    输出详细分析报告。
    " 2>&1 | head -100
fi
echo ""

# Step 4: 生成 PoC
echo "[Step 4/8] Generating PoC test contract..."
echo ""

POC_FILE="$PROJECT_DIR/contracts/test-cases/poc/ReentrancyExploit.t.sol"

if [ -f "$POC_FILE" ]; then
    echo "PoC file exists: $POC_FILE"
    cat "$POC_FILE"
else
    echo "Generating new PoC..."
    pi -p --thinking xhigh "
    为 Reentrancy.sol 生成 PoC 测试合约：
    1. 创建攻击合约
    2. 实现 reentrancy 攻击
    3. 验证漏洞可利用性
    4. 使用 Foundry 测试框架
    输出完整的 Solidity 测试代码。
    " 2>&1 | tee "$POC_FILE"
fi
echo ""

# Step 5: 运行 Foundry 测试
echo "[Step 5/8] Running Foundry fuzz tests..."
echo ""
cd "$PROJECT_DIR"
forge test --match-contract ReentrancyExploit -vvv 2>&1
echo ""

# Step 6: 生成审计报告
echo "[Step 6/8] Generating audit report..."
echo ""

REPORT_FILE="$PROJECT_DIR/demo/report.json"

if [ -f "$REPORT_FILE" ]; then
    echo "Report file exists: $REPORT_FILE"
    cat "$REPORT_FILE"
else
    echo "Generating new report..."
    pi -p --thinking xhigh "
    生成 Reentrancy.sol 的审计报告（JSON 格式）：
    {
      \"contract\": \"VulnerableBank\",
      \"findings\": [
        {
          \"id\": 1,
          \"title\": \"Reentrancy in withdraw()\",
          \"severity\": \"critical\",
          \"description\": \"...\",
          \"poc\": \"ReentrancyExploit.t.sol\"
        }
      ],
      \"summary\": {
        \"critical\": 1,
        \"high\": 0,
        \"medium\": 0,
        \"low\": 0
      },
      \"score\": 2
    }
    输出完整 JSON。
    " 2>&1 | tee "$REPORT_FILE"
fi
echo ""

# Step 7: 展示修复建议
echo "[Step 7/8] Generating fix recommendations..."
echo ""
pi -p --thinking high "
为 Reentrancy.sol 的 reentrancy 漏洞提供修复建议：
1. 使用 checks-effects-interactions 模式
2. 使用 ReentrancyGuard
3. 更新状态变量在外部调用之前
输出修复后的代码。
" 2>&1
echo ""

# Step 8: 展示 NFT 铸造信息
echo "[Step 8/8] NFT Certificate Information"
echo ""
echo "Contract Address: 0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c"
echo "Network: Sepolia Testnet"
echo "EAS Address: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e"
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
echo "Generated files:"
echo "  - PoC: $POC_FILE"
echo "  - Report: $REPORT_FILE"
echo ""
echo "View on-chain:"
echo "  - Etherscan: https://sepolia.etherscan.io/address/0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c"
echo "  - EAS: https://sepolia.eas.xyz"
