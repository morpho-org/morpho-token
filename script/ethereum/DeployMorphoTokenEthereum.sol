// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../lib/forge-std/src/Script.sol";
import "../../lib/forge-std/src/console.sol";

import {MorphoTokenEthereum} from "../../src/MorphoTokenEthereum.sol";
import {Wrapper} from "../../src/Wrapper.sol";
import {ERC1967Proxy} from
    "../../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMorphoTokenEthereum is Script {
    address public constant MORPHO_DAO = 0xcBa28b38103307Ec8dA98377ffF9816C164f9AFa;

    bytes32 public IMPLEMENTATION_SALT;
    bytes32 public PROXY_SALT;
    bytes32 public WRAPPER_SALT;

    address public tokenImplementation;
    MorphoTokenEthereum public token;
    address public wrapper;
    address public newMorphoAddress;

    function run() public returns (address, address) {
        vm.createSelectFork(vm.rpcUrl("ethereum"));

        vm.startBroadcast();

        // Deploy Token implementation
        tokenImplementation = address(new MorphoTokenEthereum{salt: IMPLEMENTATION_SALT}());

        console.log("Deployed token implementation at", tokenImplementation);

        // Deploy Token proxy
        token = MorphoTokenEthereum(address(new ERC1967Proxy{salt: PROXY_SALT}(tokenImplementation, hex"")));

        console.log("Deployed token proxy at", address(token));

        // Deploy Wrapper
        wrapper = address(new Wrapper{salt: WRAPPER_SALT}(address(token)));

        console.log("Deployed wrapper at", wrapper);

        // Initialize Token
        token.initialize(MORPHO_DAO, wrapper);

        vm.stopBroadcast();

        return (address(token), wrapper);
    }
}
