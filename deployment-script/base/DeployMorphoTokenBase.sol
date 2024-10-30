// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../ConfiguredScript.sol";

import {MorphoTokenOptimism} from "../../src/MorphoTokenOptimism.sol";

struct DeployMorphoTokenBaseSalt {
    bytes32 implementation;
    bytes32 proxy;
}

/// @dev Warning: keys must be ordered alphabetically.
struct DeployMorphoTokenEthereumConfig {
    address bridge;
    address morphoDao;
    address remoteToken;
    DeployMorphoTokenBaseSalt salt;
}

contract DeployMorphoTokenBase is ConfiguredScript {
    string constant network = "base";

    address public implementationAddress;
    MorphoTokenOptimism public token;
    address public wrapperAddress;
    address public newMorphoAddress;

    function run() public returns (DeployMorphoTokenEthereumConfig memory config) {
        config = abi.decode(_init(network), (DeployMorphoTokenEthereumConfig));

        vm.startBroadcast();

        // Deploy Token implementation
        implementationAddress = _deployCreate2Code(
            network, "MorphoTokenOptimism", abi.encode(config.remoteToken, config.bridge), config.salt.implementation
        );

        // Deploy Token proxy
        token = MorphoTokenOptimism(
            _deployCreate2Code(network, "ERC1967Proxy", abi.encode(implementationAddress), config.salt.proxy)
        );

        // Initialize Token
        token.initialize(config.morphoDao);

        vm.stopBroadcast();
    }
}
