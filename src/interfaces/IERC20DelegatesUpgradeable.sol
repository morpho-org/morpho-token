// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title IDelegates
/// @author Morpho Labs
/// @custom:contact security@morpho.org
interface IERC20DelegatesUpgradeable {
    function delegatedVotingPower(address account) external view returns (uint256);

    function delegates(address account) external view returns (address);

    function delegationNonce(address account) external view returns (uint256);

<<<<<<< HEAD
    // @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of voting units.
    event DelegateVotesChanged(address indexed delegate, uint256 previousVotes, uint256 newVotes);

    // @dev Returns the current amount of votes that `delegator` has.
    function delegatedVotingPower(address delegator) external view returns (uint256);

    // @dev Returns the delegatee that `delegator` has chosen.
    function delegatee(address delegator) external view returns (address);

    // @dev Delegates votes from the sender to `delegatee`.
=======
>>>>>>> style/docs-and-naming
    function delegate(address delegatee) external;

    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
}
