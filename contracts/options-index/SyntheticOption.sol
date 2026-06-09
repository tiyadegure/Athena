// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SyntheticOption - P (Call) and N (Put) option tokens
/// @notice Based on Vitalik's "Options-Based Index Tracking" (2026-06-01)
/// @dev P + N = 1 always holds, no liquidation needed

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

/// @notice Option token (P or N)
contract OptionToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    
    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function burn(address from, uint256 amount) external {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
    
    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
}

/// @title SyntheticOption - Split/Merge 1 ETH into P + N options
/// @notice Implements Vitalik's option-based synthetic asset mechanism
contract SyntheticOption {
    // Option parameters
    string public ticker;          // e.g., "USD/ETH"
    uint256 public strikePrice;    // Strike price S (in target units)
    uint256 public maturity;       // Maturity timestamp M
    
    // Option tokens
    OptionToken public pToken;     // Call option (P)
    OptionToken public nToken;     // Put option (N)
    
    // Collateral
    address public collateralToken = address(0); // ETH (address(0) = native ETH)
    uint256 public constant PRECISION = 1e18;
    
    // State
    bool public matured;
    uint256 public lastPrice;
    
    event Split(address indexed user, uint256 amount, uint256 pAmount, uint256 nAmount);
    event Merge(address indexed user, uint256 pAmount, uint256 nAmount, uint256 amount);
    event Matured(uint256 finalPrice, uint256 timestamp);
    event Redeemed(address indexed user, uint256 pPayout, uint256 nPayout);
    
    constructor(
        string memory _ticker,
        uint256 _strikePrice,
        uint256 _maturity
    ) {
        ticker = _ticker;
        strikePrice = _strikePrice;
        maturity = _maturity;
        
        pToken = new OptionToken(
            string(abi.encodePacked(_ticker, " Call")),
            string(abi.encodePacked(_ticker, "-C"))
        );
        
        nToken = new OptionToken(
            string(abi.encodePacked(_ticker, " Put")),
            string(abi.encodePacked(_ticker, "-N"))
        );
    }
    
    /// @notice Split 1 ETH into P + N tokens
    /// @dev P + N = 1 always holds
    function split() external payable {
        require(!matured, "Already matured");
        require(msg.value > 0, "Zero amount");
        
        // Mint P and N tokens 1:1
        uint256 amount = msg.value;
        pToken.mint(msg.sender, amount);
        nToken.mint(msg.sender, amount);
        
        emit Split(msg.sender, amount, amount, amount);
    }
    
    /// @notice Merge P + N tokens to redeem 1 ETH
    /// @dev Burns equal amounts of P and N
    function merge(uint256 amount) external {
        require(!matured, "Already matured");
        require(amount > 0, "Zero amount");
        require(pToken.balanceOf(msg.sender) >= amount, "Insufficient P tokens");
        require(nToken.balanceOf(msg.sender) >= amount, "Insufficient N tokens");
        
        // Burn P and N tokens
        pToken.burn(msg.sender, amount);
        nToken.burn(msg.sender, amount);
        
        // Return collateral
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Merge(msg.sender, amount, amount, amount);
    }
    
    /// @notice Get option payout at current price
    /// @param currentPrice Current price x (in target units)
    /// @return pPayoff P (call) payoff: min(1, S/x)
    /// @return nPayoff N (put) payoff: max(0, 1-S/x)
    function getPayoff(uint256 currentPrice) public view returns (uint256 pPayoff, uint256 nPayoff) {
        // P = min(1, S/x)
        // N = max(0, 1 - S/x)
        // P + N = 1 always
        
        if (currentPrice == 0) {
            return (PRECISION, 0); // Edge case: price = 0
        }
        
        uint256 ratio = (strikePrice * PRECISION) / currentPrice; // S/x
        
        if (ratio >= PRECISION) {
            // S >= x: P = 1, N = 0
            pPayoff = PRECISION;
            nPayoff = 0;
        } else {
            // S < x: P = S/x, N = 1 - S/x
            pPayoff = ratio;
            nPayoff = PRECISION - ratio;
        }
    }
    
    /// @notice Mature the option (settle at final price)
    /// @param finalPrice Final price at maturity
    function mature(uint256 finalPrice) external {
        require(block.timestamp >= maturity, "Not yet matured");
        require(!matured, "Already matured");
        
        matured = true;
        lastPrice = finalPrice;
        
        emit Matured(finalPrice, block.timestamp);
    }
    
    /// @notice Redeem options after maturity
    function redeem() external {
        require(matured, "Not yet matured");
        
        uint256 pBalance = pToken.balanceOf(msg.sender);
        uint256 nBalance = nToken.balanceOf(msg.sender);
        
        if (pBalance == 0 && nBalance == 0) return;
        
        (uint256 pPayoff, uint256 nPayoff) = getPayoff(lastPrice);
        
        // Calculate payouts
        uint256 pPayout = (pBalance * pPayoff) / PRECISION;
        uint256 nPayout = (nBalance * nPayoff) / PRECISION;
        uint256 totalPayout = pPayout + nPayout;
        
        // Burn tokens
        if (pBalance > 0) pToken.burn(msg.sender, pBalance);
        if (nBalance > 0) nToken.burn(msg.sender, nBalance);
        
        // Transfer payout
        if (totalPayout > 0) {
            (bool success, ) = msg.sender.call{value: totalPayout}("");
            require(success, "Transfer failed");
        }
        
        emit Redeemed(msg.sender, pPayout, nPayout);
    }
    
    /// @notice Check if option is matured
    function isMatured() external view returns (bool) {
        return matured;
    }
    
    /// @notice Get time until maturity
    function timeToMaturity() external view returns (uint256) {
        if (block.timestamp >= maturity) return 0;
        return maturity - block.timestamp;
    }
    
    receive() external payable {}
}
