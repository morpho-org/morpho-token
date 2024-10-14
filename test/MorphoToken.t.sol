// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {MorphoToken} from "../src/MorphoToken.sol";
import {Wrapper} from "../src/Wrapper.sol";
import {ERC1967Proxy} from
    "lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {SigUtils} from "./helpers/SigUtils.sol";

// TODO: Test the following:
// - Test every paths
// - Test migration flow
// - Test bundler wrapping
// - Test access control
// - Test voting
// - Test delegation
contract MorphoTokenTest is Test {
    address public constant MORPHO_DAO = 0xcBa28b38103307Ec8dA98377ffF9816C164f9AFa;

    MorphoToken public tokenImplem;
    MorphoToken public newMorpho;
    ERC1967Proxy public tokenProxy;
    Wrapper public wrapper;

    uint256 internal constant MIN_TEST_AMOUNT = 100;
    uint256 internal constant MAX_TEST_AMOUNT = 1e28;

    function setUp() public {
        // DEPLOYMENTS
        tokenImplem = new MorphoToken();
        tokenProxy = new ERC1967Proxy(address(tokenImplem), hex"");
        wrapper = new Wrapper(address(tokenProxy));

        newMorpho = MorphoToken(payable(address(tokenProxy)));
        newMorpho.initialize(MORPHO_DAO, address(wrapper));
    }

    function testUpgradeNotOwner(address updater) public {
        vm.assume(updater != address(0));
        vm.assume(updater != MORPHO_DAO);

        address newImplem = address(new MorphoToken());

        vm.expectRevert();
        newMorpho.upgradeToAndCall(newImplem, hex"");
    }

    function testUpgrade() public {
        address newImplem = address(new MorphoToken());

        vm.prank(MORPHO_DAO);
        newMorpho.upgradeToAndCall(newImplem, hex"");
    }

    function testOwnDelegation(address delegator, uint256 amount) public {
        vm.assume(delegator != address(0));
        vm.assume(delegator != MORPHO_DAO);
        amount = bound(amount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);

        deal(address(newMorpho), delegator, amount);

        vm.prank(delegator);
        newMorpho.delegate(delegator);

        assertEq(newMorpho.delegates(delegator), delegator);
        assertEq(newMorpho.getVotes(delegator), amount);
    }

    function testDelegate(address delegator, address delegatee, uint256 amount) public {
        address[] memory addresses = new address[](2);
        addresses[0] = delegator;
        addresses[1] = delegatee;
        _validateAddresses(addresses);
        amount = bound(amount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);

        deal(address(newMorpho), delegator, amount);

        vm.prank(delegator);
        newMorpho.delegate(delegatee);

        assertEq(newMorpho.delegates(delegator), delegatee);
        assertEq(newMorpho.getVotes(delegator), 0);
        assertEq(newMorpho.getVotes(delegatee), amount);
    }

    function testDelegateBySig(SigUtils.Delegation memory delegation, uint256 privateKey, uint256 amount) public {
        privateKey = bound(privateKey, 1, type(uint32).max);
        address delegator = vm.addr(privateKey);

        address[] memory addresses = new address[](2);
        addresses[0] = delegator;
        addresses[1] = delegation.delegatee;
        _validateAddresses(addresses);

        delegation.expiry = bound(delegation.expiry, block.timestamp, type(uint256).max);
        delegation.nonce = 0;

        amount = bound(amount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);
        deal(address(newMorpho), delegator, amount);

        Signature memory sig;
        bytes32 digest = SigUtils.getTypedDataHash(delegation);
        (sig.v, sig.r, sig.s) = vm.sign(privateKey, digest);

        newMorpho.delegateBySig(delegation.delegatee, delegation.nonce, delegation.expiry, sig.v, sig.r, sig.s);

        console.log(delegator);
        console.log(newMorpho.delegates(delegator));
        console.log(delegation.delegatee);
        assertEq(newMorpho.delegates(delegator), delegation.delegatee);
        assertEq(newMorpho.getVotes(delegator), 0);
        assertEq(newMorpho.getVotes(delegation.delegatee), amount);
    }

    function testMultipleDelegation(
        address delegator1,
        address delegator2,
        address delegatee,
        uint256 amount1,
        uint256 amount2
    ) public {
        address[] memory addresses = new address[](3);
        addresses[0] = delegator1;
        addresses[1] = delegator2;
        addresses[2] = delegatee;
        _validateAddresses(addresses);
        amount1 = bound(amount1, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);
        amount2 = bound(amount2, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);

        deal(address(newMorpho), delegator1, amount1);
        deal(address(newMorpho), delegator2, amount2);

        vm.prank(delegator1);
        newMorpho.delegate(delegatee);

        vm.prank(delegator2);
        newMorpho.delegate(delegatee);

        assertEq(newMorpho.getVotes(delegatee), amount1 + amount2);
    }

    function testTransferVotingPower(
        address delegator1,
        address delegator2,
        address delegatee1,
        address delegatee2,
        uint256 initialAmount,
        uint256 transferedAmount
    ) public {
        address[] memory addresses = new address[](4);
        addresses[0] = delegator1;
        addresses[1] = delegator2;
        addresses[2] = delegatee1;
        addresses[3] = delegatee2;
        _validateAddresses(addresses);
        initialAmount = bound(initialAmount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);
        transferedAmount = bound(transferedAmount, MIN_TEST_AMOUNT, initialAmount);

        deal(address(newMorpho), delegator1, initialAmount);

        vm.prank(delegator2);
        newMorpho.delegate(delegatee2);

        vm.startPrank(delegator1);
        newMorpho.delegate(delegatee1);
        newMorpho.transfer(delegator2, transferedAmount);
        vm.stopPrank();

        assertEq(newMorpho.getVotes(delegatee1), initialAmount - transferedAmount);
        assertEq(newMorpho.getVotes(delegatee2), transferedAmount);
    }

    function _validateAddresses(address[] memory addresses) internal pure {
        for (uint256 i = 0; i < addresses.length; i++) {
            vm.assume(addresses[i] != address(0));
            vm.assume(addresses[i] != MORPHO_DAO);
            for (uint256 j = i + 1; j < addresses.length; j++) {
                vm.assume(addresses[i] != addresses[j]);
            }
        }
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}
