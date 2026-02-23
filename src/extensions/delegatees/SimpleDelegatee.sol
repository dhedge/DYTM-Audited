// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IDelegatee} from "../../interfaces/IDelegatee.sol";

struct Call {
    address target;
    bytes callData;
}

/// @title SimpleDelegatee
/// @notice A simple delegatee contract that aggregates multiple calls to different targets.
/// @dev Adapted from the Multicall contract. SHOULD NOT hold any funds beyond the duration of a transaction.
/// @author Chinmay <chinmay@dhedge.org>
contract SimpleDelegatee is IDelegatee {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error SimpleDelegatee__CallFailed(Call call);

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    function onDelegationCallback(bytes calldata callbackData) external returns (bytes memory returnData) {
        Call[] memory calls = abi.decode(callbackData, (Call[]));

        return abi.encode(aggregate(calls));
    }

    /// @param calls An array of Call structs
    function aggregate(Call[] memory calls) public returns (bytes[] memory returnData) {
        uint256 length = calls.length;
        returnData = new bytes[](length);
        Call memory call;
        for (uint256 i = 0; i < length;) {
            call = calls[i];
            (bool success, bytes memory data) = call.target.call(call.callData);

            require(success, SimpleDelegatee__CallFailed(call));

            returnData[i] = data;

            unchecked {
                ++i;
            }
        }
    }
}
