// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";

import {DeployMorphoTokenBase} from "script/DeployMorphoTokenBase.sol";

import {IERC20} from
    "../../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract EthereumDeploymentTest is DeployMorphoTokenBase, Test {
    address token;

    function setUp() public virtual {
        // DEPLOYMENTS
        token = run();
    }

    function testDeployment() public view {
        assertEq(IERC20(token).totalSupply(), 0);
    }
}
