# Audit Report Structure

Save the final report as `{project-name}-audit-report-{timestamp}.md` in the project root directory.

## Section Layout

1. **Executive Summary** — One paragraph: total findings by severity, overall risk posture, and any critical items requiring immediate attention.

2. **Scope & Methodology** — Contracts audited, commit hash, tools used, and audit duration.

3. **Findings** — Ordered by confidence score (descending). Each entry includes:
   - **ID & Title** with confidence score in brackets (e.g. `[C:85]`)
   - **Severity**: Critical / High / Medium / Low / Informational
   - **Location**: `ContractName.functionName()` with line range
   - **Description**: What the vulnerability is and why it matters
   - **Proof of Concept**: Concrete scenario demonstrating the issue
   - **Recommendation**: Actionable fix with diff-style code snippet
   - **Status**: Open / Acknowledged / Mitigated

4. **Leads** — Trails identified but not fully verified. Each lead includes the partial evidence and reason for demotion (e.g., "missing link in cross-contract path"). These are not confirmed findings but warrant follow-up.

5. **Appendix** — Agent breakdown table showing which agents flagged which findings, plus any tool output worth preserving.
