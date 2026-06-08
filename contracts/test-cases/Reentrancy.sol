// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title VulnerableBank - Test case for reentrancy vulnerability
/// @notice This contract intentionally contains a reentrancy bug for audit testing
contract VulnerableBank {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    /// @notice Deposit ETH into the bank
    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    /// @notice Withdraw all ETH from the bank
    /// @dev BUG: External call before state update - vulnerable to reentrancy
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");
        
        // BUG: External call before state update
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] = 0;
    }
    
    /// @notice Get the contract's ETH balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
