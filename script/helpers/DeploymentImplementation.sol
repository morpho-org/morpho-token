// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title Deployment implementation for ERC1967Proxy
/// @author Morpho Association
/// @custom:contact security@morpho.org
/// @dev Extension of UUPSUpgradeable.
///
/// Contract meant to be the implementation of an ERC1967Proxy at deployment.
contract DeploymentImplementation is UUPSUpgradeable {
    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override {}
}
