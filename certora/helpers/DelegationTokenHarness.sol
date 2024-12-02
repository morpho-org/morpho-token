// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.27;

import {DelegationToken, Signature, Delegation} from "../munged/DelegationToken.sol";
import {ECDSA} from
    "../../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract DelegationTokenHarness is DelegationToken {
    function delegatorFromSig(Delegation calldata delegation, Signature calldata signature)
        external
        view
        returns (address)
    {
        address delegator = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(DELEGATION_TYPEHASH, delegation))),
            signature.v,
            signature.r,
            signature.s
        );
        return delegator;
    }
}
