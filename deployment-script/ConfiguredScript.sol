// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console2.sol";

abstract contract ConfiguredScript is Script {
    using stdJson for string;

    bool internal immutable SAVE_VERIFY = true;

    string internal configPath;

    address internal morphoAddressEthereum;

    function _init(string memory network) internal returns (bytes memory) {
        vm.createSelectFork(vm.rpcUrl(network));

        console2.log("Running script on network %s using %s...", network, msg.sender);

        return _loadConfig(network);
    }

    function _loadConfig(string memory network) internal returns (bytes memory) {
        configPath = string.concat("deployment-script/", network, "/config.json");

        return vm.parseJson(vm.readFile(configPath));
    }

    function _deployCreate2Code(string memory network, string memory what, bytes memory args, bytes32 salt)
        internal
        returns (address addr)
    {
        bytes memory bytecode = abi.encodePacked(vm.getCode(string.concat("/out/", what, ".sol/", what, ".json")), args);

        assembly ("memory-safe") {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        require(addr != address(0), "create2 deployment failed");

        _logDeployment(network, what, args, addr);
    }

    function _logDeployment(string memory network, string memory what, bytes memory args, address addr) internal {
        console2.log("Deployed %s at: %s", what, addr);
        console2.log("Verify using:  > yarn verify:%s", network);

        if (!SAVE_VERIFY) return;

        string memory verifyPath = string.concat("deployment-script/", network, "/verify.sh");
        vm.writeLine(verifyPath, "");
        vm.writeLine(verifyPath, "then");
        vm.writeLine(
            verifyPath,
            string.concat(
                "FOUNDRY_PROFILE=build forge verify-contract --watch --chain-id ",
                vm.toString(block.chainid),
                " --constructor-args ",
                vm.toString(args),
                " ",
                vm.toString(addr),
                " src/",
                what,
                ".sol:",
                what
            )
        );
        vm.writeLine(verifyPath, "  cd ../../");
        vm.writeLine(verifyPath, "fi");
    }
}
