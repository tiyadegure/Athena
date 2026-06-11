// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AgentEscrow v2 - EAS-integrated Agent-to-Agent Escrow
/// @notice Enables AI Agents to transact with automatic payment on audit completion
/// @dev Integrates with EAS for automatic escrow release when audit attestation is created

struct Attestation { bytes32 uid; bytes32 schema; uint64 time; uint64 expirationTime; bool revocable; bytes32 refUID; address recipient; address attester; bytes data; }
interface IEAS { function getAttestation(bytes32) external view returns (Attestation memory); function isAttestationValid(bytes32) external view returns (bool); }

enum EscrowState { Created, Funded, Completed, Disputed, Refunded }

struct EscrowTerms {
    address buyer;           // Project requesting audit
    address seller;          // AI Agent performing audit
    uint256 amount;          // Payment amount
    uint256 deadline;        // Deadline for completion
    string metadata;         // Task description / contract to audit
    EscrowState state;
    uint256 createdAt;
    uint256 completedAt;
    bytes32 attestationUID;  // EAS attestation for auto-release
}

/// @title AgentEscrow v2
contract AgentEscrowV2 {
    IEAS public immutable eas;
    address public arbitrator;

    mapping(bytes32 => EscrowTerms) public escrows;
    bytes32[] public escrowList;
    mapping(bytes32 => bool) public disputes;

    event EscrowCreated(bytes32 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event EscrowFunded(bytes32 indexed escrowId, uint256 amount);
    event EscrowCompleted(bytes32 indexed escrowId, uint256 amount, bytes32 attestationUID);
    event EscrowDisputed(bytes32 indexed escrowId, address indexed disputer);
    event EscrowRefunded(bytes32 indexed escrowId, uint256 amount);
    event ArbitratorChanged(address indexed newArbitrator);

    constructor(address _eas, address _arbitrator) {
        require(_eas != address(0), "Invalid EAS");
        require(_arbitrator != address(0), "Invalid arbitrator");
        eas = IEAS(_eas);
        arbitrator = _arbitrator;
    }

    /// @notice Create a new escrow for an audit task
    function createEscrow(
        address seller,
        uint256 deadline,
        string calldata metadata
    ) external payable returns (bytes32 escrowId) {
        require(msg.value > 0, "Zero amount");
        require(seller != address(0), "Invalid seller");
        require(seller != msg.sender, "Self-escrow");
        require(deadline > block.timestamp, "Invalid deadline");

        escrowId = keccak256(abi.encodePacked(msg.sender, seller, msg.value, block.timestamp, escrowList.length));

        escrows[escrowId] = EscrowTerms({
            buyer: msg.sender,
            seller: seller,
            amount: msg.value,
            deadline: deadline,
            metadata: metadata,
            state: EscrowState.Funded,
            createdAt: block.timestamp,
            completedAt: 0,
            attestationUID: bytes32(0)
        });

        escrowList.push(escrowId);
        emit EscrowCreated(escrowId, msg.sender, seller, msg.value);
        emit EscrowFunded(escrowId, msg.value);
    }

    /// @notice Complete escrow manually (buyer confirms audit is done)
    function completeEscrow(bytes32 escrowId) external {
        EscrowTerms storage escrow = escrows[escrowId];
        require(escrow.buyer == msg.sender, "Not buyer");
        require(escrow.state == EscrowState.Funded, "Invalid state");
        require(block.timestamp <= escrow.deadline, "Deadline passed");

        _releaseFunds(escrowId);
    }

    /// @notice Auto-release funds when EAS attestation is created
    /// @dev Anyone can call this with a valid attestation — verifies audit was completed
    function completeWithAttestation(bytes32 escrowId, bytes32 attestationUID) external {
        EscrowTerms storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Funded, "Invalid state");
        require(block.timestamp <= escrow.deadline, "Deadline passed");

        // Verify attestation is valid
        require(eas.isAttestationValid(attestationUID), "Invalid attestation");

        escrow.attestationUID = attestationUID;
        _releaseFunds(escrowId);
    }

    /// @notice Raise dispute
    function disputeEscrow(bytes32 escrowId) external {
        EscrowTerms storage escrow = escrows[escrowId];
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "Not authorized");
        require(escrow.state == EscrowState.Funded, "Invalid state");
        require(block.timestamp <= escrow.deadline, "Deadline passed");

        escrow.state = EscrowState.Disputed;
        disputes[escrowId] = true;
        emit EscrowDisputed(escrowId, msg.sender);
    }

    /// @notice Resolve dispute (arbitrator only)
    function resolveDispute(bytes32 escrowId, bool refundToBuyer) external {
        require(msg.sender == arbitrator, "Not arbitrator");
        EscrowTerms storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Disputed, "Not disputed");

        if (refundToBuyer) {
            (bool success, ) = escrow.buyer.call{value: escrow.amount}("");
            require(success, "Transfer failed");
            escrow.state = EscrowState.Refunded;
            emit EscrowRefunded(escrowId, escrow.amount);
        } else {
            _releaseFunds(escrowId);
        }
    }

    /// @notice Refund expired escrow (after deadline)
    function refundExpiredEscrow(bytes32 escrowId) external {
        EscrowTerms storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Funded, "Invalid state");
        require(block.timestamp > escrow.deadline, "Deadline not passed");

        escrow.state = EscrowState.Refunded; // State update before transfer (reentrancy safe)
        (bool success, ) = escrow.buyer.call{value: escrow.amount}("");
        require(success, "Transfer failed");
        emit EscrowRefunded(escrowId, escrow.amount);
    }

    /// @notice Internal: release funds to seller
    function _releaseFunds(bytes32 escrowId) internal {
        EscrowTerms storage escrow = escrows[escrowId];
        (bool success, ) = escrow.seller.call{value: escrow.amount}("");
        require(success, "Transfer failed");
        escrow.state = EscrowState.Completed;
        escrow.completedAt = block.timestamp;
        emit EscrowCompleted(escrowId, escrow.amount, escrow.attestationUID);
    }

    function setArbitrator(address newArbitrator) external {
        require(msg.sender == arbitrator, "Not arbitrator");
        arbitrator = newArbitrator;
        emit ArbitratorChanged(newArbitrator);
    }

    function getEscrow(bytes32 escrowId) external view returns (
        address buyer, address seller, uint256 amount, uint256 deadline, EscrowState state, bytes32 attestationUID
    ) {
        EscrowTerms storage e = escrows[escrowId];
        return (e.buyer, e.seller, e.amount, e.deadline, e.state, e.attestationUID);
    }

    function getEscrowCount() external view returns (uint256) {
        return escrowList.length;
    }

    receive() external payable {}
}
