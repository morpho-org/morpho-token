// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IDelegates} from "./interfaces/IDelegates.sol";

import {ERC20Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {EIP712Upgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/EIP712Upgradeable.sol";
import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/// @title ERC20DelegatesUpgradeable
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @dev Extension of ERC20 to support token delegation.
///
/// This extension keeps track of each account's vote power. Vote power can be delegated either by calling the
/// {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting power can be
/// queried through the external accessor {getVotes}.
///
/// By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
/// requires users to delegate to themselves in order to activate their voting power.
abstract contract ERC20DelegatesUpgradeable is Initializable, ERC20Upgradeable, EIP712Upgradeable, IDelegates {
    /* CONSTANTS */

    bytes32 private constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // keccak256(abi.encode(uint256(keccak256("morpho.storage.ERC20Delegates")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20DelegatesStorageLocation =
        0x1dc92b2c6e971ab6e08dfd7dcec0e9496d223ced663ba2a06543451548549500;

    /* STRUCTS */

    /// @custom:storage-location erc7201:morpho.storage.ERC20Delegates
    struct ERC20DelegatesStorage {
        mapping(address account => address) _delegatee;
        mapping(address delegatee => uint256) _votingPower;
        mapping(address account => uint256) _delegationNonce;
    }

    /* PUBLIC */

    /// @dev Returns the delegate that `account` has chosen.
    function delegates(address account) public view returns (address) {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        return $._delegatee[account];
    }

    /* EXTERNAL */

    /// @dev Returns the current amount of votes that `account` has.
    function getVotes(address account) external view returns (uint256) {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        return $._votingPower[account];
    }

    function delegationNonce(address account) external view returns (uint256) {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        return $._delegationNonce[account];
    }

    /// @dev Delegates votes from the sender to `delegatee`.
    function delegate(address delegatee) external {
        address account = _msgSender();
        _delegate(account, delegatee);
    }

    /// @dev Delegates votes from signer to `delegatee`.
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= expiry, DelegatesExpiredSignature(expiry));

        address signer =
            ecrecover(_hashTypedDataV4(keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry))), v, r, s);
        require(signer != address(0), InvalidDelegationSignature());

        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        uint256 current = $._delegationNonce[signer];
        require(nonce == current, InvalidDelegationNonce(signer, current));
        $._delegationNonce[signer]++;

        _delegate(signer, delegatee);
    }

    /* INTERNAL */

    /// @dev Delegates all of `account`'s voting units to `delegatee`.
    /// @dev Emits events {IDelegates-DelegateChanged} and {IDelegates-DelegateVotesChanged}.
    function _delegate(address account, address delegatee) internal {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        address oldDelegate = delegates(account);
        $._delegatee[account] = delegatee;

        emit DelegateChanged(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account));
    }

    /// @dev Must return the voting units held by an account.
    function _getVotingUnits(address account) internal view returns (uint256) {
        return balanceOf(account);
    }

    /// @dev Moves voting power when tokens are transferred.
    /// @dev Emits a {IDelegates-DelegateVotesChanged} event.
    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);
        // No check of supply cap here like in OZ implementation as MORPHO has a 1B total supply cap.
        _moveDelegateVotes(delegates(from), delegates(to), value);
    }

    /* PRIVATE */

    /// @dev Moves delegated votes from one delegate to another.
    function _moveDelegateVotes(address from, address to, uint256 amount) private {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
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

    /// @dev Returns the ERC20DelegatesStorage struct.
    function _getERC20DelegatesStorage() private pure returns (ERC20DelegatesStorage storage $) {
        assembly {
            $.slot := ERC20DelegatesStorageLocation
        }
    }
}
