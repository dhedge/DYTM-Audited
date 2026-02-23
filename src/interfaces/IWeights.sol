// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {ReserveKey, AccountId} from "../types/Types.sol";

/**
 * @title IWeights
 * @author Chinmay <chinmay@dhedge.org>
 * @notice Interface for calculating collateral weights in the DYTM protocol.
 * @dev Weights determine how much collateral value counts towards borrowing capacity.
 *      A weight of 1e18 (100%) means the collateral is fully equivalent to the debt asset.
 */
interface IWeights {
    /**
     * @notice Returns the weight of the collateral asset in relation to the debt asset.
     * @dev The weight should be a value between 0 and 1e18, where 1e18 means the collateral asset
     *      is fully equivalent to the debt asset.
     *          - If the weight between the two assets doesn't exist, it should return 0 and
     *            the asset should not be a supported asset in the market.
     *          - May return a value less than 1e18 even if the collateral asset is fully equivalent to the debt asset.
     * @param account The account ID for more context.
     * @param collateralTokenId The token ID of the collateral asset to differentiate between escrowed and lent
     *                          collateral.
     * @param debtAsset The reserve key of the debt asset.
     * @return weight The weight of the collateral asset in relation to the debt asset.
     */
    function getWeight(
        AccountId account,
        uint256 collateralTokenId,
        ReserveKey debtAsset
    )
        external
        view
        returns (uint64 weight);
}
