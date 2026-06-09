// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @notice EAS interface
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

/// @title AuditCertificate - ERC-1155 NFT 审计证书 (v2)
/// @notice 铸造条件：基于 EAS attestation 的审计结果分级
/// @dev Token IDs: 1=Gold(A级), 2=Silver(B级), 3=Bronze(C级)
/// @dev 6 trait dimensions: helmet(5)×shield(5)×color(8)×weapon(3)×bg(5)×eyes(4) = 12,000 unique combinations
contract AuditCertificate is ERC1155, Ownable {
    using Strings for uint256;

    // ============ Token IDs ============
    uint256 public constant GOLD = 1;
    uint256 public constant SILVER = 2;
    uint256 public constant BRONZE = 3;

    // ============ Trait Dimension Counts ============
    uint8 constant HELMET_VARIANTS = 5;     // 羽饰/双角/冠冕/头巾/经典
    uint8 constant SHIELD_VARIANTS = 5;     // 猫头鹰/蛇发/橄榄枝/闪电/空白
    uint8 constant COLOR_VARIANTS = 8;      // 金/银/铜/紫/绿/蓝/红/黑
    uint8 constant WEAPON_VARIANTS = 3;     // 长矛/弓箭/剑
    uint8 constant BG_VARIANTS = 5;         // 星空/火焰/海洋/森林/极光
    uint8 constant EYES_VARIANTS = 4;       // 蓝/绿/金/红

    // ============ Trait Data Structure ============
    struct TraitData {
        uint8 helmet;
        uint8 shield;
        uint8 color;
        uint8 weapon;
        uint8 background;
        uint8 eyes;
        uint256 rarityScore;
    }

    // ============ EAS Address ============
    address public immutable easContract;
    bytes32 public constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;

    // ============ State ============
    mapping(bytes32 => bool) public usedAttestations;
    mapping(bytes32 => TraitData) public traitData;
    mapping(bytes32 => AuditRecord) public auditRecords;
    mapping(uint256 => bytes32) public tokenAttestation;

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
        uint8 severity,
        TraitData traits
    );

    // ============ Constructor ============
    constructor(address _eas) ERC1155("") Ownable() {
        require(_eas != address(0), "Invalid EAS address");
        easContract = _eas;
    }

    // ============ Core Functions ============

    /// @notice Mint test NFT (owner only, for demo purposes)
    function mintTest(address to, uint8 tier) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(tier >= 1 && tier <= 3, "Invalid tier");

        bytes32 fakeUID = keccak256(abi.encodePacked(to, tier, block.timestamp));
        TraitData memory traits = _selectTraits(fakeUID);
        traitData[fakeUID] = traits;

        _mint(to, tier, 1, "");

        tokenAttestation[tier] = bytes32(uint256(uint160(to)));
        usedAttestations[fakeUID] = true;
        auditRecords[fakeUID] = AuditRecord({
            contractAddress: address(this),
            auditor: msg.sender,
            severity: tier == 1 ? 1 : (tier == 2 ? 3 : 5),
            timestamp: block.timestamp,
            tokenId: tier
        });

        emit CertificateMinted(to, fakeUID, tier, tier == 1 ? 1 : (tier == 2 ? 3 : 5), traits);
    }

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

        // Select traits deterministically from attestationUID
        TraitData memory traits = _selectTraits(attestationUID);
        traitData[attestationUID] = traits;

        _mint(to, tokenId, 1, "");

        tokenAttestation[tokenId] = attestationUID;
        usedAttestations[attestationUID] = true;
        auditRecords[attestationUID] = AuditRecord({
            contractAddress: contractAddress,
            auditor: att.attester,
            severity: auditScore,
            timestamp: timestamp,
            tokenId: tokenId
        });

        emit CertificateMinted(to, attestationUID, tokenId, auditScore, traits);
    }

    // ============ Trait Selection ============

    function _selectTraits(bytes32 uid) internal pure returns (TraitData memory) {
        bytes32 hash = keccak256(abi.encodePacked(uid));
        
        uint8 helmet = uint8(hash[0]) % HELMET_VARIANTS;
        uint8 shield = uint8(hash[1]) % SHIELD_VARIANTS;
        uint8 color = uint8(hash[2]) % COLOR_VARIANTS;
        uint8 weapon = uint8(hash[3]) % WEAPON_VARIANTS;
        uint8 bg = uint8(hash[4]) % BG_VARIANTS;
        uint8 eyes = uint8(hash[5]) % EYES_VARIANTS;
        
        uint256 rarity = _calculateRarity(helmet, shield, color, weapon, bg, eyes);
        
        return TraitData({
            helmet: helmet,
            shield: shield,
            color: color,
            weapon: weapon,
            background: bg,
            eyes: eyes,
            rarityScore: rarity
        });
    }

    function _calculateRarity(
        uint8 helmet, uint8 shield, uint8 color, uint8 weapon, uint8 bg, uint8 eyes
    ) internal pure returns (uint256) {
        // Each trait combination is equally likely (1/12000)
        // Rarity score: 1 = most common, 100 = rarest
        // We use the trait index to determine rarity
        // Using literals instead of constants to avoid uint8 overflow
        uint256 index = uint256(helmet) * 2400  // 5*8*3*5*4 = 2400
                      + uint256(shield) * 480   // 8*3*5*4 = 480
                      + uint256(color) * 60     // 3*5*4 = 60
                      + uint256(weapon) * 20    // 5*4 = 20
                      + uint256(bg) * 4         // 4
                      + uint256(eyes);
        
        // Convert to rarity (1-100), where higher = rarer
        // 12000 combinations, so index 0 = most common (rarity 1), index 11999 = rarest (rarity 100)
        uint256 rarity = 1 + (index * 99 / 11999);
        return rarity;
    }

    // ============ Metadata ============

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId >= GOLD && tokenId <= BRONZE, "Invalid token ID");

        bytes32 attestationUID = tokenAttestation[tokenId];

        if (attestationUID != ZERO_BYTES32) {
            return generateMetadata(attestationUID, tokenId);
        }

        // Default metadata for test mints (no real attestation)
        TraitData memory defaultTraits = TraitData({
            helmet: 4,  // 经典
            shield: 4,  // 空白
            color: 2,   // 铜
            weapon: 0,  // 长矛
            background: 0, // 星空
            eyes: 0,    // 蓝
            rarityScore: 50
        });

        string memory svg = _generateAthenaSVG(tokenId, defaultTraits);

        string memory tierName;
        if (tokenId == GOLD) {
            tierName = unicode"A 级 (Gold)";
        } else if (tokenId == SILVER) {
            tierName = unicode"B 级 (Silver)";
        } else {
            tierName = unicode"C 级 (Bronze)";
        }

        string memory json = string(
            abi.encodePacked(
                '{"name":"Athena Audit Certificate (Test)",',
                '"description":"', tierName, ' - Test Mint",',
                '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
                '"attributes":[',
                    '{"trait_type":"Tier","value":"', tierName, '"},',
                    '{"trait_type":"Helmet","value":"', _getHelmetName(defaultTraits.helmet), '"},',
                    '{"trait_type":"Shield","value":"', _getShieldName(defaultTraits.shield), '"},',
                    '{"trait_type":"Color","value":"', _getColorName(defaultTraits.color), '"},',
                    '{"trait_type":"Weapon","value":"', _getWeaponName(defaultTraits.weapon), '"},',
                    '{"trait_type":"Background","value":"', _getBgName(defaultTraits.background), '"},',
                    '{"trait_type":"Eyes","value":"', _getEyesName(defaultTraits.eyes), '"},',
                    '{"display_type":"number","trait_type":"Rarity Score","value":', _uint2str(defaultTraits.rarityScore), '}',
                ']}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function generateMetadata(bytes32 attestationUID, uint256 tokenId) public pure returns (string memory) {
        require(tokenId >= GOLD && tokenId <= BRONZE, "Invalid token ID");
        
        TraitData memory traits = _selectTraits(attestationUID);
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
        
        string memory json = string(
            abi.encodePacked(
                '{"name":"Athena Audit Certificate #', _uint2str(uint256(uint256(attestationUID)) % 10000), '",',
                '"description":"', tierName, desc, _uint2str(traits.rarityScore), '/100",',
                '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
                '"attributes":[',
                    '{"trait_type":"Tier","value":"', tierName, '"},',
                    '{"trait_type":"Helmet","value":"', _getHelmetName(traits.helmet), '"},',
                    '{"trait_type":"Shield","value":"', _getShieldName(traits.shield), '"},',
                    '{"trait_type":"Color","value":"', _getColorName(traits.color), '"},',
                    '{"trait_type":"Weapon","value":"', _getWeaponName(traits.weapon), '"},',
                    '{"trait_type":"Background","value":"', _getBgName(traits.background), '"},',
                    '{"trait_type":"Eyes","value":"', _getEyesName(traits.eyes), '"},',
                    '{"display_type":"number","trait_type":"Rarity Score","value":', _uint2str(traits.rarityScore), '}',
                ']}'
            )
        );
        
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // ============ SVG Generation ============

    function _generateAthenaSVG(uint256 tokenId, TraitData memory traits) internal pure returns (string memory) {
        (string memory primary, string memory secondary, string memory accent) = _colorScheme(traits.color);
        string memory bgSvg = _svgBackground(traits.background, primary);
        string memory bodySvg = _svgBody(primary, secondary);
        string memory helmetSvg = _svgHelmet(traits.helmet, primary, accent);
        string memory shieldSvg = _svgShield(traits.shield, primary, secondary);
        string memory weaponSvg = _svgWeapon(traits.weapon, primary, accent);
        string memory eyesSvg = _svgEyes(traits.eyes, primary);
        
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320" width="320" height="320">',
                bgSvg,
                bodySvg,
                helmetSvg,
                shieldSvg,
                weaponSvg,
                eyesSvg,
                '<text x="160" y="310" font-family="monospace" font-size="10" fill="', primary, '" text-anchor="middle">ATHENA</text>',
                '</svg>'
            )
        );
    }

    function _colorScheme(uint8 colorId) internal pure returns (string memory primary, string memory secondary, string memory accent) {
        if (colorId == 0) return ("#FFD700", "#B8860B", "#FFA500"); // Gold
        if (colorId == 1) return ("#C0C0C0", "#808080", "#A9A9A9"); // Silver
        if (colorId == 2) return ("#CD7F32", "#8B4513", "#D2691E"); // Copper
        if (colorId == 3) return ("#9B59B6", "#6C3483", "#8E44AD"); // Purple
        if (colorId == 4) return ("#2ECC71", "#1E8449", "#27AE60"); // Green
        if (colorId == 5) return ("#3498DB", "#2471A3", "#2980B9"); // Blue
        if (colorId == 6) return ("#E74C3C", "#922B21", "#C0392B"); // Red
        return ("#2C3E50", "#1A252F", "#34495E"); // Black
    }

    function _svgBackground(uint8 bg, string memory primary) internal pure returns (string memory) {
        if (bg == 0) {
            // Starry sky
            return string(abi.encodePacked(
                '<rect width="320" height="320" fill="#0a0a2e"/>',
                '<circle cx="50" cy="30" r="2" fill="', primary, '" opacity="0.8"/>',
                '<circle cx="150" cy="20" r="1.5" fill="', primary, '" opacity="0.6"/>',
                '<circle cx="250" cy="40" r="2" fill="', primary, '" opacity="0.7"/>',
                '<circle cx="80" cy="80" r="1" fill="', primary, '" opacity="0.5"/>',
                '<circle cx="200" cy="60" r="1.5" fill="', primary, '" opacity="0.6"/>',
                '<circle cx="280" cy="100" r="1" fill="', primary, '" opacity="0.4"/>'
            ));
        } else if (bg == 1) {
            // Fire
            return string(abi.encodePacked(
                '<rect width="320" height="320" fill="#1a0a0a"/>',
                '<rect x="0" y="280" width="320" height="40" fill="#8B0000" opacity="0.5"/>',
                '<rect x="40" y="260" width="60" height="60" fill="#FF4500" opacity="0.3"/>',
                '<rect x="220" y="270" width="50" height="50" fill="#FF6347" opacity="0.3"/>'
            ));
        } else if (bg == 2) {
            // Ocean
            return string(abi.encodePacked(
                '<rect width="320" height="320" fill="#0a1a2e"/>',
                '<rect x="0" y="250" width="320" height="70" fill="#1a4a6e" opacity="0.5"/>',
                '<path d="M0,260 Q80,250 160,260 Q240,270 320,260" fill="none" stroke="#2E86C1" stroke-width="2" opacity="0.5"/>'
            ));
        } else if (bg == 3) {
            // Forest
            return string(abi.encodePacked(
                '<rect width="320" height="320" fill="#0a1a0a"/>',
                '<rect x="20" y="200" width="30" height="120" fill="#2d5a1e" opacity="0.6"/>',
                '<rect x="270" y="210" width="25" height="110" fill="#2d5a1e" opacity="0.5"/>',
                '<rect x="150" y="220" width="20" height="100" fill="#2d5a1e" opacity="0.4"/>'
            ));
        }
        // Aurora
        return string(abi.encodePacked(
            '<rect width="320" height="320" fill="#0a0a1a"/>',
            '<path d="M0,100 Q160,50 320,100" fill="none" stroke="#00FF7F" stroke-width="20" opacity="0.2"/>',
            '<path d="M0,120 Q160,70 320,120" fill="none" stroke="#00CED1" stroke-width="15" opacity="0.15"/>'
        ));
    }

    function _svgBody(string memory primary, string memory secondary) internal pure returns (string memory) {
        return string(abi.encodePacked(
            // Face
            '<rect x="135" y="55" width="50" height="35" fill="#ffd4a8"/>',
            // Body/Robe
            '<rect x="110" y="90" width="100" height="120" rx="5" fill="', secondary, '"/>',
            '<rect x="115" y="95" width="90" height="30" fill="', primary, '"/>',
            // Legs
            '<rect x="125" y="210" width="30" height="60" fill="', secondary, '"/>',
            '<rect x="165" y="210" width="30" height="60" fill="', secondary, '"/>',
            // Boots
            '<rect x="120" y="265" width="40" height="15" rx="3" fill="', primary, '"/>',
            '<rect x="160" y="265" width="40" height="15" rx="3" fill="', primary, '"/>'
        ));
    }

    function _svgHelmet(uint8 style, string memory primary, string memory accent) internal pure returns (string memory) {
        if (style == 0) {
            // Feathered helmet (羽饰)
            return string(abi.encodePacked(
                '<rect x="130" y="20" width="60" height="10" fill="', primary, '"/>',
                '<rect x="140" y="10" width="40" height="10" fill="', accent, '"/>',
                '<rect x="150" y="0" width="20" height="10" fill="', primary, '"/>',
                '<rect x="120" y="30" width="80" height="50" rx="10" fill="', primary, '"/>'
            ));
        } else if (style == 1) {
            // Horned helmet (双角)
            return string(abi.encodePacked(
                '<rect x="120" y="30" width="80" height="50" rx="8" fill="', primary, '"/>',
                '<rect x="110" y="20" width="15" height="30" rx="3" fill="', accent, '"/>',
                '<rect x="195" y="20" width="15" height="30" rx="3" fill="', accent, '"/>'
            ));
        } else if (style == 2) {
            // Crown (冠冕)
            return string(abi.encodePacked(
                '<rect x="120" y="30" width="80" height="50" rx="5" fill="', primary, '"/>',
                '<rect x="130" y="15" width="10" height="20" fill="', accent, '"/>',
                '<rect x="150" y="10" width="10" height="25" fill="', accent, '"/>',
                '<rect x="170" y="15" width="10" height="20" fill="', accent, '"/>'
            ));
        } else if (style == 3) {
            // Turban (头巾)
            return string(abi.encodePacked(
                '<rect x="120" y="30" width="80" height="50" rx="15" fill="', primary, '"/>',
                '<rect x="130" y="25" width="60" height="15" fill="', accent, '"/>',
                '<circle cx="160" cy="32" r="8" fill="', accent, '"/>'
            ));
        }
        // Classic helmet (经典)
        return string(abi.encodePacked(
            '<rect x="120" y="30" width="80" height="55" rx="10" fill="', primary, '"/>',
            '<rect x="130" y="40" width="60" height="10" fill="', accent, '"/>',
            '<rect x="145" y="55" width="30" height="5" fill="#1a1a2e"/>'
        ));
    }

    function _svgShield(uint8 pattern, string memory primary, string memory secondary) internal pure returns (string memory) {
        if (pattern == 0) {
            // Owl shield (猫头鹰)
            return string(abi.encodePacked(
                '<rect x="60" y="100" width="45" height="60" rx="8" fill="', primary, '"/>',
                '<rect x="68" y="108" width="29" height="44" rx="4" fill="', secondary, '"/>',
                '<rect x="75" y="118" width="15" height="15" fill="', primary, '"/>',
                '<circle cx="79" cy="124" r="3" fill="#1a1a2e"/>',
                '<circle cx="87" cy="124" r="3" fill="#1a1a2e"/>'
            ));
        } else if (pattern == 1) {
            // Snake hair shield (蛇发)
            return string(abi.encodePacked(
                '<rect x="60" y="100" width="45" height="60" rx="8" fill="', primary, '"/>',
                '<rect x="68" y="108" width="29" height="44" rx="4" fill="', secondary, '"/>',
                '<path d="M75,115 Q80,110 85,115 Q80,120 75,115" fill="', primary, '"/>',
                '<path d="M78,125 Q83,120 88,125 Q83,130 78,125" fill="', primary, '"/>'
            ));
        } else if (pattern == 2) {
            // Olive branch shield (橄榄枝)
            return string(abi.encodePacked(
                '<rect x="60" y="100" width="45" height="60" rx="8" fill="', primary, '"/>',
                '<rect x="68" y="108" width="29" height="44" rx="4" fill="', secondary, '"/>',
                '<path d="M75,130 Q82,115 89,130" fill="none" stroke="#2ECC71" stroke-width="2"/>',
                '<circle cx="78" cy="122" r="2" fill="#2ECC71"/>',
                '<circle cx="86" cy="118" r="2" fill="#2ECC71"/>'
            ));
        } else if (pattern == 3) {
            // Lightning shield (闪电)
            return string(abi.encodePacked(
                '<rect x="60" y="100" width="45" height="60" rx="8" fill="', primary, '"/>',
                '<rect x="68" y="108" width="29" height="44" rx="4" fill="', secondary, '"/>',
                '<path d="M82,110 L75,125 L82,125 L78,140" fill="none" stroke="#FFD700" stroke-width="3"/>'
            ));
        }
        // Blank shield (空白)
        return string(abi.encodePacked(
            '<rect x="60" y="100" width="45" height="60" rx="8" fill="', primary, '"/>',
            '<rect x="68" y="108" width="29" height="44" rx="4" fill="', secondary, '"/>'
        ));
    }

    function _svgWeapon(uint8 weaponType, string memory primary, string memory accent) internal pure returns (string memory) {
        if (weaponType == 0) {
            // Spear (长矛)
            return string(abi.encodePacked(
                '<rect x="230" y="50" width="6" height="180" fill="', primary, '"/>',
                '<rect x="224" y="40" width="18" height="15" rx="2" fill="', accent, '"/>'
            ));
        } else if (weaponType == 1) {
            // Bow (弓箭)
            return string(abi.encodePacked(
                '<path d="M230,50 Q250,130 230,210" fill="none" stroke="', primary, '" stroke-width="4"/>',
                '<line x1="230" y1="50" x2="230" y2="210" stroke="', accent, '" stroke-width="1"/>',
                '<path d="M230,120 L250,110 L250,130 Z" fill="', accent, '"/>'
            ));
        }
        // Sword (剑)
        return string(abi.encodePacked(
            '<rect x="228" y="60" width="4" height="140" fill="', primary, '"/>',
            '<rect x="218" y="195" width="24" height="8" rx="2" fill="', accent, '"/>',
            '<rect x="224" y="203" width="12" height="20" fill="', primary, '"/>'
        ));
    }

    function _svgEyes(uint8 eyeColor, string memory primary) internal pure returns (string memory) {
        string memory color;
        if (eyeColor == 0) color = "#3498DB"; // Blue
        else if (eyeColor == 1) color = "#2ECC71"; // Green
        else if (eyeColor == 2) color = "#FFD700"; // Gold
        else color = "#E74C3C"; // Red
        
        return string(abi.encodePacked(
            '<rect x="145" y="62" width="8" height="6" fill="', color, '"/>',
            '<rect x="167" y="62" width="8" height="6" fill="', color, '"/>',
            '<rect x="152" y="75" width="16" height="4" fill="#d4956a"/>'
        ));
    }

    // ============ Trait Name Helpers ============

    function _getHelmetName(uint8 style) internal pure returns (string memory) {
        if (style == 0) return "Feathered";
        if (style == 1) return "Horned";
        if (style == 2) return "Crown";
        if (style == 3) return "Turban";
        return "Classic";
    }

    function _getShieldName(uint8 pattern) internal pure returns (string memory) {
        if (pattern == 0) return "Owl";
        if (pattern == 1) return "Snake Hair";
        if (pattern == 2) return "Olive Branch";
        if (pattern == 3) return "Lightning";
        return "Blank";
    }

    function _getColorName(uint8 colorId) internal pure returns (string memory) {
        if (colorId == 0) return "Gold";
        if (colorId == 1) return "Silver";
        if (colorId == 2) return "Copper";
        if (colorId == 3) return "Purple";
        if (colorId == 4) return "Green";
        if (colorId == 5) return "Blue";
        if (colorId == 6) return "Red";
        return "Black";
    }

    function _getWeaponName(uint8 weaponType) internal pure returns (string memory) {
        if (weaponType == 0) return "Spear";
        if (weaponType == 1) return "Bow";
        return "Sword";
    }

    function _getBgName(uint8 bg) internal pure returns (string memory) {
        if (bg == 0) return "Starry Sky";
        if (bg == 1) return "Fire";
        if (bg == 2) return "Ocean";
        if (bg == 3) return "Forest";
        return "Aurora";
    }

    function _getEyesName(uint8 eyeColor) internal pure returns (string memory) {
        if (eyeColor == 0) return "Blue";
        if (eyeColor == 1) return "Green";
        if (eyeColor == 2) return "Gold";
        return "Red";
    }

    // ============ Utility ============

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

    function getCombinations() public pure returns (uint256) {
        return uint256(HELMET_VARIANTS) * 
               uint256(SHIELD_VARIANTS) * 
               uint256(COLOR_VARIANTS) * 
               uint256(WEAPON_VARIANTS) * 
               uint256(BG_VARIANTS) * 
               uint256(EYES_VARIANTS);
    }
}
