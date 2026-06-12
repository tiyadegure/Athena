#!/bin/bash
# 终端渲染验证链接和文件内容
export TERM=xterm-256color
cd /root/projects/glm-code

clear
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  ON-CHAIN VERIFICATION"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "  Deployed Contract:"
echo "  https://sepolia.etherscan.io/address/0x8Ba4Eb12349449a91012c043Ca307BC615350E74"
echo ""
echo "  EAS Attestation:"
echo "  https://sepolia.easscan.org/attestation/view/0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9"
echo ""
echo "  Minted NFT:"
echo "  https://sepolia.etherscan.io/tx/917de9a93471273089e49b948a70a0f0f71503598ccdf60d05a7c54c6289dbc0"
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  AUDIT REPORT (demo/FINAL-AUDIT-REPORT.md)"
echo "══════════════════════════════════════════════════════════════"
echo ""
head -50 demo/FINAL-AUDIT-REPORT.md 2>/dev/null | sed 's/^/  /'
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  SLITHER RESULTS"
echo "══════════════════════════════════════════════════════════════"
echo ""
cat audit-results/slither-reentrancy.json 2>/dev/null | python3 -m json.tool 2>/dev/null | head -30 | sed 's/^/  /'
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  ATHENA — From Vulnerability Discovery to On-Chain Certification"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "  GitHub:  https://github.com/tiyadegure/Athena"
echo "  Landing: https://athena.degure.me"
echo "  Model:   GLM-5.1 (Z.AI Coding Plan)"
echo ""
sleep 3
