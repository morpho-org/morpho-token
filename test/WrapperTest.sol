// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {console} from "../lib/forge-std/src/Test.sol";
import {BaseTest} from "./helpers/BaseTest.sol";
import {Wrapper} from "../src/Wrapper.sol";
import {IMulticall} from "./helpers/interfaces/IMulticall.sol";
import {EncodeLib} from "./helpers/libraries/EncodeLib.sol";
import {IERC20} from
    "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract WrapperTest is BaseTest {
    IMulticall internal bundler = IMulticall(0x4095F064B8d3c3548A3bebfd0Bbfd04750E30077);
    IERC20 internal legacyMorpho = IERC20(0x9994E35Db50125E0DF82e4c2dde62496CE330999);

    uint256 internal forkId;

    bytes[] internal bundle;

    function setUp() public virtual override {
        super.setUp();

        _fork();

        vm.startPrank(MORPHO_DAO);
        // The role 0 already has transfer capabilities.
        RolesAuthority(address(legacyMorpho)).setUserRole(address(wrapper), 0, true);
        RolesAuthority(address(legacyMorpho)).setUserRole(address(bundler), 0, true);
        vm.stopPrank();
    }

    function _fork() internal virtual {
        string memory rpcUrl = vm.rpcUrl("ethereum");

        forkId = vm.createSelectFork(rpcUrl);
        require(block.chainid == 1, "wrong chain");
    }

    function testDeployWrapperZeroAddress() public {
        vm.expectRevert(Wrapper.ZeroAddress.selector);
        new Wrapper(address(0));
    }

    function testTotalSupply() public view {
        assertEq(newMorpho.totalSupply(), 1_000_000_000e18);
    }

    function testInitialWrapperBalances() public view {
        assertEq(legacyMorpho.balanceOf(address(wrapper)), 0);
        assertEq(newMorpho.balanceOf(address(wrapper)), 1_000_000_000e18);
    }

    function testDepositForZeroAddress(uint256 amount) public {
        vm.assume(amount != 0);

        vm.expectRevert(Wrapper.ZeroAddress.selector);
        wrapper.depositFor(address(0), amount);
    }

    function testDepositForSelfAddress(uint256 amount) public {
        vm.assume(amount != 0);

        vm.expectRevert(Wrapper.SelfAddress.selector);
        wrapper.depositFor(address(wrapper), amount);
    }

    function testWithdrawToZeroAddress(uint256 amount) public {
        vm.assume(amount != 0);

        vm.expectRevert(Wrapper.ZeroAddress.selector);
        wrapper.withdrawTo(address(0), amount);
    }

    function testWithdrawToSelfAddress(uint256 amount) public {
        vm.assume(amount != 0);

        vm.expectRevert(Wrapper.SelfAddress.selector);
        wrapper.withdrawTo(address(wrapper), amount);
    }

    function testDAOMigration() public {
        uint256 daoTokenAmount = legacyMorpho.balanceOf(MORPHO_DAO);

        bundle.push(EncodeLib._erc20TransferFrom(address(legacyMorpho), daoTokenAmount));
        bundle.push(EncodeLib._erc20WrapperDepositFor(address(wrapper), daoTokenAmount));

        vm.startPrank(MORPHO_DAO);
        legacyMorpho.approve(address(bundler), daoTokenAmount);

        vm.expectEmit(address(legacyMorpho));
        emit IERC20.Transfer(MORPHO_DAO, address(bundler), daoTokenAmount);
        vm.expectEmit(address(legacyMorpho));
        emit IERC20.Approval(address(bundler), address(wrapper), type(uint256).max);
        vm.expectEmit(address(legacyMorpho));
        emit IERC20.Transfer(address(bundler), address(wrapper), daoTokenAmount);
        vm.expectEmit(address(newMorpho));
        emit IERC20.Transfer(address(wrapper), MORPHO_DAO, daoTokenAmount);
        bundler.multicall(bundle);
        vm.stopPrank();

        assertEq(legacyMorpho.balanceOf(MORPHO_DAO), 0, "legacyMorpho.balanceOf(MORPHO_DAO)");
        assertEq(legacyMorpho.balanceOf(address(wrapper)), daoTokenAmount, "legacyMorpho.balanceOf(wrapper)");
        assertEq(newMorpho.balanceOf(MORPHO_DAO), daoTokenAmount, "newMorpho.balanceOf(MORPHO_DAO)");
    }

    function testMigration(address migrator, uint256 amount) public {
        vm.assume(migrator != address(0));
        // Unset initiator is address(1), so it can't use the bundler.
        vm.assume(migrator != address(1));
        vm.assume(migrator != MORPHO_DAO);
        vm.assume(migrator != address(wrapper));
        amount = bound(amount, MIN_TEST_AMOUNT, 1_000_000_000e18);

        deal(address(legacyMorpho), migrator, amount);

        bundle.push(EncodeLib._erc20TransferFrom(address(legacyMorpho), amount));
        bundle.push(EncodeLib._erc20WrapperDepositFor(address(wrapper), amount));

        vm.startPrank(migrator);
        legacyMorpho.approve(address(bundler), amount);

        vm.expectEmit(address(legacyMorpho));
        emit IERC20.Transfer(migrator, address(bundler), amount);
        vm.expectEmit(address(legacyMorpho));
        emit IERC20.Approval(address(bundler), address(wrapper), type(uint256).max);
        vm.expectEmit(address(legacyMorpho));
        emit IERC20.Transfer(address(bundler), address(wrapper), amount);
        vm.expectEmit(address(newMorpho));
        emit IERC20.Transfer(address(wrapper), migrator, amount);
        bundler.multicall(bundle);
        vm.stopPrank();

        assertEq(legacyMorpho.balanceOf(migrator), 0, "legacyMorpho.balanceOf(migrator)");
        assertEq(legacyMorpho.balanceOf(address(wrapper)), amount, "legacyMorpho.balanceOf(wrapper)");
        assertEq(newMorpho.balanceOf(address(wrapper)), 1_000_000_000e18 - amount, "newMorpho.balanceOf(wrapper)");
        assertEq(newMorpho.balanceOf(migrator), amount, "newMorpho.balanceOf(migrator)");
    }

    function testRevertMigration(address migrator, uint256 migratedAmount, uint256 revertedAmount) public {
        vm.assume(migrator != address(0));
        vm.assume(migrator != address(1));
        vm.assume(migrator != MORPHO_DAO);
        vm.assume(migrator != address(wrapper));
        migratedAmount = bound(migratedAmount, MIN_TEST_AMOUNT, 1_000_000_000e18);
        revertedAmount = bound(revertedAmount, MIN_TEST_AMOUNT, migratedAmount);

        deal(address(legacyMorpho), migrator, migratedAmount);

        bundle.push(EncodeLib._erc20TransferFrom(address(legacyMorpho), migratedAmount));
        bundle.push(EncodeLib._erc20WrapperDepositFor(address(wrapper), migratedAmount));

        vm.startPrank(migrator);
        legacyMorpho.approve(address(bundler), migratedAmount);
        bundler.multicall(bundle);
        vm.stopPrank();

        vm.startPrank(migrator);
        newMorpho.approve(address(wrapper), revertedAmount);

        vm.expectEmit(address(newMorpho));
        emit IERC20.Transfer(migrator, address(wrapper), revertedAmount);
        vm.expectEmit(address(legacyMorpho));
        emit IERC20.Transfer(address(wrapper), migrator, revertedAmount);
        wrapper.withdrawTo(migrator, revertedAmount);
        vm.stopPrank();

        assertEq(legacyMorpho.balanceOf(migrator), revertedAmount, "legacyMorpho.balanceOf(migrator)");
        assertEq(
            legacyMorpho.balanceOf(address(wrapper)), migratedAmount - revertedAmount, "legacyMorpho.balanceOf(wrapper)"
        );
        assertEq(
            newMorpho.balanceOf(address(wrapper)),
            1_000_000_000e18 - migratedAmount + revertedAmount,
            "newMorpho.balanceOf(wrapper)"
        );
        assertEq(newMorpho.balanceOf(migrator), migratedAmount - revertedAmount, "newMorpho.balanceOf(migrator)");
    }
}

interface RolesAuthority {
    function setUserRole(address user, uint8 role, bool enabled) external;
}
