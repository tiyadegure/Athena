// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AuditTrail — ZK-verified audit execution trail
/// @notice Stores Merkle root of audit steps, verifiable via Groth16 proof
contract AuditTrail {
    address public immutable verifier;

    struct AuditProof {
        uint256 finalRoot;
        address auditor;
        uint256 timestamp;
        bytes32 attestationUID;
        bool verified;
    }

    mapping(bytes32 => AuditProof) public proofs;
    uint256 public proofCount;

    event AuditProven(
        bytes32 indexed uid,
        uint256 indexed finalRoot,
        address auditor,
        uint256 timestamp
    );

    constructor(address _verifier) {
        require(_verifier != address(0), "Invalid verifier");
        verifier = _verifier;
    }

    function submitProof(
        bytes32 uid,
        uint256 finalRoot,
        bytes32 attestationUID,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c
    ) external {
        require(proofs[uid].timestamp == 0, "Already submitted");

        uint256[1] memory publicInputs = [finalRoot];

        // Verify ZK proof via external verifier (passes memory data as ABI-encoded calldata)
        (bool success, bytes memory result) = verifier.staticcall(
            abi.encodeWithSignature(
                "verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[1])",
                a, b, c, publicInputs
            )
        );
        require(success, "Verifier call failed");
        require(abi.decode(result, (bool)), "Invalid ZK proof");

        proofs[uid] = AuditProof({
            finalRoot: finalRoot,
            auditor: msg.sender,
            timestamp: block.timestamp,
            attestationUID: attestationUID,
            verified: true
        });
        proofCount++;

        emit AuditProven(uid, finalRoot, msg.sender, block.timestamp);
    }

    function isAuditProven(bytes32 uid) external view returns (bool) {
        return proofs[uid].verified;
    }

    function getProof(bytes32 uid) external view returns (
        uint256 finalRoot,
        address auditor,
        uint256 timestamp,
        bytes32 attestationUID,
        bool verified
    ) {
        AuditProof memory p = proofs[uid];
        return (p.finalRoot, p.auditor, p.timestamp, p.attestationUID, p.verified);
    }
}
