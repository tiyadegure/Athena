# v8: Generate All Project Artifacts for PPT

**Objective:** Run Athena's full audit workflow on Sepolia, collect all artifacts needed for PPT.

**Note:** Demo video recording is NOT included — user will handle manually.

---

## Execution Steps

### Step 1: Run Full GLM-5.1 Audit

Execute the 8-step audit loop on multi-contract suite:

```bash
cd /root/projects/glm-code
chmod +x scripts/real-audit-v6.sh
./scripts/real-audit-v6.sh
```

**Expected output:**
- `demo/report.json` — full audit report with vulnerabilities

### Step 2: Record Evidence on Chain

```bash
# Use MCP tool or direct script
cd /root/projects/glm-code
python3 mcp/tools/evidence_chain.py \
  --report demo/report.json \
  --contract 0x5e99f144D3e512f525d24077D4626a064899E177 \
  --network sepolia
```

**Expected output:**
- `demo/evidence-receipt.json` — on-chain tx hash + Merkle root

### Step 3: Mint S/A/B/C NFTs

```bash
# Mint all 4 tiers for demo
cd /root/projects/glm-code
python3 mcp/tools/eas_attest.py \
  --contract 0xcaA7faeA44C3513F629C6f260ad26EBB677E5E4E \
  --report demo/report.json \
  --network sepolia
```

**Expected output:**
- `demo/nft-mints.json` — 4 tx hashes + token IDs (S/A/B/C)

### Step 4: Generate Audit Report PDF

```bash
# Generate formatted report
cd /root/projects/glm-code
python3 -c "
import json
with open('demo/report.json') as f:
    report = json.load(f)
# Generate PDF or markdown summary
"
```

**Expected output:**
- `demo/audit-report.pdf` or `demo/audit-report.md`

### Step 5: Collect All Artifacts

Verify all artifacts exist:

```bash
cd /root/projects/glm-code
ls -la demo/report.json
ls -la demo/evidence-receipt.json
ls -la demo/nft-mints.json
ls -la demo/nft-preview.html
ls -la demo/nft-athena-owl-v6.png
```

---

## Artifact Inventory for PPT

| # | File | Source | PPT Use |
|---|------|--------|---------|
| 1 | `demo/report.json` | GLM-5.1 audit | Slide 5-6 |
| 2 | `demo/evidence-receipt.json` | Evidence chain | Slide 7 |
| 3 | `demo/nft-mints.json` | NFT minting | Slide 8 |
| 4 | `demo/nft-preview.html` | Existing | Slide 8 |
| 5 | `demo/nft-athena-owl-v6.png` | Existing | README |
| 6 | `docs/PRODUCT.md` | Existing | Slide 3 |
| 7 | `docs/ZK-INSPIRATION.md` | Existing | Slide 10 |
| 8 | `skills/glm-audit-skill/SKILL.md` | Existing | Slide 5 |
| 9 | `workflows/v5-long-horizon.md` | Existing | Slide 4 |
| 10 | `ppt-assets/*.svg` | Existing | All slides |

---

## Success Criteria

- [ ] GLM-5.1 completes full 8-step audit on multi-contract suite
- [ ] `demo/report.json` has ≥3 real vulnerabilities
- [ ] Evidence chain recorded on Sepolia with verifiable tx hash
- [ ] S/A/B/C NFTs minted on Sepolia with correct tier SVGs
- [ ] All 10 artifacts verified and ready for PPT
