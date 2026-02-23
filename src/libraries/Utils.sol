// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AccountId} from "../types/Types.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";

/// @title Utils
/// @notice Utility functions for handling `type(uint256).max` conditions and other common operations.
/// @dev Requires the inheriting contract to implement `IRegistry` for balance checks.
/// @author Chinmay <chinmay@dhedge.org>
library Utils {
    /// @dev Returns the requested assets or the maximum assets held by the caller if requested is `type(uint256).max`.
    function someOrMaxAssets(IERC20 asset, uint256 requested) internal view returns (uint256 assets) {
        return (requested == type(uint256).max) ? asset.balanceOf(msg.sender) : requested;
    }

    /// @dev Returns the requested shares or the maximum shares held by the account if requested is `type(uint256).max`.
    function someOrMaxShares(
        AccountId account,
        uint256 tokenId,
        uint256 requested
    )
        internal
        view
        returns (uint256 shares)
    {
        return (requested == type(uint256).max) ? IRegistry(address(this)).balanceOf(account, tokenId) : requested;
    }

    /// @dev Returns true if exactly one of `a` or `b` is zero but not both.
    function exactlyOneZero(uint256 a, uint256 b) internal pure returns (bool isExactlyOneZero) {
        assembly ("memory-safe") {
            isExactlyOneZero := xor(iszero(a), iszero(b))
        }
    }
}
