#!/bin/bash
# Athena 真实审计脚本（v6 完整版）
# GLM-5.1 作为 LLM 层，协调 13 个 MCP 工具执行完整 8 步审计
# 产物：24 个合约、13 个 MCP 工具、S/A/B/C 四级 NFT

set -e

PROJECT_DIR="/root/projects/glm-code"
CONTRACT_DIR="$PROJECT_DIR/contracts"
MCP_DIR="$PROJECT_DIR/mcp/tools"
DEMO_DIR="$PROJECT_DIR/demo"
FRONTEND_DIR="$PROJECT_DIR/frontend"

echo "=========================================="
echo "ATHENA — GLM-5.1 DRIVEN AUDIT (v6)"
echo "=========================================="
echo ""

# Step 1: 展示项目结构
echo "[Step 1/8] Project structure..."
echo ""
echo "Contracts: $(find $CONTRACT_DIR -name '*.sol' | wc -l) Solidity files"
echo "MCP Tools: $(ls $MCP_DIR/*.py | wc -l) Python tools"
echo "Frontend: $(ls $FRONTEND_DIR/*.{html,js,css} 2>/dev/null | wc -l) files"
echo ""
tree -L 2 -I 'node_modules|.pi|lib|out|cache' $PROJECT_DIR
echo ""

# Step 2: 展示待审计合约
echo "[Step 2/8] Target contracts (multi-contract)..."
echo ""
cat $CONTRACT_DIR/multi-contract/Token.sol
echo ""
cat $CONTRACT_DIR/multi-contract/Oracle.sol
echo ""
cat $CONTRACT_DIR/multi-contract/Vault.sol
echo ""

# Step 3: GLM-5.1 驱动审计
echo "[Step 3/8] GLM-5.1 orchestrating audit pipeline..."
echo ""
echo "GLM-5.1 will:"
echo "  1. Analyze contract structure (protocol_scanner)"
echo "  2. Call Slither MCP tool (slither_runner)"
echo "  3. Call Aderyn MCP tool (aderyn_runner)"
echo "  4. Query knowledge base (knowledge_base)"
echo "  5. Generate PoC (poc_generator)"
echo "  6. Run Foundry fuzz tests (fuzz_runner)"
echo "  7. Simulate attack (exploit_simulator)"
echo "  8. Generate audit report"
echo ""

# 启动 GLM-5.1 审计
pi -p --thinking xhigh "
你是一个智能合约安全审计专家。请审计以下合约，执行完整的 8 步审计流程。

合约目录: contracts/multi-contract/
- Token.sol: ERC20 代币
- Oracle.sol: 预言机
- Vault.sol: 金库

请按以下步骤执行：

Step 1: 读取并分析合约代码
- 读取所有合约文件
- 理解合约功能和依赖关系
- 识别关键函数

Step 2: 协议级扫描
- 分析 Token → Oracle → Vault 的调用关系
- 识别跨合约攻击面
- 输出协议架构图

Step 3: 静态分析
- 调用 slither_runner 工具
- 调用 aderyn_runner 工具
- 检测常见漏洞模式

Step 4: 知识库查询
- 调用 knowledge_base 工具
- 查询 reentrancy、flash loan、oracle manipulation 等漏洞模式
- 获取相关漏洞知识

Step 5: 攻击模拟
- 调用 exploit_simulator 工具
- 生成完整端到端 exploit script
- 支持：闪电贷+重入+预言机操纵

Step 6: PoC 生成
- 调用 poc_generator 工具
- 生成 Foundry 测试合约
- 运行 fuzz_runner 验证

Step 7: 生成审计报告
- 汇总所有发现
- 生成 JSON 格式报告
- 包含漏洞详情和修复建议

Step 8: 链上认证信息
- EAS 合约地址
- NFT 铸造命令
- 链上验证链接

请执行以上步骤，并输出详细结果。
" 2>&1

# Step 4: 展示审计结果
echo ""
echo "[Step 4/8] Audit results..."
echo ""

# 展示 PoC
if [ -f "$CONTRACT_DIR/test-cases/poc/Reentrancy.t.sol" ]; then
    echo "--- PoC Test ---"
    cat "$CONTRACT_DIR/test-cases/poc/Reentrancy.t.sol"
    echo ""
fi

# 运行测试
echo "--- Running tests ---"
cd $PROJECT_DIR
forge test -vv 2>&1 | tail -30
echo ""

# 展示审计报告
if [ -f "$DEMO_DIR/report.json" ]; then
    echo "--- Audit report ---"
    cat "$DEMO_DIR/report.json"
    echo ""
fi

# Step 5: 展示修复验证
echo "[Step 5/8] Repair validation..."
echo ""
if [ -f "$CONTRACT_DIR/test-cases/fixes/Reentrancy-fixed.sol" ]; then
    echo "--- Fixed contract ---"
    cat "$CONTRACT_DIR/test-cases/fixes/Reentrancy-fixed.sol"
    echo ""
fi

# Step 6: 展示增量审计
echo "[Step 6/8] Incremental audit..."
echo ""
if [ -f "$CONTRACT_DIR/multi-contract/Vault-v2.sol" ]; then
    echo "--- Vault-v2 (incremental) ---"
    cat "$CONTRACT_DIR/multi-contract/Vault-v2.sol"
    echo ""
fi

# Step 7: 展示前沿技术
echo "[Step 7/8] Frontier tech contracts..."
echo ""
echo "Options Index: $(ls $CONTRACT_DIR/options-index/*.sol 2>/dev/null | wc -l) files"
echo "Real World: $(ls $CONTRACT_DIR/real-world/*.sol 2>/dev/null | wc -l) files"
echo ""

# Step 8: 链上信息
echo "[Step 8/8] On-chain verification..."
echo ""
echo "NFT Contract (ERC-1155): 0xcaA7faeA44C3513F629C6f260ad26EBB677E5E4E"
echo "Evidence Chain: 0x5e99f144D3e512f525d24077D4626a064899E177"
echo "EAS Contract: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e"
echo "Network: Sepolia Testnet"
echo ""
echo "NFT Tiers (v6):"
echo "  S-Tier: 100 score + Critical severity → Rainbow gradient + Dynamic aura"
echo "  A-Tier: 80-99 score → Gold Athena"
echo "  B-Tier: 60-79 score → Silver Athena"
echo "  C-Tier: <60 score → Bronze Athena"
echo "  Total combinations: 12,064 (12,000 + 64 S-tier)"
echo ""
echo "To mint NFT:"
echo "  cast send 0xcaA7faeA44C3513F629C6f260ad26EBB677E5E4E \\"
echo "    'mintCertificate(address,bytes32,uint8,uint256)' \\"
echo "    <wallet_address> <attestation_uid> <severity> <score> \\"
echo "    --rpc-url https://ethereum-sepolia-rpc.publicnode.com \\"
echo "    --private-key <your_key>"
echo ""

echo "=========================================="
echo "AUDIT COMPLETE"
echo "=========================================="
echo ""
echo "Generated artifacts:"
echo "  - PoC: $CONTRACT_DIR/test-cases/poc/"
echo "  - Report: $DEMO_DIR/report.json"
echo "  - Fixed: $CONTRACT_DIR/test-cases/fixes/"
echo ""
echo "View on-chain:"
echo "  - Etherscan: https://sepolia.etherscan.io/address/0xcaA7faeA44C3513F629C6f260ad26EBB677E5E4E"
echo "  - EAS: https://sepolia.eas.xyz"
echo "  - Frontend: http://localhost:8765"
echo "  - NFT Preview: http://localhost:8765/nft-preview.html"
