// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "../contracts/ERC7512AuditMetadata.sol";
import "../contracts/AuditTrail.sol";
import "../contracts/ZKVerifier.sol";

contract DeployBaseSepolia2 is Script {
    function run() external {
        uint256 pk = vm.envUint("SEPOLIA_PRIVATE_KEY");
        vm.startBroadcast(pk);
        ERC7512AuditMetadata metadata = new ERC7512AuditMetadata();
        Groth16Verifier verifier = new Groth16Verifier();
        AuditTrail trail = new AuditTrail(address(verifier));
        vm.stopBroadcast();
    }
}
