// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";

import {MorphoTokenEthereum} from "../../src/MorphoTokenEthereum.sol";
import {Wrapper} from "../../src/Wrapper.sol";
import {DeployMorphoTokenEthereum} from "../../script/DeployMorphoTokenEthereum.sol";

contract EthereumDeploymentTest is DeployMorphoTokenEthereum, Test {
    address token;
    address wrapper;

    function setUp() public virtual {
        // DEPLOYMENTS
        (token, wrapper) = run();
    }

    function testDeployment() public view {
        assertEq(Wrapper(wrapper).NEW_MORPHO(), token);
        assertEq(MorphoTokenEthereum(token).totalSupply(), 1_000_000_000e18);
        assertEq(MorphoTokenEthereum(token).balanceOf(wrapper), 1_000_000_000e18);
        assertEq(MorphoTokenEthereum(token).owner(), MORPHO_DAO);
    }
}
