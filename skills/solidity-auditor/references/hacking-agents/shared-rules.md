# Shared Rules for All Agents

## Output Format

Each agent must return findings in this exact format:

```
## Finding: [Title]

**Severity:** Critical / High / Medium / Low / Informational
**Confidence:** 0-100
**Contract:** ContractName
**Function:** functionName()
**Location:** line X-Y

### Description
Clear explanation of the vulnerability and its impact.

### Attack Path
Step-by-step how an attacker would exploit this.

### Proof of Concept
Minimal code or transaction sequence demonstrating the attack.

### Recommended Fix
Specific code changes with diff format.
```

## Rules

1. **No duplicates** — If you see a finding another agent likely covers, skip it.
2. **Be specific** — Include exact line numbers, function names, and contract addresses.
3. **Prove it** — Every finding needs a concrete attack path, not theoretical possibility.
4. **Impact matters** — Focus on findings with real financial or operational impact.
5. **False positives** — When in doubt, mark as "Lead" not "Finding". Leads need more investigation.
