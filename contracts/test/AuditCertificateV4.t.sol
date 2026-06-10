// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../AuditCertificate.sol";
import "../ART.sol";

contract MockEAS {
    mapping(bytes32 => Attestation) public attestations;
    mapping(bytes32 => bool) public valid;

    bytes32 constant ZERO_B32 = 0x0000000000000000000000000000000000000000000000000000000000000000;

    function createAttestation(
        bytes32 uid, address recipient, uint8 auditScore, uint16 vulnsFound,
        string memory auditMode, uint64 timestamp, address contractAddr
    ) external {
        bytes memory data = abi.encode(auditScore, vulnsFound, auditMode, timestamp, contractAddr);
        attestations[uid] = Attestation({
            uid: uid, schema: ZERO_B32, time: uint64(block.timestamp), expirationTime: 0,
            revocable: true, refUID: ZERO_B32, recipient: recipient,
            attester: msg.sender, data: data
        });
        valid[uid] = true;
    }

    function getAttestation(bytes32 uid) external view returns (Attestation memory) { return attestations[uid]; }
    function isAttestationValid(bytes32 uid) external view returns (bool) { return valid[uid]; }
}

// ========================================================
// AuditCertificate v4 Tests
// ========================================================
contract AuditCertificateV4Test is Test {
    AuditCertificate public cert;
    MockEAS public eas;
    ART public art;

    address user1 = address(0x1);
    address user2 = address(0x2);
    address contractAddr = address(0xdead);

    bytes32 att1 = keccak256("att1");
    bytes32 att2 = keccak256("att2");
    bytes32 att3 = keccak256("att3");
    bytes32 att4 = keccak256("att4");
    bytes32 att5 = keccak256("att5");
    bytes32 att6 = keccak256("att6");

    function setUp() public {
        eas = new MockEAS();
        cert = new AuditCertificate(address(eas));
        art = new ART();

        // score=1→Gold, score=3→Silver, score=5→Silver, score=7→Bronze, score=10→Bronze, score=2→Gold
        eas.createAttestation(att1, user1, 1, 3, "full", uint64(block.timestamp), contractAddr);
        eas.createAttestation(att2, user1, 3, 2, "full", uint64(block.timestamp), contractAddr);
        eas.createAttestation(att3, user2, 5, 1, "full", uint64(block.timestamp), contractAddr);
        eas.createAttestation(att4, user2, 7, 1, "quick", uint64(block.timestamp), contractAddr);
        eas.createAttestation(att5, user1, 10, 0, "quick", uint64(block.timestamp), contractAddr);
        eas.createAttestation(att6, user2, 2, 5, "full", uint64(block.timestamp), contractAddr);
    }

    // ============ Basics ============

    function test_eas_address() public view {
        assertEq(cert.easContract(), address(eas));
    }

    function test_ownership() public view {
        assertEq(cert.owner(), address(this));
    }

    function test_token_names() public {
        cert = new AuditCertificate(address(eas));
        assertTrue(keccak256(bytes(cert.name(0))) == keccak256("Athena S (Rainbow)"));
        assertTrue(keccak256(bytes(cert.name(1))) == keccak256("Athena A (Gold)"));
        assertTrue(keccak256(bytes(cert.name(2))) == keccak256("Athena B (Silver)"));
        assertTrue(keccak256(bytes(cert.name(3))) == keccak256("Athena C (Bronze)"));
    }

    // ============ Combinations ============

    function test_combinations() public view {
        assertEq(cert.getCombinations(), 262144); // 4^9
    }

    function test_exceeds_12000() public view {
        assertTrue(cert.getCombinations() >= 12000);
    }

    // ============ Seed & Rarity ============

    function test_decode_seed() public view {
        // seed = bg=1, body=2, eyes=3, crown=0, wings=1, aura=2, badge=3, texture=0, acc=1
        uint256 seed = 1 | (2 << 2) | (3 << 4) | (0 << 6) | (1 << 8) | (2 << 10) | (3 << 12) | (0 << 14) | (1 << 16);
        uint8[9] memory t = cert.decodeSeed(seed);
        assertEq(t[0], 1); // bg
        assertEq(t[1], 2); // body
        assertEq(t[2], 3); // eyes
        assertEq(t[3], 0); // crown
        assertEq(t[4], 1); // wings
        assertEq(t[5], 2); // aura
        assertEq(t[6], 3); // badge
        assertEq(t[7], 0); // texture
        assertEq(t[8], 1); // acc
    }

    function test_decode_seed_all_zero() public view {
        uint8[9] memory t = cert.decodeSeed(0);
        for (uint256 i = 0; i < 9; i++) assertEq(t[i], 0);
    }

    function test_decode_seed_all_max() public view {
        // All 3s: 0x3FFFF = 262143
        uint256 seed = 3 | (3 << 2) | (3 << 4) | (3 << 6) | (3 << 8) | (3 << 10) | (3 << 12) | (3 << 14) | (3 << 16);
        uint8[9] memory t = cert.decodeSeed(seed);
        for (uint256 i = 0; i < 9; i++) assertEq(t[i], 3);
    }

    function test_rarity_positive() public view {
        uint256 r = cert.getRarity(0);
        assertTrue(r > 0);
    }

    function test_rarity_all_rare_higher() public view {
        uint256 rCommon = cert.getRarity(0); // all 0s
        uint256 seedRare = 3 | (3 << 2) | (3 << 4) | (3 << 6) | (3 << 8) | (3 << 10) | (3 << 12) | (3 << 14) | (3 << 16);
        uint256 rRare = cert.getRarity(seedRare);
        assertTrue(rRare > rCommon, "rare seed should score higher");
    }

    function test_tier_s() public view {
        // All-3 seed should be S-tier
        uint256 seedRare = 3 | (3 << 2) | (3 << 4) | (3 << 6) | (3 << 8) | (3 << 10) | (3 << 12) | (3 << 14) | (3 << 16);
        uint8 tier = cert.getTierFromScore(cert.getRarity(seedRare));
        assertEq(tier, 0); // S
    }

    function test_tier_c() public view {
        uint8 tier = cert.getTierFromScore(cert.getRarity(0)); // all 0s
        assertTrue(tier >= 2, "all-0 should be B or C");
    }

    // ============ EAS Minting ============

    function test_mint_gold_via_eas() public {
        cert.mintCertificate(user1, att1);
        assertEq(cert.balanceOf(user1, 1), 1);
        assertTrue(cert.isAttestationUsed(att1));
    }

    function test_mint_silver_via_eas() public {
        cert.mintCertificate(user1, att2);
        // score=3 → Silver (tier 2)
        assertEq(cert.balanceOf(user1, 2), 1);
    }

    function test_mint_bronze_via_eas() public {
        cert.mintCertificate(user2, att4);
        // score=7 → Bronze (tier 3)
        assertEq(cert.balanceOf(user2, 3), 1);
    }

    function test_cannot_double_mint() public {
        cert.mintCertificate(user1, att1);
        bool reverted = false;
        try cert.mintCertificate(user2, att1) {} catch { reverted = true; }
        assertTrue(reverted);
    }

    function test_zero_uid_reverts() public {
        bool reverted = false;
        try cert.mintCertificate(user1, bytes32(0)) {} catch { reverted = true; }
        assertTrue(reverted);
    }

    function test_invalid_attestation_reverts() public {
        bool reverted = false;
        try cert.mintCertificate(user1, keccak256("invalid")) {} catch { reverted = true; }
        assertTrue(reverted);
    }

    // ============ Test Mint (owner) ============

    function test_mint_test() public {
        cert.mintTest(user1, 1);
        uint256 bal = cert.balanceOf(user1, 0) + cert.balanceOf(user1, 1) + cert.balanceOf(user1, 2) + cert.balanceOf(user1, 3);
        assertEq(bal, 1);
    }

    function test_mint_test_s_tier() public {
        cert.mintTest(user1, 0);
        assertEq(cert.balanceOf(user1, 0), 1);
    }

    // ============ URI ============

    function test_uri_returns_base64() public {
        cert.mintTest(user1, 1);
        string memory u = cert.uri(1);
        assertTrue(bytes(u).length > 50);
        // Should start with data:application/json;base64,
        _assertPrefix(u, "data:application/json;base64,");
    }

    function test_uri_invalid_id_reverts() public {
        bool reverted = false;
        try cert.uri(4) {} catch { reverted = true; }
        assertTrue(reverted);
    }

    // ============ SVG Cache ============

    function test_cache_svg() public {
        uint256 seed = 1 | (2 << 2) | (3 << 4);
        cert.cacheSVG(seed);
        // After caching, uri() should work and use cache
    }

    // ============ ART Token ============

    function test_art_mint() public {
        art.mintForAudit(user1);
        assertEq(art.balanceOf(user1), 1000 ether);
        assertEq(art.auditCount(user1), 1);
    }

    function test_art_multiple_mints() public {
        art.mintForAudit(user1);
        art.mintForAudit(user1);
        assertEq(art.balanceOf(user1), 2000 ether);
        assertEq(art.auditCount(user1), 2);
    }

    function test_art_burn() public {
        art.mintForAudit(user1);
        // user1 has 1000, burn 500
        vm.prank(user1);
        art.burn(500 ether);
        assertEq(art.balanceOf(user1), 500 ether);
    }

    function test_art_eligible() public {
        assertFalse(art.eligibleForNFT(user1));
        art.mintForAudit(user1);
        assertTrue(art.eligibleForNFT(user1));
    }

    function test_art_name() public view {
        assertEq(art.name(), "Athena Reputation Token");
        assertEq(art.symbol(), "ART");
    }

    function test_art_batch_mint() public {
        address[] memory auditors = new address[](2);
        auditors[0] = user1;
        auditors[1] = user2;
        art.mintForAudits(auditors);
        assertEq(art.balanceOf(user1), 1000 ether);
        assertEq(art.balanceOf(user2), 1000 ether);
    }

    // ============ Helpers ============

    function _assertPrefix(string memory s, string memory prefix) internal pure {
        bytes memory sb = bytes(s);
        bytes memory pb = bytes(prefix);
        require(sb.length >= pb.length, "too short");
        for (uint256 i = 0; i < pb.length; i++) {
            require(sb[i] == pb[i], "prefix mismatch");
        }
    }
}
