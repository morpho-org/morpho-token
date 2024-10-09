// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {
    IERC20, ERC20Upgradeable
} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {Ownable2StepUpgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {ERC20VotesUpgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {ERC20WrapperUpgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20WrapperUpgradeable.sol";
import {
    ERC20PermitUpgradeable,
    NoncesUpgradeable
} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract MorphoTokenVotesWrapper is
    ERC20VotesUpgradeable,
    ERC20WrapperUpgradeable,
    ERC20PermitUpgradeable,
    Ownable2StepUpgradeable
{
    string constant NAME = "Morpho";
    string constant SYMBOL = "Morpho";
    address constant LEGACY_MORPHO = address(0x0);
    address constant DAO = address(0x0);

    function initialize() public initializer {
        ERC20VotesUpgradeable.__ERC20Votes_init_unchained();
        ERC20Upgradeable.__ERC20_init_unchained(NAME, SYMBOL);
        Ownable2StepUpgradeable.__Ownable2Step_init();
        ERC20PermitUpgradeable.__ERC20Permit_init(NAME);
        ERC20WrapperUpgradeable.__ERC20Wrapper_init_unchained(IERC20(LEGACY_MORPHO));
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        ERC20VotesUpgradeable._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20PermitUpgradeable, NoncesUpgradeable) returns (uint256) {
        return ERC20PermitUpgradeable.nonces(owner);
    }

    function decimals() public view override(ERC20Upgradeable, ERC20WrapperUpgradeable) returns (uint8) {
        return ERC20WrapperUpgradeable.decimals();
    }

    // No need to override depositFor as it wraps 1:1 legacy tokens to new tokens.
    // We would also mint 1B MORPHO tokens to the DAO at initialization and do the same thing as in `Wrapper` contract here.
    // function depositFor(address account, uint256 amount) public override returns (bool)

    function withdrawTo(address, uint256) public override pure returns (bool) {
        return false;
    }
}
