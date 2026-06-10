// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/AuditCertificate.sol";

contract DeployV4 is Script {
    address constant SEPOLIA_EAS = 0xC2679fBD37d54388Ce493F1DB75320D236e1815e;

    function run() external returns (AuditCertificate) {
        uint256 pk = vm.envUint("SEPOLIA_PRIVATE_KEY");
        vm.startBroadcast(pk);
        AuditCertificate cert = new AuditCertificate(SEPOLIA_EAS);
        vm.stopBroadcast();
        return cert;
    }
}
