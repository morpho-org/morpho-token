// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import {MorphoTokenOptimism} from "../src/MorphoTokenOptimism.sol";
import {ERC1967Proxy} from
    "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMorphoTokenBase is Script {
    address public constant MORPHO_DAO = 0xcBa28b38103307Ec8dA98377ffF9816C164f9AFa;
    address public constant REMOTE_TOKEN = 0x58D97B57BB95320F9a05dC918Aef65434969c2B2;
    address public constant BRIDGE = 0x4200000000000000000000000000000000000010;

    function run() public returns (address) {
        vm.createSelectFork(vm.rpcUrl("base"));

        vm.startBroadcast();

        // Deploy Token implementation
        address tokenImplementation = address(new MorphoTokenOptimism(REMOTE_TOKEN, BRIDGE));
        console.log("Deployed token implementation at", tokenImplementation);

        // Deploy Token proxy and initialize it.
        address token = address(
            new ERC1967Proxy(
                tokenImplementation, abi.encodeWithSelector(MorphoTokenOptimism.initialize.selector, MORPHO_DAO)
            )
        );
        console.log("Deployed token proxy at", address(token));

        vm.stopBroadcast();

        return token;
    }
}
