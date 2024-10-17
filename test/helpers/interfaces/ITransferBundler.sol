// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface ITransferBundler {
    function erc20TransferFrom(address asset, uint256 amount) external;
}
