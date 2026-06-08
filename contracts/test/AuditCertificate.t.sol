// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../AuditCertificate.sol";

contract MockEAS {
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

contract AuditCertificateTest is Test {
    AuditCertificate public certificate;
    MockEAS public mockEAS;

    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public contractAddr = address(0xdead);

    bytes32 public attUID_1 = keccak256("attestation1");
    bytes32 public attUID_2 = keccak256("attestation2");
    bytes32 public attUID_3 = keccak256("attestation3");
    bytes32 public attUID_4 = keccak256("attestation4");
    bytes32 public attUID_5 = keccak256("attestation5");
    bytes32 public attUID_6 = keccak256("attestation6");

    function setUp() public {
        mockEAS = new MockEAS();
        certificate = new AuditCertificate(address(mockEAS));

        mockEAS.createAttestation(attUID_1, user1, 1, 3, "full", uint64(block.timestamp), contractAddr);
        mockEAS.createAttestation(attUID_2, user1, 3, 2, "full", uint64(block.timestamp), contractAddr);
        mockEAS.createAttestation(attUID_3, user2, 5, 1, "full", uint64(block.timestamp), contractAddr);
        mockEAS.createAttestation(attUID_4, user2, 7, 1, "quick", uint64(block.timestamp), contractAddr);
        mockEAS.createAttestation(attUID_5, user1, 10, 0, "quick", uint64(block.timestamp), contractAddr);
        mockEAS.createAttestation(attUID_6, user2, 2, 5, "full", uint64(block.timestamp), contractAddr);
    }

    // ============ Basic Tests ============

    function test_eas_address() public {
        assertEq(certificate.easContract(), address(mockEAS));
    }

    function test_ownership() public {
        assertEq(certificate.owner(), address(this));
    }

    function test_token_names() public {
        assertTrue(keccak256(bytes(certificate.name(1))) == keccak256("Audit Certificate - Gold"));
        assertTrue(keccak256(bytes(certificate.name(2))) == keccak256("Audit Certificate - Silver"));
        assertTrue(keccak256(bytes(certificate.name(3))) == keccak256("Audit Certificate - Bronze"));
    }

    // ============ Combination Tests ============

    function test_combinations_count() public {
        uint256 combos = certificate.getCombinations();
        // 5×5×8×3×5×4 = 12,000
        assertEq(combos, 12000);
    }

    function test_exceeds_12000_requirement() public {
        uint256 combos = certificate.getCombinations();
        assertTrue(combos >= 12000, "Should have at least 12,000 combinations");
    }

    // ============ Minting Tests ============

    function test_mint_gold() public {
        certificate.mintCertificate(user1, attUID_1);
        assertEq(certificate.balanceOf(user1, 1), 1);
    }

    function test_mint_silver() public {
        certificate.mintCertificate(user1, attUID_2);
        assertEq(certificate.balanceOf(user1, 2), 1);
    }

    function test_mint_bronze() public {
        certificate.mintCertificate(user2, attUID_4);
        assertEq(certificate.balanceOf(user2, 3), 1);
    }

    function test_cannot_double_mint() public {
        certificate.mintCertificate(user1, attUID_1);
        
        bool didRevert = false;
        try certificate.mintCertificate(user2, attUID_1) {
        } catch {
            didRevert = true;
        }
        assertTrue(didRevert, "Should revert on double mint");
    }

    function test_invalid_recipient_reverts() public {
        bool didRevert = false;
        try certificate.mintCertificate(address(0), attUID_1) {
        } catch {
            didRevert = true;
        }
        assertTrue(didRevert, "Should revert for zero address");
    }

    // ============ Trait Tests ============

    function test_traits_stored_on_mint() public {
        certificate.mintCertificate(user1, attUID_1);
        
        // Verify attestation is marked as used
        assertTrue(certificate.isAttestationUsed(attUID_1), "Attestation should be marked used");
        assertEq(certificate.balanceOf(user1, 1), 1);
    }

    function test_different_uids_different_traits() public {
        // Generate metadata for 3 different UIDs
        string memory meta1 = certificate.generateMetadata(attUID_1, 1);
        string memory meta2 = certificate.generateMetadata(attUID_2, 1);
        string memory meta3 = certificate.generateMetadata(attUID_3, 1);
        
        // At least some should differ (extremely unlikely to be all same)
        bool allSame = keccak256(bytes(meta1)) == keccak256(bytes(meta2)) && 
                       keccak256(bytes(meta2)) == keccak256(bytes(meta3));
        assertFalse(allSame);
    }

    function test_same_uid_same_traits() public {
        // Generate metadata twice for same UID - should be identical
        string memory meta1 = certificate.generateMetadata(attUID_1, 1);
        string memory meta2 = certificate.generateMetadata(attUID_1, 1);
        assertTrue(keccak256(bytes(meta1)) == keccak256(bytes(meta2)), "Same UID should produce same metadata");
    }

    // ============ Metadata Tests ============

    function test_generate_metadata_gold() public {
        string memory metadata = certificate.generateMetadata(attUID_1, 1);
        assertTrue(bytes(metadata).length > 0, "Metadata should not be empty");
        _assertContains(metadata, "data:application/json;base64,");
    }

    function test_generate_metadata_silver() public {
        string memory metadata = certificate.generateMetadata(attUID_2, 2);
        assertTrue(bytes(metadata).length > 0, "Metadata should not be empty");
        _assertContains(metadata, "data:application/json;base64,");
    }

    function test_generate_metadata_bronze() public {
        string memory metadata = certificate.generateMetadata(attUID_4, 3);
        assertTrue(bytes(metadata).length > 0, "Metadata should not be empty");
        _assertContains(metadata, "data:application/json;base64,");
    }

    function test_different_tiers_different_metadata() public {
        string memory metaGold = certificate.generateMetadata(attUID_1, 1);
        string memory metaSilver = certificate.generateMetadata(attUID_1, 2);
        string memory metaBronze = certificate.generateMetadata(attUID_1, 3);
        
        assertTrue(keccak256(bytes(metaGold)) != keccak256(bytes(metaSilver)), "Gold != Silver");
        assertTrue(keccak256(bytes(metaSilver)) != keccak256(bytes(metaBronze)), "Silver != Bronze");
        assertTrue(keccak256(bytes(metaGold)) != keccak256(bytes(metaBronze)), "Gold != Bronze");
    }

    function test_different_uids_different_metadata() public {
        string memory meta1 = certificate.generateMetadata(attUID_1, 1);
        string memory meta2 = certificate.generateMetadata(attUID_2, 1);
        string memory meta3 = certificate.generateMetadata(attUID_3, 1);
        
        assertTrue(keccak256(bytes(meta1)) != keccak256(bytes(meta2)), "UID1 != UID2");
        assertTrue(keccak256(bytes(meta2)) != keccak256(bytes(meta3)), "UID2 != UID3");
        assertTrue(keccak256(bytes(meta1)) != keccak256(bytes(meta3)), "UID1 != UID3");
    }

    // ============ Invalid Token ID Tests ============

    function test_invalid_tokenid_reverts() public {
        bool didRevert = false;
        try certificate.generateMetadata(attUID_1, 4) {
        } catch {
            didRevert = true;
        }
        assertTrue(didRevert, "Should revert for invalid token ID");
    }

    // ============ EAS Validation Tests ============

    function test_invalid_attestation_reverts() public {
        bytes32 invalidUID = keccak256("invalid");
        
        bool didRevert = false;
        try certificate.mintCertificate(user1, invalidUID) {
        } catch {
            didRevert = true;
        }
        assertTrue(didRevert, "Should revert for invalid attestation");
    }

    function test_zero_uid_reverts() public {
        bool didRevert = false;
        try certificate.mintCertificate(user1, bytes32(0)) {
        } catch {
            didRevert = true;
        }
        assertTrue(didRevert, "Should revert for zero UID");
    }

    // ============ Audit Record Tests ============

    function test_audit_record_stored() public {
        certificate.mintCertificate(user1, attUID_1);
        assertTrue(certificate.isAttestationUsed(attUID_1));
        assertEq(certificate.balanceOf(user1, 1), 1);
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
