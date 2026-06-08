// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Token.sol";
import "./Oracle.sol";

/// @title Vault - Lending vault for multi-contract testing
/// @notice VULNERABLE: Cross-contract reentrancy + oracle manipulation
contract Vault {
    SimpleToken public token;
    SimpleOracle public oracle;
    
    mapping(address => uint256) public deposits;      // user => deposited amount
    mapping(address => uint256) public borrowed;       // user => borrowed amount
    mapping(address => uint256) public collateral;     // user => collateral amount
    
    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization
    uint256 public constant LIQUIDATION_THRESHOLD = 120; // 120% - liquidate
    
    address public owner;
    
    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Liquidation(address indexed user, uint256 collateralSeized);
    
    constructor(address _token, address _oracle) {
        token = SimpleToken(_token);
        oracle = SimpleOracle(_oracle);
        owner = msg.sender;
    }
    
    /// @notice Deposit tokens as collateral
    function deposit(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        deposits[msg.sender] += amount;
        collateral[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }
    
    /// @notice Borrow tokens against collateral
    /// @dev VULNERABLE: Uses spot price from oracle (can be manipulated)
    function borrow(uint256 amount) external {
        require(deposits[msg.sender] > 0, "No collateral");
        
        // Get collateral value using VULNERABLE spot price
        uint256 collateralValue = _getCollateralValue(msg.sender);
        uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;
        
        require(borrowed[msg.sender] + amount <= maxBorrow, "Exceeds borrow limit");
        
        borrowed[msg.sender] += amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        emit Borrow(msg.sender, amount);
    }
    
    /// @notice Repay borrowed tokens
    function repay(uint256 amount) external {
        require(borrowed[msg.sender] >= amount, "Repay exceeds debt");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        borrowed[msg.sender] -= amount;
        emit Repay(msg.sender, amount);
    }
    
    /// @notice Liquidate undercollateralized position
    /// @dev VULNERABLE: Oracle manipulation can trigger false liquidations
    function liquidate(address user) external {
        uint256 collateralValue = _getCollateralValue(user);
        uint256 debt = borrowed[user];
        
        // Check if undercollateralized
        uint256 ratio = (collateralValue * 100) / debt;
        require(ratio < LIQUIDATION_THRESHOLD, "Position healthy");
        
        // Seize collateral (simplified - in reality would have liquidation bonus)
        uint256 seized = collateral[user];
        collateral[user] = 0;
        deposits[user] -= seized;
        borrowed[user] = 0;
        
        // Transfer collateral to liquidator
        require(token.transfer(msg.sender, seized), "Transfer failed");
        
        emit Liquidation(user, seized);
    }
    
    /// @notice Get collateral value (VULNERABLE: uses spot price)
    function _getCollateralValue(address user) internal view returns (uint256) {
        uint256 collateralAmount = collateral[user];
        uint256 price = oracle.getPrice(address(token)); // VULNERABLE!
        return (collateralAmount * price) / 1e18;
    }
    
    /// @notice Get health factor
    function getHealthFactor(address user) external view returns (uint256) {
        if (borrowed[user] == 0) return type(uint256).max;
        uint256 collateralValue = _getCollateralValue(user);
        return (collateralValue * 100) / borrowed[user];
    }
}
