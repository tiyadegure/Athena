// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SafeVault - Test case for a properly implemented contract
/// @notice This contract has NO vulnerabilities - should not produce false positives
contract SafeVault is ERC20, Ownable, ReentrancyGuard {
    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;
    uint256 public constant MAX_DEPOSIT = 1000000 * 1e18;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    constructor() ERC20("VaultToken", "VLT") Ownable() {}
    
    /// @notice Deposit tokens and receive vault tokens
    /// @dev Protected by ReentrancyGuard, proper state management
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero amount");
        require(totalDeposits + amount <= MAX_DEPOSIT, "Exceeds max deposit");
        
        // Proper state update before external call
        deposits[msg.sender] += amount;
        totalDeposits += amount;
        
        _mint(msg.sender, amount);
        
        emit Deposit(msg.sender, amount);
    }
    
    /// @notice Withdraw tokens by burning vault tokens
    /// @dev Protected by ReentrancyGuard, proper state management
    function withdraw(uint256 amount) external nonReentrant {
        require(deposits[msg.sender] >= amount, "Insufficient deposit");
        
        // State update before external call
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;
        
        _burn(msg.sender, amount);
        
        emit Withdrawal(msg.sender, amount);
    }
    
    /// @notice Get current utilization in basis points
    function getUtilization() external view returns (uint256) {
        if (MAX_DEPOSIT == 0) return 0;
        return (totalDeposits * 10000) / MAX_DEPOSIT; // basis points
    }
}
