// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";

import {DeployMorphoTokenBase} from "../../script/DeployMorphoTokenBase.sol";
import {MorphoTokenOptimism} from "../../src/MorphoTokenOptimism.sol";

contract EthereumDeploymentTest is DeployMorphoTokenBase, Test {
    address token;

    function setUp() public virtual {
        // DEPLOYMENTS
        token = run();
    }

    function testDeployment() public view {
        assertEq(MorphoTokenOptimism(token).totalSupply(), 0);
        assertEq(MorphoTokenOptimism(token).owner(), MORPHO_DAO);
    }
}
