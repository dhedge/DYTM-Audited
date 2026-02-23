# MarketIdLibrary
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/types/MarketId.sol)

**Title:**
MarketIdLibrary

**Author:**
Chinmay <chinmay@dhedge.org>

Library for MarketId conversions related functions.


## Functions
### toMarketId

MarketId is a simple wrapper around uint256.

A market can't be created with `count` = 0.


```solidity
function toMarketId(uint88 count) internal pure returns (MarketId market);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`count`|`uint88`|The market count to be converted.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`market`|`MarketId`|The MarketId corresponding to the given count.|


## Errors
### MarketIdLibrary__ZeroMarketId

```solidity
error MarketIdLibrary__ZeroMarketId();
```

