// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {Ownable2StepUpgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {ERC20VotesUpgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {
    ERC20PermitUpgradeable,
    NoncesUpgradeable
} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract MorphoTokenVotesNoWrapper is ERC20VotesUpgradeable, ERC20PermitUpgradeable, Ownable2StepUpgradeable {
    string constant NAME = "Morpho";
    string constant SYMBOL = "Morpho";
    address constant DAO = address(0x0);
    address constant LEGACY_MORPHO = address(0x0);

    function initialize() public initializer {
        ERC20VotesUpgradeable.__ERC20Votes_init_unchained();
        ERC20Upgradeable.__ERC20_init_unchained(NAME, SYMBOL);
        Ownable2StepUpgradeable.__Ownable2Step_init();
        ERC20PermitUpgradeable.__ERC20Permit_init(NAME);

        _mint(DAO, 1_000_000_000e18); // Mint 1B to the DAO.
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
}
