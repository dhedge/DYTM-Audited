// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.29;

import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import "../../libraries/Constants.sol" as Constants;
import {AccountIdLibrary} from "../../types/AccountId.sol";
import {MarketId, AccountId} from "../../types/Types.sol";

import {IContext} from "../../interfaces/IContext.sol";
import {IRegistry} from "../../interfaces/IRegistry.sol";
import {IDelegatee} from "../../interfaces/IDelegatee.sol";

/// @title AccountSplitterAndMerger
/// @notice This contract provides functionality to split and merge accounts within DYTM.
///         > [!WARNING]
///           DO NOT SET THIS CONTRACT AS AN OPERATOR FOR ANY ACCOUNT.
///           THE EFFECTS ARE UNKNOWN AND COULD LEAD TO LOSS OF FUNDS.
///
/// - The split account functionality allows a user to create a new isolated account by splitting a fraction of an existing account's
///   assets and debt into the new account. The caller MUST own the source account. The caller will own the newly created account.
/// - The merge accounts functionality allows a user to merge a fraction of assets and debt from a source account into a recipient account.
///   The caller MUST own both the accounts.
///
/// @dev This contract can only be used via delegation calls from the Office contract.
/// @author Chinmay <chinmay@dhedge.org>
contract AccountSplitterAndMerger is IDelegatee {
    using FixedPointMathLib for uint256;
    using AccountIdLibrary for AccountId;

    /////////////////////////////////////////////
    //                 Events                  //
    /////////////////////////////////////////////

    event AccountSplitterAndMerger_AccountSplit(
        AccountId indexed originalAccount,
        AccountId newAccount,
        MarketId indexed market,
        address indexed caller,
        uint256 fraction
    );

    event AccountSplitterAndMerger_AccountsMerged(
        AccountId indexed recipientAccount,
        AccountId indexed sourceAccount,
        MarketId indexed market,
        address caller,
        uint256 fraction
    );

    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error AccountSplitterAndMerger_ZeroAddress();
    error AccountSplitterAndMerger_OnlyOffice(address caller);
    error AccountSplitterAndMerger_InvalidFraction(uint256 fraction);
    error AccountSplitterAndMerger_InvalidOperation(Operation operation);

    /////////////////////////////////////////////
    //              Enums & Structs            //
    /////////////////////////////////////////////

    enum Operation {
        INVALID, // 0
        SPLIT_ACCOUNT, // 1
        MERGE_ACCOUNTS // 2
    }

    /// @param operation The type of operation to be performed (split or merge).
    /// @param data The encoded parameters for the operation (SplitAccountParams or MergeAccountsParams).
    struct CallbackData {
        Operation operation;
        bytes data;
    }

    /// @param sourceAccount The account to be split.
    /// @param market The market in which the account's assets and debt exist.
    /// @param fraction The fraction of the account's assets to split. Must be a value between 0 and 1e18.
    struct SplitAccountParams {
        AccountId sourceAccount;
        MarketId market;
        uint64 fraction;
    }

    /// @param sourceAccount The account from which assets will be merged into the recipient account.
    /// @param recipientAccount The account that will receive the merged assets and debt.
    /// @param market The market in which the accounts' position exists.
    /// @param fraction The fraction of the source account's assets to merge. Must be a value between 0 and 1e18.
    struct MergeAccountsParams {
        AccountId sourceAccount;
        AccountId recipientAccount;
        MarketId market;
        uint64 fraction;
    }

    /////////////////////////////////////////////
    //             State Variables             //
    /////////////////////////////////////////////

    address public immutable OFFICE;

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    constructor(address _office) {
        require(_office != address(0), AccountSplitterAndMerger_ZeroAddress());

        OFFICE = _office;
    }

    /// @notice Callback function for handling delegation calls for split and merge account operations.
    ///
    /// - The `data` parameter is expected to be an encoded `CallbackData` struct.
    ///   - The `data` field of the `CallbackData` struct is further decoded (either into `SplitAccountParams` or `MergeAccountsParams`)
    ///     based on the `operation` type.
    /// - The `returnData` for the `SPLIT_ACCOUNT` operation is the `AccountId` of the newly created account.
    /// - The `returnData` for the `MERGE_ACCOUNTS` operation is empty.
    ///
    /// @param data Encoded data containing the operation type and parameters.
    /// @return returnData Encoded return data from the operation.
    function onDelegationCallback(bytes calldata data) external returns (bytes memory returnData) {
        require(msg.sender == OFFICE, AccountSplitterAndMerger_OnlyOffice(msg.sender));

        // Decode the `data` into the `CallbackData` struct.
        CallbackData memory callbackData = abi.decode(data, (CallbackData));

        if (callbackData.operation == Operation.SPLIT_ACCOUNT) {
            SplitAccountParams memory params = abi.decode(callbackData.data, (SplitAccountParams));

            AccountId newAccount = _splitAccount(params);

            return abi.encode(newAccount);
        } else if (callbackData.operation == Operation.MERGE_ACCOUNTS) {
            MergeAccountsParams memory params = abi.decode(callbackData.data, (MergeAccountsParams));

            _mergeAccounts(params);
        } else {
            revert AccountSplitterAndMerger_InvalidOperation(callbackData.operation);
        }
    }

    function _splitAccount(SplitAccountParams memory params) internal returns (AccountId newAccount) {
        // Not allowing fraction to be 1e18 (100%) because that would be the same as transferring the entire account.
        require(
            params.fraction > 0 && params.fraction < Constants.WAD,
            AccountSplitterAndMerger_InvalidFraction(params.fraction)
        );

        address msgSender = _msgSender();
        IRegistry registry = IRegistry(OFFICE);

        // Create a new isolated account for the caller.
        // This is necessary so that this contract can transfer the debt and assets to the new account.
        // This works as long as the caller in context owns the source account.
        newAccount = registry.createIsolatedAccount(msgSender);

        __transferAssetsAndDebt({
            sourceAccount: params.sourceAccount,
            recipientAccount: newAccount,
            market: params.market,
            fraction: params.fraction
        });

        emit AccountSplitterAndMerger_AccountSplit({
            originalAccount: params.sourceAccount,
            newAccount: newAccount,
            market: params.market,
            caller: msgSender,
            fraction: params.fraction
        });
    }

    function _mergeAccounts(MergeAccountsParams memory params) internal {
        // Allowing fraction to be 1e18 (100%) because that would mean merging the entire account.
        require(
            params.fraction > 0 && params.fraction <= Constants.WAD,
            AccountSplitterAndMerger_InvalidFraction(params.fraction)
        );

        __transferAssetsAndDebt({
            sourceAccount: params.sourceAccount,
            recipientAccount: params.recipientAccount,
            market: params.market,
            fraction: params.fraction
        });

        emit AccountSplitterAndMerger_AccountsMerged({
            recipientAccount: params.recipientAccount,
            sourceAccount: params.sourceAccount,
            market: params.market,
            caller: _msgSender(),
            fraction: params.fraction
        });
    }

    function __transferAssetsAndDebt(
        AccountId sourceAccount,
        AccountId recipientAccount,
        MarketId market,
        uint64 fraction
    )
        private
    {
        IRegistry registry = IRegistry(OFFICE);

        // Fetch all the collateral assets and transfer `fraction` of each to the `recipientAccount`.
        {
            uint256[] memory collateralIds = registry.getAllCollateralIds(sourceAccount, market);
            for (uint256 i; i < collateralIds.length; ++i) {
                uint256 collateralId = collateralIds[i];
                uint256 collateralSharesAmount = registry.balanceOf(sourceAccount, collateralId);
                uint256 fractionAmount = collateralSharesAmount.mulWadDown(fraction);

                registry.transferFrom({
                    sender: sourceAccount, receiver: recipientAccount, tokenId: collateralId, amount: fractionAmount
                });
            }
        }

        // Fetch the debt asset and transfer `fraction` of it to the `recipientAccount`.
        {
            uint256 debtId = registry.getDebtId(sourceAccount, market);
            uint256 debtSharesAmount = registry.balanceOf(sourceAccount, debtId);
            uint256 fractionAmount = debtSharesAmount.mulWadDown(fraction);

            registry.transferFrom({
                sender: sourceAccount, receiver: recipientAccount, tokenId: debtId, amount: fractionAmount
            });
        }
    }

    /// @dev Returns the caller in the context of the delegation call.
    function _msgSender() internal view returns (address) {
        return IContext(OFFICE).callerContext();
    }
}
