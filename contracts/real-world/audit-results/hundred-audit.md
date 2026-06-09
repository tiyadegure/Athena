# Hundred Finance - Audit Report

## Contract
- File: `hundred-finance.sol`
- Type: Lending Protocol (Compound fork)
- Incident: 2023 Hundred Finance Exploit
- Loss: ~$7M

## Vulnerability: Reentrancy + Oracle Manipulation

### Summary
Hundred Finance suffered a complex attack combining reentrancy and oracle manipulation. The attacker exploited the interaction between cToken's `redeem()` function and the price oracle.

### Root Cause
1. **Reentrancy in cToken.redeem()**: External call to `underlying.transfer()` happens after state updates but before the protocol can check for undercollateralization
2. **Oracle Manipulation**: The protocol uses spot prices which can be manipulated via flash loans
3. **Cross-market interaction**: Attacker can manipulate prices in one market to affect another

### Attack Sequence
1. Attacker deposits small collateral in Market A
2. Attacker takes flash loan
3. Uses flash loan to manipulate price of collateral token
4. Borrows maximum against inflated collateral
5. Repays flash loan, price returns to normal
6. Protocol is now undercollateralized
7. Attacker liquidates or withdraws profit

### Affected Functions
- `CToken.redeem()` - reentrancy vector
- `CToken.borrow()` - uses manipulated oracle
- `HundredFinance.getAccountLiquidity()` - uses spot prices
- `HundredFinance.liquidate()` - can be triggered falsely

### Fix
1. Add reentrancy guard to `redeem()` and `borrow()`
2. Use TWAP (Time-Weighted Average Price) instead of spot price
3. Add delay between oracle update and borrowing
4. Implement circuit breakers for extreme price movements

### References
- [Hundred Finance Post-Mortem](https://hundredfinance.medium.com/)
- [DeFi Security Summit](https://defisecuritysummit.org/)

## Agent Detection
- Slither: Should detect reentrancy-eth in CToken
- Cross-contract: Should identify oracle dependency
- Expected findings:
  1. "Reentrancy in CToken.redeem()"
  2. "Spot price oracle vulnerable to manipulation"
  3. "Cross-market liquidation risk"
