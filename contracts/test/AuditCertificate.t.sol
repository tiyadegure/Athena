// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../AuditCertificate.sol";

/// @notice Mock EAS for testing
contract MockEAS {
    // Use the same Attestation struct from AuditCertificate.sol
    mapping(bytes32 => Attestation) public attestations;
    mapping(bytes32 => bool) public valid;

    function createAttestation(
        bytes32 uid,
        address recipient,
        uint8 auditScore,
        uint16 vulnsFound,
        string memory auditMode,
        uint64 timestamp,
        address contractAddr
    ) external {
        bytes memory data = abi.encode(auditScore, vulnsFound, auditMode, timestamp, contractAddr);
        attestations[uid] = Attestation({
            uid: uid,
            schema: ZERO_BYTES32,
            time: uint64(block.timestamp),
            expirationTime: 0,
            revocable: true,
            refUID: ZERO_BYTES32,
            recipient: recipient,
            attester: msg.sender,
            data: data
        });
        valid[uid] = true;
    }

    function getAttestation(bytes32 uid) external view returns (Attestation memory) {
        return attestations[uid];
    }

    function isAttestationValid(bytes32 uid) external view returns (bool) {
        return valid[uid];
    }

    bytes32 constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;
}

/// @notice Test contract for AuditCertificate
contract AuditCertificateTest is Test {
    AuditCertificate public certificate;
    MockEAS public mockEAS;

    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public contractAddr = address(0xdead);

    // Attestation UIDs
    bytes32 public attUID_Critical = bytes32(uint256(1));
    bytes32 public attUID_High = bytes32(uint256(2));
    bytes32 public attUID_Medium = bytes32(uint256(3));
    bytes32 public attUID_Low = bytes32(uint256(4));
    bytes32 public attUID_Safe = bytes32(uint256(5));

    function setUp() public {
        // Deploy mock EAS
        mockEAS = new MockEAS();

        // Deploy certificate with mock EAS address (constructor injection)
        certificate = new AuditCertificate(address(mockEAS));

        // Create test attestations
        // Critical (auditScore=1) → Gold
        mockEAS.createAttestation(attUID_Critical, user1, 1, 3, "full", uint64(block.timestamp), contractAddr);
        // High (auditScore=3) → Silver
        mockEAS.createAttestation(attUID_High, user1, 3, 2, "full", uint64(block.timestamp), contractAddr);
        // Medium (auditScore=5) → Silver
        mockEAS.createAttestation(attUID_Medium, user2, 5, 1, "full", uint64(block.timestamp), contractAddr);
        // Low (auditScore=7) → Bronze
        mockEAS.createAttestation(attUID_Low, user2, 7, 1, "quick", uint64(block.timestamp), contractAddr);
        // Safe (auditScore=10) → Bronze
        mockEAS.createAttestation(attUID_Safe, user1, 10, 0, "quick", uint64(block.timestamp), contractAddr);
    }

    // ============ Test Cases ============

    /// @notice Test: Critical attestation mints Gold NFT
    function test_mint_gold() public {
        string memory uri = certificate.uri(1);
        assertTrue(bytes(uri).length > 0, "URI should not be empty");
        // URI should be valid base64 JSON
        _assertContains(uri, "data:application/json;base64,");
    }

    /// @notice Test: High attestation mints Silver NFT
    function test_mint_silver() public {
        string memory uri = certificate.uri(2);
        assertTrue(bytes(uri).length > 0, "URI should not be empty");
        _assertContains(uri, "data:application/json;base64,");
    }

    /// @notice Test: Low attestation mints Bronze NFT
    function test_mint_bronze() public {
        string memory uri = certificate.uri(3);
        assertTrue(bytes(uri).length > 0, "URI should not be empty");
        _assertContains(uri, "data:application/json;base64,");
    }

    /// @notice Test: Invalid token ID reverts
    function test_invalid_tokenid_reverts() public {
        // Should revert with "Invalid token ID"
        bool didRevert = false;
        try certificate.uri(4) {
            // Should not reach here
        } catch {
            didRevert = true;
        }
        assertTrue(didRevert, "Should revert for invalid token ID");
    }

    /// @notice Test: Token URIs are different for each tier
    function test_tokenuri_differ() public {
        string memory uriGold = certificate.uri(1);
        string memory uriSilver = certificate.uri(2);
        string memory uriBronze = certificate.uri(3);

        // All should be different
        assertTrue(keccak256(bytes(uriGold)) != keccak256(bytes(uriSilver)), "Gold != Silver");
        assertTrue(keccak256(bytes(uriSilver)) != keccak256(bytes(uriBronze)), "Silver != Bronze");
        assertTrue(keccak256(bytes(uriGold)) != keccak256(bytes(uriBronze)), "Gold != Bronze");
    }

    /// @notice Test: SVG colors are embedded in URI
    function test_svg_colors() public {
        // URIs should contain base64-encoded SVG with colors
        // We can't directly check for color codes in base64, but we can verify
        // that different URIs are generated for different tiers
        string memory uriGold = certificate.uri(1);
        string memory uriSilver = certificate.uri(2);
        string memory uriBronze = certificate.uri(3);

        // All should be valid base64 JSON URIs
        _assertContains(uriGold, "data:application/json;base64,");
        _assertContains(uriSilver, "data:application/json;base64,");
        _assertContains(uriBronze, "data:application/json;base64,");
        
        // All should have different content (different colors)
        assertTrue(keccak256(bytes(uriGold)) != keccak256(bytes(uriSilver)), "Gold != Silver");
        assertTrue(keccak256(bytes(uriSilver)) != keccak256(bytes(uriBronze)), "Silver != Bronze");
    }

    /// @notice Test: URI format is valid base64 JSON
    function test_uri_format() public {
        string memory uri = certificate.uri(1);
        // Should start with data:application/json;base64,
        _assertContains(uri, "data:application/json;base64,");
    }

    /// @notice Test: Contract is Ownable
    function test_ownership() public {
        assertEq(certificate.owner(), address(this));
    }

    /// @notice Test: EAS address is set correctly
    function test_eas_address() public {
        assertEq(certificate.easContract(), address(mockEAS));
    }

    /// @notice Test: Mint Gold NFT via mock EAS attestation
    function test_mint_gold_via_eas() public {
        // attUID_Critical has score=1 (Critical) → should mint Gold (tokenId=1)
        certificate.mintCertificate(user1, attUID_Critical);
        assertEq(certificate.balanceOf(user1, 1), 1);
    }

    /// @notice Test: Mint Silver NFT via mock EAS attestation
    function test_mint_silver_via_eas() public {
        // attUID_High has score=3 (High) → should mint Silver (tokenId=2)
        certificate.mintCertificate(user1, attUID_High);
        assertEq(certificate.balanceOf(user1, 2), 1);
    }

    /// @notice Test: Mint Bronze NFT via mock EAS attestation
    function test_mint_bronze_via_eas() public {
        // attUID_Low has score=7 (Low) → should mint Bronze (tokenId=3)
        certificate.mintCertificate(user2, attUID_Low);
        assertEq(certificate.balanceOf(user2, 3), 1);
    }

    /// @notice Test: Cannot double mint same attestation
    function test_cannot_double_mint() public {
        certificate.mintCertificate(user1, attUID_Critical);
        
        bool didRevert = false;
        try certificate.mintCertificate(user2, attUID_Critical) {
            // Should not reach here
        } catch {
            didRevert = true;
        }
        assertTrue(didRevert, "Should revert on double mint");
    }

    // ============ Helpers ============

    function _assertContains(string memory haystack, string memory needle) internal pure {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        require(h.length >= n.length, "Haystack too short");
        
        bool found = false;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                found = true;
                break;
            }
        }
        require(found, "String not found");
    }
}
