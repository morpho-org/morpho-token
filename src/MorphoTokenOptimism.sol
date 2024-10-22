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

    // keccak256(abi.encode(uint256(keccak256("morpho.storage.OptimismMintableERC20")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 internal constant OptimismMintableERC20StorageLocation =
        0x6fd4c0a11d0843c68c809f0a5f29b102d54bc08a251c384d9ad17600bfa05d00;

    /* STORAGE LAYOUT */

    /// @custom:storage-location erc7201:morpho.storage.OptimismMintableERC20
    struct OptimismMintableERC20Storage {
        address _remoteToken;
        address _bridge;
    }

    /* ERRORS */

    /// @notice Reverts if the address is the zero address.
    error ZeroAddress();

    /// @notice Reverts if the caller is not the bridge.
    error NotBridge(address caller);

    /* MODIFIERS */

    /// @dev A modifier that only allows the bridge to call.
    modifier onlyBridge() {
        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        require(_msgSender() == $._bridge, NotBridge(_msgSender()));
        _;
    }

    /* EXTERNAL */

    /// @notice Initializes the contract.
    /// @param owner The new owner.
    /// @param remoteToken_ The address of the Morpho token on Ethereum.
    /// @param bridge_ The address of the StandardBridge contract.
    function initialize(address owner, address remoteToken_, address bridge_) external initializer {
        require(owner != address(0), ZeroAddress());
        require(remoteToken_ != address(0), ZeroAddress());
        require(bridge_ != address(0), ZeroAddress());

        __ERC20_init(NAME, SYMBOL);
        __ERC20Permit_init(NAME);

        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        $._remoteToken = remoteToken_;
        $._bridge = bridge_;

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

    /// @dev Returns the address of the Morpho token on Ethereum.
    function remoteToken() external view returns (address) {
        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        return $._remoteToken;
    }

    /// @dev Returns the address of the StandardBridge contract.
    function bridge() external view returns (address) {
        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        return $._bridge;
    }

    /* INTERNAL */

    /// @dev Returns the OptimismMintableERC20Storage struct.
    function _getOptimismMintableERC20Storage() internal pure returns (OptimismMintableERC20Storage storage $) {
        assembly {
            $.slot := OptimismMintableERC20StorageLocation
        }
    }
}
