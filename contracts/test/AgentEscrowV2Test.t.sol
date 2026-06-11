// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../AgentEscrowV2.sol";
import "../ERC7512AuditMetadata.sol";

contract MockEAS2 {
    mapping(bytes32 => bool) public valid;
    function setValid(bytes32 uid) external { valid[uid] = true; }
    function isAttestationValid(bytes32 uid) external view returns (bool) { return valid[uid]; }
    function getAttestation(bytes32 uid) external pure returns (Attestation memory) {
        return Attestation(uid, bytes32(0), 0, 0, true, bytes32(0), address(0), address(0), "");
    }
}

contract AgentEscrowV2Test is Test {
    AgentEscrowV2 public escrow;
    MockEAS2 public mockEAS;
    ERC7512AuditMetadata public metadata;

    address buyer = address(0x1);
    address seller = address(0x2);
    address arbitrator = address(this);

    function setUp() public {
        mockEAS = new MockEAS2();
        escrow = new AgentEscrowV2(address(mockEAS), arbitrator);
        metadata = new ERC7512AuditMetadata();
    }

    function test_create_escrow() public {
        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        bytes32 id = escrow.createEscrow{value: 1 ether}(seller, block.timestamp + 1 days, "Audit Vault.sol");
        assertTrue(escrow.getEscrowCount() == 1);
    }

    function test_complete_escrow() public {
        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        bytes32 id = escrow.createEscrow{value: 1 ether}(seller, block.timestamp + 1 days, "Audit Vault.sol");

        uint256 sellerBalBefore = seller.balance;
        vm.prank(buyer);
        escrow.completeEscrow(id);
        assertEq(seller.balance - sellerBalBefore, 1 ether);
    }

    function test_complete_with_attestation() public {
        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        bytes32 id = escrow.createEscrow{value: 1 ether}(seller, block.timestamp + 1 days, "Audit Vault.sol");

        bytes32 attUID = keccak256("attestation");
        mockEAS.setValid(attUID);

        uint256 sellerBalBefore = seller.balance;
        escrow.completeWithAttestation(id, attUID);
        assertEq(seller.balance - sellerBalBefore, 1 ether);
    }

    function test_refund_expired() public {
        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        bytes32 id = escrow.createEscrow{value: 1 ether}(seller, block.timestamp + 1 days, "Audit Vault.sol");

        vm.warp(block.timestamp + 2 days);
        uint256 buyerBalBefore = buyer.balance;
        escrow.refundExpiredEscrow(id);
        assertEq(buyer.balance - buyerBalBefore, 1 ether);
    }

    function test_register_audit() public {
        bytes32 uid = metadata.registerAudit(
            address(0xdead), seller, 1, 85, 5,
            bytes32(0), keccak256("report"), "full"
        );
        assertTrue(metadata.auditCount() == 1);
    }

    function test_get_contract_audits() public {
        metadata.registerAudit(address(0xdead), seller, 1, 85, 5, bytes32(0), keccak256("report"), "full");
        metadata.registerAudit(address(0xdead), seller, 2, 70, 3, bytes32(0), keccak256("report2"), "quick");
        bytes32[] memory audits = metadata.getContractAudits(address(0xdead));
        assertEq(audits.length, 2);
    }
}
