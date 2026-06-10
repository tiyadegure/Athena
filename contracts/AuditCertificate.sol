// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./RarityCalculator.sol";

struct Attestation { bytes32 uid; bytes32 schema; uint64 time; uint64 expirationTime; bool revocable; bytes32 refUID; address recipient; address attester; bytes data; }
interface IEAS { function getAttestation(bytes32) external view returns (Attestation memory); function isAttestationValid(bytes32) external view returns (bool); }

/// @title AuditCertificate v4 — Seed-based Traits + Dynamic Rarity + SVG Cache
/// @dev 0=S(Rainbow), 1=Gold(A), 2=Silver(B), 3=Bronze(C)
/// @dev 9 traits × 2 bits = 18 bits in uint256 seed → 262,144 combinations
contract AuditCertificate is ERC1155, Ownable {
    using Strings for uint256;

    uint256 public constant S_TIER = 0;
    uint256 public constant GOLD = 1;
    uint256 public constant SILVER = 2;
    uint256 public constant BRONZE = 3;

    address public immutable easContract;
    bytes32 public constant ZERO = bytes32(0);

    // Per-attestation data
    mapping(bytes32 => bool) public usedAttestations;
    mapping(bytes32 => uint256) public attestationSeed;   // uid → seed
    mapping(bytes32 => uint8) public attestationTier;     // uid → tier
    mapping(bytes32 => uint256) public attestationRarity; // uid → rarity score

    // SVG cache: seed → base64(svg)
    mapping(uint256 => bytes) private _svgCache;

    // Token → attestation lookup
    mapping(uint256 => bytes32) public tokenAttestation;

    event CertificateMinted(address indexed to, bytes32 indexed uid, uint256 tokenId, uint8 tier, uint256 rarity);

    constructor(address _eas) ERC1155("") Ownable() {
        require(_eas != address(0));
        easContract = _eas;
    }

    // ============ Minting ============

    /// @notice Mint via EAS attestation (production)
    function mintCertificate(address to, bytes32 uid) external {
        require(to != address(0) && uid != ZERO && !usedAttestations[uid]);
        IEAS eas = IEAS(easContract);
        require(eas.isAttestationValid(uid));
        Attestation memory att = eas.getAttestation(uid);
        (uint8 score,,,,) = abi.decode(att.data, (uint8, uint16, string, uint64, address));

        // Derive seed from uid
        uint256 seed = _deriveSeed(uid);
        uint256 rarity = RarityCalculator.calculateRarity(seed);
        uint8 rarityTier = RarityCalculator.getTier(rarity);

        // Audit score determines minimum tier, rarity can upgrade
        uint8 baseTier = score == 0 ? uint8(S_TIER) : score <= 1 ? uint8(GOLD) : score <= 5 ? uint8(SILVER) : uint8(BRONZE);
        uint8 tier = rarityTier < baseTier ? rarityTier : baseTier;

        attestationSeed[uid] = seed;
        attestationTier[uid] = tier;
        attestationRarity[uid] = rarity;
        usedAttestations[uid] = true;
        tokenAttestation[tier] = uid;

        _mint(to, tier, 1, "");
        emit CertificateMinted(to, uid, tier, tier, rarity);
    }

    /// @notice Mint test NFT (owner only, for demo)
    function mintTest(address to, uint8 tier) external onlyOwner {
        require(to != address(0) && tier <= 3);
        bytes32 uid = keccak256(abi.encodePacked(to, tier, block.timestamp, block.number));
        uint256 seed = _deriveSeed(uid);
        uint256 rarity = RarityCalculator.calculateRarity(seed);

        attestationSeed[uid] = seed;
        attestationTier[uid] = tier;
        attestationRarity[uid] = rarity;
        usedAttestations[uid] = true;
        tokenAttestation[tier] = uid;

        _mint(to, tier, 1, "");
        emit CertificateMinted(to, uid, tier, tier, rarity);
    }

    // ============ Seed ============

    /// @notice Derive deterministic seed from uid
    function _deriveSeed(bytes32 uid) internal pure returns (uint256 seed) {
        bytes32 h = keccak256(abi.encodePacked(uid));
        // Pack 9 traits × 2 bits from hash bytes
        seed = uint256(
            (uint8(h[0]) % 4) |
            ((uint8(h[1]) % 4) << 2) |
            ((uint8(h[2]) % 4) << 4) |
            ((uint8(h[3]) % 4) << 6) |
            ((uint8(h[4]) % 4) << 8) |
            ((uint8(h[5]) % 4) << 10) |
            ((uint8(h[6]) % 4) << 12) |
            ((uint8(h[7]) % 4) << 14) |
            ((uint8(h[8]) % 4) << 16)
        );
    }

    /// @notice Public seed decoder
    function decodeSeed(uint256 seed) public pure returns (uint8[9] memory) {
        return RarityCalculator.decodeTraits(seed);
    }

    /// @notice Public rarity calc
    function getRarity(uint256 seed) public pure returns (uint256) {
        return RarityCalculator.calculateRarity(seed);
    }

    /// @notice Public tier from score
    function getTierFromScore(uint256 score) public pure returns (uint8) {
        return RarityCalculator.getTier(score);
    }

    // ============ URI / Metadata ============

    function uri(uint256 id) public view override returns (string memory) {
        require(id <= 3);
        bytes32 uid = tokenAttestation[id];
        if (uid == ZERO) uid = keccak256(abi.encodePacked(id, msg.sender));
        uint256 seed = attestationSeed[uid];
        if (seed == 0) seed = _deriveSeed(uid);
        uint256 rarity = RarityCalculator.calculateRarity(seed);
        uint8 tier = RarityCalculator.getTier(rarity);
        if (tier > id) tier = uint8(id);

        return _buildMetadata(seed, tier, rarity, uid);
    }

    function _buildMetadata(uint256 seed, uint8 tier, uint256 rarity, bytes32 uid) internal view returns (string memory) {
        bytes memory svg = _getSVG(seed, tier);
        string[4] memory tn = ["S (Rainbow)", "A (Gold)", "B (Silver)", "C (Bronze)"];
        uint8[9] memory traits = RarityCalculator.decodeTraits(seed);
        string[9] memory traitNames = ["bg", "body", "eyes", "crown", "wings", "aura", "badge", "texture", "acc"];

        // Build trait attributes
        bytes memory attrs = "";
        for (uint256 i = 0; i < 9; i++) {
            if (i > 0) attrs = abi.encodePacked(attrs, ",");
            attrs = abi.encodePacked(attrs, '{"trait_type":"', traitNames[i], '","value":', _u8str(traits[i]), '}');
        }

        bytes memory json = abi.encodePacked(
            '{"name":"Athena #', _uint2str(uint256(uid) % 100000),
            '","description":"Athena Audit Certificate","tier":"', tn[tier],
            '","rarity":', _uint2str(rarity),
            ',"attributes":[', attrs, ']',
            ',"image":"data:image/svg+xml;base64,', Base64.encode(svg), '"}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    // ============ SVG Generation with Cache ============

    function _getSVG(uint256 seed, uint8 tier) internal view returns (bytes memory) {
        if (_svgCache[seed].length > 0) return _svgCache[seed];
        return _generateSVG(seed, tier);
    }

    /// @notice Cache SVG for a seed (owner only, saves gas on repeated reads)
    function cacheSVG(uint256 seed) external onlyOwner {
        require(_svgCache[seed].length == 0, "already cached");
        uint256 rarity = RarityCalculator.calculateRarity(seed);
        uint8 tier = RarityCalculator.getTier(rarity);
        _svgCache[seed] = _generateSVG(seed, tier);
    }

    function _generateSVG(uint256 seed, uint8 tier) internal pure returns (bytes memory) {
        uint8[9] memory t = RarityCalculator.decodeTraits(seed);
        // Color palettes per trait
        string[4] memory bgC = ["#0a0a2e", "#1a0a2e", "#0a1a0a", "#1a0a0a"];
        string[4] memory bodyC = ["#FFD700", "#C0C0C0", "#CD7F32", "#2ECC71"];
        string[4] memory eyeC = ["#3498DB", "#2ECC71", "#E74C3C", "#FFD700"];

        if (tier == S_TIER) {
            return abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">',
                '<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">',
                '<stop offset="0%" stop-color="#ff0000"/><stop offset="50%" stop-color="#00ff00"/>',
                '<stop offset="100%" stop-color="#0000ff"/></linearGradient></defs>',
                '<rect width="200" height="200" fill="url(#g)"/>',
                '<circle cx="100" cy="90" r="60" fill="none" stroke="#fff" stroke-width="2" opacity="0.5">',
                '<animate attributeName="r" values="60;65;60" dur="2s" repeatCount="indefinite"/></circle>',
                _svgBody(bodyC[t[1]]), _svgEyes(eyeC[t[2]]),
                '<text x="100" y="190" font-size="8" fill="#fff" text-anchor="middle">ATHENA S</text></svg>'
            );
        }
        return abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">',
            '<rect width="200" height="200" fill="', bgC[t[0]], '"/>',
            _svgStars(bodyC[t[1]]), _svgBody(bodyC[t[1]]), _svgEyes(eyeC[t[2]]),
            '<text x="100" y="190" font-size="8" fill="', bodyC[t[1]], '" text-anchor="middle">ATHENA</text></svg>'
        );
    }

    function _svgBody(string memory c) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<rect x="80" y="45" width="40" height="25" fill="#ffd4a8"/>',
            '<rect x="65" y="70" width="70" height="80" fill="', c, '" opacity="0.8"/>',
            '<rect x="75" y="150" width="20" height="35" fill="', c, '" opacity="0.6"/>',
            '<rect x="105" y="150" width="20" height="35" fill="', c, '" opacity="0.6"/>'
        );
    }

    function _svgEyes(string memory c) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<rect x="88" y="52" width="6" height="4" fill="', c, '"/>',
            '<rect x="106" y="52" width="6" height="4" fill="', c, '"/>'
        );
    }

    function _svgStars(string memory c) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<circle cx="30" cy="20" r="1.5" fill="', c, '" opacity="0.6"/>',
            '<circle cx="100" cy="15" r="1" fill="', c, '" opacity="0.5"/>',
            '<circle cx="170" cy="25" r="1.5" fill="', c, '" opacity="0.7"/>'
        );
    }

    // ============ View Helpers ============

    function name(uint256 id) public pure returns (string memory) {
        if (id == 0) return "Athena S (Rainbow)";
        if (id == 1) return "Athena A (Gold)";
        if (id == 2) return "Athena B (Silver)";
        if (id == 3) return "Athena C (Bronze)";
        revert("invalid");
    }

    function getCombinations() public pure returns (uint256) { return 262144; }
    function isAttestationUsed(bytes32 uid) external view returns (bool) { return usedAttestations[uid]; }

    // ============ Internal Utils ============

    function _uint2str(uint256 v) internal pure returns (string memory) {
        if (v == 0) return "0";
        uint256 j = v; uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory b = new bytes(len); uint256 k = len;
        while (v != 0) { k--; b[k] = bytes1(uint8(48 + v % 10)); v /= 10; }
        return string(b);
    }

    function _u8str(uint8 v) internal pure returns (string memory) { return _uint2str(uint256(v)); }
}
