// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SimpleOracle - Price oracle for multi-contract testing
/// @notice VULNERABLE: Uses spot price (manipulable via flash loans)
contract SimpleOracle {
    // VULNERABILITY: Spot price can be manipulated
    mapping(address => uint256) public prices; // token => price in USD (18 decimals)
    
    address public owner;
    
    event PriceUpdated(address indexed token, uint256 price);
    
    constructor() {
        owner = msg.sender;
    }
    
    /// @notice Update price (admin only)
    function setPrice(address token, uint256 price) external {
        require(msg.sender == owner, "Not owner");
        prices[token] = price;
        emit PriceUpdated(token, price);
    }
    
    /// @notice Get price (VULNERABLE: returns spot price)
    /// @dev This is the vulnerability - spot price can be manipulated
    function getPrice(address token) external view returns (uint256) {
        return prices[token];
    }
    
    /// @notice Get price with sanity check (still vulnerable)
    function getPriceWithCheck(address token, uint256 minPrice) external view returns (uint256) {
        uint256 price = prices[token];
        require(price >= minPrice, "Price below minimum");
        return price;
    }
}
