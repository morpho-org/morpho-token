// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {DelegationToken} from "../src/abstracts/DelegationToken.sol";

contract DelegationTokenInternalTest is Test, DelegationToken {
    uint256 internal constant MAX_TEST_AMOUNT = 1e28;

    function __getInitializableStorage() internal pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00
        }
    }

    function _delegatedVotingPower(address account) internal view returns (uint256) {
        DelegationTokenStorage storage $ = _getDelegationTokenStorage();
        return $._delegatedVotingPower[account];
    }

    function testDisabledInitializers() public view {
        InitializableStorage storage $ = __getInitializableStorage();
        assertEq($._initialized, type(uint64).max, "Initializers not disabled");
    }

    function testDelegationTokenStorageLocation() public pure {
        bytes32 expectedSlot =
            keccak256(abi.encode(uint256(keccak256("DelegationToken")) - 1)) & ~bytes32(uint256(0xff));
        bytes32 usedSlot = DelegationTokenStorageLocation;
        assertEq(expectedSlot, usedSlot, "Wrong slot used");
    }

    function testMoveDelegateVotesDifferentAccounts(
        address from,
        address to,
        uint256 initialVoteFrom,
        uint256 initialVoteTo,
        uint256 amount
    ) public {
        // Setup
        DelegationTokenStorage storage $ = _getDelegationTokenStorage();
        initialVoteFrom = bound(initialVoteFrom, 0, MAX_TEST_AMOUNT);
        $._delegatedVotingPower[from] = initialVoteFrom;
        initialVoteTo = bound(initialVoteTo, 0, MAX_TEST_AMOUNT);
        $._delegatedVotingPower[to] = initialVoteTo;

        assertEq(_delegatedVotingPower(from), initialVoteFrom);
        assertEq(_delegatedVotingPower(to), initialVoteTo);

        // Test
        amount = bound(amount, 0, initialVoteFrom);
        _moveDelegateVotes(from, to, amount);

        uint256 expectedVoteFrom = from == address(0) ? initialVoteFrom : initialVoteFrom - amount;
        uint256 expectedVoteTo = to == address(0) ? initialVoteTo : initialVoteTo + amount;

        assertEq(_delegatedVotingPower(from), expectedVoteFrom, "move delegate from");
        assertEq(_delegatedVotingPower(to), expectedVoteTo, "move delegate to");
    }

    function testMoveDelegateVotesSameAccounts(address account, uint256 initialVote, uint256 amount) public {
        // Setup
        DelegationTokenStorage storage $ = _getDelegationTokenStorage();
        $._delegatedVotingPower[account] = initialVote;
        assertEq(_delegatedVotingPower(account), initialVote);

        // Test
        _moveDelegateVotes(account, account, amount);

        assertEq(_delegatedVotingPower(account), initialVote, "unchanged delegate account");
    }

    function testDelegate(address delegator, address oldDelegatee, address newDelegatee) public {
        // Setup
        DelegationTokenStorage storage $ = _getDelegationTokenStorage();
        $._delegatee[delegator] = oldDelegatee;
        assertEq(delegatee(delegator), oldDelegatee);

        // Test
        _delegate(delegator, newDelegatee);
        assertEq(delegatee(delegator), newDelegatee);
    }
}
