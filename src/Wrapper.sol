// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// TODO:
// - add natspecs
// - add events?
// - add error messages
// - update license
contract Wrapper {
    address public constant LEGACY_MORPHO = address(0x9994E35Db50125E0DF82e4c2dde62496CE330999);

    address public immutable NEW_MORPHO;

	// @dev morphoToken address can be precomputed using create2.
    constructor(address morphoToken) {
        require(morphoToken != address(0), "Wrapper: zero address"); // TODO: clean errors

        NEW_MORPHO = morphoToken;
    }

    // Compliant to ERC20Wrapper for convenience.
    function depositFor(address account, uint256 amount) public returns (bool) {
        IERC20(LEGACY_MORPHO).transferFrom(msg.sender, address(this), amount);
        IERC20(NEW_MORPHO).transfer(account, amount);
        return true;
    }

    /// @dev To ease wrapping via the bundler contract: https://github.com/morpho-org/morpho-blue-bundlers/blob/main/src/ERC20WrapperBundler.sol
    function underlying() public pure returns (address) {
        return LEGACY_MORPHO;
    }
}
