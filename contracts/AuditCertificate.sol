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
contract AuditCertificate is ERC1155, Ownable {
    using Strings for uint256;

    // ============ Token IDs ============
    uint256 public constant GOLD = 1;     // A级 - Critical
    uint256 public constant SILVER = 2;   // B级 - High/Medium
    uint256 public constant BRONZE = 3;   // C级 - Low/Info

    // ============ EAS Address (injected via constructor) ============
    /// @notice EAS contract address - injected at deployment for testability
    address public immutable easContract;
    bytes32 public constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;

    // ============ State ============
    /// @notice 已使用的 attestation（防重复铸造）
    mapping(bytes32 => bool) public usedAttestations;

    /// @notice 审计记录：attestation UID => audit info
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
    /// @param _eas Address of EAS contract (Sepolia: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e)
    constructor(address _eas) ERC1155("") Ownable() {
        require(_eas != address(0), "Invalid EAS address");
        easContract = _eas;
    }

    // ============ Core Functions ============

    /// @notice 根据 EAS attestation 铸造 NFT
    /// @param to 接收地址
    /// @param attestationUID EAS attestation UID
    function mintCertificate(
        address to,
        bytes32 attestationUID
    ) external {
        require(to != address(0), "Invalid recipient");
        require(attestationUID != ZERO_BYTES32, "Invalid attestation UID");
        require(!usedAttestations[attestationUID], "Attestation already used");

        // 1. 验证 attestation 存在且有效
        IEAS eas = IEAS(easContract);
        require(eas.isAttestationValid(attestationUID), "Invalid attestation");

        // 2. 读取 attestation 数据
        Attestation memory att = eas.getAttestation(attestationUID);

        // 3. 从 att.data 中解码 severity
        // Schema: uint8 auditScore, uint16 vulnerabilitiesFound, string auditMode, uint64 timestamp, address contractAddress
        (uint8 auditScore, , , uint64 timestamp, address contractAddress) = 
            abi.decode(att.data, (uint8, uint16, string, uint64, address));

        // 4. 根据 auditScore 映射到 tokenId
        // auditScore: 1=Critical(Gold), 3=High(Silver), 5=Medium(Silver), 7-9=Bronze, 10=Safe
        uint256 tokenId;
        if (auditScore <= 1) {
            tokenId = GOLD;      // Critical → A级
        } else if (auditScore <= 5) {
            tokenId = SILVER;    // High/Medium → B级
        } else {
            tokenId = BRONZE;    // Low/Info → C级
        }

        // 5. 铸造
        _mint(to, tokenId, 1, "");

        // 6. 标记已使用 + 记录
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

    /// @notice 返回 NFT 元数据（包含链上 SVG）
    /// @param tokenId Token ID (1/2/3)
    function uri(uint256 tokenId) public pure override returns (string memory) {
        require(tokenId >= GOLD && tokenId <= BRONZE, "Invalid token ID");

        string memory tokenName;
        string memory description;
        string memory svg;

        if (tokenId == GOLD) {
            tokenName = unicode"Audit Certificate - Gold (A级)";
            description = "Awarded for discovering Critical vulnerabilities with verified PoC";
            svg = _generateAthenaSVG("#FFD700", "#B8860B", "#FFA500");
        } else if (tokenId == SILVER) {
            tokenName = unicode"Audit Certificate - Silver (B级)";
            description = "Awarded for discovering High/Medium vulnerabilities with fix recommendations";
            svg = _generateAthenaSVG("#C0C0C0", "#808080", "#A9A9A9");
        } else {
            tokenName = unicode"Audit Certificate - Bronze (C级)";
            description = "Awarded for completing security audit scan and report";
            svg = _generateAthenaSVG("#CD7F32", "#8B4513", "#D2691E");
        }

        string memory json = string(
            abi.encodePacked(
                '{"name":"', tokenName, '",',
                '"description":"', description, '",',
                '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
                '"attributes":[{"trait_type":"Tier","value":"', 
                tokenId == GOLD ? "Gold" : (tokenId == SILVER ? "Silver" : "Bronze"),
                '"}]}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // ============ SVG Generation ============

    /// @notice 生成像素风雅典娜 SVG
    /// @param primary 主色调 (金色/银色/铜色)
    /// @param secondary 次要色
    /// @param accent 强调色
    function _generateAthenaSVG(
        string memory primary,
        string memory secondary,
        string memory accent
    ) internal pure returns (string memory) {
        // 32x32 像素雅典娜女神
        // 设计元素：头盔(带羽饰)、长矛、盾牌、长袍
        
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320" width="320" height="320">',
                '<rect width="320" height="320" fill="#1a1a2e"/>',
                
                // 头盔 - 顶部羽饰
                '<rect x="130" y="20" width="60" height="10" fill="', primary, '"/>',
                '<rect x="140" y="10" width="40" height="10" fill="', accent, '"/>',
                '<rect x="150" y="0" width="20" height="10" fill="', primary, '"/>',
                
                // 头盔 - 主体
                '<rect x="120" y="30" width="80" height="50" rx="10" fill="', secondary, '"/>',
                '<rect x="130" y="35" width="60" height="15" fill="', primary, '"/>',
                
                // 面部
                '<rect x="135" y="55" width="50" height="35" fill="#ffd4a8"/>',
                // 眼睛
                '<rect x="145" y="62" width="8" height="6" fill="#1a1a2e"/>',
                '<rect x="167" y="62" width="8" height="6" fill="#1a1a2e"/>',
                // 嘴
                '<rect x="152" y="75" width="16" height="4" fill="#d4956a"/>',
                
                // 身体 - 长袍
                '<rect x="110" y="90" width="100" height="120" rx="5" fill="', secondary, '"/>',
                '<rect x="115" y="95" width="90" height="30" fill="', primary, '"/>',
                
                // 盾牌 (左侧)
                '<rect x="60" y="100" width="45" height="60" rx="8" fill="', primary, '"/>',
                '<rect x="68" y="108" width="29" height="44" rx="4" fill="', secondary, '"/>',
                // 猫头鹰图案
                '<rect x="75" y="118" width="15" height="15" fill="', primary, '"/>',
                '<rect x="78" y="121" width="4" height="4" fill="#1a1a2e"/>',
                '<rect x="86" y="121" width="4" height="4" fill="#1a1a2e"/>',
                
                // 长矛 (右侧)
                '<rect x="230" y="50" width="6" height="180" fill="', primary, '"/>',
                '<rect x="224" y="40" width="18" height="15" rx="2" fill="', accent, '"/>',
                
                // 腿部
                '<rect x="125" y="210" width="30" height="60" fill="', secondary, '"/>',
                '<rect x="165" y="210" width="30" height="60" fill="', secondary, '"/>',
                
                // 靴子
                '<rect x="120" y="265" width="40" height="15" rx="3" fill="', primary, '"/>',
                '<rect x="160" y="265" width="40" height="15" rx="3" fill="', primary, '"/>',
                
                // 底部装饰
                '<rect x="80" y="290" width="160" height="10" fill="', primary, '" opacity="0.5"/>',
                '<rect x="100" y="300" width="120" height="8" fill="', accent, '" opacity="0.3"/>',
                
                // 文字 "GLM AUDIT"
                '<text x="160" y="315" font-family="monospace" font-size="10" fill="', primary, '" text-anchor="middle">GLM AUDIT</text>',
                
                '</svg>'
            )
        );
    }

    // ============ View Functions ============

    /// @notice 获取 NFT 名称
    function name(uint256 tokenId) public pure returns (string memory) {
        if (tokenId == GOLD) return "Audit Certificate - Gold";
        if (tokenId == SILVER) return "Audit Certificate - Silver";
        if (tokenId == BRONZE) return "Audit Certificate - Bronze";
        revert("Invalid token ID");
    }

    /// @notice 检查 attestation 是否已使用
    function isAttestationUsed(bytes32 attestationUID) external view returns (bool) {
        return usedAttestations[attestationUID];
    }

    /// @notice 获取总供应量
    function totalSupply(uint256 tokenId) external view returns (uint256) {
        return this.totalSupply(tokenId);
    }
}
