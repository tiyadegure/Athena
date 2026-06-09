# Curve V2 Pool - Audit Report

## Contract
- File: `curve-pool.sol`
- Type: AMM / Liquidity Pool
- Incident: 2023 Curve Finance Exploit
- Loss: ~$70M

## Vulnerability: Read-Only Reentrancy

### Summary
The Curve V2 pool has a read-only reentrancy vulnerability in the `addLiquidity()` and `removeLiquidity()` functions. The virtual price (used as an oracle by other protocols) returns inconsistent values during state transitions.

### Root Cause
In `addLiquidity()`:
1. LP tokens are minted BEFORE reserves are updated
2. During the callback (if attacker is a contract), `getVirtualPrice()` returns a stale value
3. The stale virtual price is lower than the actual price (because LP supply increased but reserves haven't)

In `removeLiquidity()`:
1. LP tokens are burned BEFORE assets are transferred
2. During the callback, `getVirtualPrice()` returns a stale value
3. The stale virtual price is higher than the actual price (because LP supply decreased but reserves haven't)

### Attack Vector
1. Attacker calls `addLiquidity()` with small amount
2. In the callback, attacker calls lending protocols that use `getVirtualPrice()` as oracle
3. Lending protocol sees artificially low price → allows borrowing at discount
4. Attacker profits from the price discrepancy

### Affected Functions
- `addLiquidity()` - state update order vulnerability
- `removeLiquidity()` - state update order vulnerability
- `getVirtualPrice()` - returns inconsistent value during transitions

### Fix
Use checks-effects-interactions pattern:
1. Update reserves BEFORE minting/burning LP tokens
2. Or use a reentrancy guard on `getVirtualPrice()`
3. Or snapshot the virtual price at the start of the transaction

### References
- [Curve Finance Post-Mortem](https://curve.fi/overview)
- [Read-Only Reentrancy Explained](https://chainsecurity.com/heartbreaks/read-only-reentrancy/)

## Agent Detection
- Slither: Should detect reentrancy-eth pattern
- Manual: Should identify state update order issue
- Expected finding: "Read-only reentrancy in virtual price calculation"
