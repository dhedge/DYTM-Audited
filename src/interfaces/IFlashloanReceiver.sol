// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * @title IFlashloanReceiver
 * @author Chinmay <chinmay@dhedge.org>
 * @notice Interface for the flashloan receiver contract to handle flashloan callbacks.
 */
interface IFlashloanReceiver {
    /**
     * @notice Callback function to be implemented by the flashloan receiver contract.
     * @param assets The amount of assets to be returned to clear the flashloan debt.
     *               Not to be confused with the amount borrowed or transferred to the receiver.
     * @param callbackData Additional data that can be used by the receiver to perform operations.
     */
    function onFlashloanCallback(uint256 assets, bytes calldata callbackData) external;
}
