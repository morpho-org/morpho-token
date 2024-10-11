// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC20Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {DelegatesUpgradeable} from "./DelegatesUpgradeable.sol";
import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
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
     * @dev Total supply cap has been exceeded, introducing a risk of votes overflowing.
     */
    error ERC20ExceededSafeSupply(uint256 increasedSupply, uint256 cap);

    function __ERC20Delegates_init() internal onlyInitializing {}

    function __ERC20Delegates_init_unchained() internal onlyInitializing {}
    /**
     * @dev Maximum token supply. Defaults to `type(uint208).max` (2^208^ - 1).
     *
     * This maximum is enforced in {_update}. Increasing this value will not remove the underlying limitation, and
     * will cause {_update} to fail because of a math overflow in {_transferVotingUnits}. An override could be
     * used to further restrict the total supply (to a lower value) if additional logic requires it. When resolving
     * override conflicts on this function, the minimum should be returned.
     */

    function _maxSupply() internal view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);
        if (from == address(0)) {
            uint256 supply = totalSupply();
            uint256 cap = _maxSupply();
            if (supply > cap) {
                revert ERC20ExceededSafeSupply(supply, cap);
            }
        }
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
