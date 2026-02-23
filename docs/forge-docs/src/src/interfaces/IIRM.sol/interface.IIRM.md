# IIRM
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/IIRM.sol)

**Title:**
IIRM

**Author:**
Chinmay <chinmay@dhedge.org>

Interest Rate Model interface for a market in the DYTM protocol.

Follows similar interface as a Morpho market's IRM.


## Functions
### borrowRate

Returns the updated borrow rate for a given reserve key.

Assumes that the implementation is non-view to allow for any state changes in the implementation.


```solidity
function borrowRate(ReserveKey key) external returns (uint256 ratePerSecond);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key for which the borrow rate is requested.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`ratePerSecond`|`uint256`|The borrow rate per second for the given reserve key.|


### borrowRateView

Returns the borrow rate for a given reserve key.


```solidity
function borrowRateView(ReserveKey key) external view returns (uint256 ratePerSecond);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key for which the borrow rate is requested.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`ratePerSecond`|`uint256`|The borrow rate per second for the given reserve key.|


