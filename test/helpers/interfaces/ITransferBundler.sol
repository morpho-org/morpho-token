// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferBundler {
    function erc20TransferFrom(address asset, uint256 amount) external;
}
