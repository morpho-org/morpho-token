// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library SigUtils {
    struct Delegation {
        address delegatee;
        uint256 nonce;
        uint256 expiry;
    }

    bytes32 private constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @dev Computes the hash of the EIP-712 encoded data.
    function getTypedDataHash(Delegation memory delegation) public pure returns (bytes32) {
        return keccak256(bytes.concat("\x19\x01", hashStruct(delegation)));
    }

    function hashStruct(Delegation memory delegation) internal pure returns (bytes32) {
        return keccak256(abi.encode(DELEGATION_TYPEHASH, delegation.delegatee, delegation.nonce, delegation.expiry));
    }
}
