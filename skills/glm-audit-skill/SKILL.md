---
name: glm-audit-skill
description: Parallelized smart contract security audit. Trigger on "audit", "check this contract", "review for security". Modes - default (full repo) or a specific filename.
---

# GLM Smart Contract Security Audit

You orchestrate a parallelized smart contract security audit using 12 specialized agents. This is not a checklist exercise — it is a structured adversarial analysis.

## Mode Selection

**Exclude pattern:** skip directories `interfaces/`, `lib/`, `mocks/`, `test/` and files matching `*.t.sol`, `*Test*.sol` or `*Mock*.sol`.

- **Default** (no arguments): scan all `.sol` files using the exclude pattern. Use Bash `find` (not Glob).
- **`$filename ...`**: scan the specified file(s) only.

**Flags:**

- `--file-output` (off by default): also write the report to a markdown file (path per `{resolved_path}/report-formatting.md`). Never write a report file unless explicitly passed.

## Orchestration

**Turn 1 — Discover.** Print the banner, then make these parallel tool calls in one message:

a. Bash `find` for in-scope `.sol` files per mode selection
b. Glob for `**/references/audit-agents/shared-rules.md` — extract the `references/` directory (two levels up) as `{resolved_path}`
c. ToolSearch `select:Agent`
d. Bash `mktemp -d ./.audit-XXXXXX` → store as `{bundle_dir}`

**Turn 2 — Prepare.** In one message, make parallel tool calls: (a) Read `{resolved_path}/report-formatting.md`, (b) Read `{resolved_path}/judging.md`.

Then build all bundles in a single Bash command using `cat`:

1. `{bundle_dir}/source.md` — ALL in-scope `.sol` files, each with a `### path` header and fenced code block.
2. Agent bundles = `source.md` + agent-specific files per the table below.

Each bundle = source.md + SOP + specialty + shared-rules. Agents read the bundle; no Read/Grep needed for the initial scan.

**Turn 3a — Spawn all 12 agents.** In one message, spawn all 12 agents as parallel BACKGROUND Agent calls.

Agents 1–9 use the single-specialty prompt. Agents 10–12 use the gap-hunter prompt.

**Turn 3b — Wait for all 12 agents to complete.**

**Turn 4 — Deduplicate, validate & output.** Single-pass: deduplicate all agent results, gate-evaluate per `{resolved_path}/judging.md`, and produce the final report per `{resolved_path}/report-formatting.md`.

## Agent Table

| # | Agent | Type | Specialty File |
|---|-------|------|----------------|
| 1 | Access Control | single | access-control-agent.md |
| 2 | Asymmetry | single | asymmetry-agent.md |
| 3 | Boundary | single | boundary-agent.md |
| 4 | Economic Security | single | economic-security-agent.md |
| 5 | Execution Trace | single | execution-trace-agent.md |
| 6 | First Principles | single | first-principles-agent.md |
| 7 | Invariant | single | invariant-agent.md |
| 8 | Math Precision | single | math-precision-agent.md |
| 9 | Periphery | single | periphery-agent.md |
| 10 | Flow Gap | gap-hunter | flow-gap-agent.md |
| 11 | Numerical Gap | gap-hunter | numerical-gap-agent.md |
| 12 | Trust Gap | gap-hunter | trust-gap-agent.md |

All specialty files live under `{resolved_path}/audit-agents/`. The shared rules file (`shared-rules.md`) is prepended to every agent bundle.

## Banner

```
╔══════════════════════════════════════════════════════╗
║            GLM AUDIT — Security Analysis             ║
║         Parallelized Smart Contract Auditor          ║
╚══════════════════════════════════════════════════════╝
```
