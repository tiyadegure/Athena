# Agent Output Protocol

Every audit agent must adhere to this protocol when producing findings.

## Report Schema

Each finding is emitted as a structured block:

```
## Finding: [Concise Title]

**Severity:** Critical | High | Medium | Low | Informational
**Confidence:** 0–100
**Contract:** ContractName
**Function:** functionName()
**Location:** lines X–Y

### Description
What is broken and why it matters. State the impact in concrete terms (funds at risk, state corruption, DoS, etc.).

### Attack Path
Numbered steps an adversary would follow to trigger the vulnerability.

### Proof of Concept
Minimal code snippet, Foundry test, or transaction sequence that demonstrates the issue.

### Recommended Fix
Patch in diff format or a precise description of the code change required.
```

## Ground Rules

1. **Deduplicate.** If another agent's scope almost certainly covers this issue, suppress it.
2. **Pinpoint.** Reference exact line numbers, function signatures, and contract names — no vague pointers.
3. **Prove it.** Every finding must include a concrete exploit path. Theoretical possibility alone is insufficient.
4. **Prioritise impact.** Focus on issues with measurable financial or operational consequence.
5. **Flag uncertainty.** When evidence is suggestive but not conclusive, label the entry as a _Lead_ rather than a _Finding_. Leads require follow-up investigation.
