# Smart Contract Audit Agent Projects — Comprehensive Comparison

**Research Date:** June 2026  
**Methodology:** GitHub API searches (10+ query strategies), repository cloning, file analysis, README/code inspection

---

## Top-Tier Projects (50+ stars, production-ready)

### 1. Plamen (244★)
- **URL:** https://github.com/PlamenTSV/plamen
- **Type:** CLI Framework (Python) + Skills + MCP servers
- **Platforms:** Claude Code, OpenAI Codex CLI
- **Languages:** EVM/Solidity, Solana/Anchor, Aptos Move, Sui Move, Soroban/Stellar, Go/Rust node clients
- **Tools:** Slither (MCP), Aderyn, Foundry, ChromaDB RAG, Solodit API, Farofino MCP, custom MCP servers
- **Multi-agent:** ✅ 18-100 agents across 8 phases
- **PoC Generation:** ✅ Verified PoC exploits (Phase 5)
- **Fuzz Testing:** ✅ Foundry fuzz
- **RAG/Knowledge Base:** ✅ ChromaDB + Solodit vulnerability DB (~6GB)
- **Chain Attestation:** ❌
- **Key Differentiators:** Most comprehensive multi-chain support, 8-phase pipeline, RAG database from Solodit, custom MCP servers for Slither/Farofino, orchestrator with skill registry, supports both Claude Code and Codex CLI

### 2. SolidityGuard (95★)
- **URL:** https://github.com/alt-research/SolidityGuard
- **Type:** CLI + Web App + Desktop App + OpenClaw Skill
- **Platforms:** Standalone CLI, Web (solidityguard.altllm.ai), Tauri desktop, OpenClaw
- **Languages:** Solidity/EVM
- **Tools:** Slither, Mythril, Echidna, Aderyn, Foundry v1.0, Medusa v1, Halmos, Certora, EVMBench (9 tools)
- **Multi-agent:** ✅ 9 specialized sub-agents
- **PoC Generation:** ✅ Foundry fork-based PoC
- **Fuzz Testing:** ✅ Foundry invariant + Echidna property tests
- **RAG/Knowledge Base:** ✅ 104 vulnerability patterns, exploit history, CTF test matrix, checklists
- **Chain Attestation:** ❌
- **Key Differentiators:** 100% on EVMBench (120/120), 100% on 85 CTF challenges, 3 app surfaces, OWASP 2025 aligned, most tool integrations (9), formal verification (Halmos + Certora)

### 3. BountyForge (113★)
- **URL:** https://github.com/Gabson0x/bountyforge
- **Type:** Claude Code Skill
- **Platforms:** Claude Code
- **Languages:** EVM/Solidity, Move/Aptos, Solana, TRON
- **Tools:** Slither, Foundry (via local-tooling.md references)
- **Multi-agent:** ✅ 8 parallel specialized agents (smart-contract, access-control, business-logic, crypto-math, race-condition, economic-security, recon, web-api)
- **PoC Generation:** ❌ (focuses on finding bugs, not PoC)
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌ (uses attack vector reference files)
- **Chain Attestation:** ❌
- **Key Differentiators:** Multi-target (web + smart contract), platform-specific report formatting (HackerOne, Bugcrowd, Intigriti, Immunefi), CVSS scoring, parallelized agent bundles

### 4. Vigilo (46★)
- **URL:** https://github.com/PurpleAILAB/Vigilo
- **Type:** OpenCode Plugin + Claude Code Plugin (npm package)
- **Platforms:** OpenCode, Claude Code
- **Languages:** Solidity, Vyper, Cairo, Rust (Solana/NEAR), Go (Cosmos)
- **Tools:** Foundry (forge build/test/coverage), LSP integration
- **Multi-agent:** ✅ Legion architecture (Vigilo orchestrator, Quaestor, Explorator, Speculator, 8 Centuriones)
- **PoC Generation:** ✅ Foundry PoC validation
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** Real-world finding proof (Cantina high-severity accepted), protocol-specific specialist agents, report templates for C4/Sherlock/Cantina/Immunefi, npm-distributed

### 5. forefy/.context (103★)
- **URL:** https://github.com/forefy/.context
- **Type:** Claude Code Skills Collection
- **Platforms:** Claude Code
- **Languages:** Solidity, Vyper, Anchor/Solana, TON/FunC/Tact, Sui/Move
- **Tools:** Foundry (PoC skill), protocol-type-specific tricks
- **Multi-agent:** ✅ Multi-expert analysis pattern, triager, sandboxed audit runner
- **PoC Generation:** ✅ Foundry PoC skill
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌ (reference-based vulnerability patterns)
- **Chain Attestation:** ❌
- **Key Differentiators:** Multi-chain language support (5+), infrastructure audit skill, Google Docs report output, debug logging protocol, industry-grade report format

### 6. QuillShield Skills (107★)
- **URL:** https://github.com/quillai-network/quillshield_skills
- **Type:** Claude Code / Cursor Skills (11 plugins)
- **Platforms:** Claude Code, Cursor
- **Languages:** Solidity/EVM
- **Tools:** Static analysis methodology (no direct tool integration)
- **Multi-agent:** ❌ (individual skill plugins)
- **PoC Generation:** ✅ (adversarial simulation with PoC in BSA)
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** Deep methodology-based approach (behavioral state analysis, semantic guard analysis, state invariant detection), Bayesian confidence scoring, 11 specialized analysis plugins covering reentrancy/oracle/proxy/signature/DoS/access-control

### 7. DarkNavy web3-skills (78★)
- **URL:** https://github.com/DarkNavySecurity/web3-skills
- **Type:** Claude Code / Codex Skills (3 skills)
- **Platforms:** Claude Code, Codex
- **Languages:** Solidity, Go/Rust/C++ (node clients)
- **Tools:** Foundry (PoC), Python-based analysis, Gigahorse decompiler (TAC server)
- **Multi-agent:** ✅ DFS-based context mapping, parallel hunt agents, adversarial falsifier, Analyst-Validator debate loop
- **PoC Generation:** ✅ Foundry PoC generation
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** 3 distinct skills (contract-auditor, client-auditor for node software, exploit-investigator for on-chain tx tracing), $22K Immunefi earnings, XRPL vulnerability discovery, 60+ exploit analysis artifacts

### 8. OpenAudit (6★)
- **URL:** https://github.com/tradingstrategy-ai/openaudit
- **Type:** Claude Code / Codex Metaskill
- **Platforms:** Claude Code, Codex
- **Languages:** Solidity, Vyper, Anchor/Rust, CosmWasm/Rust
- **Tools:** Slither, Foundry, web3-ethereum-defi, Web3.py, Aderyn
- **Multi-agent:** ✅ Aggregates 10+ community skill repos (100+ skills) into parallel pipelines
- **PoC Generation:** ❌
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌ (cross-references existing audit reports)
- **Chain Attestation:** ❌
- **Key Differentiators:** META-SKILL — aggregates Trail of Bits (3,274★), pashov, Cyfrin, forefy, QuillShield, and more into a single pipeline. Deduplicates findings across repos. Can audit deployed contracts by address. 100% open source.

---

## Mid-Tier Projects (10-50 stars)

### 9. Chonky (15★)
- **URL:** https://github.com/tintinweb/vscode-chonky
- **Type:** VS Code Extension
- **Platforms:** VS Code + GitHub Copilot
- **Languages:** Solidity
- **Tools:** VS Code LLM tools, Copilot agent mode
- **Multi-agent:** ❌
- **PoC Generation:** ❌
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** VS Code native, transforms Copilot into audit agent, automated scoping, agent-augmented auditing

### 10. Critikal (12★)
- **URL:** https://github.com/Tushar-Pandey-31/Critikal
- **Type:** Standalone Python Framework (CLI + TUI)
- **Platforms:** Standalone (LangGraph-based)
- **Languages:** Solidity/EVM
- **Tools:** Slither, Foundry (PoC), NetworkX knowledge graph, Etherscan API, multi-LLM (GPT-5, Grok-4, Claude, Gemini)
- **Multi-agent:** ✅ Multi-worker pipeline (Recon → Attack Hypothesis → Test Writer), jury debate with multiple LLMs
- **PoC Generation:** ✅ Foundry PoC with self-correction
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ✅ NetworkX knowledge graph with security enrichments
- **Chain Attestation:** ❌
- **Key Differentiators:** Attacker mindset, knowledge graph-based hotspot scoring, 4-gate pre-filter + jury debate, Docker support, HTML+Markdown reports, benchmark harness (SCONE)

### 11. EVM Audit Skills (5★)
- **URL:** https://github.com/austintgriffith/evm-audit-skills
- **Type:** Claude Code Skills (20 skills)
- **Platforms:** Claude Code
- **Languages:** Solidity/EVM
- **Tools:** None (pure LLM checklist-based)
- **Multi-agent:** ❌ (20 specialized skills loaded via routing table)
- **PoC Generation:** ❌
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** 500+ non-obvious checklist items across 20 specialized skills covering every DeFi vertical (AMM, lending, staking, ERC4626, ERC4337, bridges, governance, oracles, etc.), routing table for skill selection

### 12. Solidity Auditor Skills (sanbir) (26★)
- **URL:** https://github.com/sanbir/solidity-auditor-skills
- **Type:** Claude Code / Cursor / Codex / Copilot Skill
- **Platforms:** Claude Code, Cursor, Codex, GitHub Copilot, Windsurf
- **Languages:** Solidity/EVM
- **Tools:** None (LLM-based)
- **Multi-agent:** ✅ 8 parallel specialized agents (vector-scan, math-precision, access-control, economic-security, execution-trace, invariant, periphery, first-principles)
- **PoC Generation:** ❌
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** Fork of pashov/skills v2 with 328 vectors, broadest IDE platform support (5 platforms), EVM-specific tuning

### 13. EllipticZero (23★)
- **URL:** https://github.com/ECD5A/EllipticZero
- **Type:** Standalone Python Framework (CLI + TUI)
- **Platforms:** Standalone
- **Languages:** Solidity/EVM + ECC research
- **Tools:** Local computation tools, SARIF export
- **Multi-agent:** ✅ Bounded agents with evidence-first workflow
- **PoC Generation:** ❌
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** Evidence-first local research, reproducible sessions/manifests/bundles, SARIF exports, ECC (elliptic curve cryptography) research, golden cases/benchmarks, manual-review boundaries

---

## Smaller/Niche Projects

### 14. RugProof (7★)
- **URL:** https://github.com/omermaksutii/RugProof
- **Type:** Claude Code Plugin (npm)
- **Platforms:** Claude Code
- **Languages:** Solidity, Vyper (EVM)
- **Tools:** Slither, Mythril, Foundry, 9 custom MCP servers (Anvil, Forge, Tenderly, Sherlock, C4 history, gas tracker, block explorer, token metadata, Hardhat)
- **Multi-agent:** ✅ 19 specialist subagents
- **PoC Generation:** ✅ Foundry PoC with exploit chaining
- **Fuzz Testing:** ✅ Foundry invariant + fuzz tests
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ✅ Soulbound on-chain audit certificates (Berachain)
- **Key Differentiators:** 38 slash commands, 33 auto-invoked vulnerability skills, 9 custom MCP servers, mainnet-fork simulation, on-chain audit certificates, gas profiling, shareable audit cards, protocol-specific specialists (AA, crosschain, restaking, intents)

### 15. ACAI-DAG-Auditor (4★)
- **URL:** https://github.com/ACaiSec/acai-dag-auditor
- **Type:** Claude Code Skill
- **Platforms:** Claude Code
- **Languages:** Solidity
- **Tools:** DAG-based workflow engine
- **Multi-agent:** ✅ DAG-orchestrated analysis nodes
- **PoC Generation:** ❌
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** DAG-based dataflow scheduling, Code4rena-style reports, declarative extensible workflow

### 16. Web3 Audit Response Toolkit (3★)
- **URL:** https://github.com/Ammalgam-Protocol/web3-audit-response-toolkit
- **Type:** Claude Code Plugin (3 skills)
- **Platforms:** Claude Code
- **Languages:** Solidity
- **Tools:** Foundry (PoC tests)
- **Multi-agent:** ❌
- **PoC Generation:** ✅ Two-layer PoC → regression test conversion
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** AUDIT RESPONSE focus (not audit itself) — review findings, resolve via TDD, aggregate campaigns, deduplicate, score auditors

### 17. Solidity Audit MCP (1★)
- **URL:** https://github.com/mariano-aguero/solidity-audit-mcp
- **Type:** MCP Server
- **Platforms:** Any MCP client (Claude, etc.)
- **Languages:** Solidity
- **Tools:** Slither, Aderyn, SWC Registry pattern matching
- **Multi-agent:** ❌
- **PoC Generation:** ❌
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** Pure MCP server for CI/CD integration, GitHub Actions workflow included

### 18. EVM MCP Tools (18★)
- **URL:** https://github.com/0xGval/evm-mcp-tools
- **Type:** MCP Server
- **Platforms:** Claude for Desktop
- **Languages:** Solidity/EVM
- **Tools:** Etherscan, Moralis, Codex, Twitter API
- **Multi-agent:** ❌
- **PoC Generation:** ❌
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** Blockchain analysis toolkit (wallet, token, contract audit), not specialized for security auditing

### 19. Solidity Audit Recipes (2★)
- **URL:** https://github.com/TilakMaddy/solidity-audit-recipes
- **Type:** Goose Recipes + Aderyn MCP
- **Platforms:** Goose Desktop
- **Languages:** Solidity
- **Tools:** Aderyn (MCP server)
- **Multi-agent:** ❌
- **PoC Generation:** ❌
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** Uses Aderyn's built-in MCP server for guided audits, Goose recipe format

### 20. GreatPie smart-contract-audit-skill (101★)
- **URL:** https://github.com/greatpie/smart-contract-audit-skill
- **Type:** Claude Code Skill + Scripts
- **Platforms:** Claude Code, Codex
- **Languages:** EVM (Solidity)
- **Tools:** Foundry, scripted pipeline (bash)
- **Multi-agent:** ❌
- **PoC Generation:** ✅ Exploit scaffolding (Foundry template)
- **Fuzz Testing:** ❌
- **RAG/Knowledge Base:** ❌
- **Chain Attestation:** ❌
- **Key Differentiators:** EVMbench-aligned methodology, scripted deterministic execution (detect/patch/exploit phases), reproducible artifacts

---

## Comparison Matrix

| Project | ★ | Type | Tools | PoC | Fuzz | RAG | Attestation | Multi-Agent | Languages |
|---------|---|------|-------|-----|------|-----|-------------|-------------|-----------|
| Plamen | 244 | CLI+Skill+MCP | Slither, Aderyn, Foundry | ✅ | ✅ | ✅ ChromaDB/Solodit | ❌ | ✅ 18-100 | Solidity, Solana, Move, Sui, Soroban, Go/Rust |
| SolidityGuard | 95 | CLI+Web+Desktop+Skill | Slither, Mythril, Echidna, Aderyn, Foundry, Medusa, Halmos, Certora, EVMBench | ✅ | ✅ | ✅ Patterns/KB | ❌ | ✅ 9 | Solidity |
| BountyForge | 113 | Skill | Slither, Foundry | ❌ | ❌ | ❌ | ❌ | ✅ 8 | Solidity, Move, Solana, TRON |
| Vigilo | 46 | Plugin | Foundry, LSP | ✅ | ❌ | ❌ | ❌ | ✅ Legion | Solidity, Vyper, Cairo, Rust, Go |
| forefy/.context | 103 | Skills | Foundry | ✅ | ❌ | ❌ | ❌ | ✅ Multi-expert | Solidity, Vyper, Solana, TON, Sui |
| QuillShield | 107 | Skills | — | ✅ | ❌ | ❌ | ❌ | ❌ | Solidity |
| DarkNavy | 78 | Skills | Foundry, Gigahorse | ✅ | ❌ | ❌ | ❌ | ✅ | Solidity, Go/Rust/C++ |
| OpenAudit | 6 | Metaskill | Slither, Foundry, Aderyn, web3.py | ❌ | ❌ | ❌ | ❌ | ✅ 10+ repos | Solidity, Vyper, Anchor, CosmWasm |
| Critikal | 12 | Framework | Slither, Foundry, NetworkX | ✅ | ❌ | ✅ KG | ❌ | ✅ Multi-worker | Solidity |
| RugProof | 7 | Plugin+MCP | Slither, Mythril, Foundry, 9 MCP servers | ✅ | ✅ | ❌ | ✅ On-chain | ✅ 19 | Solidity, Vyper |
| EVM Audit Skills | 5 | Skills | — | ❌ | ❌ | ❌ | ❌ | ❌ | Solidity |
| sanbir | 26 | Skill | — | ❌ | ❌ | ❌ | ❌ | ✅ 8 | Solidity |
| EllipticZero | 23 | Framework | Local tools | ❌ | ❌ | ❌ | ❌ | ✅ Bounded | Solidity + ECC |
| Chonky | 15 | VS Code Ext | VS Code tools | ❌ | ❌ | ❌ | ❌ | ❌ | Solidity |
| ACAI | 4 | Skill | — | ❌ | ❌ | ❌ | ❌ | ✅ DAG | Solidity |
| Audit Response | 3 | Plugin | Foundry | ✅ | ❌ | ❌ | ❌ | ❌ | Solidity |
| Solidity Audit MCP | 1 | MCP Server | Slither, Aderyn | ❌ | ❌ | ❌ | ❌ | ❌ | Solidity |
| GreatPie | 101 | Skill+Scripts | Foundry | ✅ | ❌ | ❌ | ❌ | ❌ | Solidity |

---

## Key Findings

1. **Plamen is the most comprehensive** — multi-chain, RAG-backed, 18-100 agents, 8-phase pipeline, custom MCP servers
2. **SolidityGuard has the most tool integrations** (9 tools) and best benchmark scores (100% EVMBench)
3. **RugProof is the most feature-rich plugin** — 38 commands, 9 MCP servers, on-chain attestation, fuzz testing
4. **OpenAudit is the best aggregator** — meta-skill combining 10+ community repos into one pipeline
5. **Most projects are Solidity-only** — only Plamen, BountyForge, forefy, and Vigilo support multiple chains
6. **RAG is rare** — only Plamen (ChromaDB+Solodit) and Critikal (NetworkX KG) have knowledge bases
7. **On-chain attestation is unique to RugProof** — soulbound audit certificates
8. **MCP servers are emerging** — Plamen ships custom MCP servers, RugProof has 9, but dedicated audit MCP servers are sparse
9. **Fuzz testing is uncommon** — only Plamen, SolidityGuard, and RugProof integrate fuzz testing
10. **PoC generation is widespread** — most mature projects include Foundry PoC generation
