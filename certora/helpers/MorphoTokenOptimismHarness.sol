// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.27;

import {DelegationTokenHarness} from "./DelegationTokenHarness.sol";
import {MorphoTokenOptimism} from "../../munged/MorphoTokenOptimism.sol";

contract MorphoTokenOptimismHarness is MorphoTokenOptimism, DelegationTokenHarness {
    constructor(address newRemoteToken, address newBridge) MorphoTokenOptimism(newRemoteToken, newBridge) {}
}
