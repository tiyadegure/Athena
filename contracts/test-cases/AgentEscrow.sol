// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AgentEscrow - Native-ETH Agent-to-Agent Escrow
/// @notice Based on EIP: Native-ETH Agent-to-Agent Escrow (2026-06-05)
/// @dev Enables AI Agents to transact securely with escrow protection

/// @notice Escrow state
enum EscrowState {
    Created,      // Escrow created, awaiting deposit
    Funded,       // Funds deposited in escrow
    Completed,    // Transaction completed, funds released
    Disputed,     // Dispute raised
    Refunded      // Escrow refunded to buyer
}

/// @notice Escrow terms
struct EscrowTerms {
    address buyer;           // Buyer agent
    address seller;          // Seller agent
    uint256 amount;          // Amount in escrow
    uint256 deadline;        // Deadline for completion
    string metadata;         // Transaction metadata (e.g., task description)
    EscrowState state;       // Current state
    uint256 createdAt;       // Creation timestamp
    uint256 completedAt;     // Completion timestamp
}

/// @title AgentEscrow
contract AgentEscrow {
    // Escrow registry
    mapping(bytes32 => EscrowTerms) public escrows;
    bytes32[] public escrowList;
    
    // Dispute resolution
    address public arbitrator;
    mapping(bytes32 => bool) public disputes;
    
    // Events
    event EscrowCreated(bytes32 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event EscrowFunded(bytes32 indexed escrowId, uint256 amount);
    event EscrowCompleted(bytes32 indexed escrowId, uint256 amount);
    event EscrowDisputed(bytes32 indexed escrowId, address indexed disputer);
    event EscrowRefunded(bytes32 indexed escrowId, uint256 amount);
    event ArbitratorChanged(address indexed newArbitrator);
    
    constructor(address _arbitrator) {
        arbitrator = _arbitrator;
    }
    
    /// @notice Create a new escrow
    /// @param seller Seller agent address
    /// @param deadline Deadline for completion
    /// @param metadata Transaction metadata
    /// @return escrowId The escrow identifier
    function createEscrow(
        address seller,
        uint256 deadline,
        string calldata metadata
    ) external payable returns (bytes32 escrowId) {
        require(msg.value > 0, "Zero amount");
        require(seller != address(0), "Invalid seller");
        require(seller != msg.sender, "Self-escrow");
        require(deadline > block.timestamp, "Invalid deadline");
        
        // Generate escrow ID
        escrowId = keccak256(abi.encodePacked(
            msg.sender,
            seller,
            msg.value,
            block.timestamp,
            escrowList.length
        ));
        
        // Store escrow terms
        escrows[escrowId] = EscrowTerms({
            buyer: msg.sender,
            seller: seller,
            amount: msg.value,
            deadline: deadline,
            metadata: metadata,
            state: EscrowState.Funded,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        escrowList.push(escrowId);
        
        emit EscrowCreated(escrowId, msg.sender, seller, msg.value);
        emit EscrowFunded(escrowId, msg.value);
    }
    
    /// @notice Complete escrow (release funds to seller)
    /// @dev Only buyer can complete before deadline
    function completeEscrow(bytes32 escrowId) external {
        EscrowTerms storage escrow = escrows[escrowId];
        
        require(escrow.buyer == msg.sender, "Not buyer");
        require(escrow.state == EscrowState.Funded, "Invalid state");
        require(block.timestamp <= escrow.deadline, "Deadline passed");
        
        // Transfer funds to seller
        (bool success, ) = escrow.seller.call{value: escrow.amount}("");
        require(success, "Transfer failed");
        
        escrow.state = EscrowState.Completed;
        escrow.completedAt = block.timestamp;
        
        emit EscrowCompleted(escrowId, escrow.amount);
    }
    
    /// @notice Raise dispute
    /// @dev Only buyer or seller can dispute
    function disputeEscrow(bytes32 escrowId) external {
        EscrowTerms storage escrow = escrows[escrowId];
        
        require(
            msg.sender == escrow.buyer || msg.sender == escrow.seller,
            "Not authorized"
        );
        require(escrow.state == EscrowState.Funded, "Invalid state");
        require(block.timestamp <= escrow.deadline, "Deadline passed");
        
        escrow.state = EscrowState.Disputed;
        disputes[escrowId] = true;
        
        emit EscrowDisputed(escrowId, msg.sender);
    }
    
    /// @notice Resolve dispute (arbitrator only)
    /// @param escrowId Escrow to resolve
    /// @param refundToBuyer Whether to refund to buyer (true) or release to seller (false)
    function resolveDispute(bytes32 escrowId, bool refundToBuyer) external {
        require(msg.sender == arbitrator, "Not arbitrator");
        
        EscrowTerms storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Disputed, "Not disputed");
        
        if (refundToBuyer) {
            // Refund to buyer
            (bool success, ) = escrow.buyer.call{value: escrow.amount}("");
            require(success, "Transfer failed");
            
            escrow.state = EscrowState.Refunded;
            emit EscrowRefunded(escrowId, escrow.amount);
        } else {
            // Release to seller
            (bool success, ) = escrow.seller.call{value: escrow.amount}("");
            require(success, "Transfer failed");
            
            escrow.state = EscrowState.Completed;
            escrow.completedAt = block.timestamp;
            emit EscrowCompleted(escrowId, escrow.amount);
        }
    }
    
    /// @notice Refund expired escrow (anyone can call after deadline)
    /// @dev VULNERABILITY: No check if already completed
    function refundExpiredEscrow(bytes32 escrowId) external {
        EscrowTerms storage escrow = escrows[escrowId];
        
        require(escrow.state == EscrowState.Funded, "Invalid state");
        require(block.timestamp > escrow.deadline, "Deadline not passed");
        
        // VULNERABILITY: No state update before transfer (reentrancy)
        (bool success, ) = escrow.buyer.call{value: escrow.amount}("");
        require(success, "Transfer failed");
        
        escrow.state = EscrowState.Refunded;
        
        emit EscrowRefunded(escrowId, escrow.amount);
    }
    
    /// @notice Change arbitrator
    function setArbitrator(address newArbitrator) external {
        require(msg.sender == arbitrator, "Not arbitrator");
        arbitrator = newArbitrator;
        emit ArbitratorChanged(newArbitrator);
    }
    
    /// @notice Get escrow details
    function getEscrow(bytes32 escrowId) external view returns (
        address buyer,
        address seller,
        uint256 amount,
        uint256 deadline,
        EscrowState state
    ) {
        EscrowTerms storage escrow = escrows[escrowId];
        return (
            escrow.buyer,
            escrow.seller,
            escrow.amount,
            escrow.deadline,
            escrow.state
        );
    }
    
    /// @notice Get escrow count
    function getEscrowCount() external view returns (uint256) {
        return escrowList.length;
    }
    
    receive() external payable {}
}
