# v8: Run All Project Deliverables

**Objective:** Execute Athena's full audit workflow end-to-end on Sepolia, collect all artifacts for PPT/Demo/README.

---

## Execution Order

### Step 1: Full GLM-5.1 Audit (8-Step Loop)

Run on multi-contract suite (Token + Oracle + Vault + advanced contracts):

```bash
cd /root/projects/glm-code
export GLM_API_KEY="your-key"
# Run GLM-5.1 through the full 8-step audit loop
node scripts/real-audit-v6.js \
  --contracts contracts/multi-contract/Token.sol,contracts/multi-contract/Oracle.sol,contracts/multi-contract/Vault.sol \
  --workflow athena-audit-skill \
  --output demo/report.json \
  --verbose
```

**Deliverables:**
- `demo/report.json` — full audit report (vulnerabilities, severity, PoC, fixes)

### Step 2: Evidence Chain

```bash
# Record audit hash + process metadata on-chain
node scripts/record-evidence.js \
  --report demo/report.json \
  --contract 0x5e99f144D3e512f525d24077D4626a064899E177 \
  --network sepolia
```

**Deliverables:**
- `demo/evidence-receipt.json` — on-chain tx hash + Merkle root
- `demo/evidence-chain.json` — full evidence log (skill versions, MCP tools, timestamps)

### Step 3: NFT Minting (4 Tiers)

```bash
# Mint S-tier certificate (best audit)
node scripts/mint-nft.js \
  --contract 0xcaA7faeA44C3513F629C6f260ad26EBB677E5E4E \
  --tier S \
  --report demo/report.json \
  --evidence demo/evidence-receipt.json \
  --network sepolia

# Repeat for A, B, C tiers (demo purposes)
```

**Deliverables:**
- `demo/nft-mints.json` — 4 tx hashes + token IDs (S/A/B/C)
- On-chain SVG for each tier (visible on OpenSea/Etherscan)

### Step 4: Landing Page Screenshot

```bash
# Capture landing page state
# Use browser tool or manual screenshot of athena.degure.me
```

**Deliverables:**
- `demo/landing-screenshot.png`

### Step 5: Frontend Demo Screenshot

```bash
# Open frontend/index.html, connect MetaMask, show audit report + NFT preview
```

**Deliverables:**
- `demo/frontend-report-view.png` — report display
- `demo/frontend-nft-preview.png` — S/A/B/C NFT preview
- `demo/frontend-mint-confirmation.png` — MetaMask mint confirmation

### Step 6: Etherscan Screenshots

Capture from Etherscan (Sepolia):

**Deliverables:**
- `demo/etherscan-contract.png` — verified contract page
- `demo/etherscan-mint-tx.png` — mint transaction
- `demo/etherscan-nft-detail.png` — NFT detail with SVG
- `demo/etherscan-evidence-chain.png` — evidence chain tx

### Step 7: Demo Video

```bash
# Record terminal demo (4-5 min)
# 1. [0:00-0:30] Project overview (README)
# 2. [0:30-2:30] GLM-5.1 audit execution
# 3. [2:30-3:30] Evidence chain recording
# 4. [3:30-4:30] NFT minting + frontend
# 5. [4:30-5:00] On-chain verification
```

**Deliverables:**
- `demo/athena-demo.mp4`

---

## Artifact Inventory

| # | File | Source | PPT Use |
|---|------|--------|---------|
| 1 | `demo/report.json` | GLM-5.1 audit | Slide 5-6 |
| 2 | `demo/evidence-receipt.json` | Evidence chain | Slide 7 |
| 3 | `demo/evidence-chain.json` | Evidence chain | Appendix |
| 4 | `demo/nft-mints.json` | NFT minting | Slide 8 |
| 5 | `demo/nft-preview.html` | Existing | Slide 8 |
| 6 | `demo/nft-s-tier-v2.gif` | Existing | Slide 8 |
| 7 | `demo/nft-a-tier.png` | Existing | Slide 8 |
| 8 | `demo/nft-b-tier.png` | Existing | Slide 8 |
| 9 | `demo/nft-c-tier.png` | Existing | Slide 8 |
| 10 | `demo/nft-athena-owl-v6.png` | Existing | README |
| 11 | `demo/landing-screenshot.png` | Capture | Slide 9 |
| 12 | `demo/frontend-*.png` | Capture | Slide 9 |
| 13 | `demo/etherscan-*.png` | Capture | Slide 6,8 |
| 14 | `demo/athena-demo.mp4` | Record | Demo |
| 15 | `docs/PRODUCT.md` | Existing | Slide 3 |
| 16 | `docs/ZK-INSPIRATION.md` | Existing | Slide 10 |
| 17 | `athena-audit-skill/SKILL.md` | Existing | Slide 5 |
| 18 | `workflows/v5-long-horizon.md` | Existing | Slide 4 |

---

## New Scripts Needed

| Script | Purpose |
|--------|---------|
| `scripts/real-audit-v6.js` | GLM-5.1 full 8-step audit execution |
| `scripts/record-evidence.js` | Record audit evidence on-chain |
| `scripts/mint-nft.js` | Mint NFT with report data |

---

## Success Criteria

- [ ] GLM-5.1 completes full 8-step audit on multi-contract suite
- [ ] report.json has ≥3 real vulnerabilities (not mock data)
- [ ] Evidence chain recorded on Sepolia with verifiable tx hash
- [ ] S/A/B/C NFTs minted on Sepolia with correct tier SVGs
- [ ] All 18 artifacts collected in `demo/`
- [ ] Demo video recorded (4-5 min)
