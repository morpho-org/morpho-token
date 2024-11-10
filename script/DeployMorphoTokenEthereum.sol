// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import {MorphoTokenEthereum} from "../src/MorphoTokenEthereum.sol";
import {Wrapper} from "../src/Wrapper.sol";
import {ERC1967Proxy} from
    "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMorphoTokenEthereum is Script {
    address public constant MORPHO_DAO = 0xcBa28b38103307Ec8dA98377ffF9816C164f9AFa;

    function run() public returns (address, address) {
        vm.createSelectFork(vm.rpcUrl("ethereum"));

        vm.startBroadcast();

        // Deploy Token implementation
        address tokenImplementation = address(new MorphoTokenEthereum());
        console.log("Deployed token implementation at", tokenImplementation);

        address expectedWrapper = vm.computeCreateAddress(msg.sender, vm.getNonce(msg.sender) + 1);

        // Deploy Token proxy
        address token = address(
            new ERC1967Proxy(
                tokenImplementation,
                abi.encodeWithSelector(MorphoTokenEthereum.initialize.selector, MORPHO_DAO, expectedWrapper)
            )
        );

        console.log("Deployed token proxy at", address(token));

        // Deploy Wrapper
        address wrapper = address(new Wrapper(address(token)));
        console.log("Deployed wrapper at", wrapper);

        require(wrapper == expectedWrapper, "wrapper != expectedWrapper");

        vm.stopBroadcast();

        return (token, wrapper);
    }
}
