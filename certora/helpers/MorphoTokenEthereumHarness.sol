// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.27;

import {DelegationTokenHarness} from "./DelegationTokenHarness.sol";
// forge-lint: disable-next-line(unaliased-plain-import) Certora harness, not deployed.
import "../../munged/MorphoTokenEthereum.sol";

contract MorphoTokenEthereumHarness is MorphoTokenEthereum, DelegationTokenHarness {}
