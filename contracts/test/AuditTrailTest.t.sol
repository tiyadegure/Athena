// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../AuditTrail.sol";
import "../ZKVerifier.sol";

contract AuditTrailTest is Test {
    Groth16Verifier public verifier;
    AuditTrail public trail;

    function setUp() public {
        verifier = new Groth16Verifier();
        trail = new AuditTrail(address(verifier));
    }

    function test_submit_proof() public {
        // Real proof from circom circuit (8-step audit trail)
        uint256[2] memory a = [
            0x1ff91667c5d37a02e7a66479590ab60fb0e4ba5b29e8fb238eb13aa2130cf6ee,
            0x04a67c3ac3350f9b14d4dff2952bf76c1e06773b138760c6a74d1de70bb4af47
        ];
        uint256[2][2] memory b = [
            [0x197332a611674aa34bb5592e93594b82989987d462feef3f9eb7c24d02423248,
             0x0613e22d5b785b95c87fa0072295cfec40b7624507ce3a0ab9e175bb63ccac41],
            [0x2172ac3b3fb686e2c13155b0dd9c61e3778c3b26cd62073971982abfee43f1ff,
             0x2b0795feca5843cdf77a3e57739988349567492059d6646a0fe8543a3bb3e8ba]
        ];
        uint256[2] memory c = [
            0x2920f9bd48cc00f841d52aa56e87bd05a33a35ee4d779b2480225a61ea75cfce,
            0x19fb32ba4e6d1350f2aa1e69daa6c39780a27caf12ab216fe21fb75e74b54f93
        ];

        bytes32 uid = bytes32(uint256(1));
        bytes32 attestationUID = bytes32(uint256(0xdead));
        uint256 finalRoot = 1997222079909642731634426035341630674624782381618311407530302066084165613773;

        trail.submitProof(uid, finalRoot, attestationUID, a, b, c);

        assertTrue(trail.isAuditProven(uid), "Audit should be proven");
        assertEq(trail.proofCount(), 1);

        (uint256 fr, address auditor,, bytes32 att, bool verified) = trail.getProof(uid);
        assertEq(fr, finalRoot);
        assertEq(auditor, address(this));
        assertEq(att, attestationUID);
        assertTrue(verified);
    }

    function test_invalid_uid_reverts() public {
        bool reverted = false;
        try trail.submitProof(
            bytes32(0), 123, bytes32(0),
            [uint256(1), uint256(2)],
            [[uint256(3), uint256(4)], [uint256(5), uint256(6)]],
            [uint256(7), uint256(8)]
        ) {} catch { reverted = true; }
        // Will revert either from "Already submitted" or "Invalid ZK proof"
        assertTrue(reverted);
    }

    function test_proof_count_starts_zero() public view {
        assertEq(trail.proofCount(), 0);
    }

    function test_verifier_set() public view {
        assertEq(trail.verifier(), address(verifier));
    }
}
