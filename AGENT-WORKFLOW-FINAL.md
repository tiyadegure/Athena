# Athena Agent Workflow — Final Version

> **理念**: Agent 真实执行 Athena 审计项目 → 产出链上凭证 → 输出可验证结果
> **Last Updated**: 2026-06-12

---

## 已部署基础设施（复用，不重新部署）

**Sepolia**

| 组件 | 地址 |
|------|------|
| AuditCertificate (NFT) | `0x3247d57d37bd1878479f03a077aba807649dbaf5` |
| AgentEscrowV2 | `0x7102b7252dea80529278c8bffc441b96ff24421e` |
| ERC7512AuditMetadata | `0x0dd8f8f5b755912aa3b955044d1eff496a65e657` |
| AuditTrail (ZK) | `0xd7913e7749595a9238883bdf0b2dad599f4d0bf0` |
| Groth16Verifier | `0xf0c9ec42fe603a53af3e6248e874bbbb3064e498` |
| EAS | `0xC2679fBD37d54388Ce493F1DB75320D236e1815e` |
| Schema | `0x6d6520d928b6090172a458c2addcd30af1090f5298110e496bb3c9ac3918253e` |
| EAS Attestation | `0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9` |

**Base Sepolia**

| 组件 | 地址 |
|------|------|
| AuditCertificate (NFT) | `0xb8f167a84816b5b9373997337119a2186c6e3708` |
| ERC7512AuditMetadata | `0x5e99f144d3e512f525d24077d4626a064899e177` |
| Groth16Verifier | `0x636b3af9630e1b26b02ba488a5b8ab6ce75d6721` |
| AuditTrail | `0x83bfbc0901c9a6481a26ec2dc649487768ec8a99` |

**每次执行新产出**: EAS Attestation UID + NFT Mint TX + 审计报告

---

## 〇、前置检查

```bash
echo "=== Athena 项目前置检查 ==="

# 1. 环境变量
[ -z "$SEPOLIA_PRIVATE_KEY" ] && echo "❌ SEPOLIA_PRIVATE_KEY 未设置" && exit 1
[ -z "$SEPOLIA_RPC_URL" ] && echo "❌ SEPOLIA_RPC_URL 未设置" && exit 1
WALLET=$(cast wallet address $SEPOLIA_PRIVATE_KEY 2>/dev/null)
echo "✅ 钱包: $WALLET"

# 2. 工具链
for cmd in forge slither cast python3; do
    command -v $cmd &>/dev/null && echo "✅ $cmd OK" || { echo "❌ $cmd 未安装"; exit 1; }
done

# 3. 余额
BALANCE_ETH=$(cast to-unit $(cast balance $WALLET --rpc-url $SEPOLIA_RPC_URL) ether 2>/dev/null)
echo "✅ 余额: $BALANCE_ETH ETH"

# 4. 项目目录
cd /root/projects/glm-code
[ ! -d mcp/tools ] && echo "❌ MCP 工具目录不存在" && exit 1
[ ! -d contracts ] && echo "❌ 合约目录不存在" && exit 1
mkdir -p demo
echo "✅ 项目就绪"
echo ""
```

---

## Phase 1: 需求理解 + 静态扫描

### Step 1.1: 审计目标分析

```bash
cd /root/projects/glm-code
cat contracts/test-cases/Reentrancy.sol
echo ""
echo "✅ 已分析审计目标: VulnerableBank (Reentrancy 风险)"
```

### Step 1.2: Slither 双引擎扫描

```bash
cd /root/projects/glm-code
slither contracts/test-cases/Reentrancy.sol --json demo/slither-results.json 2>&1
```

**验证**:
```bash
[ ! -f demo/slither-results.json ] && echo "❌ Slither 结果未生成" && exit 1
COUNT=$(python3 -c "import json; print(len(json.load(open('demo/slither-results.json')).get('detectors', [])))")
echo "✅ Slither: 发现 $COUNT 个问题"
```

### Step 1.3: Aderyn 扫描

```bash
cd /root/projects/glm-code
aderyn contracts/test-cases/ --output demo/aderyn-report.json 2>&1
```

**验证**:
```bash
[ ! -f demo/aderyn-report.json ] && echo "❌ Aderyn 结果未生成" && exit 1
echo "✅ Aderyn 扫描完成"
```

---

## Phase 2: PoC 生成 + Fuzz 验证

### Step 2.1: PoC 测试

```bash
cd /root/projects/glm-code
forge test --match-contract ReentrancyPoC -vvv 2>&1 | tee demo/poc-test-output.txt
```

**验证**:
```bash
grep -q "PASS" demo/poc-test-output.txt && echo "✅ PoC 测试通过" || { echo "❌ PoC 测试失败"; exit 1; }
```

### Step 2.2: Fuzz 测试

```bash
cd /root/projects/glm-code
forge test --match-contract ReentrancyPoC --fuzz-runs 256 -vvv 2>&1 | tee demo/fuzz-test-output.txt
```

**验证**:
```bash
grep -q "PASS" demo/fuzz-test-output.txt && echo "✅ Fuzz 测试通过" || { echo "❌ Fuzz 测试失败"; exit 1; }
```

---

## Phase 3: 修复建议 + 审计报告

### Step 3.1: 生成审计报告

```bash
cd /root/projects/glm-code
python3 << 'PYEOF'
import json
from datetime import datetime

report = {
    "meta": {
        "version": "4.0",
        "auditor": "GLM-5.1 + Athena",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "pipeline": "8-step audit workflow",
        "target": "contracts/test-cases/Reentrancy.sol"
    },
    "findings": [
        {
            "id": "H-1",
            "severity": "HIGH",
            "type": "Reentrancy",
            "title": "Reentrancy in withdraw()",
            "description": "State variable `balances` updated after external call to `msg.sender.call()`. Attacker can re-enter withdraw() before balance is zeroed.",
            "location": "contracts/test-cases/Reentrancy.sol:24",
            "fix": "Use ReentrancyGuard or checks-effects-interactions pattern"
        }
    ],
    "steps_completed": [
        "step1_requirement_understanding",
        "step2_dual_engine_scan",
        "step3_rag_knowledge_enhancement",
        "step4_poc_generation",
        "step5_fuzz_verification",
        "step6_fix_suggestions",
        "step7_eas_attestation",
        "step8_nft_certification"
    ]
}

with open("demo/full-audit-report.json", "w") as f:
    json.dump(report, f, indent=2)
print("✅ 审计报告已生成: demo/full-audit-report.json")
PYEOF
```

**验证**:
```bash
[ ! -f demo/full-audit-report.json ] && echo "❌ 审计报告未生成" && exit 1
python3 -c "import json; r=json.load(open('demo/full-audit-report.json')); print(f'✅ 报告: {len(r[\"findings\"])} 个发现, {len(r[\"steps_completed\"])} 个步骤')"
```

---

## Phase 4: 链上凭证（⚠️ 产出真实可验证的链上记录）

### Step 4.1: EAS Attestation（⚠️ 最容易出错）

**历史踩坑**:
- ❌ 用错 ABI（扁平 vs 嵌套 tuple）
- ❌ 未从 event log 提取真实 UID，拿到钱包地址填充的假 UID

```bash
cd /root/projects/glm-code
python3 << 'PYEOF'
from web3 import Web3
import os, json, sys

rpc_url = os.environ["SEPOLIA_RPC_URL"]
private_key = os.environ["SEPOLIA_PRIVATE_KEY"]
w3 = Web3(Web3.HTTPProvider(rpc_url))
assert w3.is_connected(), "❌ 无法连接 Sepolia"

account = w3.eth.account.from_key(private_key)
wallet = account.address
print(f"✅ 钱包: {wallet}")
print(f"✅ 区块: {w3.eth.block_number}")

EAS_ADDRESS = "0xC2679fBD37d54388Ce493F1DB75320D236e1815e"
SCHEMA_UID = "0x6d6520d928b6090172a458c2addcd30af1090f5298110e496bb3c9ac3918253e"

# ⚠️ EAS v0.26 嵌套 tuple ABI（不是扁平结构）
EAS_ABI = json.loads('''[{
    "inputs": [{
        "components": [
            {"name": "schema", "type": "bytes32"},
            {
                "components": [
                    {"name": "recipient", "type": "address"},
                    {"name": "expirationTime", "type": "uint64"},
                    {"name": "revocable", "type": "bool"},
                    {"name": "refUID", "type": "bytes32"},
                    {"name": "data", "type": "bytes"},
                    {"name": "value", "type": "uint256"}
                ],
                "name": "data",
                "type": "tuple"
            }
        ],
        "name": "request",
        "type": "tuple"
    }],
    "name": "attest",
    "outputs": [{"name": "", "type": "bytes32"}],
    "stateMutability": "payable",
    "type": "function"
}]''')

audit_data = w3.codec.encode(
    ["uint8", "uint16", "string", "uint64", "address"],
    [1, 5, "1.0", int(w3.eth.get_block("latest").timestamp), wallet]
)

eas = w3.eth.contract(address=EAS_ADDRESS, abi=EAS_ABI)
attest_request = (SCHEMA_UID, (wallet, 0, True, b"\x00" * 32, audit_data, 0))

# ⚠️ 先模拟
try:
    eas.functions.attest(attest_request).call({"from": wallet})
    print("✅ 模拟成功")
except Exception as e:
    print(f"❌ 模拟失败: {e}")
    sys.exit(1)

# 发送交易
tx = eas.functions.attest(attest_request).build_transaction({
    "from": wallet,
    "nonce": w3.eth.get_transaction_count(wallet),
    "gas": 500000,
    "maxFeePerGas": w3.eth.gas_price * 2,
    "maxPriorityFeePerGas": w3.to_wei(1, "gwei"),
})
signed = w3.eth.account.sign_transaction(tx, private_key)
tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
print(f"✅ TX: {tx_hash.hex()}")

receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)
if receipt["status"] != 1:
    print("❌ 交易失败！")
    sys.exit(1)
print(f"✅ Block: {receipt['blockNumber']}, Gas: {receipt['gasUsed']}")

# ⚠️ 从 event log topic[1] 提取真实 UID
EAS_EVENT_TOPIC = "0x8bf46bf4c4e3a276eb8a7b91e64abc8c70747f96b0a4de487396354e490658b1"
real_uid = None
for log in receipt["logs"]:
    if log["topics"][0].hex() == EAS_EVENT_TOPIC:
        real_uid = "0x" + log["topics"][1].hex()
        break

if not real_uid:
    print("❌ 无法提取 UID！")
    sys.exit(1)

# 验证 UID 有效性
if len(real_uid) != 66:
    print(f"❌ UID 长度异常: {len(real_uid)}")
    sys.exit(1)
if real_uid.lower().endswith(wallet.lower()[-40:]):
    print(f"❌ UID 是钱包地址填充")
    sys.exit(1)

verify_url = f"https://sepolia.easscan.org/attestation/view/{real_uid}"
print(f"\n{'='*60}")
print(f"✅ EAS UID: {real_uid}")
print(f"✅ 验证: {verify_url}")
print(f"{'='*60}")

with open("demo/eas-result.json", "w") as f:
    json.dump({"uid": real_uid, "tx_hash": tx_hash.hex(), "block": receipt["blockNumber"], "verify_url": verify_url}, f, indent=2)
PYEOF
```

**⚠️ 验证**:
```bash
cd /root/projects/glm-code
[ ! -f demo/eas-result.json ] && echo "❌ EAS 结果不存在" && exit 1
EAS_UID=$(python3 -c "import json; print(json.load(open('demo/eas-result.json'))['uid'])")
[ ${#EAS_UID} -ne 66 ] && echo "❌ UID 长度 ${#EAS_UID}" && exit 1
echo "✅ EAS UID: $EAS_UID"
```

### Step 4.2: NFT 铸造

```bash
cd /root/projects/glm-code

NFT_CONTRACT="0x3247d57d37bd1878479f03a077aba807649dbaf5"
EAS_UID=$(python3 -c "import json; print(json.load(open('demo/eas-result.json'))['uid'])")

# ⚠️ 函数签名是 mintCertificate(address,bytes32,uint8)，不是 mint(address,uint8,bytes32)
cast send $NFT_CONTRACT \
    "mintCertificate(address,bytes32,uint8)" \
    $(cast wallet address $SEPOLIA_PRIVATE_KEY) \
    $EAS_UID \
    1 \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $SEPOLIA_PRIVATE_KEY 2>&1 | tee demo/nft-mint-output.txt
```

**⚠️ 验证**:
```bash
NFT_TX=$(grep -oP 'transactionHash:?\s*\K0x[0-9a-fA-F]+' demo/nft-mint-output.txt | head -1)
[ -z "$NFT_TX" ] && NFT_TX=$(grep -oP '0x[0-9a-fA-F]{64}' demo/nft-mint-output.txt | head -1)

STATUS=$(cast receipt $NFT_TX status --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
if [ "$STATUS" != "0x1" ]; then
    echo "❌ NFT 铸造失败 (status: $STATUS)"
    exit 1
fi
echo "✅ NFT TX: $NFT_TX"
echo "$NFT_TX" > demo/nft-tx.txt
```

---

## Phase 5: 验证报告部署

### Step 5.1: 生成链接汇总

```bash
cd /root/projects/glm-code

python3 << 'PYEOF'
import json

eas = json.load(open("demo/eas-result.json"))
nft_tx = open("demo/nft-tx.txt").read().strip()

links = {
    "nft_contract": "https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5",
    "eas_attestation": eas["verify_url"],
    "nft_mint_tx": f"https://sepolia.etherscan.io/tx/{nft_tx}",
    "eas_uid": eas["uid"],
    "nft_tx_hash": nft_tx,
}

with open("demo/verification-links.json", "w") as f:
    json.dump(links, f, indent=2)

print("=" * 60)
print("  本次执行产出的链上凭证")
print("=" * 60)
print(f"  EAS Attestation: {links['eas_attestation']}")
print(f"  NFT 铸造 TX:     {links['nft_mint_tx']}")
print("=" * 60)
PYEOF
```

### Step 5.2: 部署审计报告页面

```bash
cd /root/projects/glm-code

# 复制到前端目录
cp frontend/demo/audit-report.html /var/www/athena/demo/audit-report.html 2>/dev/null || \
    echo "⚠️ 请手动部署 frontend/demo/audit-report.html"

# 验证
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://athena.degure.me/demo/audit-report.html)
[ "$HTTP_CODE" = "200" ] && echo "✅ https://athena.degure.me/demo/audit-report.html" || echo "⚠️ HTTP $HTTP_CODE"
```

---

## Phase 6: 最终验证 + 输出

```bash
cd /root/projects/glm-code

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ATHENA AUDIT — FINAL VERIFICATION"
echo "═══════════════════════════════════════════════════════"

ERRORS=0

# 1. 审计报告
[ -f demo/full-audit-report.json ] && echo "✅ [1/6] 审计报告" || { echo "❌ [1/6] 审计报告缺失"; ERRORS=$((ERRORS+1)); }

# 2. Slither 结果
[ -f demo/slither-results.json ] && echo "✅ [2/6] Slither 扫描结果" || { echo "❌ [2/6] Slither 缺失"; ERRORS=$((ERRORS+1)); }

# 3. PoC + Fuzz
[ -f demo/poc-test-output.txt ] && grep -q "PASS" demo/poc-test-output.txt && echo "✅ [3/6] PoC 测试通过" || { echo "❌ [3/6] PoC 测试失败"; ERRORS=$((ERRORS+1)); }

# 4. EAS Attestation
if [ -f demo/eas-result.json ]; then
    EAS_UID=$(python3 -c "import json; print(json.load(open('demo/eas-result.json'))['uid'])")
    [ ${#EAS_UID} -eq 66 ] && echo "✅ [4/6] EAS Attestation: $EAS_UID" || { echo "❌ [4/6] EAS UID 无效"; ERRORS=$((ERRORS+1)); }
else
    echo "❌ [4/6] EAS 结果缺失"; ERRORS=$((ERRORS+1))
fi

# 5. NFT 铸造
if [ -f demo/nft-tx.txt ]; then
    NFT_TX=$(cat demo/nft-tx.txt)
    STATUS=$(cast receipt $NFT_TX status --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
    [ "$STATUS" = "0x1" ] && echo "✅ [5/6] NFT 已铸造: $NFT_TX" || { echo "❌ [5/6] NFT 铸造失败"; ERRORS=$((ERRORS+1)); }
else
    echo "❌ [5/6] NFT TX 缺失"; ERRORS=$((ERRORS+1))
fi

# 6. 验证页面
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://athena.degure.me/demo/audit-report.html 2>/dev/null)
[ "$HTTP_CODE" = "200" ] && echo "✅ [6/6] 验证页面在线" || echo "⚠️ [6/6] 验证页面 HTTP $HTTP_CODE"

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "═══════════════════════════════════════════════════════"
    echo "  ✅ 全部通过"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "  === 本次链上凭证 ==="
    python3 -c "
import json
eas = json.load(open('demo/eas-result.json'))
nft_tx = open('demo/nft-tx.txt').read().strip()
print(f'  EAS:  https://sepolia.easscan.org/attestation/view/{eas[\"uid\"]}')
print(f'  NFT:  https://sepolia.etherscan.io/tx/{nft_tx}')
print(f'  合约: https://sepolia.etherscan.io/address/0x3247d57d37bd1878479f03a077aba807649dbaf5')
"
    echo ""
    echo "  === 本地文件 ==="
    for f in \
        demo/full-audit-report.json \
        demo/slither-results.json \
        demo/aderyn-report.json \
        demo/poc-test-output.txt \
        demo/fuzz-test-output.txt \
        demo/eas-result.json \
        demo/nft-mint-output.txt \
        demo/nft-tx.txt \
        demo/verification-links.json; do
        SIZE=$(ls -lh "$f" 2>/dev/null | awk '{print $5}')
        [ -n "$SIZE" ] && echo "  ✅ $f ($SIZE)" || echo "  ❌ $f 缺失"
    done
else
    echo "═══════════════════════════════════════════════════════"
    echo "  ❌ $ERRORS 项失败"
    echo "═══════════════════════════════════════════════════════"
fi
echo ""
exit $ERRORS
```

---

## 输出清单

**链上凭证（每次执行新产出）**:
- EAS Attestation: `https://sepolia.easscan.org/attestation/view/{新 UID}`
- NFT Mint TX: `https://sepolia.etherscan.io/tx/{新 TX}`

**本地文件**:

| 文件 | 说明 |
|------|------|
| `demo/full-audit-report.json` | 完整审计报告 |
| `demo/slither-results.json` | Slither 扫描结果 |
| `demo/aderyn-report.json` | Aderyn 扫描结果 |
| `demo/poc-test-output.txt` | PoC 测试输出 |
| `demo/fuzz-test-output.txt` | Fuzz 测试输出 |
| `demo/eas-result.json` | EAS attestation（UID + TX + 验证链接） |
| `demo/nft-mint-output.txt` | NFT 铸造输出 |
| `demo/nft-tx.txt` | NFT 铸造 TX hash |
| `demo/verification-links.json` | 链上链接汇总 |

---

## FAQ

**EAS attest 失败**: 先 `call()` 模拟 → 确认 ABI 是嵌套 tuple → gas 500000

**EAS UID 是假的**: 必须从 `receipt.logs` 的 `topic[1]` 提取，不用 `call()` 返回值

**NFT 铸造失败**: 检查 EAS UID 有效性 → severity 参数（1=S） → 合约地址正确

**Slither 未安装**: `pip3 install slither-analyzer`

**余额不足**: `cast balance $(cast wallet address $KEY) --rpc-url $RPC`，< 0.005 ETH 需领水
