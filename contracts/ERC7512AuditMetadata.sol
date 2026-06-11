// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ERC7512AuditMetadata - On-chain audit metadata standard
/// @notice Standardizes audit results for on-chain querying and interoperability
/// @dev Compatible with ERC-7512 audit metadata standard

struct AuditMetadata {
    address contractAudited;    // Contract that was audited
    address auditor;            // Who performed the audit (AI Agent or human)
    uint8 severity;             // 0=Critical, 1=High, 2=Medium, 3=Low, 4=Informational
    uint8 score;                // 0-100 audit score
    uint256 timestamp;          // When audit was completed
    uint256 findingsCount;      // Number of findings
    bytes32 attestationUID;     // EAS attestation reference
    bytes32 reportHash;         // Hash of the full audit report
    string auditMode;           // "full", "quick", "incremental"
    bool verified;              // Whether ZK proof exists
}

/// @title ERC7512AuditMetadata
contract ERC7512AuditMetadata {
    mapping(bytes32 => AuditMetadata) public audits;
    mapping(address => bytes32[]) public contractAudits;  // contract => audit UIDs
    mapping(address => bytes32[]) public auditorAudits;   // auditor => audit UIDs
    uint256 public auditCount;

    event AuditRegistered(
        bytes32 indexed uid,
        address indexed contractAudited,
        address indexed auditor,
        uint8 severity,
        uint8 score
    );

    /// @notice Register an audit result on-chain
    function registerAudit(
        address contractAudited,
        address auditor,
        uint8 severity,
        uint8 score,
        uint256 findingsCount,
        bytes32 attestationUID,
        bytes32 reportHash,
        string calldata auditMode
    ) external returns (bytes32 uid) {
        require(contractAudited != address(0), "Invalid contract");
        require(auditor != address(0), "Invalid auditor");
        require(score <= 100, "Invalid score");

        uid = keccak256(abi.encodePacked(contractAudited, auditor, block.timestamp, auditCount));

        audits[uid] = AuditMetadata({
            contractAudited: contractAudited,
            auditor: auditor,
            severity: severity,
            score: score,
            timestamp: block.timestamp,
            findingsCount: findingsCount,
            attestationUID: attestationUID,
            reportHash: reportHash,
            auditMode: auditMode,
            verified: false
        });

        contractAudits[contractAudited].push(uid);
        auditorAudits[auditor].push(uid);
        auditCount++;

        emit AuditRegistered(uid, contractAudited, auditor, severity, score);
    }

    /// @notice Mark audit as ZK-verified
    function markVerified(bytes32 uid, bytes32 zkProofHash) external {
        AuditMetadata storage audit = audits[uid];
        require(audit.timestamp != 0, "Audit not found");
        require(msg.sender == audit.auditor, "Not auditor");
        audit.verified = true;
    }

    /// @notice Get all audit UIDs for a contract
    function getContractAudits(address contractAddr) external view returns (bytes32[] memory) {
        return contractAudits[contractAddr];
    }

    /// @notice Get all audit UIDs by an auditor
    function getAuditorAudits(address auditorAddr) external view returns (bytes32[] memory) {
        return auditorAudits[auditorAddr];
    }

    /// @notice Get audit details
    function getAudit(bytes32 uid) external view returns (
        address contractAudited,
        address auditor,
        uint8 severity,
        uint8 score,
        uint256 timestamp,
        uint256 findingsCount,
        bytes32 attestationUID,
        bytes32 reportHash,
        string memory auditMode,
        bool verified
    ) {
        AuditMetadata memory a = audits[uid];
        return (
            a.contractAudited, a.auditor, a.severity, a.score,
            a.timestamp, a.findingsCount, a.attestationUID,
            a.reportHash, a.auditMode, a.verified
        );
    }
}
