// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AgentIdentity
 * @notice Test case for AI agent identity registry — reputation manipulation via unauthenticated threat reports
 * @difficulty Intermediate
 * @vuln_types Access Control, Reputation Manipulation
 * @expected_findings Anyone can report threats and reduce an agent's reputation without verification; no rate-limiting on threat reports; governance can be changed to zero address
 * @audit_command claude "audit contracts/test-cases/AgentIdentity.sol"
 */

/// @title AgentIdentity - AI Agent Identity and Threat Registry
/// @notice Based on EIP: AI Agent Identity and Threat Registry (2026-06-05)
/// @dev Enables registration and verification of AI agents with threat tracking

/// @notice Agent identity data
struct AgentData {
    address owner;           // Owner of the agent
    string name;             // Agent name
    string metadata;         // Agent metadata (capabilities, version, etc.)
    bytes32 identityHash;    // Hash of agent identity proof
    uint256 registeredAt;    // Registration timestamp
    uint256 lastActive;      // Last activity timestamp
    bool isActive;           // Whether agent is active
    uint256 reputation;      // Reputation score (0-100)
}

/// @notice Threat report
struct ThreatReport {
    address reporter;        // Who reported the threat
    address agent;           // Threat agent
    string threatType;       // Type of threat
    string description;      // Threat description
    uint256 severity;        // Severity (1-10)
    uint256 reportedAt;      // Report timestamp
    bool verified;           // Whether verified by governance
}

/// @title AgentIdentity
contract AgentIdentity {
    // Agent registry
    mapping(address => AgentData) public agents;
    address[] public agentList;
    
    // Threat registry
    mapping(address => ThreatReport[]) public threatReports;
    mapping(bytes32 => bool) public verifiedThreats;
    
    // Governance
    address public governance;
    mapping(address => bool) public verifiers;
    
    // Identity verification
    mapping(bytes32 => address) public identityToAgent;
    
    // Events
    event AgentRegistered(address indexed agent, string name, bytes32 identityHash);
    event AgentUpdated(address indexed agent, string metadata);
    event AgentDeactivated(address indexed agent);
    event ThreatReported(address indexed agent, address indexed reporter, string threatType, uint256 severity);
    event ThreatVerified(bytes32 indexed reportId, address indexed agent);
    event GovernanceChanged(address indexed newGovernance);
    
    constructor(address _governance) {
        governance = _governance;
        verifiers[_governance] = true;
    }
    
    /// @notice Register a new AI agent
    /// @param name Agent name
    /// @param metadata Agent metadata
    /// @param identityProof Proof of identity (e.g., signed message hash)
    function registerAgent(
        string calldata name,
        string calldata metadata,
        bytes32 identityProof
    ) external {
        require(agents[msg.sender].owner == address(0), "Already registered");
        require(identityToAgent[identityProof] == address(0), "Identity already taken");
        
        agents[msg.sender] = AgentData({
            owner: msg.sender,
            name: name,
            metadata: metadata,
            identityHash: identityProof,
            registeredAt: block.timestamp,
            lastActive: block.timestamp,
            isActive: true,
            reputation: 50 // Default reputation
        });
        
        agentList.push(msg.sender);
        identityToAgent[identityProof] = msg.sender;
        
        emit AgentRegistered(msg.sender, name, identityProof);
    }
    
    /// @notice Update agent metadata
    /// @param metadata New metadata
    function updateMetadata(string calldata metadata) external {
        require(agents[msg.sender].owner == msg.sender, "Not registered");
        require(agents[msg.sender].isActive, "Agent not active");
        
        agents[msg.sender].metadata = metadata;
        agents[msg.sender].lastActive = block.timestamp;
        
        emit AgentUpdated(msg.sender, metadata);
    }
    
    /// @notice Deactivate agent
    function deactivateAgent() external {
        require(agents[msg.sender].owner == msg.sender, "Not owner");
        
        agents[msg.sender].isActive = false;
        
        emit AgentDeactivated(msg.sender);
    }
    
    /// @notice Report a threat
    /// @param agent Threat agent address
    /// @param threatType Type of threat
    /// @param description Threat description
    /// @param severity Severity (1-10)
    function reportThreat(
        address agent,
        string calldata threatType,
        string calldata description,
        uint256 severity
    ) external {
        require(agents[agent].owner != address(0), "Agent not registered");
        require(severity >= 1 && severity <= 10, "Invalid severity");
        
        threatReports[agent].push(ThreatReport({
            reporter: msg.sender,
            agent: agent,
            threatType: threatType,
            description: description,
            severity: severity,
            reportedAt: block.timestamp,
            verified: false
        }));
        
        // Reduce reputation based on severity
        if (agents[agent].reputation >= severity) {
            agents[agent].reputation -= severity;
        } else {
            agents[agent].reputation = 0;
        }
        
        emit ThreatReported(agent, msg.sender, threatType, severity);
    }
    
    /// @notice Verify a threat report (verifier only)
    /// @param agent Threat agent
    /// @param reportIndex Index of the report
    function verifyThreat(address agent, uint256 reportIndex) external {
        require(verifiers[msg.sender], "Not verifier");
        require(reportIndex < threatReports[agent].length, "Invalid index");
        
        ThreatReport storage report = threatReports[agent][reportIndex];
        report.verified = true;
        
        bytes32 reportId = keccak256(abi.encodePacked(agent, reportIndex));
        verifiedThreats[reportId] = true;
        
        emit ThreatVerified(reportId, agent);
    }
    
    /// @notice Add a verifier
    /// @param verifier Address to add as verifier
    function addVerifier(address verifier) external {
        require(msg.sender == governance, "Not governance");
        verifiers[verifier] = true;
    }
    
    /// @notice Remove a verifier
    /// @param verifier Address to remove
    function removeVerifier(address verifier) external {
        require(msg.sender == governance, "Not governance");
        verifiers[verifier] = false;
    }
    
    /// @notice Change governance
    /// @param newGovernance New governance address
    function setGovernance(address newGovernance) external {
        require(msg.sender == governance, "Not governance");
        governance = newGovernance;
        verifiers[newGovernance] = true;
        
        emit GovernanceChanged(newGovernance);
    }
    
    /// @notice Get agent details
    function getAgent(address agent) external view returns (
        address owner,
        string memory name,
        uint256 reputation,
        bool isActive,
        uint256 threatCount
    ) {
        AgentData storage identity = agents[agent];
        return (
            identity.owner,
            identity.name,
            identity.reputation,
            identity.isActive,
            threatReports[agent].length
        );
    }
    
    /// @notice Get threat report
    function getThreatReport(address agent, uint256 index) external view returns (
        address reporter,
        string memory threatType,
        uint256 severity,
        bool verified
    ) {
        require(index < threatReports[agent].length, "Invalid index");
        ThreatReport storage report = threatReports[agent][index];
        return (
            report.reporter,
            report.threatType,
            report.severity,
            report.verified
        );
    }
    
    /// @notice Get agent count
    function getAgentCount() external view returns (uint256) {
        return agentList.length;
    }
    
    /// @notice Check if agent is trusted (reputation > threshold)
    function isTrusted(address agent, uint256 threshold) external view returns (bool) {
        return agents[agent].isActive && agents[agent].reputation >= threshold;
    }
}
