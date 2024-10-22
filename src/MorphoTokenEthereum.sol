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

    /* EVENTS */

    /// @dev Emitted whenever tokens are minted for an account.
    event Mint(address indexed account, uint256 amount);

    /// @dev Emitted whenever tokens are burned from an account.
    event Burn(address indexed account, uint256 amount);

    /* ERRORS */

    /// @notice Reverts if the address is the zero address.
    error ZeroAddress();

    /* EXTERNAL */

    /// @notice Initializes the contract.
    /// @param owner The new owner.
    /// @param wrapper The wrapper contract address to migrate legacy MORPHO tokens to the new one.
    function initialize(address owner, address wrapper) external initializer {
        require(owner != address(0), ZeroAddress());

        __ERC20_init(NAME, SYMBOL);
        __ERC20Permit_init(NAME);

        _transferOwnership(owner);
        _mint(wrapper, 1_000_000_000e18); // Mint 1B to the wrapper contract.
    }

    /// @dev Mints tokens.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    /// @dev Burns sender's tokens.
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
        emit Burn(_msgSender(), amount);
    }
}
