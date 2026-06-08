// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title VulnerableAMM - Test case for flash loan price manipulation
/// @notice This contract intentionally has oracle manipulation vulnerabilities
contract VulnerableAMM {
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    uint256 public reserveA;
    uint256 public reserveB;
    
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    /// @notice Add liquidity to the pool
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        reserveA += amountA;
        reserveB += amountB;
    }
    
    /// @notice Get the current spot price
    /// @dev BUG: Price determined by spot reserves, vulnerable to flash loan manipulation
    function getSpotPrice() public view returns (uint256) {
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        return (reserveB * 1e18) / reserveA;
    }
    
    /// @notice Swap token A for token B
    /// @dev BUG: No slippage protection
    function swapAtoB(uint256 amountIn) external {
        require(amountIn > 0, "Zero amount");
        uint256 amountOut = (amountIn * reserveB) / (reserveA + amountIn);
        
        tokenA.transferFrom(msg.sender, address(this), amountIn);
        tokenB.transfer(msg.sender, amountOut);
        
        reserveA += amountIn;
        reserveB -= amountOut;
    }
    
    /// @notice Flash loan - borrow tokens and repay in same transaction
    /// @dev BUG: No flash loan fee and no price manipulation protection
    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = tokenA.balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient liquidity");
        
        tokenA.transfer(msg.sender, amount);
        
        // Callback - borrower must return funds
        // But no fee and no check that price wasn't manipulated
        require(tokenA.balanceOf(address(this)) >= balanceBefore, "Flash loan not repaid");
    }
}
