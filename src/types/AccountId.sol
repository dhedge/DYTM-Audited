// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "../libraries/Constants.sol" as Constants;
import {AccountId} from "../types/Types.sol";

/* solhint-disable private-vars-leading-underscore */
function eq(AccountId a, AccountId b) pure returns (bool isEqual) {
    return AccountId.unwrap(a) == AccountId.unwrap(b);
}

function notEq(AccountId a, AccountId b) pure returns (bool isNotEqual) {
    return AccountId.unwrap(a) != AccountId.unwrap(b);
}

/* solhint-enable private-vars-leading-underscore */

/// @title AccountIdLibrary
/// @notice Library for AccountId conversions related functions.
/// @author Chinmay <chinmay@dhedge.org>
library AccountIdLibrary {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error AccountIdLibrary__ZeroAddress();
    error AccountIdLibrary__ZeroAccountNumber();
    error AccountIdLibrary__InvalidRawAccountId(uint256 rawAccount);
    error AccountIdLibrary__InvalidUserAccountId(AccountId account);
    error AccountIdLibrary__InvalidIsolatedAccountId(AccountId account);

    /////////////////////////////////////////////
    //                 Enums                   //
    /////////////////////////////////////////////

    enum AccountType {
        INVALID_ACCOUNT, // 0
        USER_ACCOUNT, // 1
        ISOLATED_ACCOUNT // 2
    }

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @notice Converts a user address to an account ID.
    /// @param user The user address to be converted.
    /// @return account The account ID corresponding to the user address.
    function toUserAccount(address user) internal pure returns (AccountId account) {
        require(user != address(0), AccountIdLibrary__ZeroAddress());

        uint256 userNumber = uint256(uint160(user));
        return AccountId.wrap(userNumber);
    }

    /// @notice Converts an account ID to a token ID.
    /// @dev The token ID is the same as the account ID.
    ///      Note: A user account can't be tokenized, so this function is only valid for isolated accounts.
    /// @param account The account ID to be converted.
    /// @return tokenId The token ID corresponding to the account ID.
    function toTokenId(AccountId account) internal pure returns (uint256 tokenId) {
        require(
            account != Constants.ACCOUNT_ID_ZERO && !isUserAccount(account),
            AccountIdLibrary__InvalidIsolatedAccountId(account)
        );

        // The token ID is the same as the account ID.
        return AccountId.unwrap(account);
    }

    /// @notice Converts an account count to an isolated account ID.
    /// @dev An isolated account is one where the least significant 160 bits are zero
    ///      and the top 96 bits are set to the count.
    ///      - Reverts if the count is zero.
    /// @param count The account count to be converted.
    /// @return account The isolated account ID corresponding to the count.
    function toIsolatedAccount(uint96 count) internal pure returns (AccountId account) {
        if (count == 0) {
            revert AccountIdLibrary__ZeroAccountNumber();
        }

        // Set the most significant 96 bits to the count and the least significant 160 bits to zero.
        uint256 accountNumber = (uint256(count) << 160);
        return AccountId.wrap(accountNumber);
    }

    /// @notice Validates and converts an account ID to a user address.
    /// @dev - Reverts if the account ID is not a user account.
    ///      - Revert if the account ID is a null account (i.e., zero address).
    /// @param account The account ID to be converted.
    /// @return user The user address corresponding to the user account ID.
    function toUserAddress(AccountId account) internal pure returns (address user) {
        // Validate that the account is a user account.
        require(isUserAccount(account), AccountIdLibrary__InvalidUserAccountId(account));

        return address(uint160(AccountId.unwrap(account)));
    }

    /// @notice Function to check if an account is a user account.
    ///         Will revert if the `account` is not a valid account type.
    /// @dev A user account is one where the least significant 160 bits are non-zero and
    ///      the top 96 bits are zero.
    /// @param account The account ID to be checked.
    /// @return isUser True if the account is a user account, false otherwise.
    function isUserAccount(AccountId account) internal pure returns (bool isUser) {
        return getAccountType(AccountId.unwrap(account)) == AccountType.USER_ACCOUNT;
    }

    /// @notice Function to check if an account is an isolated account.
    ///         Will revert if the `account` is not a valid account type.
    /// @dev An isolated account is one where the least significant 160 bits are zero
    ///      and the top 96 bits are non-zero.
    /// @param account The account ID to be checked.
    /// @return isIsolated True if the account is an isolated account, false otherwise.
    function isIsolatedAccount(AccountId account) internal pure returns (bool isIsolated) {
        return getAccountType(AccountId.unwrap(account)) == AccountType.ISOLATED_ACCOUNT;
    }

    /// @notice Determines the type of account based on its raw uint256 representation.
    /// @dev Reverts if the raw account ID does not conform to either type.
    /// @param rawAccount The raw uint256 representation of the account ID.
    /// @return accountType The type of the account (USER_ACCOUNT or ISOLATED_ACCOUNT).
    function getAccountType(uint256 rawAccount) internal pure returns (AccountType accountType) {
        uint160 addressField = uint160(rawAccount);
        uint96 accountCount = uint96(rawAccount >> 160);

        if (addressField == 0 && accountCount != 0) {
            return AccountType.ISOLATED_ACCOUNT; // Isolated account
        } else if (addressField != 0 && accountCount == 0) {
            return AccountType.USER_ACCOUNT; // User account
        } else {
            revert AccountIdLibrary__InvalidRawAccountId(rawAccount);
        }
    }
}
