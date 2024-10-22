// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {IERC20DelegatesUpgradeable} from "./interfaces/IERC20DelegatesUpgradeable.sol";

import {ERC20PermitUpgradeable} from
    "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ECDSA} from
    "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {Ownable2StepUpgradeable} from
    "../lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title Token
/// @author Morpho Association
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
abstract contract Token is
    ERC20PermitUpgradeable,
    IERC20DelegatesUpgradeable,
    Ownable2StepUpgradeable,
    UUPSUpgradeable
{
    /* CONSTANTS */

    bytes32 internal constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // keccak256(abi.encode(uint256(keccak256("morpho.storage.ERC20Delegates")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 internal constant ERC20DelegatesStorageLocation =
        0x1dc92b2c6e971ab6e08dfd7dcec0e9496d223ced663ba2a06543451548549500;

    /* STORAGE LAYOUT */

    /// @custom:storage-location erc7201:morpho.storage.ERC20Delegates
    struct ERC20DelegatesStorage {
        mapping(address => address) _delegatee;
        mapping(address => uint256) _delegatedVotingPower;
        mapping(address => uint256) _delegationNonce;
    }

    /* ERRORS */

    /// @dev The signature used has expired.
    error DelegatesExpiredSignature(uint256 expiry);

    /// @dev The delegation nonce used by the signer is not its current delegation nonce.
    error InvalidDelegationNonce();

    /* EVENTS */

    /// @dev Emitted when an delegator changes their delegatee.
    event DelegateeChanged(address indexed delegator, address indexed oldDelegatee, address indexed newDelegatee);

    /// @dev Emitted when a delegatee's delegated voting power changes.
    event DelegatedVotingPowerChanged(address indexed delegatee, uint256 oldVotes, uint256 newVotes);

    /// @dev Emitted whenever tokens are minted for an account.
    event Mint(address indexed account, uint256 amount);

    /// @dev Emitted whenever tokens are burned from an account.
    event Burn(address indexed account, uint256 amount);

    /* CONSTRUCTOR */

    /// @dev Disables initializers for the implementation contract.
    constructor() {
        _disableInitializers();
    }

    /* GETTERS */

    /// @dev Returns the delegatee that `account` has chosen.
    function delegatee(address account) public view returns (address) {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        return $._delegatee[account];
    }

    /// @dev Returns the current voting power delegated to `account`.
    function delegatedVotingPower(address account) external view returns (uint256) {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        return $._delegatedVotingPower[account];
    }

    /// @dev Returns the current delegation nonce of `account`.
    function delegationNonce(address account) external view returns (uint256) {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        return $._delegationNonce[account];
    }

    /* DELEGATE */

    /// @dev Delegates the balance of the sender to `newDelegatee`.
    function delegate(address newDelegatee) external {
        address delegator = _msgSender();
        _delegate(delegator, newDelegatee);
    }

    /// @dev Delegates the balance of the signer to `newDelegatee`.
    function delegateWithSig(address newDelegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(block.timestamp <= expiry, DelegatesExpiredSignature(expiry));

        address delegator = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(DELEGATION_TYPEHASH, newDelegatee, nonce, expiry))), v, r, s
        );

        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        require(nonce == $._delegationNonce[delegator]++, InvalidDelegationNonce());

        _delegate(delegator, newDelegatee);
    }

    /* INTERNAL */

    /// @dev Delegates the balance of the `delegator` to `newDelegatee`.
    function _delegate(address delegator, address newDelegatee) internal {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
        address oldDelegatee = $._delegatee[delegator];
        $._delegatee[delegator] = newDelegatee;

        emit DelegateeChanged(delegator, oldDelegatee, newDelegatee);
        _moveDelegateVotes(oldDelegatee, newDelegatee, balanceOf(delegator));
    }

    /// @dev Moves voting power when tokens are transferred.
    /// @dev Emits a {IDelegates-DelegateVotesChanged} event.
    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);
        _moveDelegateVotes(delegatee(from), delegatee(to), value);
    }

    /// @dev Moves delegated votes from one delegate to another.
    function _moveDelegateVotes(address from, address to, uint256 amount) internal {
        ERC20DelegatesStorage storage $ = _getERC20DelegatesStorage();
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

    /// @dev Returns the ERC20DelegatesStorage struct.
    function _getERC20DelegatesStorage() internal pure returns (ERC20DelegatesStorage storage $) {
        assembly {
            $.slot := ERC20DelegatesStorageLocation
        }
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}
