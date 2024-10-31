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

    address public implementationAddress;
    MorphoTokenEthereum public token;
    address public wrapperAddress;
    address public newMorphoAddress;

    function run() public returns (address, address) {
        vm.createSelectFork(vm.rpcUrl(network));

        vm.startBroadcast();

        // Deploy Token implementation
        implementationAddress = address(new MorphoTokenEthereum{salt: IMPLEMENTATION_SALT}());

        console.log("Deployed token implementation at", implementationAddress);

        // Deploy Token proxy
        token = MorphoTokenEthereum(address(new ERC1967Proxy{salt: PROXY_SALT}(implementationAddress, hex"")));

        console.log("Deployed token proxy at", address(token));

        // Deploy Wrapper
        wrapperAddress = address(new Wrapper{salt: WRAPPER_SALT}(address(token)));

        console.log("Deployed wrapper at", wrapperAddress);

        // Initialize Token
        token.initialize(MORPHO_DAO, wrapperAddress);

        vm.stopBroadcast();

        return (address(token), wrapperAddress);
    }
}
