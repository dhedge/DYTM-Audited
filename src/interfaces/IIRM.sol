// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {ReserveKey} from "../types/Types.sol";

/**
 * @title IIRM
 * @notice Interest Rate Model interface for a market in the DYTM protocol.
 * @author Chinmay <chinmay@dhedge.org>
 * @dev Follows similar interface as a Morpho market's IRM.
 */
interface IIRM {
    /**
     * @notice Returns the updated borrow rate for a given reserve key.
     * @dev Assumes that the implementation is non-view to allow for any state changes in the implementation.
     * @param key The reserve key for which the borrow rate is requested.
     * @return ratePerSecond The borrow rate per second for the given reserve key.
     */
    function borrowRate(ReserveKey key) external returns (uint256 ratePerSecond);

    /**
     * @notice Returns the borrow rate for a given reserve key.
     * @param key The reserve key for which the borrow rate is requested.
     * @return ratePerSecond The borrow rate per second for the given reserve key.
     */
    function borrowRateView(ReserveKey key) external view returns (uint256 ratePerSecond);
}
