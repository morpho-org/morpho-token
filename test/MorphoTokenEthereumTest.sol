// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseTest} from "./helpers/BaseTest.sol";
import {SigUtils} from "./helpers/SigUtils.sol";
import {MorphoTokenEthereum} from "../src/MorphoTokenEthereum.sol";
import {DelegationToken} from "../src/abstracts/DelegationToken.sol";
import {IERC20Errors} from
    "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {OwnableUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ERC1967Proxy} from
    "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MorphoTokenEthereumTest is BaseTest {
    function testInitilizeZeroAddress(address randomAddress) public {
        vm.assume(randomAddress != address(0));

        address proxy = address(new ERC1967Proxy(address(tokenImplem), hex""));

        vm.expectRevert(MorphoTokenEthereum.ZeroAddress.selector);
        MorphoTokenEthereum(proxy).initialize(address(0), randomAddress);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        MorphoTokenEthereum(proxy).initialize(randomAddress, address(0));
    }

    function testUpgradeNotOwner(address updater) public {
        vm.assume(updater != address(0));
        vm.assume(updater != MORPHO_DAO);

        address newImplem = address(new MorphoTokenEthereum());

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, updater));
        vm.prank(updater);
        newMorpho.upgradeToAndCall(newImplem, hex"");
    }

    function testUpgrade() public {
        address newImplem = address(new MorphoTokenEthereum());

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

        assertEq(newMorpho.delegatee(delegator), delegator);
        assertEq(newMorpho.delegatedVotingPower(delegator), amount);
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

        assertEq(newMorpho.delegatee(delegator), delegatee);
        assertEq(newMorpho.delegatedVotingPower(delegator), 0);
        assertEq(newMorpho.delegatedVotingPower(delegatee), amount);
    }

    function testDelegateBySigExpired(SigUtils.Delegation memory delegation, uint256 privateKey) public {
        delegation.expiry = bound(delegation.expiry, 0, type(uint32).max);
        privateKey = bound(privateKey, 1, type(uint32).max);
        address delegator = vm.addr(privateKey);

        address[] memory addresses = new address[](2);
        addresses[0] = delegator;
        addresses[1] = delegation.delegatee;
        _validateAddresses(addresses);

        delegation.nonce = 0;

        Signature memory sig;
        bytes32 digest = SigUtils.getDelegationTypedDataHash(delegation, address(newMorpho));
        (sig.v, sig.r, sig.s) = vm.sign(privateKey, digest);

        vm.warp(delegation.expiry + 1);

        vm.expectRevert(abi.encodeWithSelector(DelegationToken.DelegatesExpiredSignature.selector, delegation.expiry));
        newMorpho.delegateWithSig(delegation.delegatee, delegation.nonce, delegation.expiry, sig.v, sig.r, sig.s);
    }

    function testDelegateBySigWrongNonce(SigUtils.Delegation memory delegation, uint256 privateKey, uint256 nounce)
        public
    {
        vm.assume(nounce != 0);
        privateKey = bound(privateKey, 1, type(uint32).max);
        address delegator = vm.addr(privateKey);

        address[] memory addresses = new address[](2);
        addresses[0] = delegator;
        addresses[1] = delegation.delegatee;
        _validateAddresses(addresses);

        delegation.expiry = bound(delegation.expiry, block.timestamp, type(uint32).max);
        delegation.nonce = nounce;

        Signature memory sig;
        bytes32 digest = SigUtils.getDelegationTypedDataHash(delegation, address(newMorpho));
        (sig.v, sig.r, sig.s) = vm.sign(privateKey, digest);

        vm.expectRevert(DelegationToken.InvalidDelegationNonce.selector);
        newMorpho.delegateWithSig(delegation.delegatee, delegation.nonce, delegation.expiry, sig.v, sig.r, sig.s);
    }

    function testDelegateBySig(SigUtils.Delegation memory delegation, uint256 privateKey, uint256 amount) public {
        privateKey = bound(privateKey, 1, type(uint32).max);
        address delegator = vm.addr(privateKey);

        address[] memory addresses = new address[](2);
        addresses[0] = delegator;
        addresses[1] = delegation.delegatee;
        _validateAddresses(addresses);
        vm.assume(newMorpho.delegationNonce(delegator) == 0);

        delegation.expiry = bound(delegation.expiry, block.timestamp, type(uint32).max);
        delegation.nonce = 0;

        amount = bound(amount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);
        deal(address(newMorpho), delegator, amount);

        Signature memory sig;
        bytes32 digest = SigUtils.getDelegationTypedDataHash(delegation, address(newMorpho));
        (sig.v, sig.r, sig.s) = vm.sign(privateKey, digest);

        newMorpho.delegateWithSig(delegation.delegatee, delegation.nonce, delegation.expiry, sig.v, sig.r, sig.s);

        assertEq(newMorpho.delegatee(delegator), delegation.delegatee);
        assertEq(newMorpho.delegatedVotingPower(delegator), 0);
        assertEq(newMorpho.delegatedVotingPower(delegation.delegatee), amount);
        assertEq(newMorpho.delegationNonce(delegator), 1);
        assertEq(newMorpho.nonces(delegator), 0);
    }

    function testPermitNotIncrementingNonce(SigUtils.Permit memory permit, uint256 privateKey) public {
        privateKey = bound(privateKey, 1, type(uint32).max);
        permit.owner = vm.addr(privateKey);

        address[] memory addresses = new address[](2);
        addresses[0] = permit.owner;
        addresses[1] = permit.spender;
        _validateAddresses(addresses);
        vm.assume(newMorpho.delegationNonce(permit.owner) == 0);
        vm.assume(newMorpho.nonces(permit.owner) == 0);

        permit.deadline = bound(permit.deadline, block.timestamp, type(uint256).max);
        permit.nonce = 0;

        permit.value = bound(permit.value, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);

        Signature memory sig;
        bytes32 digest = SigUtils.getPermitTypedDataHash(permit, address(newMorpho));
        (sig.v, sig.r, sig.s) = vm.sign(privateKey, digest);

        newMorpho.permit(permit.owner, permit.spender, permit.value, permit.deadline, sig.v, sig.r, sig.s);

        assertEq(newMorpho.delegationNonce(permit.owner), 0);
        assertEq(newMorpho.nonces(permit.owner), 1);
    }

    function testMultipleDelegations(
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

        assertEq(newMorpho.delegatedVotingPower(delegatee), amount1 + amount2);
    }

    function testTransferVotingPower(
        address delegator1,
        address delegator2,
        address delegatee1,
        address delegatee2,
        uint256 initialAmount,
        uint256 transferredAmount
    ) public {
        address[] memory addresses = new address[](4);
        addresses[0] = delegator1;
        addresses[1] = delegator2;
        addresses[2] = delegatee1;
        addresses[3] = delegatee2;
        _validateAddresses(addresses);
        initialAmount = bound(initialAmount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);
        transferredAmount = bound(transferredAmount, MIN_TEST_AMOUNT, initialAmount);

        deal(address(newMorpho), delegator1, initialAmount);

        vm.prank(delegator2);
        newMorpho.delegate(delegatee2);

        vm.startPrank(delegator1);
        newMorpho.delegate(delegatee1);
        newMorpho.transfer(delegator2, transferredAmount);
        vm.stopPrank();

        assertEq(newMorpho.delegatedVotingPower(delegatee1), initialAmount - transferredAmount);
        assertEq(newMorpho.delegatedVotingPower(delegatee2), transferredAmount);
    }

    function testMint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        amount = bound(amount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);

        uint256 initialTotalSupply = newMorpho.totalSupply();
        uint256 initialAmount = newMorpho.balanceOf(to);

        vm.prank(MORPHO_DAO);
        newMorpho.mint(to, amount);

        assertEq(newMorpho.totalSupply(), initialTotalSupply + amount);
        assertEq(newMorpho.balanceOf(to), initialAmount + amount);
    }

    function testMintOverflow(address to, uint256 amount) public {
        vm.assume(to != address(0));
        amount = bound(amount, type(uint256).max - newMorpho.totalSupply() + 1, type(uint256).max);

        vm.prank(MORPHO_DAO);
        vm.expectRevert();
        newMorpho.mint(to, amount);
    }

    function testMintAccess(address account, address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(account != MORPHO_DAO);
        amount = bound(amount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, account));
        vm.prank(account);
        newMorpho.mint(to, amount);
    }

    function testBurn(address from, uint256 amountMinted, uint256 amountBurned) public {
        vm.assume(from != address(0));
        amountMinted = bound(amountMinted, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);
        amountBurned = bound(amountBurned, MIN_TEST_AMOUNT, amountMinted);

        uint256 initialTotalSupply = newMorpho.totalSupply();
        uint256 initialAmount = newMorpho.balanceOf(from);

        vm.prank(MORPHO_DAO);
        newMorpho.mint(from, amountMinted);

        vm.prank(from);
        newMorpho.burn(amountBurned);

        assertEq(newMorpho.totalSupply(), initialTotalSupply + amountMinted - amountBurned);
        assertEq(newMorpho.balanceOf(from), initialAmount + amountMinted - amountBurned);
    }
}
