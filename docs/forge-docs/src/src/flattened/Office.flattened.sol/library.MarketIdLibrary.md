# MarketIdLibrary
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

**Author:**
Chinmay <chinmay@dhedge.org>

*Library for MarketId conversions related functions.*


## Functions
### toMarketId

*MarketId is a simple wrapper around uint256.*

*A market can't be created with `count` = 0.*


```solidity
function toMarketId(uint88 count) internal pure returns (MarketId market);
```

## Errors
### MarketIdLibrary__ZeroMarketId

```solidity
error MarketIdLibrary__ZeroMarketId();
```

