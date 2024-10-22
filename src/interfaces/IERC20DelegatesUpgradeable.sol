// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title IDelegates
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice The Delegates interface.
interface IERC20DelegatesUpgradeable {
    function delegatedVotingPower(address account) external view returns (uint256);

    function delegates(address account) external view returns (address);

    function delegationNonce(address account) external view returns (uint256);

    function delegate(address delegatee) external;

    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
}
