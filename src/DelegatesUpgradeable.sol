// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDelegates} from "./interfaces/IDelegates.sol";

import {ECDSA} from
    "lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {ContextUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol";
import {NoncesUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/utils/NoncesUpgradeable.sol";
import {EIP712Upgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/EIP712Upgradeable.sol";
import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

abstract contract DelegatesUpgradeable is
    Initializable,
    ContextUpgradeable,
    EIP712Upgradeable,
    NoncesUpgradeable,
    IDelegates
{
    bytes32 private constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @custom:storage-location erc7201:morpho.storage.Delegates
    struct DelegatesStorage {
        mapping(address account => address) _delegatee;
        mapping(address delegatee => uint256) _votingPower;
        uint256 _totalVotingPower;
    }

    // keccak256(abi.encode(uint256(keccak256("morpho.storage.Delegates")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant DelegatesStorageLocation =
        0xe96d6a46d8feefe49b223986c94a74a56f4e1500280e36600ec085ab28160200;

    function _getDelegatesStorage() private pure returns (DelegatesStorage storage $) {
        assembly {
            $.slot := DelegatesStorageLocation
        }
    }

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) public view virtual returns (uint256) {
        DelegatesStorage storage $ = _getDelegatesStorage();
        return $._votingPower[account];
    }

    /**
     * @dev Returns the current total supply of votes.
     */
    function _getTotalSupply() internal view virtual returns (uint256) {
        DelegatesStorage storage $ = _getDelegatesStorage();
        return $._totalVotingPower;
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) public view virtual returns (address) {
        DelegatesStorage storage $ = _getDelegatesStorage();
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
        DelegatesStorage storage $ = _getDelegatesStorage();
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
        DelegatesStorage storage $ = _getDelegatesStorage();
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
        DelegatesStorage storage $ = _getDelegatesStorage();
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
    function _getVotingUnits(address) internal view virtual returns (uint256);
}
