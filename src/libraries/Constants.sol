// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {MarketId, ReserveKey, AccountId} from "../types/Types.sol";

/* Hook permissions flags. */
uint160 constant BEFORE_SUPPLY_FLAG = 1 << 0;
uint160 constant AFTER_SUPPLY_FLAG = 1 << 1;
uint160 constant BEFORE_SWITCH_COLLATERAL_FLAG = 1 << 2;
uint160 constant AFTER_SWITCH_COLLATERAL_FLAG = 1 << 3;
uint160 constant BEFORE_BORROW_FLAG = 1 << 4;
uint160 constant AFTER_BORROW_FLAG = 1 << 5;
uint160 constant BEFORE_WITHDRAW_FLAG = 1 << 6;
uint160 constant AFTER_WITHDRAW_FLAG = 1 << 7;
uint160 constant BEFORE_REPAY_FLAG = 1 << 8;
uint160 constant AFTER_REPAY_FLAG = 1 << 9;
uint160 constant BEFORE_LIQUIDATE_FLAG = 1 << 10;
uint160 constant AFTER_LIQUIDATE_FLAG = 1 << 11;
uint160 constant BEFORE_MIGRATE_SUPPLY_FLAG = 1 << 12;
uint160 constant AFTER_MIGRATE_SUPPLY_FLAG = 1 << 13;
uint160 constant ALL_HOOK_MASK = uint160((1 << 14) - 1);

/* ERC7201 storage namespaces. */

// keccak256(abi.encode(uint256(keccak256("DYTM.storage.Office")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant OFFICE_STORAGE_LOCATION = 0x71d51ffbf9e21449409619cca98ecabe4a4a4497c444c0c069176d2b254ae700;

// keccak256(abi.encode(uint256(keccak256("DYTM.storage.Accounts")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ACCOUNTS_STORAGE_LOCATION = 0x5e1358d18e2f22d9f7b5b2ce571845b90812696899eaa9f0525b422dc97c1400;

/* Transient Hash Table Storage Constants */
uint8 constant MAX_TRANSIENT_QUEUE_LENGTH = 10; // Max length of the transient array storage.
uint256 constant TRANSIENT_QUEUE_STORAGE_BASE_SLOT = 100;

/* Miscellaneous constants. */
ReserveKey constant RESERVE_KEY_ZERO = ReserveKey.wrap(0);
AccountId constant ACCOUNT_ID_ZERO = AccountId.wrap(0);
MarketId constant MARKET_ID_ZERO = MarketId.wrap(0);
address constant USD_ISO_ADDRESS = address(840); // As required by IOracleModule interface.
uint256 constant WAD = 1e18; // Fixed-point representation with 18 decimals.
