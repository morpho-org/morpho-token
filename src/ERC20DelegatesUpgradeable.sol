// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.27;

import {IERC20DelegatesUpgradeable} from "./interfaces/IERC20DelegatesUpgradeable.sol";

import {ERC20Upgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {ECDSA} from
    "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {EIP712Upgradeable} from
    "../lib/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/EIP712Upgradeable.sol";
import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/// @title ERC20DelegatesUpgradeable
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @dev Extension of ERC20 to support token delegation.
///
/// This extension keeps track of the current voting power delegated to each account. Voting power can be delegated
/// either by calling the `delegate` function directly, or by providing a signature to be used with `delegateBySig`.
///
/// This enables onchain votes on external voting smart contracts leveraging storage proofs.
///
/// By default, token balance does not account for voting power. This makes transfers cheaper. Whether an account
/// has to self-delegate to vote depends on the voting contract implementation.
abstract contract ERC20DelegatesUpgradeable is
    Initializable,
    ERC20Upgradeable,
    EIP712Upgradeable,
    IERC20DelegatesUpgradeable
{
    /* CONSTANTS */

    bytes32 private constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // keccak256(abi.encode(uint256(keccak256("morpho.storage.ERC20Delegates")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20DelegatesStorageLocation =
        0x1dc92b2c6e971ab6e08dfd7dcec0e9496d223ced663ba2a06543451548549500;

    /* STRUCTS */

    /// @custom:storage-location erc7201:morpho.storage.ERC20Delegates
    struct ERC20DelegatesStorage {
        mapping(address => address) _delegatee;
        mapping(address => uint256) _delegatedVotingPower;
        mapping(address => uint256) _delegationNonce;
    }

    /* GETTERS */

    /// @dev Returns the delegate that `delegator` has chosen.
    function delegates(address delegator) public view returns (address) {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        return $._delegatee[delegator];
    }

    /// @dev Returns the current voting power delegated to `delegatee`.
    function delegatedVotingPower(address delegatee) external view returns (uint256) {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        return $._delegatedVotingPower[delegatee];
    }

    /// @dev Returns the current delegation nonce of `delegator`.
    function delegationNonce(address delegator) external view returns (uint256) {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        return $._delegationNonce[delegator];
    }

    /* DELEGATE */

    /// @dev Delegates the balance of the sender to `delegatee`.
    function delegate(address delegatee) external {
        address delegator = _msgSender();
        _delegate(delegator, delegatee);
    }

    /// @dev Delegates the balance of the signer to `delegatee`.
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= expiry, DelegatesExpiredSignature(expiry));

        address delegator = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry))), v, r, s
        );

        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        require(nonce == $._delegationNonce[delegator]++, InvalidDelegationNonce());

        _delegate(delegator, delegatee);
    }

    /* INTERNAL */

    /// @dev Delegates the balance of the `delegator` to `delegatee`.
    function _delegate(address delegator, address delegatee) internal {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        address oldDelegate = delegates(delegator);
        $._delegatee[delegator] = delegatee;

        emit DelegateChanged(delegator, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, balanceOf(delegator));
    }

    /// @dev Moves voting power when tokens are transferred.
    /// @dev Emits a {IDelegates-DelegateVotesChanged} event.
    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);
        _moveDelegateVotes(delegates(from), delegates(to), value);
    }

    /* PRIVATE */

    /// @dev Moves delegated votes from one delegate to another.
    function _moveDelegateVotes(address from, address to, uint256 amount) private {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        if (from != to && amount > 0) {
            if (from != address(0)) {
                uint256 oldValue = $._delegatedVotingPower[from];
                uint256 newValue = oldValue - amount;
                $._delegatedVotingPower[from] = newValue;
                emit DelegateVotesChanged(from, oldValue, newValue);
            }
            if (to != address(0)) {
                uint256 oldValue = $._delegatedVotingPower[to];
                uint256 newValue = oldValue + amount;
                $._delegatedVotingPower[to] = newValue;
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
