// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Minimal Vm interface for cheatcodes
interface Vm {
    function deal(address account, uint256 newBalance) external;
    function prank(address sender) external;
    function startPrank(address sender) external;
    function stopPrank() external;
    function label(address account, string calldata label) external;
}

abstract contract Script {
    address internal constant VM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    function broadcast() internal {
        // Placeholder
    }

    function broadcast(uint256 privateKey) internal {
        // Placeholder
    }

    function startBroadcast() internal {
        // Placeholder
    }

    function startBroadcast(uint256 privateKey) internal {
        // Placeholder
    }

    function stopBroadcast() internal {
        // Placeholder
    }
}

library console {
    function log(string memory) internal {}
    function log(address) internal {}
    function log(uint256) internal {}
    function log(string memory, uint256) internal {}
    function log(string memory, address) internal {}
    function log(string memory, bool) internal {}
}
