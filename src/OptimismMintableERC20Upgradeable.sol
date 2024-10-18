// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IOptimismMintableERC20} from "./interfaces/IOptimismMintableERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

/// @title OptimismMintableERC20
/// @author Morpho Association
/// @custom:contact security@morpho.org
/// @dev Extension of ERC20 to Optimism network deployment.
///
/// This extension allows the StandardBridge contracts to mint and burn tokens. This makes it possible to use an
/// OptimismMintablERC20 as the L2 representation of an L1 token, or vice-versa. Designed to be backwards compatible
/// with the older StandardL2ERC20 token which was only meant for use on L2.
contract OptimismMintableERC20Upgradeable is Initializable, IOptimismMintableERC20, ERC20Upgradeable {
    // keccak256(abi.encode(uint256(keccak256("morpho.storage.OptimismMintableERC20")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OptimismMintableERC20StorageLocation =
        0x6fd4c0a11d0843c68c809f0a5f29b102d54bc08a251c384d9ad17600bfa05d00;

    /* STRUCTS */

    /// @custom:storage-location erc7201:morpho.storage.OptimismMintableERC20
    struct OptimismMintableERC20Storage {
        address _REMOTE_TOKEN;
        address _BRIDGE;
    }

    /* EVENTS */

    /// @dev Emitted whenever tokens are minted for an account.
    event Mint(address indexed account, uint256 amount);

    /// @dev Emitted whenever tokens are burned from an account.
    event Burn(address indexed account, uint256 amount);

    /* ERRORS */

    /// @notice Reverts if the address is the zero address.
    error ZeroAddress();

    /// @notice Reverts if the caller is not the bridge.
    error NotBridge(address caller);

    /* MODIFIERS */

    /// @dev A modifier that only allows the bridge to call.
    modifier onlyBridge() {
        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        require(_msgSender() == $._BRIDGE, NotBridge(_msgSender()));
        _;
    }

    /* INITIALIZER */

    /// @dev Sets the values for {remoteToken} and {bridge}.
    /// @dev All two of these values are immutable: they can only be set once during initialization.
    function __OptimismMintableERC20_init(address remoteToken_, address bridge_) internal onlyInitializing {
        __OptimismMintableERC20_init_unchained(remoteToken_, bridge_);
    }

    function __OptimismMintableERC20_init_unchained(address remoteToken_, address bridge_) internal onlyInitializing {
        require(remoteToken_ != address(0), ZeroAddress());
        require(bridge_ != address(0), ZeroAddress());

        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        $._REMOTE_TOKEN = remoteToken_;
        $._BRIDGE = bridge_;
    }

    /* EXTERNAL */

    /// @dev Allows the StandardBridge on this network to mint tokens.
    function mint(address _to, uint256 _amount) external virtual override onlyBridge {
        _mint(_to, _amount);
        emit Mint(_to, _amount);
    }

    /// @dev Allows the StandardBridge on this network to burn tokens.
    function burn(address _from, uint256 _amount) external virtual override onlyBridge {
        _burn(_from, _amount);
        emit Burn(_from, _amount);
    }

    /// @notice ERC165 interface check function.
    /// @param _interfaceId Interface ID to check.
    /// @return Whether or not the interface is supported by this contract.
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        bytes4 iface1 = type(IERC165).interfaceId;
        // Interface corresponding to the updated OptimismMintableERC20 (this contract).
        bytes4 iface3 = type(IOptimismMintableERC20).interfaceId;
        return _interfaceId == iface1 || _interfaceId == iface3;
    }

    /* PUBLIC */

    /// @custom:legacy
    /// @dev Legacy getter for REMOTE_TOKEN.
    function remoteToken() public view returns (address) {
        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        return $._REMOTE_TOKEN;
    }

    /// @custom:legacy
    /// @dev Legacy getter for BRIDGE.
    function bridge() public view returns (address) {
        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        return $._BRIDGE;
    }

    /* PRIVATE */

    /// @dev Returns the OptimismMintableERC20Storage struct.
    function _getOptimismMintableERC20Storage() private pure returns (OptimismMintableERC20Storage storage $) {
        assembly {
            $.slot := OptimismMintableERC20StorageLocation
        }
    }
}
