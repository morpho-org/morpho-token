// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.27;

import {Token} from "./Token.sol";

/// @title MorphoTokenEthereum
/// @author Morpho Association
/// @custom:contact security@morpho.org
/// @notice The Morpho token contract for Ethereum.
contract MorphoTokenEthereum is Token {
    /* CONSTANTS */

    /// @dev The name of the token.
    string internal constant NAME = "Morpho Token";

    /// @dev The symbol of the token.
    string internal constant SYMBOL = "MORPHO";

    /* ERRORS */

    /// @notice Reverts if the address is the zero address.
    error ZeroAddress();

    /* PUBLIC */

    /// @notice Initializes the contract.
    /// @param owner The new owner.
    /// @param wrapper The wrapper contract address to migrate legacy MORPHO tokens to the new one.
    function initialize(address owner, address wrapper) public initializer {
        require(owner != address(0), ZeroAddress());

        __ERC20_init(NAME, SYMBOL);
        __ERC20Permit_init(NAME);

        _transferOwnership(owner);
        _mint(wrapper, 1_000_000_000e18); // Mint 1B to the wrapper contract.
    }
}
