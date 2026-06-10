// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct Attestation { bytes32 uid; bytes32 schema; uint64 time; uint64 expirationTime; bool revocable; bytes32 refUID; address recipient; address attester; bytes data; }
interface IEAS { function getAttestation(bytes32) external view returns (Attestation memory); function isAttestationValid(bytes32) external view returns (bool); }

/// @title AuditCertificate v3 - ERC-1155 with S-tier
/// @dev 0=S(Rainbow), 1=Gold(A), 2=Silver(B), 3=Bronze(C)
/// @dev 9 traits: helmet(5) x shield(5) x color(8) x weapon(3) x bg(5) x eyes(4) x aura(4) x crown(4) x wings(4) = 768,000
contract AuditCertificate is ERC1155, Ownable {
    using Strings for uint256;
    uint256 public constant S_TIER = 0;
    uint256 public constant GOLD = 1;
    uint256 public constant SILVER = 2;
    uint256 public constant BRONZE = 3;

    struct TraitData { uint8 helmet; uint8 shield; uint8 color; uint8 weapon; uint8 background; uint8 eyes; uint8 aura; uint8 crown; uint8 wings; uint256 rarityScore; }

    address public immutable easContract;
    bytes32 public constant ZERO_BYTES32 = bytes32(0);
    mapping(bytes32 => bool) public usedAttestations;
    mapping(bytes32 => TraitData) public traitData;
    mapping(bytes32 => AuditRecord) public auditRecords;
    mapping(uint256 => bytes32) public tokenAttestation;

    struct AuditRecord { address contractAddress; address auditor; uint8 severity; uint256 timestamp; uint256 tokenId; }

    event CertificateMinted(address indexed to, bytes32 indexed attestationUID, uint256 tokenId, uint8 severity, TraitData traits);

    constructor(address _eas) ERC1155("") Ownable() { require(_eas != address(0)); easContract = _eas; }

    function mintTest(address to, uint8 tier) external onlyOwner {
        require(to != address(0) && tier <= 3);
        bytes32 uid = keccak256(abi.encodePacked(to, tier, block.timestamp));
        TraitData memory t = _selectTraits(uid);
        traitData[uid] = t;
        _mint(to, tier, 1, "");
        tokenAttestation[tier] = bytes32(uint256(uint160(to)));
        usedAttestations[uid] = true;
        auditRecords[uid] = AuditRecord(address(this), msg.sender, tier, block.timestamp, tier);
        emit CertificateMinted(to, uid, tier, tier, t);
    }

    function mintCertificate(address to, bytes32 uid) external {
        require(to != address(0) && uid != ZERO_BYTES32 && !usedAttestations[uid]);
        IEAS eas = IEAS(easContract);
        require(eas.isAttestationValid(uid));
        Attestation memory att = eas.getAttestation(uid);
        (uint8 score, , , uint64 ts, address ca) = abi.decode(att.data, (uint8, uint16, string, uint64, address));
        uint256 tid = score == 0 ? S_TIER : score <= 1 ? GOLD : score <= 5 ? SILVER : BRONZE;
        TraitData memory t = _selectTraits(uid);
        traitData[uid] = t;
        _mint(to, tid, 1, "");
        tokenAttestation[tid] = uid;
        usedAttestations[uid] = true;
        auditRecords[uid] = AuditRecord(ca, att.attester, score, ts, tid);
        emit CertificateMinted(to, uid, tid, score, t);
    }

    function _selectTraits(bytes32 uid) internal pure returns (TraitData memory) {
        bytes32 h = keccak256(abi.encodePacked(uid));
        uint8 a = uint8(h[6]) % 4; uint8 c = uint8(h[7]) % 4; uint8 w = uint8(h[8]) % 4;
        uint8 he = uint8(h[0]) % 5; uint8 sh = uint8(h[1]) % 5; uint8 co = uint8(h[2]) % 8;
        uint8 wp = uint8(h[3]) % 3; uint8 bg = uint8(h[4]) % 5; uint8 ey = uint8(h[5]) % 4;
        uint256 idx = uint256(he)*153600 + uint256(sh)*30720 + uint256(co)*3840 + uint256(wp)*1280 + uint256(bg)*256 + uint256(ey)*64 + uint256(a)*16 + uint256(c)*4 + uint256(w);
        return TraitData(he, sh, co, wp, bg, ey, a, c, w, 1 + idx * 99 / 767999);
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(id <= 3);
        bytes32 uid = tokenAttestation[id];
        if (uid != ZERO_BYTES32) return _meta(uid, id);
        return _meta(bytes32(uint256(uint160(msg.sender))), id);
    }

    function generateMetadata(bytes32 uid, uint256 id) public pure returns (string memory) {
        require(id <= 3);
        return _meta(uid, id);
    }

    function _meta(bytes32 uid, uint256 id) internal pure returns (string memory) {
        TraitData memory t = _selectTraits(uid);
        string memory svg = _svg(id, t);
        string[4] memory tn = ["S (Rainbow)", "A (Gold)", "B (Silver)", "C (Bronze)"];
        string memory json = string(abi.encodePacked(
            '{"name":"Athena #', _uint2str(uint256(uid) % 10000), '","tier":"', tn[id],
            '","rarity":', _uint2str(t.rarityScore),
            ',"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
        ));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // ============ Minimal SVG ============
    function _svg(uint256 id, TraitData memory t) internal pure returns (string memory) {
        string[8] memory colors = ["#FFD700","#C0C0C0","#CD7F32","#9B59B6","#2ECC71","#3498DB","#E74C3C","#2C3E50"];
        string[5] memory bgs = ["#0a0a2e","#1a0a0a","#0a1a2e","#0a1a0a","#0a0a1a"];
        string memory c = colors[t.color];
        string memory b = bgs[t.background];
        string memory s;
        if (id == 0) {
            // S-tier: rainbow background + glow
            s = string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">',
                '<defs><linearGradient id="rb" x1="0" y1="0" x2="1" y2="1">',
                '<stop offset="0%" stop-color="#ff0000"/><stop offset="50%" stop-color="#00ff00"/>',
                '<stop offset="100%" stop-color="#0000ff"/></linearGradient></defs>',
                '<rect width="200" height="200" fill="url(#rb)"/>',
                '<circle cx="100" cy="90" r="60" fill="none" stroke="#fff" stroke-width="2" opacity="0.6">',
                '<animate attributeName="r" values="60;65;60" dur="2s" repeatCount="indefinite"/></circle>',
                _body(c), _sParts(t), '<text x="100" y="190" font-size="8" fill="#fff" text-anchor="middle">ATHENA S</text></svg>'
            ));
        } else {
            s = string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">',
                '<rect width="200" height="200" fill="', b, '"/>',
                _stars(c), _body(c), _parts(t), '<text x="100" y="190" font-size="8" fill="', c, '" text-anchor="middle">ATHENA</text></svg>'
            ));
        }
        return s;
    }

    function _body(string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<rect x="80" y="45" width="40" height="25" fill="#ffd4a8"/>',
            '<rect x="65" y="70" width="70" height="80" fill="', c, '" opacity="0.8"/>',
            '<rect x="75" y="150" width="20" height="35" fill="', c, '" opacity="0.6"/>',
            '<rect x="105" y="150" width="20" height="35" fill="', c, '" opacity="0.6"/>'
        ));
    }

    function _stars(string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<circle cx="30" cy="20" r="1.5" fill="', c, '" opacity="0.6"/>',
            '<circle cx="100" cy="15" r="1" fill="', c, '" opacity="0.5"/>',
            '<circle cx="170" cy="25" r="1.5" fill="', c, '" opacity="0.7"/>'
        ));
    }

    function _parts(TraitData memory t) internal pure returns (string memory) {
        string[8] memory co = ["#FFD700","#C0C0C0","#CD7F32","#9B59B6","#2ECC71","#3498DB","#E74C3C","#2C3E50"];
        string[4] memory ec = ["#3498DB","#2ECC71","#FFD700","#E74C3C"];
        string memory c = co[t.color];
        return string(abi.encodePacked(
            '<rect x="70" y="22" width="60" height="30" rx="8" fill="', c, '"/>',
            '<rect x="30" y="75" width="30" height="40" rx="6" fill="', c, '" opacity="0.8"/>',
            '<rect x="140" y="40" width="4" height="100" fill="', c, '"/>',
            '<rect x="88" y="52" width="6" height="4" fill="', ec[t.eyes], '"/>',
            '<rect x="106" y="52" width="6" height="4" fill="', ec[t.eyes], '"/>'
        ));
    }

    function _sParts(TraitData memory t) internal pure returns (string memory) {
        string[4] memory ec = ["#3498DB","#2ECC71","#FFD700","#E74C3C"];
        string memory eyes = string(abi.encodePacked('<rect x="88" y="52" width="6" height="4" fill="', ec[t.eyes], '"/><rect x="106" y="52" width="6" height="4" fill="', ec[t.eyes], '"/>'));
        return string(abi.encodePacked(
            '<rect x="75" y="8" width="50" height="12" fill="#FFD700"/>',
            '<circle cx="100" cy="7" r="4" fill="#3498DB"/>',
            eyes
        ));
    }

    function name(uint256 id) public pure returns (string memory) {
        if (id == 0) return "Athena S (Rainbow)";
        if (id == 1) return "Athena A (Gold)";
        if (id == 2) return "Athena B (Silver)";
        if (id == 3) return "Athena C (Bronze)";
        revert("");
    }

    function isAttestationUsed(bytes32 uid) external view returns (bool) { return usedAttestations[uid]; }
    function getCombinations() public pure returns (uint256) { return 768000; }

    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i; uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory b = new bytes(len); uint256 k = len;
        while (_i != 0) { k--; b[k] = bytes1(uint8(48 + _i % 10)); _i /= 10; }
        return string(b);
    }
}
