// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @notice EAS interface (only the parts we need)
struct Attestation {
    bytes32 uid;
    bytes32 schema;
    uint64 time;
    uint64 expirationTime;
    bool revocable;
    bytes32 refUID;
    address recipient;
    address attester;
    bytes data;
}

interface IEAS {
    function getAttestation(bytes32 uid) external view returns (Attestation memory);
    function isAttestationValid(bytes32 uid) external view returns (bool);
}

/// @title AuditCertificate - ERC-1155 NFT 审计证书
/// @notice 铸造条件：基于 EAS attestation 的审计结果分级
/// @dev Token IDs: 1=Gold(A级), 2=Silver(B级), 3=Bronze(C级)
/// @dev 8 trait dimensions × 3-4 variants each = 26,244+ unique combinations
contract AuditCertificate is ERC1155, Ownable {
    using Strings for uint256;

    // ============ Token IDs ============
    uint256 public constant GOLD = 1;     // A级 - Critical
    uint256 public constant SILVER = 2;   // B级 - High/Medium
    uint256 public constant BRONZE = 3;   // C级 - Low/Info

    // ============ Trait Dimensions ============
    // Each trait has 3-4 variants, derived from attestationUID hash
    // Total combinations: 3×3×3×3×3×4×3×3 = 8,748 per tier = 26,244 total
    
    uint8 constant HELMET_VARIANTS = 3;    // Spartan, Corinthian, Phrygian
    uint8 constant SHIELD_VARIANTS = 3;    // Owl, Snake, Eagle
    uint8 constant SPEAR_VARIANTS = 3;     // Long, Short, Javelin
    uint8 constant ROBE_VARIANTS = 3;      // Solid, Striped, Gradient
    uint8 constant SKIN_VARIANTS = 3;      // Light, Medium, Dark
    uint8 constant BG_VARIANTS = 4;        // Deep Blue, Dark Purple, Dark Green, Dark Red
    uint8 constant ENCHANT_VARIANTS = 3;   // Fire, Ice, Lightning
    uint8 constant AURA_VARIANTS = 3;      // None, Glow, Sparkle

    // ============ EAS Address (injected via constructor) ============
    address public immutable easContract;
    bytes32 public constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;

    // ============ State ============
    mapping(bytes32 => bool) public usedAttestations;
    mapping(bytes32 => AuditRecord) public auditRecords;

    struct AuditRecord {
        address contractAddress;
        address auditor;
        uint8 severity;
        uint256 timestamp;
        uint256 tokenId;
    }

    // ============ Events ============
    event CertificateMinted(
        address indexed to,
        bytes32 indexed attestationUID,
        uint256 tokenId,
        uint8 severity
    );

    // ============ Constructor ============
    constructor(address _eas) ERC1155("") Ownable() {
        require(_eas != address(0), "Invalid EAS address");
        easContract = _eas;
    }

    // ============ Core Functions ============

    function mintCertificate(address to, bytes32 attestationUID) external {
        require(to != address(0), "Invalid recipient");
        require(attestationUID != ZERO_BYTES32, "Invalid attestation UID");
        require(!usedAttestations[attestationUID], "Attestation already used");

        IEAS eas = IEAS(easContract);
        require(eas.isAttestationValid(attestationUID), "Invalid attestation");

        Attestation memory att = eas.getAttestation(attestationUID);
        (uint8 auditScore, , , uint64 timestamp, address contractAddress) = 
            abi.decode(att.data, (uint8, uint16, string, uint64, address));

        uint256 tokenId;
        if (auditScore <= 1) {
            tokenId = GOLD;
        } else if (auditScore <= 5) {
            tokenId = SILVER;
        } else {
            tokenId = BRONZE;
        }

        _mint(to, tokenId, 1, "");

        usedAttestations[attestationUID] = true;
        auditRecords[attestationUID] = AuditRecord({
            contractAddress: contractAddress,
            auditor: att.attester,
            severity: auditScore,
            timestamp: timestamp,
            tokenId: tokenId
        });

        emit CertificateMinted(to, attestationUID, tokenId, auditScore);
    }

    // ============ Metadata ============

    function uri(uint256 tokenId) public pure override returns (string memory) {
        require(tokenId >= GOLD && tokenId <= BRONZE, "Invalid token ID");
        // For ERC-1155, uri() returns the base URI for all tokens
        // Individual token metadata is handled by the minting process
        // For now, return a base URI that points to our metadata
        return "";
    }

    /// @notice Generate metadata for a specific attestation
    /// @param attestationUID The attestation UID (used to derive traits)
    /// @param tokenId The token tier (Gold/Silver/Bronze)
    function generateMetadata(bytes32 attestationUID, uint256 tokenId) public pure returns (string memory) {
        require(tokenId >= GOLD && tokenId <= BRONZE, "Invalid token ID");
        
        // Derive all traits from attestationUID hash
        bytes32 hash = keccak256(abi.encodePacked(attestationUID));
        uint8[8] memory traits = _deriveTraits(hash);
        
        // Calculate rarity score
        uint256 rarity = _calculateRarity(traits);
        
        // Generate SVG
        string memory svg = _generateAthenaSVG(tokenId, traits);
        
        string memory tierName;
        if (tokenId == GOLD) {
            tierName = unicode"A 级 (Gold)";
        } else if (tokenId == SILVER) {
            tierName = unicode"B 级 (Silver)";
        } else {
            tierName = unicode"C 级 (Bronze)";
        }
        
        string memory desc = unicode"审计证书 - Rarity: ";
        
        // Build full JSON metadata
        string memory json = string(
            abi.encodePacked(
                '{"name":"GLM Audit Certificate #', _uint2str(uint256(uint256(attestationUID)) % 10000), '",',
                '"description":"', tierName, desc, _uint2str(rarity), '%",',
                '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
                '"attributes":[',
                    '{"trait_type":"Tier","value":"', tierName, '"},',
                    '{"trait_type":"Helmet","value":"', _getHelmetName(traits[0]) , '"},',
                    '{"trait_type":"Shield","value":"', _getShieldName(traits[1]) , '"},',
                    '{"trait_type":"Spear","value":"', _getSpearName(traits[2]) , '"},',
                    '{"trait_type":"Robe","value":"', _getRobeName(traits[3]) , '"},',
                    '{"trait_type":"Skin","value":"', _getSkinName(traits[4]) , '"},',
                    '{"trait_type":"Background","value":"', _getBgName(traits[5]) , '"},',
                    '{"trait_type":"Enchant","value":"', _getEnchantName(traits[6]) , '"},',
                    '{"trait_type":"Aura","value":"', _getAuraName(traits[7]) , '"},',
                    '{"trait_type":"Rarity","value":', _uint2str(rarity), '}',
                ']}'
            )
        );
        
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // ============ Trait Derivation ============

    function _deriveTraits(bytes32 hash) internal pure returns (uint8[8] memory traits) {
        // Extract 8 trait indices from the hash
        // Each byte of the hash maps to a trait dimension
        traits[0] = uint8(hash[0]) % HELMET_VARIANTS;   // Helmet
        traits[1] = uint8(hash[1]) % SHIELD_VARIANTS;   // Shield
        traits[2] = uint8(hash[2]) % SPEAR_VARIANTS;    // Spear
        traits[3] = uint8(hash[3]) % ROBE_VARIANTS;     // Robe
        traits[4] = uint8(hash[4]) % SKIN_VARIANTS;     // Skin
        traits[5] = uint8(hash[5]) % BG_VARIANTS;       // Background
        traits[6] = uint8(hash[6]) % ENCHANT_VARIANTS;  // Enchant
        traits[7] = uint8(hash[7]) % AURA_VARIANTS;     // Aura
    }

    // ============ Rarity Calculation ============

    function _calculateRarity(uint8[8] memory traits) internal pure returns (uint256) {
        // Each trait has equal probability, so rarity = 100 / (number of combinations)
        // With 8,748 combinations per tier, base rarity = ~0.011%
        // We scale to 0-100 where 100 = most common, 1 = rarest
        
        // Calculate unique combination index (0 to 8747)
        uint256 index = uint256(traits[0]);
        index = index * HELMET_VARIANTS + uint256(traits[1]);
        index = index * SHIELD_VARIANTS + uint256(traits[2]);
        index = index * SPEAR_VARIANTS + uint256(traits[3]);
        index = index * ROBE_VARIANTS + uint256(traits[4]);
        index = index * SKIN_VARIANTS + uint256(traits[5]);
        index = index * BG_VARIANTS + uint256(traits[6]);
        index = index * ENCHANT_VARIANTS + uint256(traits[7]);
        
        // Convert to rarity percentage (inverse - rarer = higher number)
        // Max combinations = 8748
        // Rarity = 100 - (index / 8748 * 100)
        // This gives 100 for index 0, ~0 for index 8747
        uint256 rarity = 100 - (index * 100 / 8748);
        
        // Ensure minimum rarity of 1
        if (rarity == 0) rarity = 1;
        
        return rarity;
    }

    // ============ SVG Generation ============

    function _generateAthenaSVG(uint256 tokenId, uint8[8] memory traits) internal pure returns (string memory) {
        // Get color scheme based on tier
        string memory primary;
        string memory secondary;
        string memory accent;
        
        if (tokenId == GOLD) {
            primary = "#FFD700";
            secondary = "#B8860B";
            accent = "#FFA500";
        } else if (tokenId == SILVER) {
            primary = "#C0C0C0";
            secondary = "#808080";
            accent = "#A9A9A9";
        } else {
            primary = "#CD7F32";
            secondary = "#8B4513";
            accent = "#D2691E";
        }
        
        // Get background color
        string memory bg = _getBgColor(traits[5]);
        
        // Get skin color
        string memory skin = _getSkinColor(traits[4]);
        
        // Get enchant effect
        string memory enchantColor = _getEnchantColor(traits[6]);
        
        // Build SVG with trait variations
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320" width="320" height="320">',
                _generateBackground(bg),
                _generateAura(traits[7], primary),
                _generateHelmet(traits[0], primary, secondary, accent),
                _generateFace(skin),
                _generateRobe(traits[3], primary, secondary, accent),
                _generateShield(traits[1], primary, secondary, accent),
                _generateSpear(traits[2], primary, accent, enchantColor),
                _generateLegs(secondary),
                _generateBoots(primary),
                _generateFooter(primary, accent),
                '</svg>'
            )
        );
    }

    // ============ SVG Components ============

    function _generateBackground(string memory bg) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<rect width="320" height="320" fill="', bg, '"/>'
        ));
    }

    function _generateAura(uint8 auraType, string memory primary) internal pure returns (string memory) {
        if (auraType == 0) return ""; // No aura
        if (auraType == 1) {
            // Glow aura
            return string(abi.encodePacked(
                '<circle cx="160" cy="160" r="140" fill="none" stroke="', primary, '" stroke-width="2" opacity="0.3"/>',
                '<circle cx="160" cy="160" r="130" fill="none" stroke="', primary, '" stroke-width="1" opacity="0.2"/>'
            ));
        }
        // Sparkle aura
        return string(abi.encodePacked(
            '<circle cx="50" cy="50" r="3" fill="', primary, '" opacity="0.6"/>',
            '<circle cx="270" cy="80" r="2" fill="', primary, '" opacity="0.5"/>',
            '<circle cx="40" cy="250" r="2" fill="', primary, '" opacity="0.4"/>',
            '<circle cx="280" cy="280" r="3" fill="', primary, '" opacity="0.6"/>'
        ));
    }

    function _generateHelmet(uint8 style, string memory primary, string memory secondary, string memory accent) internal pure returns (string memory) {
        if (style == 0) {
            // Spartan helmet
            return string(abi.encodePacked(
                '<rect x="130" y="20" width="60" height="10" fill="', primary, '"/>',
                '<rect x="140" y="10" width="40" height="10" fill="', accent, '"/>',
                '<rect x="150" y="0" width="20" height="10" fill="', primary, '"/>',
                '<rect x="120" y="30" width="80" height="50" rx="10" fill="', secondary, '"/>',
                '<rect x="130" y="35" width="60" height="15" fill="', primary, '"/>'
            ));
        } else if (style == 1) {
            // Corinthian helmet
            return string(abi.encodePacked(
                '<rect x="120" y="20" width="80" height="15" fill="', primary, '"/>',
                '<rect x="115" y="35" width="90" height="45" rx="5" fill="', secondary, '"/>',
                '<rect x="125" y="40" width="70" height="10" fill="', accent, '"/>',
                '<rect x="140" y="20" width="40" height="20" fill="', primary, '"/>'
            ));
        }
        // Phrygian helmet
        return string(abi.encodePacked(
            '<rect x="125" y="25" width="70" height="55" rx="8" fill="', secondary, '"/>',
            '<rect x="135" y="15" width="50" height="15" fill="', primary, '"/>',
            '<rect x="155" y="5" width="30" height="15" rx="5" fill="', accent, '"/>',
            '<rect x="130" y="40" width="60" height="10" fill="', primary, '"/>'
        ));
    }

    function _generateFace(string memory skin) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<rect x="135" y="55" width="50" height="35" fill="', skin, '"/>',
            '<rect x="145" y="62" width="8" height="6" fill="#1a1a2e"/>',
            '<rect x="167" y="62" width="8" height="6" fill="#1a1a2e"/>',
            '<rect x="152" y="75" width="16" height="4" fill="#d4956a"/>'
        ));
    }

    function _generateRobe(uint8 style, string memory primary, string memory secondary, string memory accent) internal pure returns (string memory) {
        if (style == 0) {
            // Solid robe
            return string(abi.encodePacked(
                '<rect x="110" y="90" width="100" height="120" rx="5" fill="', secondary, '"/>',
                '<rect x="115" y="95" width="90" height="30" fill="', primary, '"/>'
            ));
        } else if (style == 1) {
            // Striped robe
            return string(abi.encodePacked(
                '<rect x="110" y="90" width="100" height="120" rx="5" fill="', secondary, '"/>',
                '<rect x="115" y="100" width="90" height="8" fill="', primary, '"/>',
                '<rect x="115" y="116" width="90" height="8" fill="', primary, '"/>',
                '<rect x="115" y="132" width="90" height="8" fill="', primary, '"/>',
                '<rect x="115" y="148" width="90" height="8" fill="', primary, '"/>'
            ));
        }
        // Gradient robe (simulated with rectangles)
        return string(abi.encodePacked(
            '<rect x="110" y="90" width="100" height="120" rx="5" fill="', secondary, '"/>',
            '<rect x="110" y="90" width="100" height="40" fill="', primary, '" opacity="0.8"/>',
            '<rect x="110" y="130" width="100" height="40" fill="', primary, '" opacity="0.5"/>',
            '<rect x="110" y="170" width="100" height="40" fill="', accent, '" opacity="0.3"/>'
        ));
    }

    function _generateShield(uint8 design, string memory primary, string memory secondary, string memory accent) internal pure returns (string memory) {
        if (design == 0) {
            // Owl shield
            return string(abi.encodePacked(
                '<rect x="60" y="100" width="45" height="60" rx="8" fill="', primary, '"/>',
                '<rect x="68" y="108" width="29" height="44" rx="4" fill="', secondary, '"/>',
                '<rect x="75" y="118" width="15" height="15" fill="', primary, '"/>',
                '<rect x="78" y="121" width="4" height="4" fill="#1a1a2e"/>',
                '<rect x="86" y="121" width="4" height="4" fill="#1a1a2e"/>'
            ));
        } else if (design == 1) {
            // Snake shield
            return string(abi.encodePacked(
                '<rect x="60" y="100" width="45" height="60" rx="8" fill="', primary, '"/>',
                '<rect x="68" y="108" width="29" height="44" rx="4" fill="', secondary, '"/>',
                '<path d="M75,120 Q82,115 89,120 Q82,125 75,120" fill="', accent, '"/>',
                '<circle cx="78" cy="118" r="2" fill="#1a1a2e"/>',
                '<circle cx="86" cy="118" r="2" fill="#1a1a2e"/>'
            ));
        }
        // Eagle shield
        return string(abi.encodePacked(
            '<rect x="60" y="100" width="45" height="60" rx="8" fill="', primary, '"/>',
            '<rect x="68" y="108" width="29" height="44" rx="4" fill="', secondary, '"/>',
            '<path d="M75,120 L82,110 L89,120 L82,130 Z" fill="', accent, '"/>',
            '<circle cx="82" cy="118" r="3" fill="#1a1a2e"/>'
        ));
    }

    function _generateSpear(uint8 style, string memory primary, string memory accent, string memory enchant) internal pure returns (string memory) {
        if (style == 0) {
            // Long spear
            return string(abi.encodePacked(
                '<rect x="230" y="50" width="6" height="180" fill="', primary, '"/>',
                '<rect x="224" y="40" width="18" height="15" rx="2" fill="', accent, '"/>',
                '<rect x="226" y="35" width="14" height="8" fill="', enchant, '" opacity="0.6"/>'
            ));
        } else if (style == 1) {
            // Short spear
            return string(abi.encodePacked(
                '<rect x="230" y="80" width="6" height="120" fill="', primary, '"/>',
                '<rect x="224" y="70" width="18" height="15" rx="2" fill="', accent, '"/>',
                '<rect x="226" y="65" width="14" height="8" fill="', enchant, '" opacity="0.6"/>'
            ));
        }
        // Javelin
        return string(abi.encodePacked(
            '<rect x="220" y="60" width="5" height="150" fill="', primary, '" transform="rotate(-15, 222, 135)"/>',
            '<rect x="215" y="50" width="15" height="12" rx="2" fill="', accent, '" transform="rotate(-15, 222, 56)"/>',
            '<rect x="217" y="45" width="11" height="8" fill="', enchant, '" opacity="0.6" transform="rotate(-15, 222, 49)"/>'
        ));
    }

    function _generateLegs(string memory secondary) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<rect x="125" y="210" width="30" height="60" fill="', secondary, '"/>',
            '<rect x="165" y="210" width="30" height="60" fill="', secondary, '"/>'
        ));
    }

    function _generateBoots(string memory primary) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<rect x="120" y="265" width="40" height="15" rx="3" fill="', primary, '"/>',
            '<rect x="160" y="265" width="40" height="15" rx="3" fill="', primary, '"/>'
        ));
    }

    function _generateFooter(string memory primary, string memory accent) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<rect x="80" y="290" width="160" height="10" fill="', primary, '" opacity="0.5"/>',
            '<rect x="100" y="300" width="120" height="8" fill="', accent, '" opacity="0.3"/>',
            '<text x="160" y="315" font-family="monospace" font-size="10" fill="', primary, '" text-anchor="middle">GLM AUDIT</text>'
        ));
    }

    // ============ Color Helpers ============

    function _getBgColor(uint8 bgType) internal pure returns (string memory) {
        if (bgType == 0) return "#1a1a2e"; // Deep Blue
        if (bgType == 1) return "#2d1b3d"; // Dark Purple
        if (bgType == 2) return "#1a2e1a"; // Dark Green
        return "#2e1a1a"; // Dark Red
    }

    function _getSkinColor(uint8 skinType) internal pure returns (string memory) {
        if (skinType == 0) return "#ffd4a8"; // Light
        if (skinType == 1) return "#d4956a"; // Medium
        return "#8b6b4a"; // Dark
    }

    function _getEnchantColor(uint8 enchantType) internal pure returns (string memory) {
        if (enchantType == 0) return "#ff4500"; // Fire
        if (enchantType == 1) return "#00bfff"; // Ice
        return "#ffff00"; // Lightning
    }

    // ============ Trait Name Helpers ============

    function _getHelmetName(uint8 style) internal pure returns (string memory) {
        if (style == 0) return "Spartan";
        if (style == 1) return "Corinthian";
        return "Phrygian";
    }

    function _getShieldName(uint8 design) internal pure returns (string memory) {
        if (design == 0) return "Owl";
        if (design == 1) return "Snake";
        return "Eagle";
    }

    function _getSpearName(uint8 style) internal pure returns (string memory) {
        if (style == 0) return "Long";
        if (style == 1) return "Short";
        return "Javelin";
    }

    function _getRobeName(uint8 style) internal pure returns (string memory) {
        if (style == 0) return "Solid";
        if (style == 1) return "Striped";
        return "Gradient";
    }

    function _getSkinName(uint8 skinType) internal pure returns (string memory) {
        if (skinType == 0) return "Light";
        if (skinType == 1) return "Medium";
        return "Dark";
    }

    function _getBgName(uint8 bgType) internal pure returns (string memory) {
        if (bgType == 0) return "Deep Blue";
        if (bgType == 1) return "Dark Purple";
        if (bgType == 2) return "Dark Green";
        return "Dark Red";
    }

    function _getEnchantName(uint8 enchantType) internal pure returns (string memory) {
        if (enchantType == 0) return "Fire";
        if (enchantType == 1) return "Ice";
        return "Lightning";
    }

    function _getAuraName(uint8 auraType) internal pure returns (string memory) {
        if (auraType == 0) return "None";
        if (auraType == 1) return "Glow";
        return "Sparkle";
    }

    // ============ Utility Functions ============

    function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) { k = k - 1; uint8 temp = (48 + uint8(_i - (_i / 10) * 10)); bytes1 b1 = bytes1(temp); bstr[k] = b1; _i /= 10; }
        return string(bstr);
    }

    // ============ View Functions ============

    function name(uint256 tokenId) public pure returns (string memory) {
        if (tokenId == GOLD) return "Audit Certificate - Gold";
        if (tokenId == SILVER) return "Audit Certificate - Silver";
        if (tokenId == BRONZE) return "Audit Certificate - Bronze";
        revert("Invalid token ID");
    }

    function isAttestationUsed(bytes32 attestationUID) external view returns (bool) {
        return usedAttestations[attestationUID];
    }

    function totalSupply(uint256 tokenId) external view returns (uint256) {
        return this.totalSupply(tokenId);
    }

    /// @notice Get total possible combinations per tier
    function getCombinationsPerTier() public pure returns (uint256) {
        return uint256(HELMET_VARIANTS) * 
               uint256(SHIELD_VARIANTS) * 
               uint256(SPEAR_VARIANTS) * 
               uint256(ROBE_VARIANTS) * 
               uint256(SKIN_VARIANTS) * 
               uint256(BG_VARIANTS) * 
               uint256(ENCHANT_VARIANTS) * 
               uint256(AURA_VARIANTS);
    }

    /// @notice Get total possible combinations across all tiers
    function getTotalCombinations() public pure returns (uint256) {
        return getCombinationsPerTier() * 3;
    }
}
