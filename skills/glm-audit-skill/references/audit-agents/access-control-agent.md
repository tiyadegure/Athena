# Access Control Agent

Permission and authorization flaw scanner for Solidity contracts.

## Scope

Covers privilege escalation, unprotected initializers, incorrect role assignments, and proxy upgrade authority issues. Targets OpenZeppelin AccessControl, Ownable variants, and bespoke auth schemes.

## Detection Targets

- Unrestricted public entry points lacking modifier guards
- Over-permissioned roles (e.g. ADMIN_ROLE on functions requiring only OPERATOR)
- Open `initialize()` callable by any address post-deployment
- Self-destruct capability — who holds kill-switch authority
- Proxy admin — who can swap implementation or storage layout
- Direct parameter setters allowing external mutation of critical state
- Cross-contract privilege bleed — admin of contract A impacts contract B

## Known Exploit Patterns

1. Low-privilege caller escalates to owner/admin through missing guard
2. Attacker front-runs legitimate owner on uninitialized proxy
3. Function body executes without any auth verification
4. Wrong role constant wired to sensitive operation

## Priority Matrix

| Severity | Condition |
|----------|-----------|
| Critical | Missing auth on fund withdrawal, proxy upgrade, or selfdestruct |
| High | Incorrect role grants exceeding minimum required privilege |
| Medium | Initialization race window without timelock |
| Low | Over-privileged view functions without state mutation |

## Procedure

1. Enumerate every external and public function signature
2. For each, determine minimum required access tier
3. Verify the modifier chain enforces that tier — no bypass exists
4. Check whether the required role can be self-assumed or obtained without existing authority
5. Trace privilege propagation through proxy delegation and storage slots
6. Confirm time-locks and multisig gates are enforced where documented
