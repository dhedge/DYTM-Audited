// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * @title ILiquidator
 * @notice Interface for liquidator contracts.
 * @author Chinmay <chinmay@dhedge.org>
 */
interface ILiquidator {
    /**
     * @notice Function which is called during liquidation of an account for repayment.
     * @param debtAssetAmount The amount of the debt asset that needs to be approved to the Office contract.
     * @param callbackData Additional data that can be used by the liquidator to perform the liquidation.
     */
    function onLiquidationCallback(uint256 debtAssetAmount, bytes calldata callbackData) external;
}
