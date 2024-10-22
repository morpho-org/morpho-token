// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IOptimismMintableERC20} from "./interfaces/IOptimismMintableERC20.sol";
import {IERC165} from
    "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import {Token} from "./Token.sol";

/// @title MorphoToken
/// @author Morpho Association
/// @custom:contact security@morpho.org
/// @notice The MORPHO Token contract for Optimism networks.
contract MorphoTokenOptimism is Token  {
    /* CONSTANTS */

    /// @dev The name of the token.
    string internal constant NAME = "Morpho Token";

    /// @dev The symbol of the token.
    string internal constant SYMBOL = "MORPHO";

    // keccak256(abi.encode(uint256(keccak256("morpho.storage.OptimismMintableERC20")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OptimismMintableERC20StorageLocation =
        0x6fd4c0a11d0843c68c809f0a5f29b102d54bc08a251c384d9ad17600bfa05d00;

    /* STRUCTS */

    /// @custom:storage-location erc7201:morpho.storage.OptimismMintableERC20
    struct OptimismMintableERC20Storage {
        address _remoteToken;
        address _bridge;
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
        require(_msgSender() == $._bridge, NotBridge(_msgSender()));
        _;
    }

    /* PUBLIC */

    /// @notice Initializes the contract.
    /// @param dao The DAO address.
    /// @param remoteToken_ The address of the Morpho Token on Ethereum.
    /// @param bridge_ The address of the StandardBridge contract.
    function initialize(address dao, address remoteToken_, address bridge_) public initializer {
        require(dao != address(0), ZeroAddress());
        require(remoteToken_ != address(0), ZeroAddress());
        require(bridge_ != address(0), ZeroAddress());

        __ERC20_init(NAME, SYMBOL);

        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        $._remoteToken = remoteToken_;
        $._bridge = bridge_;

        _transferOwnership(dao); // Transfer ownership to the DAO.
    }

    /* EXTERNAL */

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

    /// @custom:legacy
    /// @dev Legacy getter for REMOTE_TOKEN.
    function remoteToken() external view returns (address) {
        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        return $._remoteToken;
    }

    /// @custom:legacy
    /// @dev Legacy getter for BRIDGE.
    function bridge() external view returns (address) {
        OptimismMintableERC20Storage storage $ = _getOptimismMintableERC20Storage();
        return $._bridge;
    }

    /* PRIVATE */

    /// @dev Returns the OptimismMintableERC20Storage struct.
    function _getOptimismMintableERC20Storage() private pure returns (OptimismMintableERC20Storage storage $) {
        assembly {
            $.slot := OptimismMintableERC20StorageLocation
        }
    }
}
