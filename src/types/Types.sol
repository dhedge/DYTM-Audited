// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "./MarketId.sol" as MarketIdOps;
import "./ReserveKey.sol" as ReserveKeyOps;
import "./AccountId.sol" as AccountIdOps;

// A market id can be any natural number.
type MarketId is uint88;

// An account id is a unique identifier for an account NFT.
// AccountId bit layout:
//      +-------------------------------+--------------------------------------+
//      |         96 bits               |             160 bits                 |
//      |       account count           |           address field              |
//      +-------------------------------+--------------------------------------+
// - Every Ethereum public key has an account represented by its address.
//   This is called the "user account".
// - If the least significant 160 bits are zero and the most significant 96 bits are non-zero,
//   it is an "isolated account".
type AccountId is uint256;

// Comprises of the market id and the asset address.
// ReserveKey bit layout:
//      +------------------------+--------------------------------------+
//      |      88 bits           |            160 bits                  |
//      |     market id          |         asset address                |
//      +------------------------+--------------------------------------+
type ReserveKey is uint248;

using {MarketIdOps.eq as ==, MarketIdOps.notEq as !=} for MarketId global;
using {AccountIdOps.eq as ==, AccountIdOps.notEq as !=} for AccountId global;
using {ReserveKeyOps.eq as ==, ReserveKeyOps.notEq as !=} for ReserveKey global;
