// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SyntheticOption.sol";

/// @title OptionsIndexTracker - Index tracking using options
/// @notice Based on Vitalik's "Options-Based Index Tracking" (2026-06-01)
/// @dev Tracks an index by holding a basket of option positions
/// @dev Key innovation: No liquidation mechanism needed (P + N = 1)

interface IPriceOracle {
    function getPrice(address asset) external view returns (uint256);
}

/// @notice Index constituent
struct Constituent {
    address asset;          // Asset address
    uint256 weight;         // Weight in index (basis points, 10000 = 100%)
    SyntheticOption option; // Option contract for this constituent
}

/// @title OptionsIndexTracker
contract OptionsIndexTracker {
    string public name;
    string public symbol;
    
    // Index constituents
    Constituent[] public constituents;
    uint256 public totalWeight;
    
    // Index token
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    // Oracle
    IPriceOracle public oracle;
    
    // Rebalancing
    uint256 public lastRebalance;
    uint256 public rebalanceInterval = 1 days;
    uint256 public rebalanceThreshold = 100; // 1% deviation triggers rebalance
    
    // Events
    event ConstituentAdded(address indexed asset, uint256 weight);
    event Rebalanced(uint256 timestamp, uint256[] newWeights);
    event Minted(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);
    
    constructor(string memory _name, string memory _symbol, address _oracle) {
        name = _name;
        symbol = _symbol;
        oracle = IPriceOracle(_oracle);
    }
    
    /// @notice Add a constituent to the index
    function addConstituent(address asset, uint256 weight, uint256 strike, uint256 maturity) external {
        require(weight > 0, "Zero weight");
        require(totalWeight + weight <= 10000, "Exceeds 100%");
        
        SyntheticOption option = new SyntheticOption(
            "Index Option",
            strike,
            maturity
        );
        
        constituents.push(Constituent({
            asset: asset,
            weight: weight,
            option: option
        }));
        
        totalWeight += weight;
        
        emit ConstituentAdded(asset, weight);
    }
    
    /// @notice Mint index tokens by depositing options
    /// @param pAmounts Array of P token amounts for each constituent
    /// @param nAmounts Array of N token amounts for each constituent
    function mint(uint256[] calldata pAmounts, uint256[] calldata nAmounts) external {
        require(pAmounts.length == constituents.length, "Invalid P amounts length");
        require(nAmounts.length == constituents.length, "Invalid N amounts length");
        
        uint256 mintAmount = 0;
        
        for (uint256 i = 0; i < constituents.length; i++) {
            Constituent storage c = constituents[i];
            
            // Transfer P and N tokens to contract
            c.option.pToken().transferFrom(msg.sender, address(this), pAmounts[i]);
            c.option.nToken().transferFrom(msg.sender, address(this), nAmounts[i]);
            
            // Calculate value (P + N = collateral value)
            uint256 value = pAmounts[i] + nAmounts[i];
            mintAmount += (value * c.weight) / 10000;
        }
        
        // Mint index tokens
        totalSupply += mintAmount;
        balanceOf[msg.sender] += mintAmount;
        
        emit Minted(msg.sender, mintAmount);
    }
    
    /// @notice Redeem index tokens for underlying options
    /// @param amount Amount of index tokens to redeem
    function redeem(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        // Burn index tokens
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        
        // Calculate and return proportional options
        for (uint256 i = 0; i < constituents.length; i++) {
            Constituent storage c = constituents[i];
            
            uint256 pBalance = c.option.pToken().balanceOf(address(this));
            uint256 nBalance = c.option.nToken().balanceOf(address(this));
            
            uint256 pReturn = (pBalance * amount) / totalSupply;
            uint256 nReturn = (nBalance * amount) / totalSupply;
            
            if (pReturn > 0) c.option.pToken().transfer(msg.sender, pReturn);
            if (nReturn > 0) c.option.nToken().transfer(msg.sender, nReturn);
        }
        
        emit Redeemed(msg.sender, amount);
    }
    
    /// @notice Get current index value
    function getIndexValue() external view returns (uint256) {
        uint256 totalValue = 0;
        
        for (uint256 i = 0; i < constituents.length; i++) {
            Constituent storage c = constituents[i];
            
            uint256 pBalance = c.option.pToken().balanceOf(address(this));
            uint256 nBalance = c.option.nToken().balanceOf(address(this));
            
            // Value = P + N = collateral value
            totalValue += pBalance + nBalance;
        }
        
        if (totalSupply == 0) return 0;
        return (totalValue * 1e18) / totalSupply;
    }
    
    /// @notice Check if rebalancing is needed
    function needsRebalance() external view returns (bool) {
        if (block.timestamp - lastRebalance < rebalanceInterval) return false;
        
        // Check weight deviations
        for (uint256 i = 0; i < constituents.length; i++) {
            Constituent storage c = constituents[i];
            
            uint256 currentValue = c.option.pToken().balanceOf(address(this)) + 
                                   c.option.nToken().balanceOf(address(this));
            uint256 totalValue = _getTotalValue();
            
            if (totalValue == 0) continue;
            
            uint256 currentWeight = (currentValue * 10000) / totalValue;
            uint256 deviation = currentWeight > c.weight ? 
                               currentWeight - c.weight : 
                               c.weight - currentWeight;
            
            if (deviation > rebalanceThreshold) return true;
        }
        
        return false;
    }
    
    /// @notice Execute rebalance
    /// @param newWeights New weights for each constituent (basis points)
    function rebalance(uint256[] calldata newWeights) external {
        require(newWeights.length == constituents.length, "Invalid weights length");
        require(block.timestamp - lastRebalance >= rebalanceInterval, "Too early");
        
        uint256 totalNewWeight = 0;
        for (uint256 i = 0; i < newWeights.length; i++) {
            totalNewWeight += newWeights[i];
        }
        require(totalNewWeight == 10000, "Weights must sum to 10000");
        
        // Update weights
        for (uint256 i = 0; i < constituents.length; i++) {
            constituents[i].weight = newWeights[i];
        }
        
        lastRebalance = block.timestamp;
        
        emit Rebalanced(block.timestamp, newWeights);
    }
    
    /// @notice Get constituent count
    function getConstituentCount() external view returns (uint256) {
        return constituents.length;
    }
    
    /// @notice Get constituent details
    function getConstituent(uint256 index) external view returns (
        address asset,
        uint256 weight,
        address pToken,
        address nToken
    ) {
        require(index < constituents.length, "Invalid index");
        Constituent storage c = constituents[index];
        return (c.asset, c.weight, address(c.option.pToken()), address(c.option.nToken()));
    }
    
    function _getTotalValue() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < constituents.length; i++) {
            Constituent storage c = constituents[i];
            total += c.option.pToken().balanceOf(address(this)) + 
                     c.option.nToken().balanceOf(address(this));
        }
        return total;
    }
}
