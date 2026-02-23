// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IMarketConfig} from "./IMarketConfig.sol";

import {MarketId, ReserveKey} from "../types/Types.sol";

/**
 * @title IOfficeStorage
 * @notice Interface for the storage functions of the Office contract.
 * @author Chinmay <chinmay@dhedge.org>
 */
interface IOfficeStorage {
    /**
     * @dev Struct to store the asset amounts supplied and borrowed to/from a reserve.
     * @dev `supplied` and `borrowed` accounts for interest accrued until the last update timestamp.
     * @param supplied The amount of the asset supplied (lent) to the reserve.
     * @param borrowed The amount of the asset borrowed from the reserve.
     * @param lastUpdateTimestamp The last time the reserve data was updated.
     */
    struct ReserveData {
        uint256 supplied;
        uint256 borrowed;
        uint128 lastUpdateTimestamp;
    }

    /**
     * @notice Returns the officer address for a given market.
     * @param market The market ID for which to retrieve the officer.
     * @return officer The address of the officer for the specified market.
     */
    function getOfficer(MarketId market) external view returns (address officer);

    /**
     * @notice Returns the market configuration contract for a given market.
     * @param market The market ID for which to retrieve the configuration.
     * @return marketConfig The market configuration contract for the specified market.
     */
    function getMarketConfig(MarketId market) external view returns (IMarketConfig marketConfig);

    /**
     * @notice Returns the reserve data for a given reserve key.
     * @param key The reserve key for the asset.
     * @return reserveData The reserve data for the asset.
     */
    function getReserveData(ReserveKey key) external view returns (ReserveData memory reserveData);
}
