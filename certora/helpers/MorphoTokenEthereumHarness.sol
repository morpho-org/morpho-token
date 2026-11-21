// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.27;

import {DelegationTokenHarness} from "./DelegationTokenHarness.sol";
import {MorphoTokenEthereum} from "../../src/MorphoTokenEthereum.sol";

contract MorphoTokenEthereumHarness is MorphoTokenEthereum, DelegationTokenHarness {}
