// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {DelegationToken} from "../src/DelegationToken.sol";

contract DelegationTokenInternalTest is Test, DelegationToken {
    function testDelegationTokenStorageLocation() public pure {
        bytes32 expectedSlot =
            keccak256(abi.encode(uint256(keccak256("DelegationToken")) - 1)) & ~bytes32(uint256(0xff));
        bytes32 usedSlot = DelegationTokenStorageLocation;
        assertEq(expectedSlot, usedSlot, "Wrong slot used");
    }
}
