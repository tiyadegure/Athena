// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MultiChainRegistry - Cross-chain contract registry
/// @notice Tracks Athena deployments across multiple chains
contract MultiChainRegistry {
    struct ChainDeployment {
        uint256 chainId;
        address nftContract;
        address escrowContract;
        address trailContract;
        address metadataContract;
        uint256 deployedAt;
        bool active;
    }

    mapping(uint256 => ChainDeployment) public chains;
    uint256[] public registeredChains;
    address public owner;

    event ChainRegistered(uint256 indexed chainId, address nftContract, address escrowContract);
    event ChainUpdated(uint256 indexed chainId, address nftContract, address escrowContract);

    constructor() {
        owner = msg.sender;
    }

    function registerChain(
        uint256 chainId,
        address nftContract,
        address escrowContract,
        address trailContract,
        address metadataContract
    ) external {
        require(msg.sender == owner, "Not owner");
        require(nftContract != address(0), "Invalid NFT contract");

        chains[chainId] = ChainDeployment({
            chainId: chainId,
            nftContract: nftContract,
            escrowContract: escrowContract,
            trailContract: trailContract,
            metadataContract: metadataContract,
            deployedAt: block.timestamp,
            active: true
        });

        registeredChains.push(chainId);
        emit ChainRegistered(chainId, nftContract, escrowContract);
    }

    function updateChain(
        uint256 chainId,
        address nftContract,
        address escrowContract,
        address trailContract,
        address metadataContract
    ) external {
        require(msg.sender == owner, "Not owner");
        ChainDeployment storage c = chains[chainId];
        require(c.deployedAt != 0, "Chain not registered");

        if (nftContract != address(0)) c.nftContract = nftContract;
        if (escrowContract != address(0)) c.escrowContract = escrowContract;
        if (trailContract != address(0)) c.trailContract = trailContract;
        if (metadataContract != address(0)) c.metadataContract = metadataContract;

        emit ChainUpdated(chainId, nftContract, escrowContract);
    }

    function getChain(uint256 chainId) external view returns (
        address nftContract,
        address escrowContract,
        address trailContract,
        address metadataContract,
        uint256 deployedAt,
        bool active
    ) {
        ChainDeployment memory c = chains[chainId];
        return (c.nftContract, c.escrowContract, c.trailContract, c.metadataContract, c.deployedAt, c.active);
    }

    function getRegisteredChains() external view returns (uint256[] memory) {
        return registeredChains;
    }
}
