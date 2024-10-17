// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20WrapperBundler} from "../interfaces/IERC20WrapperBundler.sol";
import {ITransferBundler} from "../interfaces/ITransferBundler.sol";

library EncodeLib {
    function _erc20WrapperDepositFor(address asset, uint256 amount) internal pure returns (bytes memory) {
        return abi.encodeCall(IERC20WrapperBundler.erc20WrapperDepositFor, (asset, amount));
    }

    function _erc20TransferFrom(address asset, uint256 amount) internal pure returns (bytes memory) {
        return abi.encodeCall(ITransferBundler.erc20TransferFrom, (asset, amount));
    }
}
