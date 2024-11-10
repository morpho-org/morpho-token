// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";

import {MorphoTokenEthereum} from "../../src/MorphoTokenEthereum.sol";
import {Wrapper} from "../../src/Wrapper.sol";
import {DeployMorphoTokenEthereum} from "../../script/DeployMorphoTokenEthereum.sol";
import {UUPSUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

contract DumbImplementation is UUPSUpgradeable {
    function _authorizeUpgrade(address) internal override {}
}

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

    function testUpgrade() public {
        address newImplementation = address(new DumbImplementation());
        vm.prank(MORPHO_DAO);
        MorphoTokenEthereum(token).upgradeToAndCall(newImplementation, hex"");
        assertEq(address(uint160(uint256(vm.load(token, IMPLEMENTATION_SLOT)))), newImplementation);
    }
}
