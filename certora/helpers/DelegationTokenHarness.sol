// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {DelegationToken} from "../../src/DelegationToken.sol";

import {ERC20PermitUpgradeable} from
    "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

abstract contract DelegationTokenHarness is DelegationToken {
    /// @dev Hookable copy of _moveDelegateVotes.
    function _moveDelegateVotesExternal(address from, address to, uint256 amount) external {
        DelegationTokenStorage storage $ = _getDelegationTokenStorage();
        if (from != to && amount > 0) {
            if (from != address(0)) {
                uint256 oldValue = $._delegatedVotingPower[from];
                uint256 newValue = oldValue - amount;
                $._delegatedVotingPower[from] = newValue;
                emit DelegatedVotingPowerChanged(from, oldValue, newValue);
            }
            if (to != address(0)) {
                uint256 oldValue = $._delegatedVotingPower[to];
                uint256 newValue = oldValue + amount;
                $._delegatedVotingPower[to] = newValue;
                emit DelegatedVotingPowerChanged(to, oldValue, newValue);
            }
        }
    }

    /// @dev Hookable copy of _burn.
    function _burnExternal(address account, uint256 value) external {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }
}
