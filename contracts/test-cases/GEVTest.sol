// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GEVTest
 * @notice Test case for Generalized Extractable Value — oracle manipulation, flash loan governance attack, and liquidation exploits
 * @difficulty Advanced
 * @vuln_types MEV, Flash Loan Governance, Oracle Manipulation, Liquidation
 * @expected_findings SimpleOracle.setPrice() has no access control; SimpleGovernance.vote() uses current voting power (flash-loan exploitable); GEVTest.borrow() relies on manipulable oracle; liquidation can be triggered by oracle manipulation
 * @audit_command claude "audit contracts/test-cases/GEVTest.sol"
 */

/// @title GEVTest - Test contract for Generalized Extractable Value analysis
/// @notice Demonstrates various GEV attack vectors
/// @dev Based on "Extraction Is Conserved: From MEV to GEV" (2026-05-25)

/// @notice Simple oracle for testing
contract SimpleOracle {
    mapping(address => uint256) public prices;
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function setPrice(address token, uint256 price) external {
        // VULNERABILITY: Anyone can set price (no access control)
        prices[token] = price;
    }
    
    function getPrice(address token) external view returns (uint256) {
        return prices[token];
    }
}

/// @notice Simple governance for testing
contract SimpleGovernance {
    struct Proposal {
        address target;
        bytes data;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 deadline;
        bool executed;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    
    uint256 public proposalCount;
    address public token;
    
    constructor(address _token) {
        token = _token;
    }
    
    function propose(address target, bytes calldata data) external returns (uint256) {
        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            target: target,
            data: data,
            forVotes: 0,
            againstVotes: 0,
            deadline: block.timestamp + 3 days,
            executed: false
        });
        return proposalId;
    }
    
    /// @notice VULNERABLE: Flash loan voting
    function vote(uint256 proposalId, bool support) external {
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        
        uint256 power = votingPower[msg.sender];
        // VULNERABILITY: Uses current voting power, not snapshot
        // Flash loan can temporarily boost voting power
        
        if (support) {
            proposals[proposalId].forVotes += power;
        } else {
            proposals[proposalId].againstVotes += power;
        }
        
        hasVoted[msg.sender][proposalId] = true;
    }
    
    function execute(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.deadline, "Not ended");
        require(p.forVotes > p.againstVotes, "Not passed");
        require(!p.executed, "Already executed");
        
        p.executed = true;
        (bool success, ) = p.target.call(p.data);
        require(success, "Execution failed");
    }
    
    function setVotingPower(address voter, uint256 power) external {
        // VULNERABILITY: No access control
        votingPower[voter] = power;
    }
}

/// @title GEVTest - Demonstrates GEV vulnerabilities
contract GEVTest {
    SimpleOracle public oracle;
    SimpleGovernance public governance;
    
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;
    
    uint256 public constant COLLATERAL_RATIO = 150;
    
    constructor(address _oracle, address _governance) {
        oracle = SimpleOracle(_oracle);
        governance = SimpleGovernance(_governance);
    }
    
    /// @notice Deposit collateral
    function deposit() external payable {
        deposits[msg.sender] += msg.value;
    }
    
    /// @notice Borrow against collateral
    /// @dev VULNERABLE: Uses manipulable oracle price
    function borrow(uint256 amount) external {
        uint256 price = oracle.getPrice(address(this));
        uint256 collateralValue = (deposits[msg.sender] * price) / 1e18;
        uint256 maxBorrow = (collateralValue * 100) / COLLATERAL_RATIO;
        
        require(borrows[msg.sender] + amount <= maxBorrow, "Exceeds limit");
        
        borrows[msg.sender] += amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /// @notice Liquidate undercollateralized position
    /// @dev Can be triggered by oracle manipulation
    function liquidate(address user) external {
        uint256 price = oracle.getPrice(address(this));
        uint256 collateralValue = (deposits[user] * price) / 1e18;
        
        require(collateralValue < borrows[user], "Position healthy");
        
        // Seize collateral
        uint256 seized = deposits[user];
        deposits[user] = 0;
        borrows[user] = 0;
        
        (bool success, ) = msg.sender.call{value: seized}("");
        require(success, "Transfer failed");
    }
    
    /// @notice VULNERABLE: Governance can drain funds
    function executeGovernanceProposal(bytes calldata data) external {
        // Only governance can call
        // But governance is vulnerable to flash loan voting
        (bool success, ) = address(this).call(data);
        require(success, "Execution failed");
    }
    
    receive() external payable {}
}
