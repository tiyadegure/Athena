# Workflow v7: uPEG-Inspired Enhancements

> Inspired by [Unipeg (uPEG)](https://etherscan.io/address/0x44b28991b167582f18ba0259e0173176ca125505) — a hybrid ERC-20/NFT collection on Uniswap v4 Hooks.

## Core Insight

uPEG demonstrates that **a single asset can have dual financial semantics**:
- **ERC-721 (non-fungible)**: The unique audit certificate with full report data
- **ERC-20 (fungible)**: A transferable reputation token representing audit quality score

This unlocks DeFi composability that pure NFT approaches miss.

---

## Idea 1: Hybrid Reputation Token (ERC-20 + ERC-721)

### Concept

Each audit mints:
1. **AuditCertificate (ERC-721)** — non-transferable soulbound NFT containing the full audit report, evidence chain, and on-chain verification
2. **AthenaRep (ERC-20)** — transferable reputation tokens minted proportional to audit quality score

### Mechanism

```
Audit Score    AthenaRep Minted    Tier
   95+         1000 REP            S
   80-94       500 REP             A
   60-79       200 REP             B
   <60         50 REP              C
```

### Why It Matters

- **Stakers** can accumulate REP to signal cumulative audit quality
- **Protocols** can require minimum REP holdings before accepting audit reports
- **Market dynamics**: REP becomes a tradeable measure of auditor reputation
- **Composability**: REP can be used in DeFi (lending markets for audit reputation)

### Contract Design

```solidity
contract AthenaRep is ERC20 {
    address public auditCertificate; // linked ERC-721
    
    function mintForAudit(uint256 tokenId) external {
        // Verify caller owns the certificate
        // Read score from certificate
        // Mint proportional REP
    }
}
```

---

## Idea 2: Uniswap v4 Hook for Automated Security

### Concept

A Uniswap v4 Hook that:
1. Reads audit scores from Athena certificates
2. Adjusts pool parameters based on security posture
3. Blocks swaps for unaudited tokens

### Mechanism

```
Pool Creation → Hook checks if token has Athena audit
├── S-tier audit → Normal fees, full liquidity
├── A-tier audit → Slightly higher fees
├── B-tier audit → Higher fees + warning
├── C-tier audit → Very high fees + mandatory warning
└── No audit      → Blocked (or 50%+ fee)
```

### Why It Matters

- **Protocol-level enforcement**: Security posture directly affects trading conditions
- **Incentive alignment**: Projects are incentivized to get higher-tier audits
- **Risk pricing**: The market prices in security risk automatically

### Contract Design

```solidity
contract AthenaSecurityHook is BaseHook {
    IAuditCertificate public certificate;
    
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params
    ) external override returns (bytes4) {
        uint8 tier = getAuditTier(key.currency0);
        if (tier == 0) revert("Unaudited token");
        // Adjust fee based on tier
    }
}
```

---

## Idea 3: OpenRarity Dynamic Scoring

### Concept

Replace static S/A/B/C thresholds with [OpenRarity](https://github.com/ProjectOpenSea/open-rarity) Information Content algorithm — scores are **relative to the entire audit population**, not fixed cutoffs.

### Mechanism

```
Score = -log2(probability of this trait combination)

Traits evaluated:
- Vulnerability count
- Severity distribution
- Evidence completeness
- Repair verification success
- Contract complexity
- Audit duration
```

### Why It Matters

- **Self-adjusting**: As more audits complete, the scoring becomes more granular
- **No arbitrary thresholds**: Grade distribution emerges from data
- **Rarity transparency**: Users can verify their score against the population

### Implementation

```python
def compute_rarity(audit_traits, population):
    """OpenRarity-style Information Content score."""
    score = 0.0
    for trait, value in audit_traits.items():
        frequency = count_in_population(population, trait, value)
        probability = frequency / len(population)
        score -= math.log2(probability)
    return score

def assign_tier(rarity_score, population_scores):
    """Dynamic tier assignment based on percentile."""
    percentile = percentile_rank(rarity_score, population_scores)
    if percentile >= 95: return 'S'
    if percentile >= 75: return 'A'
    if percentile >= 40: return 'B'
    return 'C'
```

---

## Implementation Plan

### Phase 7.1: AthenaRep ERC-20 Token
- [ ] New contract: `AthenaRep.sol`
- [ ] Link to AuditCertificate
- [ ] Mint logic based on audit score
- [ ] Tests

### Phase 7.2: Uniswap v4 Hook (Prototype)
- [ ] New contract: `AthenaSecurityHook.sol`
- [ ] beforeSwap logic
- [ ] Tier-based fee adjustment
- [ ] Tests with mock Uniswap v4

### Phase 7.3: OpenRarity Integration
- [ ] Python pipeline for trait extraction
- [ ] Rarity score computation
- [ ] Dynamic tier assignment
- [ ] Update frontend to show rarity

### Phase 7.4: Frontend Updates
- [ ] Show AthenaRep balance on profile
- [ ] Display rarity percentile
- [ ] Hook demo visualization

---

## Technical References

| Resource | Link |
|----------|------|
| uPEG Contract | `0x44b28991b167582f18ba0259e0173176ca125505` |
| uPEG Hook | `0xe54082DfBf044B6a8F584bdDdb90a22d5613C440` |
| uPEG Rarity Explorer | `upegrarity.com` |
| OpenRarity | `github.com/ProjectOpenSea/open-rarity` |
| Uniswap v4 Hooks | `docs.uniswap.org/contracts/v4/guides/hooks` |

---

## Priority for Hackathon

| Idea | Effort | Impact | Priority |
|------|--------|--------|----------|
| AthenaRep ERC-20 | 2 days | High | P1 |
| OpenRarity Scoring | 1 day | Medium | P2 |
| Uniswap v4 Hook | 3 days | Very High | P3 (stretch goal) |

> **Recommendation**: Implement AthenaRep + OpenRarity for hackathon submission. The Uniswap v4 Hook is a compelling demo but requires deep v4 integration — mention in Roadmap.
