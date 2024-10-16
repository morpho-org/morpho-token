// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDelegates} from "./interfaces/IDelegates.sol";

import {ERC20Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {ECDSA} from
    "lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {NoncesUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/utils/NoncesUpgradeable.sol";
import {EIP712Upgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/EIP712Upgradeable.sol";
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
abstract contract ERC20DelegatesUpgradeable is
    Initializable,
    ERC20Upgradeable,
    EIP712Upgradeable,
    NoncesUpgradeable,
    IDelegates
{
    bytes32 private constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @custom:storage-location erc7201:morpho.storage.Delegates
    struct ERC20DelegatesStorage {
        mapping(address account => address) _delegatee;
        mapping(address delegatee => uint256) _votingPower;
        uint256 _totalVotingPower;
    }

    // keccak256(abi.encode(uint256(keccak256("morpho.storage.ERC20Delegates")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20DelegatesStorageLocation =
        0x1dc92b2c6e971ab6e08dfd7dcec0e9496d223ced663ba2a06543451548549500;

    function _getDelegatesStorage() private pure returns (ERC20DelegatesStorage storage $) {
        assembly {
            $.slot := ERC20DelegatesStorageLocation
        }
    }

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) public view virtual returns (uint256) {
        ERC20DelegatesStorage storage $ = _getDelegatesStorage();
        return $._votingPower[account];
    }

    /**
     * @dev Returns the current total supply of votes.
     */
    function _getTotalSupply() internal view virtual returns (uint256) {
        ERC20DelegatesStorage storage $ = _getDelegatesStorage();
        return $._totalVotingPower;
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) public view virtual returns (address) {
        ERC20DelegatesStorage storage $ = _getDelegatesStorage();
        return $._delegatee[account];
    }

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        address account = _msgSender();
        _delegate(account, delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
    {
        if (block.timestamp > expiry) {
            revert DelegatesExpiredSignature(expiry);
        }
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry))), v, r, s
        );
        _useCheckedNonce(signer, nonce);
        _delegate(signer, delegatee);
    }

    /**
     * @dev Delegate all of `account`'s voting units to `delegatee`.
     *
     * Emits events {IVotes-DelegateChanged} and {IVotes-DelegateVotesChanged}.
     */
    function _delegate(address account, address delegatee) internal virtual {
        ERC20DelegatesStorage storage $ = _getDelegatesStorage();
        address oldDelegate = delegates(account);
        $._delegatee[account] = delegatee;

        emit DelegateChanged(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account));
    }

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero. Total supply of voting units will be adjusted with mints and burns.
     */
    function _transferVotingUnits(address from, address to, uint256 amount) internal virtual {
        ERC20DelegatesStorage storage $ = _getDelegatesStorage();
        if (from == address(0)) {
            $._totalVotingPower += amount;
        }
        if (to == address(0)) {
            $._totalVotingPower -= amount;
        }
        _moveDelegateVotes(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Moves delegated votes from one delegate to another.
     */
    function _moveDelegateVotes(address from, address to, uint256 amount) private {
        ERC20DelegatesStorage storage $ = _getDelegatesStorage();
        if (from != to && amount > 0) {
            if (from != address(0)) {
                uint256 oldValue = $._votingPower[from];
                uint256 newValue = oldValue - amount;
                $._votingPower[from] = newValue;
                emit DelegateVotesChanged(from, oldValue, newValue);
            }
            if (to != address(0)) {
                uint256 oldValue = $._votingPower[to];
                uint256 newValue = oldValue + amount;
                $._votingPower[to] = newValue;
                emit DelegateVotesChanged(to, oldValue, newValue);
            }
        }
    }

    /**
     * @dev Must return the voting units held by an account.
     */
    function _getVotingUnits(address account) internal view returns (uint256) {
        return balanceOf(account);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);
        _transferVotingUnits(from, to, value);
    }
}
