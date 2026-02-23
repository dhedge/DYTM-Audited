// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";
import {MarketId, ReserveKey} from "../types/Types.sol";

enum TokenType {
    NONE, // 0
    ESCROW, // 1
    LEND, // 2
    DEBT, // 3
    ISOLATED_ACCOUNT // 4
}

/// @title TokenHelpers
/// @notice A library for handling tokenId related operations.
/// @author Chinmay <chinmay@dhedge.org>
library TokenHelpers {
    /// @dev Function to get the token type from a tokenId.
    /// @dev If the least significant 160 bits of the tokenId are zero and the top 96 bits are non-zero, it's an
    ///      isolated account token. Otherwise, provided the next 88 bits and the most significant byte bits are non-zero,
    ///      the token type is stored in the most significant byte of the tokenId.
    /// @dev [!WARNING] It will return `TokenType.NONE` instead of reverting.
    /// @param tokenId The token ID to convert.
    /// @return tokenType The type of the token, represented as a uint8.
    function getTokenType(uint256 tokenId) internal pure returns (TokenType tokenType) {
        uint160 lsb160 = uint160(tokenId);
        uint96 msb96 = uint96(tokenId >> 160);
        uint8 typeByte = uint8(msb96 >> 88);

        if (lsb160 == 0 && msb96 != 0) {
            return TokenType.ISOLATED_ACCOUNT;
        } else if (lsb160 != 0 && msb96 != 0 && typeByte > 0) {
            // The token is one of ESCROW, LEND, DEBT type.
            return TokenType(typeByte);
        } else {
            return TokenType.NONE;
        }
    }

    /// @dev Function to get the MarketId from a tokenId.
    /// @dev The MarketId is stored in the bits [247:160] of the tokenId.
    /// @dev We can extract it by right shifting the tokenId by 160 bits and casting it to a uint88.
    function getMarketId(uint256 tokenId) internal pure returns (MarketId marketId) {
        return MarketId.wrap(uint88(tokenId >> 160));
    }

    /// @dev Function to get the asset address from a tokenId.
    /// @dev The asset address is the last 160 bits of the token ID.
    /// @param tokenId The token ID to convert.
    /// @return asset The IERC20 asset corresponding to the tokenId.
    function getAsset(uint256 tokenId) internal pure returns (IERC20 asset) {
        return IERC20(address(uint160(tokenId)));
    }

    /// @dev Function to get the ReserveKey from a tokenId.
    /// @dev The ReserveKey is the last 248 bits of the tokenId consisting of the MarketId and the asset address.
    /// @dev We can extract it by casting the tokenId to a uint248 and then wrapping it in a ReserveKey.
    /// @param tokenId The token ID to convert.
    /// @return key The ReserveKey corresponding to the tokenId.
    function getReserveKey(uint256 tokenId) internal pure returns (ReserveKey key) {
        return ReserveKey.wrap(uint248(tokenId));
    }

    /// @dev Function to check if a tokenId is a collateral token.
    /// @dev A token is considered collateral if it is either an escrow token or a share token.
    /// @param tokenId The token ID to check.
    /// @return result True if the tokenId is a collateral token, false otherwise.
    function isCollateral(uint256 tokenId) internal pure returns (bool result) {
        TokenType tokenType = getTokenType(tokenId);

        return (tokenType == TokenType.ESCROW || tokenType == TokenType.LEND);
    }

    /// @dev Function to check if a tokenId is a debt token.
    /// @param tokenId The token ID to check.
    /// @return result True if the tokenId is a debt token, false otherwise.
    function isDebt(uint256 tokenId) internal pure returns (bool result) {
        TokenType tokenType = getTokenType(tokenId);

        return (tokenType == TokenType.DEBT);
    }
}
