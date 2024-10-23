// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {DelegationToken} from "../src/DelegationToken.sol";

contract DelegationTokenInternalTest is Test, DelegationToken {
    function getInitializableStorage() internal pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00
        }
    }

    function testDelegationTokenStorageLocation() public pure {
        bytes32 expectedSlot =
            keccak256(abi.encode(uint256(keccak256("DelegationToken")) - 1)) & ~bytes32(uint256(0xff));
        bytes32 usedSlot = DelegationTokenStorageLocation;
        assertEq(expectedSlot, usedSlot, "Wrong slot used");
    }

    function testDisabledInitializers() public view {
        InitializableStorage storage $ = getInitializableStorage();
        assertEq($._initialized, type(uint64).max, "Initializers not disabled");
    }
}
