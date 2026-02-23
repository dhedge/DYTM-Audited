// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.29;

import {TRANSIENT_QUEUE_STORAGE_BASE_SLOT, MAX_TRANSIENT_QUEUE_LENGTH} from "../../libraries/Constants.sol";

import {AccountId, MarketId} from "../../types/Types.sol";
import {MarketIdLibrary} from "../../types/MarketId.sol";
import {AccountIdLibrary} from "../../types/AccountId.sol";

/// @title TransientEnumerableHashTableStorage
/// @notice Abstract contract which stores the account Id and market Id of the account for which
///         health check is required, into a queue with duplication checks using a hash table approach.
/// @dev The hash table isn't cleared after use and we rely on the fact that the transient storage
///      is automatically cleared after the transaction ends.
/// @dev Only per-transaction delegation calls are guaranteed to work correctly.
///      This contract uses transient storage to track (account, market) pairs in a queue during a `delegationCall()` execution.
///      The `__length` counter and hashtable entries persist in transient storage until the end of the transaction.
///      When a transaction contains multiple `delegationCall()` invocations, the second call inherits stale (account, market) pairs
///      from the first call's queue. These leftover entries are then re-processed during health checks, even though they are
///      unrelated to the current operation. Since transient storage is only cleared at the end of a transaction (not between internal calls),
///      subsequent `delegationCall()` operations within the same transaction will iterate over an increasingly polluted queue.
///
/// @author Chinmay <chinmay@dhedge.org>
abstract contract TransientEnumerableHashTableStorage {
    using AccountIdLibrary for *;
    using MarketIdLibrary for uint88;

    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error TransientEnumerableHashTableStorage__QueueFull();
    error TransientEnumerableHashTableStorage__IndexOutOfBounds();

    /////////////////////////////////////////////
    //                 Storage                 //
    /////////////////////////////////////////////

    uint8 private transient __length;

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @dev Inserts the `account` and the `market` in the transient queue if there is space and not already inserted.
    ///      This function will revert if the queue is full.
    /// @param account The account ID to be stored.
    /// @param market The market ID to be stored.
    function _insert(AccountId account, MarketId market) internal {
        require(__length < MAX_TRANSIENT_QUEUE_LENGTH, TransientEnumerableHashTableStorage__QueueFull());

        uint256 encodedValue = __encodeAccountMarket(account, market);

        // Check if the combo already exists using our hash table.
        if (__isDuplicate(encodedValue)) {
            return; // Skip if already queued.
        }

        uint256 baseSlot = TRANSIENT_QUEUE_STORAGE_BASE_SLOT;
        uint8 queueIndex = __length;
        assembly ("memory-safe") {
            tstore(add(baseSlot, queueIndex), encodedValue)
        }

        __addToHashTable(encodedValue);

        ++__length;
    }

    /// @dev Gets the account Id and market Id at the `index` from the transient queue.
    /// @param index The index of the element to be retrieved.
    /// @return account The account Id at the given index.
    /// @return market The market Id at the given index.
    function _get(uint8 index) internal view returns (AccountId account, MarketId market) {
        require(index < __length, TransientEnumerableHashTableStorage__IndexOutOfBounds());

        uint256 baseSlot = TRANSIENT_QUEUE_STORAGE_BASE_SLOT;
        uint256 encodedValue;

        assembly ("memory-safe") {
            encodedValue := tload(add(baseSlot, index))
        }

        (account, market) = __decodeAccountMarket(encodedValue);
    }

    /// @dev Gets the current length of the transient queue.
    /// @return length The current length of the transient queue.
    function _getLength() internal view returns (uint8 length) {
        return __length;
    }

    /// @dev Marks the encoded value as inserted.
    /// @dev Given that `__encodeAccountMarket` is a bijective function and the least value of
    ///      this function is `2^168 + 2`, One could safely assume that there will never be collisions.
    /// @param encodedValue The pre-encoded account and market combination.
    function __addToHashTable(uint256 encodedValue) private {
        assembly ("memory-safe") {
            tstore(encodedValue, 1)
        }
    }

    /// @dev Checks if account and market combination is already in the queue using a hash table approach.
    ///      The check loads the value at the slot `encodedValue` and checks if it is 1 indicating duplication.
    /// @param encodedValue The account and market id combination encoded value.
    /// @return isDuplicate True if the combination is a duplicate.
    function __isDuplicate(uint256 encodedValue) private view returns (bool isDuplicate) {
        assembly ("memory-safe") {
            // If the slot contains 1, it is a duplicate. Otherwise, it will be 0 (default).
            isDuplicate := tload(encodedValue)
        }
    }

    /// @dev We encode the account Id, market Id and the account type into a single uint256 and store it in the table.
    ///      This is possible because the market Id is at most 88 bits and the account Id is at most 160 bits
    ///      even though the underlying account Id type is 256 bits, only the upper 96 bits are useful for isolated accounts
    ///      and only the lower 160 bits are useful for user accounts. The LSB is used to differentiate between
    ///      isolated and user accounts (0 for user accounts, 1 for isolated accounts). In short, this is a bijective function.
    /// @param account The account ID to encode.
    /// @param market The market ID to encode.
    /// @return encoded The encoded value containing both IDs.
    function __encodeAccountMarket(AccountId account, MarketId market) private pure returns (uint256 encoded) {
        uint256 rawAccount = AccountId.unwrap(account);
        uint88 rawMarket = MarketId.unwrap(market);

        bool isIsolatedAccount = account.isIsolatedAccount();

        if (isIsolatedAccount) {
            // Although the actual isolated account ID is in the upper 96 bits,
            // we only need to shift right by 159 as the LSB is always 0 for isolated accounts.
            // The lower 160 bits of an isolated account ID are always 0.
            uint256 rawIsolatedAccount = uint256(rawAccount >> 159);

            // Isolated account: upper 88 bits = market, 71 bits padding, next 96 bits = account, LSB = 1
            encoded = (uint256(rawMarket) << 168) | rawIsolatedAccount | 1;
        } else {
            // Although we could have casted the rawAccount to uint160 directly,
            // we do it this way to set the LSB to 0.
            uint256 rawUserAccount = rawAccount << 1;

            // User account: upper 88 bits = market, 7 bits padding, next 160 bits = account, LSB = 0
            encoded = (uint256(rawMarket) << 168) | rawUserAccount;
        }
    }

    /// @dev Decodes the encoded value back to account and market IDs.
    /// @param encoded The encoded value to decode.
    /// @return account The decoded account ID.
    /// @return market The decoded market ID.
    function __decodeAccountMarket(uint256 encoded) private pure returns (AccountId account, MarketId market) {
        // Extract market ID from upper 88 bits
        uint88 rawMarket = uint88(encoded >> 168);
        market = rawMarket.toMarketId();

        // Check the LSB to determine account type
        bool isIsolatedAccount = (encoded & 1) == 1;

        if (isIsolatedAccount) {
            // Extract lower 96 bits (after right-shifting 1 bit) for isolated account (bits 1-96).
            uint96 rawIsolatedAccount = uint96(encoded >> 1);

            account = rawIsolatedAccount.toIsolatedAccount();
        } else {
            // Extract lower 160 bits (after right-shifting 1 bit) for user account (bits 1-160).
            address rawUserAccount = address(uint160(encoded >> 1));

            account = rawUserAccount.toUserAccount();
        }
    }
}
