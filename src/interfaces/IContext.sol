// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IDelegatee} from "./IDelegatee.sol";

/**
 * @title IContext
 * @author Chinmay <chinmay@dhedge.org>
 * @notice Interface for managing delegation call context in the DYTM protocol.
 * @dev This interface tracks the state during delegation calls, including the caller,
 *      delegatee, and health check requirements.
 */
interface IContext {
    /////////////////////////////////////////////
    //                 Events                  //
    /////////////////////////////////////////////

    event Context__DelegationCallCompleted(address indexed caller, IDelegatee indexed delegatee);

    /////////////////////////////////////////////
    //                  Errors                 //
    /////////////////////////////////////////////

    error Context__ContextAlreadySet();

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /**
     * @notice The original caller of the delegation call (if ongoing).
     * @return caller The address of the original caller, or address(0) if no delegation call is ongoing.
     */
    function callerContext() external view returns (address caller);

    /**
     * @notice The delegatee address for the delegation call (if ongoing).
     * @dev This is not to be confused with the `msg.sender` of the delegation call
     *      which is the `callerContext`.
     * @return delegatee The delegatee contract, or IDelegatee(address(0)) if no delegation call is ongoing.
     */
    function delegateeContext() external view returns (IDelegatee delegatee);

    /**
     * @notice Indicates if an account health check is required after the delegation call.
     * @return healthCheck True if a health check should be performed after the delegation call.
     */
    function requiresHealthCheck() external view returns (bool healthCheck);

    /**
     * @notice Checks if the ongoing call is a delegation call.
     * @dev Only checks if the delegatee context is set (not address(0)).
     * @return callStatus True if a delegation call is currently in progress.
     */
    function isOngoingDelegationCall() external view returns (bool callStatus);
}
