// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.29;

import {IContext} from "../../interfaces/IContext.sol";
import {IDelegatee} from "../../interfaces/IDelegatee.sol";

/// @title Context
/// @notice Abstract contract to manage transient state context for delegation calls.
/// @dev Transient storage variables have completely independent address space from storage,
///      which means the order of the transient state variables does not affect the layout of the
///      storage state variables and vice-versa.
/// @author Chinmay <chinmay@dhedge.org>
abstract contract Context is IContext {
    /////////////////////////////////////////////
    //                 Storage                 //
    /////////////////////////////////////////////

    /// @inheritdoc IContext
    address public transient callerContext;

    /// @inheritdoc IContext
    IDelegatee public transient delegateeContext;

    /// @inheritdoc IContext
    bool public transient requiresHealthCheck;

    /////////////////////////////////////////////
    //                Modifiers                //
    /////////////////////////////////////////////

    /// @dev Can be used to enable delegation calls.
    modifier useContext(IDelegatee delegatee) {
        _setContext(delegatee);
        _;
        _deleteContext();

        emit Context__DelegationCallCompleted(msg.sender, delegatee);
    }

    ///////////////////////////////////////////////
    //                 Functions                 //
    ///////////////////////////////////////////////

    /// @inheritdoc IContext
    function isOngoingDelegationCall() public view returns (bool callStatus) {
        return address(delegateeContext) != address(0);
    }

    /// @dev Sets the context of the delegation call.
    ///      - Sets the caller, delegatee, account, and market context for the delegation call.
    ///      - Should be called at the beginning of a delegation call.
    ///      - Once set, the context cannot be changed until deleted so the function utilising `useContext` modifier
    ///        is effectively non-reentrant.
    function _setContext(IDelegatee delegatee) private {
        if (isOngoingDelegationCall()) {
            revert Context__ContextAlreadySet();
        }

        callerContext = msg.sender;
        delegateeContext = delegatee;
    }

    /// @dev Deletes the context of the delegation call.
    ///      Should be called at the end of a delegation call.
    function _deleteContext() private {
        delete callerContext;
        delete delegateeContext;
        delete requiresHealthCheck;
    }
}
