#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Athena Demo — 基于真实 Pi 执行的录屏脚本
# 配合配音使用，暂停时间与语音同步
# ═══════════════════════════════════════════════════════════════
#
# Recording: asciinema rec demo.cast -c "bash demo/DEMO.sh"
# Video:     ffmpeg -f x11grab -i :99 -i demo/voice/final.ogg -shortest demo.mp4

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

hr() { echo -e "${DIM}$(printf '%.0s─' {1..72})${RESET}"; }
pause() { sleep "${1:-1.5}"; }

# ══════════════════════════════════════════════════════════════════
#  INTRO (voice: 11.7s)
# ══════════════════════════════════════════════════════════════════
clear
echo ""
echo -e "${BOLD}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}  ║${RESET}  ${CYAN}A T H E N A${RESET} — Web3 Smart Contract Security Audit Agent    ${BOLD}║${RESET}"
echo -e "${BOLD}  ║${RESET}  Powered by GLM-5.1 Long-Horizon Task                     ${BOLD}║${RESET}"
echo -e "${BOLD}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${DIM}Model:${RESET}     GLM-5.1 (200K context, long-horizon reasoning)"
echo -e "  ${DIM}Pipeline:${RESET}  8-step audit with subagent parallel orchestration"
echo -e "  ${DIM}Tools:${RESET}     13 MCP tools (slither, aderyn, poc_generator, fuzz_runner...)"
echo -e "  ${DIM}Chains:${RESET}    Sepolia + Base Sepolia"
echo ""
pause 8

# ══════════════════════════════════════════════════════════════════
#  STEP 1: 读取审计 Skill (voice: 15.8s)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}[STEP 1/8]${RESET} ${BOLD}读取审计 Skill — 12 Agent 并行架构${RESET}"
hr
pause 1

echo -e "  ${YELLOW}> cat skills/glm-audit-skill/SKILL.md${RESET}"
pause 0.5
echo ""
echo -e "  ${GREEN}[OK]${RESET} Athena — Parallelized Smart Contract Security Audit"
echo -e "  ${DIM}     12 specialized agents running in parallel:${RESET}"
echo -e "  ${DIM}     ├── Access Control Agent${RESET}"
echo -e "  ${DIM}     ├── Reentrancy Agent${RESET}"
echo -e "  ${DIM}     ├── Flash Loan Agent${RESET}"
echo -e "  ${DIM}     ├── Oracle Manipulation Agent${RESET}"
echo -e "  ${DIM}     └── ... (8 more specialized agents)${RESET}"
echo ""
pause 10

# ══════════════════════════════════════════════════════════════════
#  STEP 2: 选择审计目标 (voice: 11.0s)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}[STEP 2/8]${RESET} ${BOLD}选择审计目标 — VulnerableBank${RESET}"
hr
pause 1

echo -e "  ${YELLOW}> cat contracts/test-cases/Reentrancy.sol${RESET}"
pause 0.5
echo ""
echo -e "${DIM}  // SPDX-License-Identifier: MIT"
echo -e "  pragma solidity ^0.8.0;"
echo -e ""
echo -e "  contract VulnerableBank {"
echo -e "      mapping(address => uint256) public balances;"
echo -e ""
echo -e "      function deposit() public payable {"
echo -e "          balances[msg.sender] += msg.value;"
echo -e "      }"
echo -e ""
echo -e "      function withdraw() public {"
echo -e "          uint256 balance = balances[msg.sender];"
echo -e "          require(balance > 0, \"No balance\");"
echo -e "          // BUG: External call before state update"
echo -e "          (bool success, ) = msg.sender.call{value: balance}(\"\");"
echo -e "          require(success, \"Transfer failed\");"
echo -e "          balances[msg.sender] = 0;  // Too late!"
echo -e "      }"
echo -e "  }${RESET}"
echo ""
echo -e "  ${RED}[VULN]${RESET} Reentrancy: state update AFTER external call"
pause 6

# ══════════════════════════════════════════════════════════════════
#  STEP 3: 调度 Subagent 并行审计 (voice: 10.9s)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}[STEP 3/8]${RESET} ${BOLD}调度 3 个 Subagent 并行执行${RESET}"
hr
pause 1

echo -e "  ${BOLD}Spawning subagents...${RESET}"
echo ""
echo -e "  ${DIM}  ├─ subagent-1: 静态分析 (Slither + Aderyn)${RESET}"
echo -e "  ${DIM}  ├─ subagent-2: PoC 生成${RESET}"
echo -e "  ${DIM}  └─ subagent-3: Fuzz 测试${RESET}"
echo ""
pause 7

# ══════════════════════════════════════════════════════════════════
#  STEP 4: Subagent 1 — 双引擎静态分析 (voice: 16.5s)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}[STEP 4/8]${RESET} ${BOLD}Subagent 1 — 双引擎静态分析${RESET}"
hr
pause 1

echo -e "  ${YELLOW}> slither contracts/test-cases/Reentrancy.sol${RESET}"
pause 1
echo ""
echo -e "  ${RED}[HIGH]${RESET}  reentrancy-eth: Reentrancy in VulnerableBank.withdraw()"
echo -e "  ${DIM}     External call before state update at line 25${RESET}"
echo -e "  ${DIM}[LOW]${RESET}  solc-version: Unspecific pragma version"
echo -e "  ${DIM}[INFO]${RESET} low-level-calls: Low-level call usage"
echo ""
pause 1

echo -e "  ${YELLOW}> aderyn contracts/test-cases/${RESET}"
pause 1
echo ""
echo -e "  ${RED}[HIGH]${RESET}  H-3: Reentrancy — State change after external call"
echo -e "  ${RED}[HIGH]${RESET}  H-2: ETH transferred without address checks"
echo -e "  ${DIM}[LOW]${RESET}  L-19: Unspecific Solidity Pragma"
echo -e "  ${DIM}[LOW]${RESET}  L-21: Public Function Not Used Internally"
echo ""
echo -e "  ${GREEN}[MERGE]${RESET} Slither (3) + Aderyn (4) → 4 unique findings after dedup"
pause 7

# ══════════════════════════════════════════════════════════════════
#  STEP 5: Subagent 2 — PoC 生成 (voice: 12.5s)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}[STEP 5/8]${RESET} ${BOLD}Subagent 2 — PoC 攻击验证${RESET}"
hr
pause 1

echo -e "  ${YELLOW}> python3 mcp/tools/poc_generator.py --vuln reentrancy${RESET}"
pause 1
echo ""
echo -e "${DIM}  contract Attacker {"
echo -e "      VulnerableBank public bank;"
echo -e "      uint256 public constant DEPOSIT_AMOUNT = 1 ether;"
echo -e ""
echo -e "      function attack() external payable {"
echo -e "          bank.deposit{value: DEPOSIT_AMOUNT}();"
echo -e "          bank.withdraw();  // triggers reentrancy"
echo -e "      }"
echo -e ""
echo -e "      receive() external payable {"
echo -e "          if (address(bank).balance >= DEPOSIT_AMOUNT) {"
echo -e "              bank.withdraw();  // re-enter"
echo -e "          }"
echo -e "      }"
echo -e "  }${RESET}"
echo ""
echo -e "  ${GREEN}[OK]${RESET} PoC generated → contracts/test-cases/ReentrancyAttack.sol"
pause 5

# ══════════════════════════════════════════════════════════════════
#  STEP 6: Subagent 3 — Fuzz 测试 (voice: 15.8s)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}[STEP 6/8]${RESET} ${BOLD}Subagent 3 — Fuzz 测试验证${RESET}"
hr
pause 1

echo -e "  ${YELLOW}> forge test --match-test testReentrancy -vvv${RESET}"
pause 1
echo ""
echo -e "  ${GREEN}[PASS]${RESET} testFuzz_full_drain()"
echo -e "  ${GREEN}[PASS]${RESET} testFuzz_reentrancy_steals()"
echo -e "  ${GREEN}[PASS]${RESET} testFuzz_varying_bank_balance()"
echo -e "  ${GREEN}[PASS]${RESET} test_attack_counts_reentries()"
echo -e "  ${GREEN}[PASS]${RESET} test_full_drain()"
echo -e "  ${GREEN}[PASS]${RESET} test_reentrancy_exploit()"
echo ""
echo -e "  ${DIM}  总测试: 6 | 通过: 6/6 | Fuzz 运行: 768 次${RESET}"
echo -e "  ${DIM}  银行余额: 10 ETH → 0 ETH | 攻击者获利: 11 ETH${RESET}"
echo ""
echo -e "  ${GREEN}[VERIFIED]${RESET} 漏洞通过 fuzz 测试确认"
pause 7

# ══════════════════════════════════════════════════════════════════
#  STEP 7: 汇总 Subagent 结果 (voice: 20.0s)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}[STEP 7/8]${RESET} ${BOLD}汇总审计结果${RESET}"
hr
pause 1

echo ""
echo -e "  ${BOLD}审计结果汇总:${RESET}"
echo ""
echo -e "  ${DIM}  静态分析:${RESET}"
echo -e "  ${DIM}    └─ 4 个唯一发现 (2 HIGH + 2 LOW)${RESET}"
echo ""
echo -e "  ${DIM}  PoC 生成:${RESET}"
echo -e "  ${DIM}    └─ 攻击成功，银行余额被清空${RESET}"
echo ""
echo -e "  ${DIM}  Fuzz 测试:${RESET}"
echo -e "  ${DIM}    └─ 768 次 fuzz 运行，0 反例${RESET}"
echo ""
echo -e "  ${RED}  综合评级: S (Critical)${RESET}"
echo ""
echo -e "  ${CYAN}  修复建议:${RESET}"
echo -e "  ${DIM}    1. 使用 Checks-Effects-Interactions 模式${RESET}"
echo -e "  ${DIM}    2. 添加 ReentrancyGuard${RESET}"
echo -e "  ${DIM}    3. 先更新状态，再外部调用${RESET}"
pause 10

# ══════════════════════════════════════════════════════════════════
#  STEP 8: 链上认证 (voice: 17.0s)
# ══════════════════════════════════════════════════════════════════
hr
echo -e "${CYAN}${BOLD}[STEP 8/8]${RESET} ${BOLD}链上认证 — EAS + NFT${RESET}"
hr
pause 1

echo -e "  ${YELLOW}> python3 mcp/tools/eas_attest.py --schema 0x6d6520d9...${RESET}"
pause 1
echo ""
echo -e "  ${GREEN}[TX]${RESET}  EAS Attestation created"
echo -e "  ${DIM}     Schema: 0x6d6520d928b6090172a458c2addcd30af1090f5298110e496bb3c9ac3918253e${RESET}"
echo -e "  ${DIM}     UID:    0xd02800c960f18f0483af4aa320aff314e34c5a83d1c9a9c963b299a88af958b9${RESET}"
echo ""
pause 1

echo -e "  ${YELLOW}> python3 mcp/tools/evidence_chain.py --mint-nft --grade S${RESET}"
pause 1
echo ""
echo -e "  ${GREEN}[TX]${RESET}  NFT Minted on Sepolia"
echo -e "  ${DIM}     Sepolia:  0x3247d57d37bd1878479f03a077aba807649dbaf5${RESET}"
echo -e "  ${DIM}     Base:     0xb8f167a84816b5b9373997337119a2186c6e3708${RESET}"
echo -e "  ${DIM}     Token ID: 1 (Grade S)${RESET}"
echo -e "  ${DIM}     Traits:   262,144 possible combinations (4^9)${RESET}"
echo ""
pause 8

# ══════════════════════════════════════════════════════════════════
#  CLOSING (voice: 21.1s)
# ══════════════════════════════════════════════════════════════════
echo ""
hr
echo -e "  ${BOLD}MULTI-CHAIN DEPLOYMENT${RESET}"
hr
pause 1

echo ""
echo -e "  ${BOLD}Sepolia (Ethereum Testnet)${RESET}"
echo -e "  ${DIM}  AuditCertificate:    0x3247d57d37bd1878479f03a077aba807649dbaf5${RESET}"
echo -e "  ${DIM}  AgentEscrowV2:       0x7102b7252dea80529278c8bffc441b96ff24421e${RESET}"
echo -e "  ${DIM}  ERC7512Metadata:     0x0dd8f8f5b755912aa3b955044d1eff496a65e657${RESET}"
echo -e "  ${DIM}  AuditTrail:          0xd7913e7749595a9238883bdf0b2dad599f4d0bf0${RESET}"
echo -e "  ${DIM}  Groth16Verifier:     0xf0c9ec42fe603a53af3e6248e874bbbb3064e498${RESET}"
echo ""
echo -e "  ${BOLD}Base Sepolia (L2 Testnet)${RESET}"
echo -e "  ${DIM}  AuditCertificate:    0xb8f167a84816b5b9373997337119a2186c6e3708${RESET}"
echo -e "  ${DIM}  ERC7512Metadata:     0x5e99f144d3e512f525d24077d4626a064899e177${RESET}"
echo -e "  ${DIM}  Groth16Verifier:     0x636b3af9630e1b26b02ba488a5b8ab6ce75d6721${RESET}"
echo -e "  ${DIM}  AuditTrail:          0x83bfbc0901c9a6481a26ec2dc649487768ec8a99${RESET}"
pause 3

echo ""
hr
echo -e "  ${BOLD}REAL PROTOCOL AUDITS${RESET}"
hr
pause 1

echo ""
echo -e "  ${BOLD}[Audit 1] Curve V2 — Read-Only Reentrancy${RESET}"
echo -e "  ${DIM}  Severity:  CRITICAL${RESET}"
echo -e "  ${DIM}  Impact:    \$70M at risk${RESET}"
echo -e "  ${DIM}  Type:      Read-only reentrancy in remove_liquidity_one_coin()${RESET}"
echo -e "  ${DIM}  Match:     95% (Agent vs actual attack path)${RESET}"
echo -e "  ${RED}  [FOUND]${RESET} Detected by Athena's reentrancy + oracle analysis"
echo ""
pause 2

echo -e "  ${BOLD}[Audit 2] Hundred Finance — Reentrancy + Oracle Manipulation${RESET}"
echo -e "  ${DIM}  Severity:  CRITICAL${RESET}"
echo -e "  ${DIM}  Impact:    \$7M stolen${RESET}"
echo -e "  ${DIM}  Type:      Compound fork reentrancy + Curve oracle manipulation${RESET}"
echo -e "  ${DIM}  Match:     88% (Agent vs actual attack path)${RESET}"
echo -e "  ${RED}  [FOUND]${RESET} Multi-vector attack chain identified"
pause 2

echo ""
hr
echo -e "  ${CYAN}ATHENA${RESET} — From Vulnerability Discovery to On-Chain Certification"
hr
echo ""
echo -e "  ${DIM}GitHub:${RESET}   https://github.com/tiyadegure/Athena"
echo -e "  ${DIM}Landing:${RESET}  https://athena.degure.me"
echo -e "  ${DIM}Model:${RESET}    GLM-5.1 (Z.AI Coding Plan)"
echo -e "  ${DIM}Chains:${RESET}   Sepolia + Base Sepolia"
echo -e "  ${DIM}NFT:${RESET}      262,144 generative warrior combinations"
echo ""
echo -e "  ${DIM}Powered by GLM-5.1 Long-Horizon Task${RESET}"
echo ""
echo -e "  ${DIM}Thank you for watching.${RESET}"
echo ""
pause 2
