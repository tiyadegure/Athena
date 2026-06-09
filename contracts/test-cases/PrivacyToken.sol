// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title PrivacyToken - EIP-8287 Privacy-Native Fungible Token (pERC20)
/// @notice Privacy-native ERC20 with encrypted transfers
/// @dev Simplified implementation for audit testing
/// @dev Real implementation would use ZK proofs (e.g., Semaphore, Tornado Cash style)

/// @notice Encrypted balance commitment
struct Commitment {
    bytes32 valueHash;      // Hash of (value, secret)
    uint256 nullifier;      // Prevents double-spending
    bool spent;             // Whether this commitment is spent
}

/// @title PrivacyToken - pERC20 implementation
contract PrivacyToken {
    string public name = "Privacy Token";
    string public symbol = "pERC20";
    uint8 public decimals = 18;
    
    // Public total supply (for compatibility)
    uint256 public totalSupply;
    
    // Commitment tree (Merkle tree of commitments)
    bytes32 public merkleRoot;
    mapping(bytes32 => bool) public knownRoots;
    
    // Nullifier set (prevents double-spending)
    mapping(uint256 => bool) public nullifiers;
    
    // Commitment registry
    mapping(bytes32 => Commitment) public commitments;
    bytes32[] public commitmentList;
    
    // Events
    event Deposit(address indexed depositor, bytes32 commitment, uint256 amount);
    event Transfer(bytes32[] oldCommitments, bytes32[] newCommitments, bytes32 proof);
    event Withdraw(address indexed recipient, uint256 amount, uint256 nullifier);
    event MerkleRootUpdated(bytes32 newRoot);
    
    // VULNERABILITY: Admin can manipulate merkle root
    address public owner;
    
    constructor() {
        owner = msg.sender;
        _updateMerkleRoot();
    }
    
    /// @notice Deposit tokens to get private commitments
    /// @param amount Amount to deposit
    /// @param secret Secret for commitment generation
    function deposit(uint256 amount, uint256 secret) external {
        require(amount > 0, "Zero amount");
        
        // Create commitment
        bytes32 commitment = _createCommitment(amount, secret);
        
        // Store commitment
        commitments[commitment] = Commitment({
            valueHash: keccak256(abi.encodePacked(amount, secret)),
            nullifier: 0,
            spent: false
        });
        
        commitmentList.push(commitment);
        
        // Update total supply
        totalSupply += amount;
        
        // Update merkle root
        _updateMerkleRoot();
        
        emit Deposit(msg.sender, commitment, amount);
    }
    
    /// @notice Private transfer using commitments
    /// @dev VULNERABLE: No ZK proof verification (simplified)
    function transfer(
        bytes32[] calldata oldCommitments,
        bytes32[] calldata newCommitments,
        uint256[] calldata amounts,
        uint256[] calldata secrets,
        bytes calldata proof
    ) external {
        // VULNERABILITY: Should verify ZK proof but doesn't
        // In a real implementation, this would verify a ZK proof
        
        // Mark old commitments as spent
        for (uint256 i = 0; i < oldCommitments.length; i++) {
            require(commitments[oldCommitments[i]].valueHash != bytes32(0), "Invalid commitment");
            require(!commitments[oldCommitments[i]].spent, "Already spent");
            commitments[oldCommitments[i]].spent = true;
        }
        
        // Create new commitments
        for (uint256 i = 0; i < newCommitments.length; i++) {
            bytes32 commitment = _createCommitment(amounts[i], secrets[i]);
            require(commitment == newCommitments[i], "Invalid commitment");
            
            commitments[commitment] = Commitment({
                valueHash: keccak256(abi.encodePacked(amounts[i], secrets[i])),
                nullifier: 0,
                spent: false
            });
            
            commitmentList.push(commitment);
        }
        
        // Update merkle root
        _updateMerkleRoot();
        
        // Convert proof to bytes32
        bytes32 proofHash = keccak256(proof);
        
        emit Transfer(oldCommitments, newCommitments, proofHash);
    }
    
    /// @notice Withdraw from private to public
    /// @param amount Amount to withdraw
    /// @param secret Secret used in commitment
    /// @param nullifier Nullifier to prevent double-spending
    function withdraw(uint256 amount, uint256 secret, uint256 nullifier) external {
        bytes32 commitment = _createCommitment(amount, secret);
        
        require(commitments[commitment].valueHash != bytes32(0), "Invalid commitment");
        require(!commitments[commitment].spent, "Already spent");
        require(!nullifiers[nullifier], "Nullifier already used");
        
        // Mark as spent
        commitments[commitment].spent = true;
        nullifiers[nullifier] = true;
        
        // Transfer tokens (simplified - in reality would be more complex)
        totalSupply -= amount;
        
        emit Withdraw(msg.sender, amount, nullifier);
    }
    
    /// @notice VULNERABLE: Admin can update merkle root
    /// @dev This is a vulnerability - allows manipulation
    function updateMerkleRoot(bytes32 newRoot) external {
        require(msg.sender == owner, "Not owner");
        merkleRoot = newRoot;
        knownRoots[newRoot] = true;
        emit MerkleRootUpdated(newRoot);
    }
    
    /// @notice Check if a commitment exists
    function hasCommitment(bytes32 commitment) external view returns (bool) {
        return commitments[commitment].valueHash != bytes32(0);
    }
    
    /// @notice Check if a nullifier is used
    function isNullifierUsed(uint256 nullifier) external view returns (bool) {
        return nullifiers[nullifier];
    }
    
    /// @notice Get commitment count
    function getCommitmentCount() external view returns (uint256) {
        return commitmentList.length;
    }
    
    // ============ Internal Functions ============
    
    function _createCommitment(uint256 amount, uint256 secret) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(amount, secret));
    }
    
    function _updateMerkleRoot() internal {
        // Simplified merkle root calculation
        // In production, use a proper Merkle tree library
        if (commitmentList.length == 0) {
            merkleRoot = bytes32(0);
        } else if (commitmentList.length == 1) {
            merkleRoot = commitmentList[0];
        } else {
            // Simple hash chain (not a real Merkle tree, but demonstrates the concept)
            bytes32 current = commitmentList[0];
            for (uint256 i = 1; i < commitmentList.length; i++) {
                current = keccak256(abi.encodePacked(current, commitmentList[i]));
            }
            merkleRoot = current;
        }
        
        knownRoots[merkleRoot] = true;
    }
}
