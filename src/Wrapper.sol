// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBurn {
    function burn(uint256 amount) external;
}

contract Wrapper {
    address public constant LEGACY_MORPHO = address(0x0);
    address public constant DAO = address(0x0);
    address public constant MORPHO = address(0x0);

    function wrap(uint256 amount) external {
        IERC20(LEGACY_MORPHO).transferFrom(msg.sender, address(this), amount);
        IBurn(LEGACY_MORPHO).burn(amount);
        IERC20(MORPHO).transferFrom(DAO, msg.sender, amount);
    }
}
