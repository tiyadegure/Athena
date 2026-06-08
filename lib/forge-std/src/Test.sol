// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Test {
    event log(string);
    event log_named_uint(string key, uint val);
    event log_named_address(string key, address val);
    event log_named_bytes32(string key, bytes32 val);
    event log_named_string(string key, string val);

    bool public IS_TEST = true;
    bool private _failed;

    address internal constant VM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));

    function failed() public view returns (bool) {
        return _failed;
    }

    function fail() public {
        _failed = true;
        revert("Test::FAIL");
    }

    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
    }

    function assertTrue(bool condition, string memory reason) internal {
        if (!condition) {
            emit log(reason);
            fail();
        }
    }

    function assertFalse(bool condition) internal {
        assertTrue(!condition);
    }

    function assertEq(uint a, uint b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            fail();
        }
    }

    function assertEq(address a, address b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }

    function assertEq(bool a, bool b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied");
            fail();
        }
    }

    function assertGt(uint a, uint b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied");
            fail();
        }
    }

    function assertLt(uint a, uint b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied");
            fail();
        }
    }

    function assertGe(uint a, uint b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied");
            fail();
        }
    }

    function assertLe(uint a, uint b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied");
            fail();
        }
    }
}
