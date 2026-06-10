#!/bin/bash
set -e
cd /root/projects/glm-code

# Wallet: 0x7b5538AAd3b048bAe0EFF2b457C59B8FE98032B8
# Usage: export SEPOLIA_PRIVATE_KEY="你的私钥" && bash deploy.sh

if [ -z "$SEPOLIA_PRIVATE_KEY" ]; then
    echo "Error: export SEPOLIA_PRIVATE_KEY first"
    exit 1
fi

SEPOLIA_RPC="https://ethereum-sepolia-rpc.publicnode.com"
EAS_ADDRESS="0xC2679fBD37d54388Ce493F1DB75320D236e1815e"

echo "=== Deploy AuditCertificate v4 to Sepolia ==="
echo "Wallet: $(cast wallet address --private-key $SEPOLIA_PRIVATE_KEY)"
echo "Balance: $(cast balance $(cast wallet address --private-key $SEPOLIA_PRIVATE_KEY) --rpc-url $SEPOLIA_RPC)"
echo ""

forge create contracts/AuditCertificate.sol:AuditCertificate \
  --constructor-args "$EAS_ADDRESS" \
  --rpc-url "$SEPOLIA_RPC" \
  --private-key "$SEPOLIA_PRIVATE_KEY" \
  --legacy

echo ""
echo "=== Done ==="
