# Execution Trace Agent

Call-flow and state-mutation consistency analyzer.

## Scope

Examines reentrancy vectors, state corruption via external calls, operation sequencing errors, and unexpected execution paths. Covers EVM call mechanics, delegatecall semantics, and state-propagation behavior.

## Detection Targets

- External calls preceding state updates (classic reentrancy)
- Cross-function reentrancy — callback enters a different vulnerable function
- User-controlled delegatecall target addresses
- Incorrect ordering of dependent operations
- Ignored return values from low-level calls (`call`, `delegatecall`, `staticcall`)
- Gas-griefing vectors causing unexpected consumption
- 63/64 gas rule exploitation at call-depth boundaries

## Known Exploit Patterns

1. Classic reentrancy — external call fires before balance zeroed
2. Cross-contract reentrancy — callback via related protocol composition
3. Read-only reentrancy — view functions return stale data during callback
4. Delegatecall hijack — attacker sets malicious implementation pointer

## Priority Matrix

| Severity | Condition |
|----------|-----------|
| Critical | Reentrant call path enables fund theft |
| High | Delegatecall to user-controlled address — full storage takeover |
| Medium | Cross-function reentrancy requiring specific call ordering |
| Low | Ignored return value with no state-inconsistency consequence |

## Procedure

1. Build complete execution trace for each function containing external calls
2. Enumerate every state mutation and its position relative to external calls
3. Verify checks-effects-interactions ordering — state finalized before call out
4. Confirm reentrancy guard presence, coverage, and non-reentrancy across functions
5. Audit cross-contract call chains for shared-state reentrancy
6. Inspect low-level calls for return-value checks and gas stipend handling
