// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.27;

import {DelegationTokenHarness, Signature, Delegation} from "./DelegationTokenHarness.sol";
import "../../munged/MorphoTokenEthereum.sol";

contract MorphoTokenEthereumHarness is MorphoTokenEthereum, DelegationTokenHarness {}
