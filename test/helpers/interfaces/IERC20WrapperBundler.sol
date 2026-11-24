// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20WrapperBundler {
    function erc20WrapperDepositFor(address wrapper, uint256 amount) external;
}
