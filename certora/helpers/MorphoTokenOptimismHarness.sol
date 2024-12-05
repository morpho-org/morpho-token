// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.27;

import {DelegationTokenHarness, Signature, Delegation} from "./DelegationTokenHarness.sol";
import "../../munged/MorphoTokenOptimism.sol";
import {ECDSA} from
    "../../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract MorphoTokenOptimismHarness is MorphoTokenOptimism, DelegationTokenHarness {
    constructor(address newRemoteToken, address newBridge) MorphoTokenOptimism(newRemoteToken, newBridge) {}
}
