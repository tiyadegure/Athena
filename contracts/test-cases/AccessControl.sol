// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VulnerableToken
 * @notice Test case for missing access control — mint, burn, and ownership transfer are unprotected
 * @difficulty Beginner
 * @vuln_types Access Control
 * @expected_findings Anyone can mint unlimited tokens; anyone can burn others' tokens; single-step ownership transfer with no two-step verification
 * @audit_command claude "audit contracts/test-cases/AccessControl.sol"
 */

/// @title VulnerableToken - Test case for missing access control
/// @notice This contract intentionally has missing access control for audit testing
contract VulnerableToken {
    string public name = "VulnToken";
    string public symbol = "VULN";
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    /// @notice Mint new tokens
    /// @dev BUG: Missing onlyOwner modifier - anyone can mint
    function mint(address to, uint256 amount) public {
        totalSupply += amount;
        balanceOf[to] += amount;
    }
    
    /// @notice Burn tokens from an address
    /// @dev BUG: Missing access control - anyone can burn anyone's tokens
    function burn(address from, uint256 amount) public {
        require(balanceOf[from] >= amount, "Insufficient balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
    }
    
    /// @notice Transfer ownership to a new address
    /// @dev BUG: No two-step ownership transfer, no access control
    function transferOwnership(address newOwner) public {
        owner = newOwner;
    }
    
    /// @notice Transfer tokens to another address
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}
