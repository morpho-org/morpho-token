// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../ConfiguredScript.sol";

import {MorphoTokenEthereum} from "../../src/MorphoTokenEthereum.sol";

contract DeployMorphoTokenEthereum is ConfiguredScript {
    bytes32 public constant IMPLEMENTATION_SALT;
    bytes32 public constant PROXY_SALT;
    bytes32 public constant WRAPPER_SALT;

    address public implementationAddress;
    MorphoTokenEthereum public token;
    address public wrapperAddress;
    address public newMorphoAddress;

    function run() public returns (address, address) {
        vm.startBroadcast();

        // Deploy Token implementation
        implementationAddress = _deployCreate2Code("MorphoTokenEthereum", hex"", IMPLEMENTATION_SALT);

        // Deploy Token proxy
        token = MorphoTokenEthereum(_deployCreate2Code("ERC1967Proxy", abi.encode(implementationAddress), PROXY_SALT));

        // Deploy Wrapper
        wrapperAddress = _deployCreate2Code("Wrapper", abi.encode(address(token)), WRAPPER_SALT);

        // Initialize Token
        token.initialize(MORPHO_DAO, wrapperAddress);

        vm.stopBroadcast();

        return (address(token), wrapperAddress);
    }
}
