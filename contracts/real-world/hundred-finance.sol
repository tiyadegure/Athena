// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title HundredFinance - Simplified lending protocol (vulnerable version)
/// @notice Based on the 2023 Hundred Finance exploit ($7M loss)
/// @dev Vulnerability: Reentrancy in cToken + oracle manipulation

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @notice cToken - Compound-style lending token
contract CToken {
    string public name;
    IERC20 public underlying;
    
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    // Exchange rate: underlying per cToken (scaled by 1e18)
    uint256 public exchangeRate = 1e18;
    
    // Borrow tracking
    mapping(address => uint256) public borrowBalance;
    
    event Mint(address indexed minter, uint256 mintAmount, uint256 mintTokens);
    event Redeem(address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens);
    event Borrow(address indexed borrower, uint256 borrowAmount);
    event RepayBorrow(address indexed payer, uint256 repayAmount);
    
    constructor(string memory _name, address _underlying) {
        name = _name;
        underlying = IERC20(_underlying);
    }
    
    /// @notice Deposit underlying tokens, receive cTokens
    function mint(uint256 amount) external {
        underlying.transferFrom(msg.sender, address(this), amount);
        
        uint256 mintTokens = (amount * 1e18) / exchangeRate;
        totalSupply += mintTokens;
        balanceOf[msg.sender] += mintTokens;
        
        emit Mint(msg.sender, amount, mintTokens);
    }
    
    /// @notice Withdraw underlying tokens by burning cTokens
    /// @dev VULNERABLE: External call before state finalization
    function redeem(uint256 redeemTokens) external {
        require(balanceOf[msg.sender] >= redeemTokens, "Insufficient balance");
        
        uint256 redeemAmount = (redeemTokens * exchangeRate) / 1e18;
        
        // VULNERABILITY: State update and external call ordering
        balanceOf[msg.sender] -= redeemTokens;
        totalSupply -= redeemTokens;
        
        // External call - enables reentrancy
        underlying.transfer(msg.sender, redeemAmount);
        
        emit Redeem(msg.sender, redeemAmount, redeemTokens);
    }
    
    /// @notice Borrow underlying tokens against collateral
    function borrow(uint256 amount) external {
        require(borrowBalance[msg.sender] + amount <= _getBorrowLimit(msg.sender), "Exceeds borrow limit");
        
        borrowBalance[msg.sender] += amount;
        
        // External call
        underlying.transfer(msg.sender, amount);
        
        emit Borrow(msg.sender, amount);
    }
    
    /// @notice Repay borrowed tokens
    function repayBorrow(uint256 amount) external {
        require(borrowBalance[msg.sender] >= amount, "Repay exceeds debt");
        
        underlying.transferFrom(msg.sender, address(this), amount);
        borrowBalance[msg.sender] -= amount;
        
        emit RepayBorrow(msg.sender, amount);
    }
    
    function _getBorrowLimit(address user) internal view returns (uint256) {
        // Simplified: borrow limit = 75% of collateral value
        return (balanceOf[user] * exchangeRate * 75) / (100 * 1e18);
    }
}

/// @title HundredFinance - Vulnerable lending protocol
/// @notice Orchestrates multiple cTokens with shared oracle
contract HundredFinance {
    mapping(address => CToken) public cTokens;
    address[] public cTokenList;
    
    // Price oracle (simplified)
    mapping(address => uint256) public prices;
    
    event MarketListed(address indexed cToken);
    
    function listMarket(address cToken) external {
        cTokens[cToken] = CToken(cToken);
        cTokenList.push(cToken);
        emit MarketListed(cToken);
    }
    
    function setPrice(address token, uint256 price) external {
        prices[token] = price;
    }
    
    /// @notice Get account liquidity across all markets
    /// @dev VULNERABLE: Uses spot prices which can be manipulated
    function getAccountLiquidity(address account) external view returns (
        uint256 totalCollateralValue,
        uint256 totalBorrowValue,
        uint256 liquidity
    ) {
        for (uint256 i = 0; i < cTokenList.length; i++) {
            CToken cToken = cTokens[cTokenList[i]];
            address underlying = address(cToken.underlying());
            
            uint256 cTokenBalance = cToken.balanceOf(account);
            uint256 underlyingAmount = (cTokenBalance * cToken.exchangeRate()) / 1e18;
            
            // VULNERABLE: Uses spot price
            uint256 price = prices[underlying];
            totalCollateralValue += (underlyingAmount * price) / 1e18;
            
            uint256 borrowAmount = cToken.borrowBalance(account);
            totalBorrowValue += (borrowAmount * price) / 1e18;
        }
        
        if (totalCollateralValue > totalBorrowValue) {
            liquidity = totalCollateralValue - totalBorrowValue;
        }
    }
    
    /// @notice Liquidate undercollateralized position
    /// @dev Can be triggered by oracle manipulation
    function liquidate(
        address borrower,
        address cTokenBorrowed,
        uint256 repayAmount,
        address cTokenCollateral
    ) external {
        (, uint256 totalBorrow, uint256 liquidity) = this.getAccountLiquidity(borrower);
        require(liquidity == 0, "Account is solvent");
        
        // Seize collateral (simplified - 10% liquidation bonus)
        uint256 seizedAmount = (repayAmount * 110) / 100;
        
        // Transfer borrowed tokens from liquidator
        CToken(cTokenBorrowed).underlying().transferFrom(msg.sender, address(this), repayAmount);
        
        // Reduce borrower's debt
        // ... (simplified)
        
        // Transfer collateral to liquidator
        // ... (simplified)
    }
}
