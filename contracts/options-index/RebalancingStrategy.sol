// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OptionsIndexTracker.sol";

/// @title RebalancingStrategy - Automated rebalancing for OptionsIndexTracker
/// @notice Handles automatic rebalancing based on market conditions
/// @dev Considers MEV risks during rebalancing

interface ISwapRouter {
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256 amountOut);
}

/// @title RebalancingStrategy
contract RebalancingStrategy {
    OptionsIndexTracker public index;
    ISwapRouter public swapRouter;
    
    // Strategy parameters
    uint256 public maxSlippage = 50; // 0.5% max slippage
    uint256 public minRebalanceAmount = 1e18; // Minimum 1 ETH to rebalance
    uint256 public mevProtectionDelay = 2; // 2 blocks delay for MEV protection
    
    // State
    uint256 public lastRebalanceBlock;
    mapping(address => bool) public authorizedRebalancers;
    address public owner;
    
    // Events
    event RebalanceExecuted(uint256 timestamp, uint256[] oldWeights, uint256[] newWeights);
    event SlippageExceeded(uint256 expected, uint256 actual);
    event MEVDetected(uint256 blockNumber, uint256 priceImpact);
    
    constructor(address _index, address _swapRouter) {
        index = OptionsIndexTracker(_index);
        swapRouter = ISwapRouter(_swapRouter);
        owner = msg.sender;
        authorizedRebalancers[msg.sender] = true;
    }
    
    /// @notice Execute rebalance with MEV protection
    /// @param newWeights New weights for each constituent
    function executeRebalance(uint256[] calldata newWeights) external {
        require(authorizedRebalancers[msg.sender], "Not authorized");
        require(block.number > lastRebalanceBlock + mevProtectionDelay, "MEV protection: wait");
        
        // Check if rebalance is needed
        if (!index.needsRebalance()) {
            // Still allow manual rebalance
        }
        
        // Execute rebalance
        index.rebalance(newWeights);
        
        lastRebalanceBlock = block.number;
        
        emit RebalanceExecuted(block.timestamp, new uint256[](0), newWeights);
    }
    
    /// @notice Calculate optimal weights based on market conditions
    /// @param prices Current prices of each constituent
    /// @param targetWeights Target weights (equal weight, market cap weight, etc.)
    /// @return optimalWeights Calculated optimal weights
    function calculateOptimalWeights(
        uint256[] calldata prices,
        uint256[] calldata targetWeights
    ) external view returns (uint256[] memory optimalWeights) {
        require(prices.length == targetWeights.length, "Length mismatch");
        
        optimalWeights = new uint256[](prices.length);
        
        // Simple equal-weight strategy with price adjustment
        uint256 totalAdjusted = 0;
        for (uint256 i = 0; i < prices.length; i++) {
            // Adjust weight by inverse price (cheaper assets get higher weight)
            optimalWeights[i] = (targetWeights[i] * 1e18) / prices[i];
            totalAdjusted += optimalWeights[i];
        }
        
        // Normalize to 10000 basis points
        for (uint256 i = 0; i < optimalWeights.length; i++) {
            optimalWeights[i] = (optimalWeights[i] * 10000) / totalAdjusted;
        }
    }
    
    /// @notice Detect potential MEV attack
    /// @param pricesBefore Prices before rebalance
    /// @param pricesAfter Prices after rebalance
    /// @return isMEV Whether MEV was detected
    function detectMEV(
        uint256[] calldata pricesBefore,
        uint256[] calldata pricesAfter
    ) external view returns (bool isMEV) {
        require(pricesBefore.length == pricesAfter.length, "Length mismatch");
        
        for (uint256 i = 0; i < pricesBefore.length; i++) {
            uint256 priceDiff = pricesBefore[i] > pricesAfter[i] ?
                               pricesBefore[i] - pricesAfter[i] :
                               pricesAfter[i] - pricesBefore[i];
            
            uint256 priceImpact = (priceDiff * 10000) / pricesBefore[i];
            
            // If price impact > 1%, potential MEV
            if (priceImpact > 100) {
                return true;
            }
        }
        
        return false;
    }
    
    /// @notice Set max slippage
    function setMaxSlippage(uint256 _maxSlippage) external {
        require(msg.sender == owner, "Not owner");
        maxSlippage = _maxSlippage;
    }
    
    /// @notice Set MEV protection delay
    function setMEVProtectionDelay(uint256 _delay) external {
        require(msg.sender == owner, "Not owner");
        mevProtectionDelay = _delay;
    }
    
    /// @notice Add authorized rebalancer
    function addRebalancer(address rebalancer) external {
        require(msg.sender == owner, "Not owner");
        authorizedRebalancers[rebalancer] = true;
    }
    
    /// @notice Remove authorized rebalancer
    function removeRebalancer(address rebalancer) external {
        require(msg.sender == owner, "Not owner");
        authorizedRebalancers[rebalancer] = false;
    }
}
