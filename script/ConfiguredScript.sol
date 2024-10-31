// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

abstract contract ConfiguredScript is Script {
    using stdJson for string;

    address public constant MORPHO_DAO = 0xcBa28b38103307Ec8dA98377ffF9816C164f9AFa;

    function _deployCreate2Code(string memory what, bytes memory args, bytes32 salt) internal returns (address addr) {
        bytes memory bytecode = abi.encodePacked(vm.getCode(string.concat("/out/", what, ".sol/", what, ".json")), args);

        assembly ("memory-safe") {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        require(addr != address(0), "create2 deployment failed");

        console.log("Deployed", what, "at", addr);
    }
}
