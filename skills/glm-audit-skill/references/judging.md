# Finding Validation

Every finding passes four sequential gates. Fail any gate → **rejected** or **demoted** to lead.

## Gate 1 — Attack execution
Trace the agent's claimed attack path from caller to harm. Read every guard, check, modifier, and constraint on that path.

## Gate 2 — Reachability
Prove the vulnerable state exists in a live deployment.

## Gate 3 — Trigger
Prove an unprivileged actor executes the attack.

## Gate 4 — Impact
Prove material harm to an identifiable victim.

## Confidence
Start at 100, deduct: partial attack path -20, bounded non-compounding impact -15, requires specific state -10.

## Safe patterns (do not flag)
- `unchecked` in 0.8+
- SafeERC20
- `nonReentrant` (only flag cross-contract attacks)
- Two-step admin transfer

## Lead promotion
- Cross-contract echo
- Multi-agent convergence (2+ agents)
- Partial-path completion
