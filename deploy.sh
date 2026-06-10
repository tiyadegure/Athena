#!/bin/bash
set -e
cd /root/projects/glm-code

PRIVATE_KEY="REDACTED_PRIVATE_KEY"
SEPOLIA_RPC="https://ethereum-sepolia-rpc.publicnode.com"
EAS_ADDRESS="0xC2679fBD37d54388Ce493F1DB75320D236e1815e"

echo "=== Step 1: Deploy AuditCertificate to Sepolia ==="
forge create contracts/AuditCertificate.sol:AuditCertificate \
  --constructor-args "$EAS_ADDRESS" \
  --rpc-url "$SEPOLIA_RPC" \
  --private-key "$PRIVATE_KEY"

echo ""
echo "=== Deployment complete ==="
