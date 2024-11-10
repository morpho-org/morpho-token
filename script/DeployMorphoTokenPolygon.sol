// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import {MorphoTokenOptimism} from "../src/MorphoTokenOptimism.sol";
import {ERC1967Proxy} from
    "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DeploymentImplementation} from "./helpers/DeploymentImplementation.sol";

contract DeployMorphoTokenBase is Script {
    address public constant MORPHO_DAO = 0xcBa28b38103307Ec8dA98377ffF9816C164f9AFa;
    address public constant REMOTE_TOKEN = 0x12Ec7dF395E8B974537006Cf3DF8b8fFE5C0D41C;
    address public constant BRIDGE = 0x4200000000000000000000000000000000000010;

    bytes32 public constant DEPLOYMENT_IMPLEMENTATION_SALT = 0;
    bytes32 public constant IMPLEMENTATION_SALT = 0;
    bytes32 public constant PROXY_SALT = 0;

    address public constant DEPLOYER = 0x937Ce2d6c488b361825D2DB5e8A70e26d48afEd5;

    function run() public returns (address) {
        vm.createSelectFork(vm.rpcUrl("polygon"));

        vm.startBroadcast(REMOTE_TOKEN);

        // Deploy initial implementation
        address deploymentImplementation = address(new DeploymentImplementation{salt: DEPLOYMENT_IMPLEMENTATION_SALT}());

        // Deploy Token proxy
        MorphoTokenOptimism token =
            MorphoTokenOptimism(address(new ERC1967Proxy{salt: PROXY_SALT}(deploymentImplementation, hex"")));
        console.log("Deployed token proxy at", address(token));

        vm.stopBroadcast();

        return address(token);
    }
}
