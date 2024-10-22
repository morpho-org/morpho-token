// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IERC20WrapperBundler {
    function erc20WrapperDepositFor(address wrapper, uint256 amount) external;
}
