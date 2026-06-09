// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AuditEvidenceChain - Merkle-based audit evidence chain
/// @notice Each audit step is attested on-chain, verifiable via Merkle proof
/// @dev Integrates with EAS for individual step attestations

interface IEAS {
    struct Attestation {
        bytes32 uid;
        bytes32 schema;
        uint64 time;
        uint64 expirationTime;
        bool revocable;
        bytes32 refUID;
        address recipient;
        address attester;
        bytes data;
    }
    
    function attest(bytes32 schema, address recipient, uint64 expirationTime, bool revocable, bytes32 refUID, bytes calldata data, uint256 value) external returns (bytes32);
    function getAttestation(bytes32 uid) external view returns (Attestation memory);
    function isAttestationValid(bytes32 uid) external view returns (bool);
}

/// @notice Audit step data structure
struct AuditStep {
    uint8 stepNumber;      // 1-8
    string stepName;       // "scope", "slither", "aderyn", "poc", "fuzz", "fix", "report", "certificate"
    bytes32 inputHash;     // Hash of input data
    bytes32 outputHash;    // Hash of output data
    uint64 timestamp;      // When the step was executed
    address auditor;       // Who executed the step
}

/// @title AuditEvidenceChain
contract AuditEvidenceChain {
    IEAS public immutable eas;
    address public immutable owner;
    
    // Schema UID for audit step attestations
    bytes32 public stepSchemaUID;
    
    // Audit ID => step number => step data
    mapping(bytes32 => mapping(uint8 => AuditStep)) public auditSteps;
    
    // Audit ID => Merkle root
    mapping(bytes32 => bytes32) public auditMerkleRoots;
    
    // Audit ID => step count
    mapping(bytes32 => uint8) public stepCounts;
    
    // Audit ID => completed
    mapping(bytes32 => bool) public auditCompleted;
    
    // Events
    event StepAttested(bytes32 indexed auditId, uint8 stepNumber, bytes32 stepHash);
    event AuditCompleted(bytes32 indexed auditId, bytes32 merkleRoot);
    event AuditFinalized(bytes32 indexed auditId, bytes32 attestationUID);
    
    constructor(address _eas, bytes32 _stepSchemaUID) {
        eas = IEAS(_eas);
        owner = msg.sender;
        stepSchemaUID = _stepSchemaUID;
    }
    
    /// @notice Record an audit step
    /// @param auditId Unique audit identifier
    /// @param stepNumber Step number (1-8)
    /// @param stepName Name of the step
    /// @param inputHash Hash of input data
    /// @param outputHash Hash of output data
    function recordStep(
        bytes32 auditId,
        uint8 stepNumber,
        string calldata stepName,
        bytes32 inputHash,
        bytes32 outputHash
    ) external {
        require(stepNumber >= 1 && stepNumber <= 8, "Invalid step number");
        require(!auditCompleted[auditId], "Audit already completed");
        
        uint64 timestamp = uint64(block.timestamp);
        
        auditSteps[auditId][stepNumber] = AuditStep({
            stepNumber: stepNumber,
            stepName: stepName,
            inputHash: inputHash,
            outputHash: outputHash,
            timestamp: timestamp,
            auditor: msg.sender
        });
        
        stepCounts[auditId] = stepCounts[auditId] + 1;
        
        // Calculate step hash
        bytes32 stepHash = keccak256(abi.encodePacked(
            auditId,
            stepNumber,
            stepName,
            inputHash,
            outputHash,
            timestamp,
            msg.sender
        ));
        
        emit StepAttested(auditId, stepNumber, stepHash);
    }
    
    /// @notice Calculate Merkle root from all recorded steps
    /// @param auditId Unique audit identifier
    /// @return merkleRoot The calculated Merkle root
    function calculateMerkleRoot(bytes32 auditId) external returns (bytes32 merkleRoot) {
        require(stepCounts[auditId] > 0, "No steps recorded");
        
        // Collect all step hashes
        bytes32[] memory leaves = new bytes32[](stepCounts[auditId]);
        uint8 count = 0;
        
        for (uint8 i = 1; i <= 8; i++) {
            if (auditSteps[auditId][i].timestamp > 0) {
                leaves[count] = keccak256(abi.encodePacked(
                    auditId,
                    auditSteps[auditId][i].stepNumber,
                    auditSteps[auditId][i].stepName,
                    auditSteps[auditId][i].inputHash,
                    auditSteps[auditId][i].outputHash,
                    auditSteps[auditId][i].timestamp,
                    auditSteps[auditId][i].auditor
                ));
                count++;
            }
        }
        
        // Calculate Merkle root
        merkleRoot = _calculateMerkleRoot(leaves);
        auditMerkleRoots[auditId] = merkleRoot;
        
        return merkleRoot;
    }
    
    /// @notice Finalize audit with EAS attestation
    /// @param auditId Unique audit identifier
    /// @param recipient Address to receive the attestation
    /// @return attestationUID The EAS attestation UID
    function finalizeAudit(
        bytes32 auditId,
        address recipient
    ) external returns (bytes32 attestationUID) {
        require(stepCounts[auditId] >= 7, "Not all steps completed");
        require(auditMerkleRoots[auditId] != bytes32(0), "Merkle root not calculated");
        require(!auditCompleted[auditId], "Audit already finalized");
        
        // Encode attestation data
        bytes memory data = abi.encode(
            auditId,
            auditMerkleRoots[auditId],
            stepCounts[auditId],
            block.timestamp,
            msg.sender
        );
        
        // Create EAS attestation
        attestationUID = eas.attest(
            stepSchemaUID,
            recipient,
            0, // no expiration
            true, // revocable
            bytes32(0), // no ref UID
            data,
            0 // no value
        );
        
        auditCompleted[auditId] = true;
        
        emit AuditFinalized(auditId, attestationUID);
        
        return attestationUID;
    }
    
    /// @notice Verify a step is in the audit evidence chain
    /// @param auditId Unique audit identifier
    /// @param stepNumber Step number to verify
    /// @param proof Merkle proof (array of sibling hashes)
    /// @return valid Whether the step is valid
    function verifyStep(
        bytes32 auditId,
        uint8 stepNumber,
        bytes32[] calldata proof
    ) external view returns (bool valid) {
        require(auditSteps[auditId][stepNumber].timestamp > 0, "Step not recorded");
        
        // Calculate step hash
        bytes32 stepHash = keccak256(abi.encodePacked(
            auditId,
            auditSteps[auditId][stepNumber].stepNumber,
            auditSteps[auditId][stepNumber].stepName,
            auditSteps[auditId][stepNumber].inputHash,
            auditSteps[auditId][stepNumber].outputHash,
            auditSteps[auditId][stepNumber].timestamp,
            auditSteps[auditId][stepNumber].auditor
        ));
        
        // Verify Merkle proof
        bytes32 computedRoot = _verifyMerkleProof(stepHash, proof);
        
        return computedRoot == auditMerkleRoots[auditId];
    }
    
    /// @notice Get all steps for an audit
    /// @param auditId Unique audit identifier
    /// @return steps Array of step data
    function getAuditSteps(bytes32 auditId) external view returns (AuditStep[] memory steps) {
        uint8 count = stepCounts[auditId];
        steps = new AuditStep[](count);
        uint8 index = 0;
        
        for (uint8 i = 1; i <= 8; i++) {
            if (auditSteps[auditId][i].timestamp > 0) {
                steps[index] = auditSteps[auditId][i];
                index++;
            }
        }
        
        return steps;
    }
    
    // ============ Internal Functions ============
    
    function _calculateMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        if (leaves.length == 0) return bytes32(0);
        if (leaves.length == 1) return leaves[0];
        
        // Build Merkle tree
        while (leaves.length > 1) {
            uint256 newLength = (leaves.length + 1) / 2;
            bytes32[] memory newLeaves = new bytes32[](newLength);
            
            for (uint256 i = 0; i < leaves.length; i += 2) {
                if (i + 1 < leaves.length) {
                    newLeaves[i / 2] = _hashPair(leaves[i], leaves[i + 1]);
                } else {
                    newLeaves[i / 2] = leaves[i]; // Odd leaf, promote
                }
            }
            
            leaves = newLeaves;
        }
        
        return leaves[0];
    }
    
    function _verifyMerkleProof(bytes32 leaf, bytes32[] calldata proof) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        
        return computedHash;
    }
    
    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}
