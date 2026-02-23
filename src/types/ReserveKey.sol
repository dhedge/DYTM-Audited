// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";
import {MarketId, ReserveKey} from "./Types.sol";
import {TokenType} from "../libraries/TokenHelpers.sol";

import "../libraries/Constants.sol" as Constants;

/* solhint-disable private-vars-leading-underscore */
function eq(ReserveKey a, ReserveKey b) pure returns (bool isEqual) {
    return ReserveKey.unwrap(a) == ReserveKey.unwrap(b);
}

function notEq(ReserveKey a, ReserveKey b) pure returns (bool isNotEqual) {
    return ReserveKey.unwrap(a) != ReserveKey.unwrap(b);
}

/* solhint-enable private-vars-leading-underscore */

/// @title ReserveKeyLibrary
/// @notice Library for ReserveKey conversions related functions.
/// @author Chinmay <chinmay@dhedge.org>
library ReserveKeyLibrary {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error ReserveKeyLibrary__ZeroMarketId();
    error ReserveKeyLibrary__InvalidReserveKey(ReserveKey key);

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @dev Returns the ReserveKey for a particular principal asset in a market.
    function toReserveKey(MarketId marketId, IERC20 asset) internal pure returns (ReserveKey key) {
        uint88 unwrappedMarketId = MarketId.unwrap(marketId);

        require(unwrappedMarketId != 0, ReserveKeyLibrary__ZeroMarketId());

        uint248 marketIdPart = uint248(unwrappedMarketId) << 160;
        uint248 assetPart = uint160(address(asset));

        return ReserveKey.wrap(marketIdPart | assetPart);
    }

    /// @dev Function to convert a ReserveKey to an escrow reserve id.
    function toEscrowId(ReserveKey key) internal pure returns (uint256 escrowReserveId) {
        return uint256(uint256(TokenType.ESCROW) << 248) | uint256(ReserveKey.unwrap(key));
    }

    /// @dev Function to convert a ReserveKey to a share reserve id.
    function toLentId(ReserveKey key) internal pure returns (uint256 shareReserveId) {
        return uint256(uint256(TokenType.LEND) << 248) | uint256(ReserveKey.unwrap(key));
    }

    /// @dev Function to convert a ReserveKey to a debt reserve id.
    function toDebtId(ReserveKey key) internal pure returns (uint256 debtReserveId) {
        return uint256(uint256(TokenType.DEBT) << 248) | uint256(ReserveKey.unwrap(key));
    }

    /// @dev Function to get the ERC20 asset address from a ReserveKey.
    /// @dev Since the last 160 bits of the ReserveKey are reserved for the asset address,
    ///      we can cast the unwrapped key to a uint160.
    function getAsset(ReserveKey key) internal pure returns (IERC20 asset) {
        return IERC20(address(uint160(ReserveKey.unwrap(key))));
    }

    /// @dev Function to get the MarketId from a ReserveKey.
    /// @dev The MarketId is stored in the bits [247:160] of the ReserveKey.
    /// @dev We can extract it by right shifting the unwrapped key by 160 bits and casting it to a uint88.
    function getMarketId(ReserveKey key) internal pure returns (MarketId marketId) {
        uint88 marketIdPart = uint88(ReserveKey.unwrap(key) >> 160);

        return MarketId.wrap(marketIdPart);
    }

    /// @dev Function to validate a ReserveKey.
    /// @dev A valid ReserveKey must have a non-zero MarketId part.
    function validateReserveKey(ReserveKey key) internal pure {
        require(
            key != Constants.RESERVE_KEY_ZERO && uint88(ReserveKey.unwrap(key) >> 160) != 0,
            ReserveKeyLibrary__InvalidReserveKey(key)
        );
    }
}
