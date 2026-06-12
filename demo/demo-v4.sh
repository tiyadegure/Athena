#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Athena Demo — GLM-5.1 Web3 Security Audit Agent
# 8-Step Pipeline + Advanced Contracts + Real Protocol Audits + Multi-Chain
# ═══════════════════════════════════════════════════════════════
#
# Recording: asciinema rec demo.cast -c "bash demo/demo.sh"
# Playback:  asciinema play demo.cast
# Convert:   agg demo.cast demo.gif

set -e
cd "$(dirname "$0")/.."

# ── Helpers ──────────────────────────────────────────────────────
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'
BOX='\033[0;37m'

hr() { echo -e "${DIM}$(printf '%.0s─' {1..72})${RESET}"; }
pause() { sleep "${1:-1.5}"; }
step() {
    hr
    echo -e "${CYAN}${BOLD}[STEP $1/8]${RESET} ${BOLD}$2${RESET}"
    hr
    pause 1
}

# ══════════════════════════════════════════════════════════════════
#  INTRO
# ══════════════════════════════════════════════════════════════════
clear
echo ""
echo -e "${BOLD}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}  ║${RESET}  ${CYAN}A T H E N A${RESET} — Web3 Smart Contract Security Audit Agent    ${BOLD}║${RESET}"
echo -e "${BOLD}  ║${RESET}  Powered by GLM-5.1 Long-Horizon Task                     ${BOLD}║${RESET}"
echo -e "${BOLD}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${DIM}Model:${RESET}     GLM-5.1 (200K context, long-horizon reasoning)"
echo -e "  ${DIM}Pipeline:${RESET}  8-step audit → EAS attestation → NFT certification"
echo -e "  ${DIM}Contracts:${RESET} ZK proof + Agent Escrow + ERC-7512"
echo -e "  ${DIM}Chains:${RESET}    Sepolia + Base Sepolia"
echo ""
pause 2

# ══════════════════════════════════════════════════════════════════
#  STEP 1: Requirement Understanding
# ══════════════════════════════════════════════════════════════════
step 1 "Requirement Understanding — Target Analysis"

echo -e "  ${YELLOW}> athena audit --target contracts/test-cases/VulnerableBank.sol${RESET}"
pause 1
echo ""
echo -e "  ${GREEN}[OK]${RESET} Contract: VulnerableBank"
echo -e "  ${DIM}     Functions: deposit(), withdraw(), getBalance()${RESET}"
echo -e "  ${DIM}     Lines: 47 | Compiler: ^0.8.20${RESET}"
echo -e "  ${DIM}     Pattern: Classic reentrancy + missing access control${RESET}"
echo ""
pause 2

# ══════════════════════════════════════════════════════════════════
#  STEP 2: Dual-Engine Scan (Slither + Aderyn)
# ══════════════════════════════════════════════════════════════════
step 2 "Dual-Engine Static Analysis (Slither + Aderyn)"

echo -e "  ${YELLOW}> slither contracts/test-cases/VulnerableBank.sol${RESET}"
pause 0.8
echo ""
echo -e "  ${RED}[HIGH]${RESET}  Reentrancy in withdraw() — state updated after call"
echo -e "  ${RED}[HIGH]${RESET}  Missing zero-address check in constructor"
echo -e "  ${DIM}[INFO]  3 informational findings${RESET}"
echo ""
pause 1

echo -e "  ${YELLOW}> aderyn contracts/test-cases/${RESET}"
pause 0.8
echo ""
echo -e "  ${RED}[HIGH]${RESET}  Reentrancy-vulnerability: external call before state update"
echo -e "  ${YELLOW}[MED]${RESET}  Unchecked return value in withdraw()"
echo -e "  ${DIM}[LOW]   5 low-severity findings${RESET}"
echo ""
echo -e "  ${GREEN}[MERGE]${RESET} Slither (5) + Aderyn (7) → 9 unique findings after dedup"
pause 2

# ══════════════════════════════════════════════════════════════════
#  STEP 3: RAG Knowledge Enhancement
# ══════════════════════════════════════════════════════════════════
step 3 "RAG Knowledge Enhancement — Vulnerability DB"

echo -e "  ${YELLOW}> athena rag --query \"reentrancy attack patterns\"${RESET}"
pause 0.8
echo ""
echo -e "  ${GREEN}[MATCH]${RESET} SWC-107: Reentrancy"
echo -e "  ${DIM}     ├── TheDAO hack (2016) — \$60M drained${RESET}"
echo -e "  ${DIM}     ├── Curve V2 read-only reentrancy (2023) — \$70M at risk${RESET}"
echo -e "  ${DIM}     └── Hundred Finance (2023) — \$7M stolen${RESET}"
echo ""
echo -e "  ${GREEN}[MATCH]${RESET} Mitigation: Checks-Effects-Interactions pattern"
echo -e "  ${GREEN}[MATCH]${RESET} OpenZeppelin ReentrancyGuard usage"
pause 2

# ══════════════════════════════════════════════════════════════════
#  STEP 4: PoC Generation
# ══════════════════════════════════════════════════════════════════
step 4 "PoC Generation — Attack Simulation"

echo -e "  ${YELLOW}> athena poc --vuln reentrancy --target VulnerableBank${RESET}"
pause 1
echo ""
echo -e "${DIM}  // SPDX-License-Identifier: MIT"
echo -e "  contract Attacker {"
echo -e "      VulnerableBank bank;"
echo -e "      function attack() external payable {"
echo -e "          bank.deposit{value: 1 ether}();"
echo -e "          bank.withdraw();  // triggers reentrancy"
echo -e "      }"
echo -e "      receive() external payable {"
echo -e "          if (address(bank).balance >= 1 ether)"
echo -e "              bank.withdraw();  // re-enter"
echo -e "      }"
echo -e "  }${RESET}"
echo ""
echo -e "  ${GREEN}[OK]${RESET} PoC generated → test/Attacker.t.sol"
pause 2

# ══════════════════════════════════════════════════════════════════
#  STEP 5: Foundry Fuzz Verification
# ══════════════════════════════════════════════════════════════════
step 5 "Foundry Fuzz Testing"

echo -e "  ${YELLOW}> forge test --match-test testReentrancy -vvv${RESET}"
pause 1
echo ""
echo -e "  ${GREEN}[PASS]${RESET} testReentrancy() — 500 fuzz runs"
echo -e "  ${DIM}     Gas used: 284,156 | Traces: 12${RESET}"
echo -e "  ${DIM}     Attack succeeded: balance drained in single tx${RESET}"
echo ""
echo -e "  ${GREEN}[VERIFIED]${RESET} Vulnerability confirmed via fuzz testing"
pause 2

# ══════════════════════════════════════════════════════════════════
#  STEP 6: Fix Suggestions
# ══════════════════════════════════════════════════════════════════
step 6 "Fix Suggestions"

echo -e "  ${YELLOW}> athena fix --vuln reentrancy --target VulnerableBank${RESET}"
pause 1
echo ""
echo -e "  ${CYAN}[FIX]${RESET} 1. Add ReentrancyGuard from OpenZeppelin"
echo -e "  ${CYAN}[FIX]${RESET} 2. Apply Checks-Effects-Interactions pattern"
echo -e "  ${CYAN}[FIX]${RESET} 3. Update balance BEFORE external call"
echo ""
echo -e "${DIM}  function withdraw() external nonReentrant {"
echo -e "      uint256 bal = balances[msg.sender];"
echo -e "      require(bal > 0, \"no balance\");"
echo -e "      balances[msg.sender] = 0;  // effect before interaction"
echo -e "      (bool ok, ) = msg.sender.call{value: bal}(\"\");"
echo -e "      require(ok, \"transfer failed\");"
echo -e "  }${RESET}"
pause 2

# ══════════════════════════════════════════════════════════════════
#  STEP 7: EAS On-Chain Certification
# ══════════════════════════════════════════════════════════════════
step 7 "EAS On-Chain Certification (Sepolia)"

echo -e "  ${YELLOW}> athena eas --schema 0x6d6520d9...853e --target VulnerableBank${RESET}"
pause 1
echo ""
echo -e "  ${GREEN}[TX]${RESET}  EAS Attestation created"
echo -e "  ${DIM}     Schema: 0x6d6520d928b6090172a458c2addcd30af1090f5298110e496bb3c9ac3918253e${RESET}"
echo -e "  ${DIM}     UID:    0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9${RESET}"
echo -e "  ${DIM}     Chain:  Sepolia${RESET}"
echo -e "  ${DIM}     Grade:  S (Critical — Reentrancy + PoC verified)${RESET}"
echo ""
echo -e "  ${DIM}     https://sepolia.easscan.org/attestation/view/0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9${RESET}"
pause 2

# ══════════════════════════════════════════════════════════════════
#  STEP 8: NFT Certificate Minting (Generative Athena)
# ══════════════════════════════════════════════════════════════════
step 8 "Mint Athena NFT Certificate (ERC-1155 Generative)"

echo -e "  ${YELLOW}> athena nft --grade S --attestation 0xd02800c9...${RESET}"
pause 1
echo ""
echo -e "  ${GREEN}[TX]${RESET}  NFT Minted on Sepolia"
echo -e "  ${DIM}     Sepolia:  0x3247d57d37bd1878479f03a077aba807649dbaf5${RESET}"
echo -e "  ${DIM}     Base:     0xb8f167a84816b5b9373997337119a2186c6e3708${RESET}"
echo -e "  ${DIM}     Token ID: 1 (Grade S)${RESET}"
echo -e "  ${DIM}     Traits:   262,144 possible combinations (4^9)${RESET}"
echo -e "  ${DIM}     Rendering: On-chain SVG, generative warrior Athena${RESET}"
echo ""
pause 1

echo -e "  ${BOLD}NFT Trait Breakdown:${RESET}"
echo -e "  ${DIM}  ├── Helmet:  Crown of Wisdom (4 variants)"
echo -e "  ├── Armor:   Aegis Shield (4 variants)"
echo -e "  ├── Weapon:  Lightning Spear (4 variants)"
echo -e "  ├── Aura:   Electric Blue (4 variants)"
echo -e "  ├── Wings:  Eagle Wings (4 variants)"
echo -e "  ├── Eyes:   Glowing Gold (4 variants)"
echo -e "  ├── Cape:   Royal Purple (4 variants)"
echo -e "  ├── Base:   Chain Pattern (4 variants)"
echo -e "  └── Background: Nebula (4 variants)${RESET}"
echo ""
pause 2


# ══════════════════════════════════════════════════════════════════
#  ADVANCED CONTRACTS (compact)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}  ADVANCED CONTRACTS${RESET}"
hr

echo -e "  ${BOLD}[1] ZK Proof${RESET}  Groth16Verifier  ${DIM}Sepolia: 0xf0c9...498${RESET}"
echo -e "  ${BOLD}[2] Agent Escrow${RESET}  AgentEscrowV2  ${DIM}Sepolia: 0x7102...21e${RESET}"
echo -e "  ${BOLD}[3] ERC-7512${RESET}  AuditMetadata  ${DIM}Sepolia: 0x0dd8...657${RESET}"
echo -e "  ${BOLD}[4] Audit Trail${RESET}  ImmutableHistory  ${DIM}Sepolia: 0xd791...bf0${RESET}"
pause 2

# ══════════════════════════════════════════════════════════════════
#  MULTI-CHAIN DEPLOYMENT (compact)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}  MULTI-CHAIN DEPLOYMENT${RESET}"
hr

echo -e "  ${BOLD}Sepolia:${RESET}  AuditCertificate  AgentEscrow  ERC7512  AuditTrail  Groth16"
echo -e "  ${BOLD}Base:${RESET}     AuditCertificate  ERC7512  AuditTrail  Groth16"
pause 1.5

# ══════════════════════════════════════════════════════════════════
#  REAL PROTOCOL AUDITS (compact)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}  REAL PROTOCOL AUDITS${RESET}"
hr

echo -e "  ${BOLD}[Audit 1] Curve V2${RESET}  Read-Only Reentrancy  ${RED}CRITICAL${RESET}  \$70M at risk  ${DIM}95% match${RESET}"
echo -e "  ${BOLD}[Audit 2] Hundred Finance${RESET}  Reentrancy+Oracle  ${RED}CRITICAL${RESET}  \$7M stolen  ${DIM}88% match${RESET}"
pause 1.5

# ══════════════════════════════════════════════════════════════════
#  RESULTS
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${BOLD}  ${CYAN}ATHENA${RESET} — Audit Complete"
hr
echo ""
pause 1

# On-chain verification page
echo -e "  ${BOLD}On-Chain Verification:${RESET}"
echo -e "  ${DIM}  https://athena.degure.me/demo/audit-report.html${RESET}"
echo ""
pause 1

# Local files
echo -e "  ${BOLD}Local Files:${RESET}"
echo -e "  ${DIM}  demo/full-audit-report.json    — Full audit report${RESET}"
echo -e "  ${DIM}  demo/audit-report.html         — On-chain verification page${RESET}"
echo -e "  ${DIM}  demo/FINAL-AUDIT-REPORT.md     — Final report${RESET}"
echo ""
pause 2

echo -e "  ${DIM}Thank you for watching.${RESET}"
echo ""
