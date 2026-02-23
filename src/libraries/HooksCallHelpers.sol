// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IHooks} from "../interfaces/IHooks.sol";

// solhint-disable avoid-low-level-calls
/// @title HooksCallHelpers
/// @notice A library to dispatch calls to hook functions in the Hooks contract.
///         Inspired by Uniswap v4's hooks.
/// @author Chinmay <chinmay@dhedge.org>
library HooksCallHelpers {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////
    error HookCallHelpers__HookCallFailed(bytes4 selector, bytes errorData);

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @dev Calls a hook function on the provided hooks contract if the flag is set.
    /// @param hooks The hooks contract to call.
    /// @param hookSelector The selector of the hook function to call.
    /// @param flag The flag to check for permission.
    function callHook(IHooks hooks, bytes4 hookSelector, uint160 flag) internal {
        if (hasPermission(hooks, flag)) {
            (bool success, bytes memory result) = address(hooks).call(abi.encodePacked(hookSelector, msg.data[4:]));

            require(success, HookCallHelpers__HookCallFailed(hookSelector, result));
        }
    }

    /// @dev Checks if the hooks contract has permission to call a specific hook function based on the flag.
    /// @param hooks The hooks contract to check.
    /// @param flag The flag to check for permission.
    /// @return permitted True if the hooks contract has permission, false otherwise.
    function hasPermission(IHooks hooks, uint160 flag) internal pure returns (bool permitted) {
        return uint160(address(hooks)) & flag != 0;
    }
}
