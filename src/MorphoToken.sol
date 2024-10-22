// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.27;

import {Ownable2StepUpgradeable} from
    "../lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {ERC20PermitDelegatesUpgradeable} from "./ERC20PermitDelegatesUpgradeable.sol";
import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title MorphoToken
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice The MORPHO Token contract.
contract MorphoToken is ERC20PermitDelegatesUpgradeable, Ownable2StepUpgradeable, UUPSUpgradeable {
    /* CONSTANTS */

    /// @dev The name of the token.
    string internal constant NAME = "Morpho Token";

    /// @dev The symbol of the token.
    string internal constant SYMBOL = "MORPHO";

    /* ERRORS */

    /// @notice Reverts if the address is the zero address.
    error ZeroAddress();

    /* CONSTRUCTOR */

    // @dev Disables initializers for the implementation contract.
    constructor() {
        _disableInitializers();
    }

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

    /* INTERNAL */

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
