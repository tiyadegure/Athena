// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/AuditCertificate.sol";

/// @notice Deploy AuditCertificate to Sepolia
/// @dev Usage: 
///   1. Set environment: export PRIVATE_KEY="your_key" SEPOLIA_RPC_URL="..."
///   2. Deploy: forge script script/DeployCertificate.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
contract DeployCertificate {
    function run() external returns (AuditCertificate) {
        AuditCertificate certificate = new AuditCertificate();
        
        // Log deployment info
        // In production, use console.log from forge-std
        // console.log("AuditCertificate deployed at:", address(certificate));
        // console.log("Owner:", certificate.owner());
        
        return certificate;
    }
}
