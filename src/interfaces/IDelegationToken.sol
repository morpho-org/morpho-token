// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IERC20} from
    "../../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title IDelegationToken
/// @author Morpho Association
/// @custom:contact security@morpho.org
interface IDelegationToken is IERC20 {
    function delegatedVotingPower(address account) external view returns (uint256);

    function delegatee(address account) external view returns (address);

    function delegationNonce(address account) external view returns (uint256);

    function delegate(address delegatee) external;

    function delegateWithSig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s)
        external;
}
