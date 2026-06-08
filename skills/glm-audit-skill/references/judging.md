# Finding Assessment Protocol

Every candidate finding must clear four sequential checkpoints before it becomes a confirmed finding. A failure at any checkpoint results in rejection or demotion to a lead for further investigation.

## Checkpoint 1 — Path Reconstruction

Walk the full execution path from external entry point to the alleged vulnerability. Document every modifier, require statement, guard clause, and access control check encountered along that path. If you cannot trace a complete unbroken path, the finding fails here.

## Checkpoint 2 — State Feasibility

Demonstrate that the vulnerable contract state can actually be reached in a production deployment. Consider initialization order, proxy patterns, upgrade mechanisms, and realistic transaction sequences. Theoretical states that require impossible preconditions do not pass.

## Checkpoint 3 — Actor Profile

Identify the minimum privilege level required to trigger the vulnerability. The attack must be executable by an unprivileged or semi-privileged actor — owner-only findings are typically informational only. Document the exact actor type and their capabilities.

## Checkpoint 4 — Damage Assessment

Quantify the concrete harm: stolen funds, bricked contracts, corrupted state, or broken invariants. Tie the impact to an identifiable victim class (liquidity providers, token holders, protocol treasury). Abstract or theoretical damage does not qualify.

## Confidence Scoring

Base score starts at 100. Apply deductions:

- Incomplete execution path traced: -20
- Impact bounded to a single non-compounding scenario: -15
- Requires specific or unusual contract state to be reachable: -10
- Actor requires partial privilege (not fully unprivileged): -5

Score below 60 → demote to lead. Score below 40 → reject outright.

## Known-Safe Patterns (skip these)

- `unchecked` arithmetic blocks in Solidity ≥0.8 (overflow reverts by default)
- SafeERC20 wrapper usage for token interactions
- `nonReentrant` guards (flag only if cross-contract reentrancy is still possible)
- Two-step ownership transfer patterns

## Lead Escalation Criteria

Promote a finding to lead status (requires senior auditor review) when:

- The vulnerability spans multiple contracts in an echo/reentrancy chain
- Two or more independent agents converge on the same attack surface
- The attack path is partially complete but missing one link that may exist under specific conditions
