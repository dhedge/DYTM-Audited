# ReserveKeyLibrary
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/types/ReserveKey.sol)

**Title:**
ReserveKeyLibrary

**Author:**
Chinmay <chinmay@dhedge.org>

Library for ReserveKey conversions related functions.


## Functions
### toReserveKey

Returns the ReserveKey for a particular principal asset in a market.


```solidity
function toReserveKey(MarketId marketId, IERC20 asset) internal pure returns (ReserveKey key);
```

### toEscrowId

Function to convert a ReserveKey to an escrow reserve id.


```solidity
function toEscrowId(ReserveKey key) internal pure returns (uint256 escrowReserveId);
```

### toLentId

Function to convert a ReserveKey to a share reserve id.


```solidity
function toLentId(ReserveKey key) internal pure returns (uint256 shareReserveId);
```

### toDebtId

Function to convert a ReserveKey to a debt reserve id.


```solidity
function toDebtId(ReserveKey key) internal pure returns (uint256 debtReserveId);
```

### getAsset

Function to get the ERC20 asset address from a ReserveKey.

Since the last 160 bits of the ReserveKey are reserved for the asset address,
we can cast the unwrapped key to a uint160.


```solidity
function getAsset(ReserveKey key) internal pure returns (IERC20 asset);
```

### getMarketId

Function to get the MarketId from a ReserveKey.

The MarketId is stored in the bits [247:160] of the ReserveKey.

We can extract it by right shifting the unwrapped key by 160 bits and casting it to a uint88.


```solidity
function getMarketId(ReserveKey key) internal pure returns (MarketId marketId);
```

### validateReserveKey

Function to validate a ReserveKey.

A valid ReserveKey must have a non-zero MarketId part.


```solidity
function validateReserveKey(ReserveKey key) internal pure;
```

## Errors
### ReserveKeyLibrary__ZeroMarketId

```solidity
error ReserveKeyLibrary__ZeroMarketId();
```

### ReserveKeyLibrary__InvalidReserveKey

```solidity
error ReserveKeyLibrary__InvalidReserveKey(ReserveKey key);
```

