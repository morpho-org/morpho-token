// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {DelegationTokenHarness} from "./DelegationTokenHarness.sol";
import {MorphoTokenEthereum} from "../../src/MorphoTokenEthereum.sol";

contract MorphoTokenEthereumHarness is MorphoTokenEthereum, DelegationTokenHarness {}
