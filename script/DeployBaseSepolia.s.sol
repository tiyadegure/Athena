// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "../contracts/AuditCertificate.sol";

contract DeployBaseSepolia is Script {
    function run() external {
        uint256 pk = vm.envUint("SEPOLIA_PRIVATE_KEY");
        vm.startBroadcast(pk);
        AuditCertificate cert = new AuditCertificate(0x4200000000000000000000000000000000000021);
        vm.stopBroadcast();
    }
}
