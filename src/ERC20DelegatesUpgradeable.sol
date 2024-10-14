// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DelegatesUpgradeable} from "./DelegatesUpgradeable.sol";
import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
/**
 * @dev Extension of ERC20 to support token delegation.                  |
 *
 * This extension keeps track of each account's vote power. Vote power can be delegated eithe by calling the
 * {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting power can be
 * queried through the public accessor {getVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate their voting power.
 */

abstract contract ERC20DelegatesUpgradeable is Initializable, ERC20Upgradeable, DelegatesUpgradeable {
    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);
        _transferVotingUnits(from, to, value);
    }

    /**
     * @dev Returns the voting units of an `account`.
     *
     * WARNING: Overriding this function may compromise the internal vote accounting.
     * `ERC20Delegates` assumes tokens map to voting units 1:1 and this is not easy to change.
     */
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return balanceOf(account);
    }
}
