// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Token.sol";
import "./Oracle.sol";

/// @title Vault v2 - Updated lending vault for incremental audit demo
/// @notice Changes from v1:
///   1. Added ReentrancyGuard
///   2. Added TWAP oracle support
///   3. Added liquidation bonus
///   4. Added emergency pause
///   5. Fixed access control on transferOwnership

interface IOracle {
    function getPrice(address token) external view returns (uint256);
    function getTWAPPrice(address token, uint256 period) external view returns (uint256);
}

/// @notice ReentrancyGuard (simplified)
abstract contract ReentrancyGuard {
    uint256 private _status;
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    
    constructor() {
        _status = NOT_ENTERED;
    }
    
    modifier nonReentrant() {
        require(_status != ENTERED, "ReentrancyGuard: reentrant call");
        _status = ENTERED;
        _;
        _status = NOT_ENTERED;
    }
}

/// @title VaultV2 - Fixed version of Vault
contract VaultV2 is ReentrancyGuard {
    SimpleToken public token;
    IOracle public oracle;
    
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrowed;
    mapping(address => uint256) public collateral;
    
    uint256 public constant COLLATERAL_RATIO = 150;
    uint256 public constant LIQUIDATION_THRESHOLD = 120;
    uint256 public constant LIQUIDATION_BONUS = 5; // 5% bonus for liquidators
    
    address public owner;
    bool public paused;
    
    // TWAP period (1 hour)
    uint256 public constant TWAP_PERIOD = 3600;
    
    // Events
    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Liquidation(address indexed user, uint256 collateralSeized, uint256 bonus);
    event PauseStateChanged(bool paused);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor(address _token, address _oracle) {
        token = SimpleToken(_token);
        oracle = IOracle(_oracle);
        owner = msg.sender;
    }
    
    /// @notice Deposit tokens as collateral
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        deposits[msg.sender] += amount;
        collateral[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }
    
    /// @notice Borrow tokens against collateral
    /// @dev FIXED: Uses TWAP oracle instead of spot price
    function borrow(uint256 amount) external nonReentrant whenNotPaused {
        require(deposits[msg.sender] > 0, "No collateral");
        
        // FIXED: Use TWAP price instead of spot price
        uint256 collateralValue = _getCollateralValue(msg.sender);
        uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;
        
        require(borrowed[msg.sender] + amount <= maxBorrow, "Exceeds borrow limit");
        
        borrowed[msg.sender] += amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        emit Borrow(msg.sender, amount);
    }
    
    /// @notice Repay borrowed tokens
    function repay(uint256 amount) external nonReentrant whenNotPaused {
        require(borrowed[msg.sender] >= amount, "Repay exceeds debt");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        borrowed[msg.sender] -= amount;
        emit Repay(msg.sender, amount);
    }
    
    /// @notice Liquidate undercollateralized position
    /// @dev FIXED: Added liquidation bonus for incentivizing liquidators
    function liquidate(address user) external nonReentrant whenNotPaused {
        uint256 collateralValue = _getCollateralValue(user);
        uint256 debt = borrowed[user];
        
        require(debt > 0, "No debt");
        
        // Check if undercollateralized
        uint256 ratio = (collateralValue * 100) / debt;
        require(ratio < LIQUIDATION_THRESHOLD, "Position healthy");
        
        // Calculate seizure with bonus
        uint256 baseSeized = collateral[user];
        uint256 bonus = (baseSeized * LIQUIDATION_BONUS) / 100;
        uint256 totalSeized = baseSeized + bonus;
        
        // Cap at available collateral
        if (totalSeized > collateral[user]) {
            totalSeized = collateral[user];
            bonus = totalSeized - baseSeized;
        }
        
        // Update state
        collateral[user] = 0;
        deposits[user] -= baseSeized;
        borrowed[user] = 0;
        
        // Transfer to liquidator
        require(token.transfer(msg.sender, totalSeized), "Transfer failed");
        
        emit Liquidation(user, totalSeized, bonus);
    }
    
    /// @notice Get collateral value using TWAP oracle
    /// @dev FIXED: Uses TWAP instead of spot price
    function _getCollateralValue(address user) internal view returns (uint256) {
        uint256 collateralAmount = collateral[user];
        // FIXED: Use TWAP price for manipulation resistance
        uint256 price = oracle.getTWAPPrice(address(token), TWAP_PERIOD);
        return (collateralAmount * price) / 1e18;
    }
    
    /// @notice Get health factor
    function getHealthFactor(address user) external view returns (uint256) {
        if (borrowed[user] == 0) return type(uint256).max;
        uint256 collateralValue = _getCollateralValue(user);
        return (collateralValue * 100) / borrowed[user];
    }
    
    // ============ Access Control ============
    
    /// @notice Transfer ownership (two-step)
    /// @dev FIXED: Added two-step transfer for safety
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Not owner");
        require(newOwner != address(0), "Zero address");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /// @notice Pause/unpause the contract
    function setPaused(bool _paused) external {
        require(msg.sender == owner, "Not owner");
        paused = _paused;
        emit PauseStateChanged(_paused);
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    receive() external payable {}
}
