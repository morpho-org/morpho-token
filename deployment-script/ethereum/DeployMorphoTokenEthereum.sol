// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../ConfiguredScript.sol";

import {MorphoTokenEthereum} from "../../src/MorphoTokenEthereum.sol";

struct DeployMorphoTokenEthereumSalt {
    bytes32 implementation;
    bytes32 proxy;
    bytes32 wrapper;
}

/// @dev Warning: keys must be ordered alphabetically.
struct DeployMorphoTokenEthereumConfig {
    address morphoDao;
    DeployMorphoTokenEthereumSalt salt;
}

contract DeployMorphoTokenEthereum is ConfiguredScript {
    string constant network = "ethereum";

    address public implementationAddress;
    MorphoTokenEthereum public token;
    address public wrapperAddress;
    address public newMorphoAddress;

    function run() public returns (DeployMorphoTokenEthereumConfig memory config) {
        config = abi.decode(_init("ethereum"), (DeployMorphoTokenEthereumConfig));

        vm.startBroadcast();

        // Deploy Token implementation
        implementationAddress = _deployCreate2Code(network, "MorphoTokenEthereum", hex"", config.salt.implementation);

        // Deploy Token proxy
        token = MorphoTokenEthereum(
            _deployCreate2Code(network, "ERC1967Proxy", abi.encode(implementationAddress), config.salt.proxy)
        );

        // Deploy Wrapper
        wrapperAddress = _deployCreate2Code(network, "Wrapper", abi.encode(address(token)), config.salt.wrapper);

        // Initialize Token
        token.initialize(config.morphoDao, wrapperAddress);

        vm.stopBroadcast();
    }
}
