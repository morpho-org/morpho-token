// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../lib/forge-std/src/Script.sol";
import "../../lib/forge-std/src/console.sol";

import {MorphoTokenOptimism} from "../../src/MorphoTokenOptimism.sol";
import {ERC1967Proxy} from
    "../../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DeploymentImplementation} from "../helpers/DeploymentImplementation.sol";

contract DeployMorphoTokenBase is Script {
    address public constant MORPHO_DAO = 0xcBa28b38103307Ec8dA98377ffF9816C164f9AFa;
    address public REMOTE_TOKEN = 0x12Ec7dF395E8B974537006Cf3DF8b8fFE5C0D41C;
    address public constant BRIDGE = 0x4200000000000000000000000000000000000010;

    address constant DEPLOYER = 0x937Ce2d6c488b361825D2DB5e8A70e26d48afEd5;

    bytes32 public DEPLOYMENT_IMPLEMENTATION_SALT;
    bytes32 public IMPLEMENTATION_SALT;
    bytes32 public PROXY_SALT;

    address public deploymentImplementation;
    address public tokenImplementation;
    MorphoTokenOptimism public token;
    address public newMorphoAddress;

    function run() public returns (address) {
        vm.createSelectFork(vm.rpcUrl("base"));

        vm.startBroadcast(DEPLOYER);

        // Deploy initial implementation
        deploymentImplementation = address(new DeploymentImplementation{salt: DEPLOYMENT_IMPLEMENTATION_SALT}());

        // Deploy Token implementation
        tokenImplementation = address(new MorphoTokenOptimism{salt: IMPLEMENTATION_SALT}(REMOTE_TOKEN, BRIDGE));

        console.log("Deployed token implementation at", tokenImplementation);

        // Deploy Token proxy
        token = MorphoTokenOptimism(address(new ERC1967Proxy{salt: PROXY_SALT}(deploymentImplementation, hex"")));

        console.log("Deployed token proxy at", address(token));

        // Upgrade to Token implementation
        token.upgradeToAndCall(tokenImplementation, hex"");

        // Initialize Token
        token.initialize(MORPHO_DAO);

        vm.stopBroadcast();

        return address(token);
    }
}
