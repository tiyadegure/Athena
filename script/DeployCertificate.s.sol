// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/AuditCertificate.sol";

/// @notice Deploy AuditCertificate to Sepolia
/// @dev Usage: 
///   1. Set environment: export PRIVATE_KEY="your_key" SEPOLIA_RPC_URL="..."
///   2. Deploy: forge script script/DeployCertificate.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
contract DeployCertificate {
    // EAS contract on Sepolia
    address constant SEPOLIA_EAS = 0xC2679fBD37d54388Ce493F1DB75320D236e1815e;
    
    function run() external returns (AuditCertificate) {
        // Deploy with real EAS address on Sepolia
        AuditCertificate certificate = new AuditCertificate(SEPOLIA_EAS);
        
        return certificate;
    }
}
