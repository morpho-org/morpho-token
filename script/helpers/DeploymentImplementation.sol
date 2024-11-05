// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title Deployment implementation for ERC1967Proxy
/// @author Morpho Association
/// @custom:security-contact security@morpho.org
/// Contract meant to be the implementation of an ERC1967Proxy at deployment.
contract DeploymentImplementation is UUPSUpgradeable {
    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override {}
}
