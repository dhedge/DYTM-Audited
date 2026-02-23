// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {MarketId} from "./Types.sol";

/* solhint-disable private-vars-leading-underscore */
function eq(MarketId a, MarketId b) pure returns (bool isEqual) {
    return MarketId.unwrap(a) == MarketId.unwrap(b);
}

function notEq(MarketId a, MarketId b) pure returns (bool isNotEqual) {
    return MarketId.unwrap(a) != MarketId.unwrap(b);
}

/* solhint-enable private-vars-leading-underscore */

/// @title MarketIdLibrary
/// @notice Library for MarketId conversions related functions.
/// @author Chinmay <chinmay@dhedge.org>
library MarketIdLibrary {
    error MarketIdLibrary__ZeroMarketId();

    /// @dev MarketId is a simple wrapper around uint256.
    /// @dev A market can't be created with `count` = 0.
    /// @param count The market count to be converted.
    /// @return market The MarketId corresponding to the given count.
    function toMarketId(uint88 count) internal pure returns (MarketId market) {
        require(count != 0, MarketIdLibrary__ZeroMarketId());

        return MarketId.wrap(count);
    }
}
