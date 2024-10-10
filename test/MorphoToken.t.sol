// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MorphoToken} from "../src/MorphoToken.sol";

// TODO: Test the following:
// - Test every paths
// - Test migration flow
// - Test bundler wrapping
// - Test access control
// - Test voting
// - Test delegation
contract MorphoTokenTest is Test {
    MorphoToken public token;

    function setUp() public {}
}
