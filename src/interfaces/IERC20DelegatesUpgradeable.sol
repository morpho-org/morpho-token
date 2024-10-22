// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title IDelegates
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice The Delegates interface.
interface IERC20DelegatesUpgradeable {
    // @dev The signature used has expired.
    error DelegatesExpiredSignature(uint256 expiry);

    // @dev The delegation nonce used by the signer is not its current delegation nonce.
    error InvalidDelegationNonce();

    // @dev Emitted when an delegator changes their delegate.
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of voting units.
    event DelegateVotesChanged(address indexed delegate, uint256 previousVotes, uint256 newVotes);

    // @dev Returns the current amount of votes that `account` has.
    function delegatedVotingPower(address account) external view returns (uint256);

    // @dev Returns the delegatee that `account` has chosen.
    function delegates(address account) external view returns (address);

    // @dev Returns the current delegation nonce of `account`.
    function delegationNonce(address account) external view returns (uint256);

    // @dev Delegates votes from the sender to `delegatee`.
    function delegate(address delegatee) external;

    // @dev Delegates votes from signer to `delegatee`.
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
}
