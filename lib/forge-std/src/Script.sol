// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Script {
    address internal constant VM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));

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
}
