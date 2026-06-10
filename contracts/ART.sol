// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ART — Athena Reputation Token
/// @notice ERC-20 reputation token for audit achievements
/// @dev Minted per completed audit. 1000 ART = 1 NFT certificate eligibility.
contract ART is ERC20, Ownable {
    uint256 public constant ART_PER_AUDIT = 1000 ether;
    uint256 public constant ART_FOR_NFT = 1000 ether;

    mapping(address => uint256) public auditCount;

    event ARTMinted(address indexed auditor, uint256 amount, uint256 totalAudits);
    event ARTBurned(address indexed from, uint256 amount);

    constructor() ERC20("Athena Reputation Token", "ART") Ownable() {}

    /// @notice Mint ART for completing an audit (owner only)
    function mintForAudit(address auditor) external onlyOwner {
        require(auditor != address(0), "zero address");
        auditCount[auditor]++;
        _mint(auditor, ART_PER_AUDIT);
        emit ARTMinted(auditor, ART_PER_AUDIT, auditCount[auditor]);
    }

    /// @notice Batch mint for multiple audits
    function mintForAudits(address[] calldata auditors) external onlyOwner {
        for (uint256 i = 0; i < auditors.length; i++) {
            require(auditors[i] != address(0), "zero address");
            auditCount[auditors[i]]++;
            _mint(auditors[i], ART_PER_AUDIT);
            emit ARTMinted(auditors[i], ART_PER_AUDIT, auditCount[auditors[i]]);
        }
    }

    /// @notice Burn own ART
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit ARTBurned(msg.sender, amount);
    }

    /// @notice Check if holder has enough ART for NFT
    function eligibleForNFT(address account) external view returns (bool) {
        return balanceOf(account) >= ART_FOR_NFT;
    }
}
