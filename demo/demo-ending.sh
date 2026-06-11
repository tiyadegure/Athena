#!/bin/bash
# Athena Demo - Ending Section: Verification Links & Files
export TERM=xterm-256color
cd /root/projects/glm-code

clear
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VERIFICATION LINKS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  [Contract]  https://sepolia.etherscan.io/address/0x8Ba4Eb..."
echo "  [EAS]       https://sepolia.easscan.org/attestation/view/0x..."
echo "  [NFT]       https://sepolia.etherscan.io/tx/917de9a9..."
echo ""
sleep 5

clear
echo "════════════════════════════════════════════════════════════════"
echo "  AUDIT REPORT (demo/FINAL-AUDIT-REPORT.md)"
echo "════════════════════════════════════════════════════════════════"
echo ""
head -50 demo/FINAL-AUDIT-REPORT.md 2>/dev/null || echo "  [File not found]"
echo ""
sleep 10

clear
echo "════════════════════════════════════════════════════════════════"
echo "  SLITHER RESULTS (audit-results/slither-reentrancy.json)"
echo "════════════════════════════════════════════════════════════════"
echo ""
cat audit-results/slither-reentrancy.json 2>/dev/null | python3 -m json.tool 2>/dev/null | head -40 || echo "  [File not found]"
echo ""
sleep 8

clear
echo "════════════════════════════════════════════════════════════════"
echo "  ADERYN RESULTS (report.md)"
echo "════════════════════════════════════════════════════════════════"
echo ""
head -40 report.md 2>/dev/null || echo "  [File not found]"
echo ""
sleep 8

clear
echo "════════════════════════════════════════════════════════════════"
echo "  LANDING PAGE (https://athena.degure.me)"
echo "════════════════════════════════════════════════════════════════"
echo ""
curl -s https://athena.degure.me 2>/dev/null | head -30 || echo "  [Cannot fetch]"
echo ""
sleep 5

clear
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  ATHENA — From Vulnerability Discovery to On-Chain Certification"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  GitHub:  https://github.com/tiyadegure/Athena"
echo "  Landing: https://athena.degure.me"
echo "  Model:   GLM-5.1 (Z.AI Coding Plan)"
echo ""
echo "  Chains:  Sepolia + Base Sepolia"
echo "  NFT:     262,144 generative warrior combinations"
echo ""
echo "  Thank you for watching."
echo ""
sleep 3
