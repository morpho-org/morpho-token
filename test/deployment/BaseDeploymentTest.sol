// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";

import {DeployMorphoTokenBase} from "../../script/DeployMorphoTokenBase.sol";
import {MorphoTokenOptimism} from "../../src/MorphoTokenOptimism.sol";
import {UUPSUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

contract DumbImplementation is UUPSUpgradeable {
    function _authorizeUpgrade(address) internal override {}
}

contract BaseDeploymentTest is DeployMorphoTokenBase, Test {
    address token;

    function setUp() public virtual {
        // DEPLOYMENTS
        token = run();
    }

    function testDeployment() public view {
        assertEq(MorphoTokenOptimism(token).totalSupply(), 0);
        assertEq(MorphoTokenOptimism(token).owner(), MORPHO_DAO);
    }

    function testUpgrade() public {
        address newImplementation = address(new DumbImplementation());
        vm.prank(MORPHO_DAO);
        MorphoTokenOptimism(token).upgradeToAndCall(newImplementation, hex"");
        assertEq(address(uint160(uint256(vm.load(token, IMPLEMENTATION_SLOT)))), newImplementation);
    }
}
