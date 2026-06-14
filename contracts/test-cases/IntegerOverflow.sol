// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VulnerableAuction
 * @notice Test case for integer overflow in unchecked blocks — batchBid() totals can wrap around
 * @difficulty Intermediate
 * @vuln_types Integer Overflow, Unchecked Arithmetic, Reentrancy
 * @expected_findings batchBid() sums amounts in unchecked{} allowing overflow to fake high bids; claimRefund() has reentrancy via external call before zeroing refund balance
 * @audit_command claude "audit contracts/test-cases/IntegerOverflow.sol"
 */

/// @title VulnerableAuction - Test case for integer overflow vulnerability
/// @notice This contract intentionally contains unchecked arithmetic for audit testing
contract VulnerableAuction {
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public refunds;
    
    /// @notice Place a bid in the auction
    function bid() public payable {
        require(msg.value > highestBid, "Bid too low");
        
        if (highestBidder != address(0)) {
            refunds[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
    }
    
    /// @notice Claim refund for outbid bidder
    /// @dev BUG: Potential overflow in refund calculation due to unchecked block
    function claimRefund() public {
        uint256 refund = refunds[msg.sender];
        require(refund > 0, "No refund");
        
        // Unchecked block allows overflow
        unchecked {
            refunds[msg.sender] = 0;
            (bool success, ) = msg.sender.call{value: refund}("");
            require(success, "Refund failed");
        }
    }
    
    /// @notice Place multiple bids in batch
    /// @dev BUG: Potential overflow in total calculation
    function batchBid(uint256[] calldata amounts) public {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            unchecked {
                total += amounts[i]; // Can overflow
            }
        }
        require(total > highestBid, "Total bid too low");
        highestBidder = msg.sender;
        highestBid = total;
    }
}
