// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract DSTest {
    event log(string);
    event log_named_uint(string key, uint val);
    event log_named_address(string key, address val);
    event log_named_bytes32(string key, bytes32 val);
    event log_named_string(string key, string val);

    bool public IS_TEST = true;
    bool private _failed;

    function failed() public view returns (bool) {
        return _failed;
    }

    function fail() public {
        _failed = true;
        revert("DSTest::FAIL");
    }

    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
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
}
