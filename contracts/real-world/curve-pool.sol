// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CurveV2Pool - Simplified Curve V2 LP Pool (vulnerable version)
/// @notice Based on the Curve read-only reentrancy vulnerability (2023)
/// @dev This is a simplified reproduction for audit testing
/// @dev Real vulnerability: Balancer LP share price manipulation during add/remove liquidity

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @notice Curve-style LP token
contract CurveLPToken {
    string public name = "Curve LP Token";
    string public symbol = "crvLP";
    uint8 public decimals = 18;
    
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function burn(address from, uint256 amount) external {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
    
    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}

/// @title CurveV2Pool - Vulnerable to read-only reentrancy
/// @notice Based on the 2023 Curve/Balancer vulnerability
contract CurveV2Pool {
    IERC20 public token0;
    IERC20 public token1;
    CurveLPToken public lpToken;
    
    uint256 public reserve0;
    uint256 public reserve1;
    
    // Virtual price = total_value / lp_supply
    // VULNERABILITY: This can be manipulated during add/remove liquidity
    uint256 public virtualPrice;
    
    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint256 lpTokens);
    event LiquidityRemoved(address indexed provider, uint256 amount0, uint256 amount1, uint256 lpTokensBurned);
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut);
    
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        lpToken = new CurveLPToken();
    }
    
    /// @notice Add liquidity to the pool
    /// @dev VULNERABLE: Callback during state transition
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 lpTokens) {
        // Transfer tokens in
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);
        
        // Calculate LP tokens to mint
        if (lpToken.totalSupply() == 0) {
            lpTokens = _sqrt(amount0 * amount1);
        } else {
            uint256 share0 = (amount0 * lpToken.totalSupply()) / reserve0;
            uint256 share1 = (amount1 * lpToken.totalSupply()) / reserve1;
            lpTokens = (share0 + share1) / 2;
        }
        
        // VULNERABILITY: State update order issue
        // LP tokens are minted BEFORE reserves are updated
        // This means virtualPrice is calculated with old reserves but new LP supply
        lpToken.mint(msg.sender, lpTokens);
        
        // Callback happens here if msg.sender is a contract
        // During callback, virtualPrice returns STALE value
        
        // Update reserves AFTER mint
        reserve0 += amount0;
        reserve1 += amount1;
        
        _updateVirtualPrice();
        
        emit LiquidityAdded(msg.sender, amount0, amount1, lpTokens);
    }
    
    /// @notice Remove liquidity from the pool
    /// @dev VULNERABLE: Same callback issue during removal
    function removeLiquidity(uint256 lpTokens) external returns (uint256 amount0, uint256 amount1) {
        require(lpTokens > 0, "Zero tokens");
        
        // Calculate amounts to return
        amount0 = (lpTokens * reserve0) / lpToken.totalSupply();
        amount1 = (lpTokens * lpToken.totalSupply() / lpToken.totalSupply());
        
        // VULNERABILITY: Burn LP tokens BEFORE transferring assets
        // This means virtualPrice is calculated with new LP supply but old reserves
        lpToken.burn(msg.sender, lpTokens);
        
        // Callback happens here
        // During callback, virtualPrice returns STALE value (inflated)
        
        // Transfer assets AFTER burn
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        
        // Update reserves AFTER transfer
        reserve0 -= amount0;
        reserve1 -= amount1;
        
        _updateVirtualPrice();
        
        emit LiquidityRemoved(msg.sender, amount0, amount1, lpTokens);
    }
    
    /// @notice Get virtual price (VULNERABLE during state transitions)
    /// @dev This is the read-only reentrancy vulnerability
    function getVirtualPrice() external view returns (uint256) {
        return virtualPrice;
    }
    
    /// @notice Swap token0 for token1
    function swap0to1(uint256 amountIn) external {
        require(amountIn > 0, "Zero amount");
        
        uint256 amountOut = _getAmountOut(amountIn, reserve0, reserve1);
        
        token0.transferFrom(msg.sender, address(this), amountIn);
        token1.transfer(msg.sender, amountOut);
        
        reserve0 += amountIn;
        reserve1 -= amountOut;
        
        emit Swap(msg.sender, amountIn, amountOut);
    }
    
    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }
    
    function _updateVirtualPrice() internal {
        uint256 totalValue = reserve0 + reserve1; // Simplified
        uint256 supply = lpToken.totalSupply();
        if (supply > 0) {
            virtualPrice = (totalValue * 1e18) / supply;
        }
    }
    
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
