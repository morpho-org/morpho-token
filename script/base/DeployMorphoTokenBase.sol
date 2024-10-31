// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../lib/forge-std/src/Script.sol";
import "../../lib/forge-std/src/console.sol";

import {MorphoTokenOptimism} from "../../src/MorphoTokenOptimism.sol";
import {ERC1967Proxy} from
    "../../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMorphoTokenBase is Script {
    address public constant MORPHO_DAO = 0xcBa28b38103307Ec8dA98377ffF9816C164f9AFa;
    address public REMOTE_TOKEN;
    address public constant BRIDGE = 0x4200000000000000000000000000000000000010;

    bytes32 public IMPLEMENTATION_SALT;
    bytes32 public PROXY_SALT;

    address public implementationAddress;
    MorphoTokenOptimism public token;
    address public wrapperAddress;
    address public newMorphoAddress;

    function run() public returns (address) {
        vm.createSelectFork(vm.rpcUrl(network));

        vm.startBroadcast();

        // Deploy Token implementation
        implementationAddress = address(new MorphoTokenOptimism{salt: IMPLEMENTATION_SALT}(REMOTE_TOKEN, BRIDGE));

        console.log("Deployed token implementation at", implementationAddress);

        // Deploy Token proxy
        token = MorphoTokenOptimism(address(new ERC1967Proxy{salt: PROXY_SALT}(implementationAddress, hex"")));

        console.log("Deployed token proxy at", address(token));

        // Initialize Token
        token.initialize(MORPHO_DAO);

        vm.stopBroadcast();

        return address(token);
    }
}
