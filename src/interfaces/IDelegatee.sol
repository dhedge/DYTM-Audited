// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * @title IDelegatee
 * @author Chinmay <chinmay@dhedge.org>
 * @notice Interface for the delegatee contract to handle delegation calls.
 * @dev Be extremely cautious when creating a delegatee contract regarding security implications
 *      in case a delegatee is ever authorized as an operator. It's best to check for access control
 *      within the delegatee contract itself in case operating on an account. There can be cases where
 *      someone can invoke an action on behalf of an account via a delegatee contract which is set as an
 *      operator for that account.
 */
interface IDelegatee {
    /**
     * @notice Callback function to be called by the Office contract for a delegation call.
     * @param callbackData The data to be passed to the callback function of the delegatee.
     * @return returnData An array of return data from the delegatee's calls.
     */
    function onDelegationCallback(bytes calldata callbackData) external returns (bytes memory returnData);
}
