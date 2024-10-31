// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../ConfiguredScript.sol";

import {MorphoTokenOptimism} from "../../src/MorphoTokenOptimism.sol";

contract DeployMorphoTokenBase is ConfiguredScript {
    address public REMOTE_TOKEN;
    address public constant BRIDGE = 0x4200000000000000000000000000000000000010;

    bytes32 public IMPLEMENTATION_SALT;
    bytes32 public PROXY_SALT;

    address public implementationAddress;
    MorphoTokenOptimism public token;
    address public wrapperAddress;
    address public newMorphoAddress;

    function run() public returns (address) {
        vm.startBroadcast();

        // Deploy Token implementation
        implementationAddress =
            _deployCreate2Code("MorphoTokenOptimism", abi.encode(REMOTE_TOKEN, BRIDGE), IMPLEMENTATION_SALT);

        // Deploy Token proxy
        token = MorphoTokenOptimism(_deployCreate2Code("ERC1967Proxy", abi.encode(implementationAddress), PROXY_SALT));

        // Initialize Token
        token.initialize(MORPHO_DAO);

        vm.stopBroadcast();

        return address(token);
    }
}
