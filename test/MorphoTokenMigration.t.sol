// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "./helpers/BaseTest.sol";

// TODO: Test the following:
// - Test migration flow
// - Test bundler wrapping
contract MorphoTokenMigrationTest is BaseTest {
    uint256 internal forkId;

    function setUp() public virtual override {
        // DEPLOYMENTS
        _fork();
        super.setUp();
    }

    function _fork() internal virtual {
        string memory rpcUrl = vm.rpcUrl("ethereum");
        uint256 forkBlockNumber = 20969715;

        forkId = vm.createSelectFork(rpcUrl, forkBlockNumber);
        vm.chainId(1);
    }
}
