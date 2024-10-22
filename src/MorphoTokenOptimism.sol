// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.27;

import {IOptimismMintableERC20} from "./interfaces/IOptimismMintableERC20.sol";
import {IERC165} from
    "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {Token} from "./Token.sol";

/// @title MorphoTokenOptimism
/// @author Morpho Association
/// @custom:contact security@morpho.org
/// @notice The Morpho token contract for Optimism networks.
contract MorphoTokenOptimism is Token, IOptimismMintableERC20 {
    /* CONSTANTS */

    /// @dev The name of the token.
    string internal constant NAME = "Morpho Token";

    /// @dev The symbol of the token.
    string internal constant SYMBOL = "MORPHO";

    /// @notice The Morpho token on Ethereum.
    /// @dev Does not follow our classic naming convention to suits Optimism' standard.
    address public immutable remoteToken;

    /// @dev The StandardBridge.
    /// @dev Does not follow our classic naming convention to suits Optimism' standard.
    address public immutable bridge;

    /* ERRORS */

    /// @notice Reverts if the address is the zero address.
    error ZeroAddress();

    /// @notice Reverts if the caller is not the bridge.
    error NotBridge();

    /* CONSTRUCTOR */

    constructor(address newRemoteToken, address newBridge) {
        remoteToken = newRemoteToken;
        bridge = newBridge;
    }

    /* MODIFIERS */

    /// @dev A modifier that only allows the bridge to call.
    modifier onlyBridge() {
        require(_msgSender() == bridge, NotBridge());
        _;
    }

    /* EXTERNAL */

    /// @notice Initializes the contract.
    /// @param owner The new owner.
    function initialize(address owner) external initializer {
        require(owner != address(0), ZeroAddress());

        __ERC20_init(NAME, SYMBOL);
        __ERC20Permit_init(NAME);

        _transferOwnership(owner);
    }

    /// @dev Allows the StandardBridge on this network to mint tokens.
    function mint(address to, uint256 amount) external onlyBridge {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    /// @dev Allows the StandardBridge on this network to burn tokens.
    function burn(address from, uint256 amount) external onlyBridge {
        _burn(from, amount);
        emit Burn(from, amount);
    }

    /// @notice ERC165 interface check function.
    /// @param _interfaceId Interface ID to check.
    /// @return Whether or not the interface is supported by this contract.
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        bytes4 interfaceERC165 = type(IERC165).interfaceId;
        bytes4 interfaceOptimismMintableERC20 = type(IOptimismMintableERC20).interfaceId;
        return _interfaceId == interfaceERC165 || _interfaceId == interfaceOptimismMintableERC20;
    }
}
