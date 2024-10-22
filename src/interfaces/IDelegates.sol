// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IDelegates
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice The Delegates interface.
interface IDelegates {
    // @dev The signature used has expired.
    error DelegatesExpiredSignature(uint256 expiry);

    // @dev The delegation nonce used by `delegator` is not its current delegation nonce.
    error InvalidDelegationNonce(address delegator, uint256 currentNonce);

    // @dev Emitted when an delegator changes their delegate.
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of voting units.
    event DelegateVotesChanged(address indexed delegate, uint256 previousVotes, uint256 newVotes);

    // @dev Returns the current amount of votes that `delegator` has.
    function delegatedVotingPower(address delegator) external view returns (uint256);

    // @dev Returns the delegate that `delegator` has chosen.
    function delegatee(address delegator) external view returns (address);

    // @dev Delegates votes from the sender to `delegatee`.
    function delegate(address delegatee) external;

    // @dev Delegates votes from signer to `delegatee`.
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
}
