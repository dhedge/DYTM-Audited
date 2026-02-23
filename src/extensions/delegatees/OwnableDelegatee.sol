// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IDelegatee} from "../../interfaces/IDelegatee.sol";

struct Call {
    address target;
    bytes callData;
}

/// @title OwnableDelegatee
/// @notice An ownable delegatee contract that aggregates multiple calls to different targets.
///         - The aggregate function can only be called by the owner of the contract (checked via tx.origin).
///         - The owner MUST be an EOA address (isn't checked in the contract though).
///         - The delegation call initiator MUST be the owner of this contract.
/// @dev Adapted from the Multicall contract and SimpleDelegatee.
/// @author Chinmay <chinmay@dhedge.org>
contract OwnableDelegatee is IDelegatee, Ownable {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error OwnableDelegatee__NotOwner();
    error OwnableDelegatee__CallFailed(Call call);

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice DYTM Office callback function to handle delegation calls.
    ///         The delegation call initiator MUST be the owner of this contract.
    /// @param callbackData Encoded array of `Call` structs.
    /// @return returnData Encoded array of return data from each call.
    function onDelegationCallback(bytes calldata callbackData) external returns (bytes memory returnData) {
        Call[] memory calls = abi.decode(callbackData, (Call[]));

        return abi.encode(aggregate(calls));
    }

    /// @notice Executes multiple calls if the transaction origin is the owner.
    /// @dev Make sure you are using an EOA which is the owner of this contract to perform delegation calls.
    /// @param calls An array of `Call` structs.
    /// @return returnData An array of return data from each call.
    function aggregate(Call[] memory calls) public returns (bytes[] memory returnData) {
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == owner(), OwnableDelegatee__NotOwner());

        uint256 length = calls.length;
        returnData = new bytes[](length);
        Call memory call;
        for (uint256 i = 0; i < length;) {
            call = calls[i];
            (bool success, bytes memory data) = call.target.call(call.callData);

            require(success, OwnableDelegatee__CallFailed(call));

            returnData[i] = data;

            unchecked {
                ++i;
            }
        }
    }
}
