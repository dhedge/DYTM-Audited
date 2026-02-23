// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20Metadata} from "@openzeppelin-contracts/interfaces/IERC20Metadata.sol";

import {IOracleModule} from "../../interfaces/IOracleModule.sol";

/// @title BaseOracleModule
/// @author Euler Labs <https://www.eulerlabs.com/>, Chinmay <chinmay@dhedge.org>
/// @custom:attribution Adapted from Euler's `BaseAdapter` contract <https://github.com/euler-xyz/euler-price-oracle/blob/ffc3cb82615fc7d003a7f431175bd1eaf0bf41c5/src/adapter/BaseAdapter.sol>
/// @notice Base contract for oracle modules.
abstract contract BaseOracleModule is IOracleModule {
    // @dev Addresses <= 0x00..00ffffffff are considered to have 18 decimals without dispatching a call.
    // This avoids collisions between ISO 4217 representations and (future) precompiles.
    uint256 internal constant _ADDRESS_RESERVED_RANGE = 0xffffffff;

    /// @inheritdoc IOracleModule
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount) {
        return _getQuote(inAmount, base, quote);
    }

    /// @notice Determine the decimals of an asset.
    /// @param asset ERC20 token address or other asset.
    /// @dev Oracles can use ERC-7535, ISO 4217 or other conventions to represent non-ERC20 assets as addresses.
    /// Integrator Note: `_getDecimals` will return 18 if `asset` is:
    /// - an EOA or a to-be-deployed contract (which may implement `decimals()` after deployment).
    /// - a contract that does not implement `decimals()`.
    /// @return decimals The decimals of the asset.
    function _getDecimals(address asset) internal view returns (uint8 decimals) {
        (bool success, bytes memory data) = asset.staticcall(abi.encodeCall(IERC20Metadata.decimals, ()));

        if (success && data.length == 32) {
            return abi.decode(data, (uint8));
        }

        return 18;
    }

    /// @notice Return the quote for the given price query.
    /// @dev Must be overridden in the inheriting contract.
    function _getQuote(uint256 inAmount, address base, address quote) internal view virtual returns (uint256 outAmount);
}
