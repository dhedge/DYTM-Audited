# LinearKinkIRM
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/IRM/LinearKinkIRM.sol)

**Inherits:**
[IIRM](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IIRM.sol/interface.IIRM.md)

**Title:**
LinearKinkIRM

**Author:**
Chinmay <chinmay@dhedge.org>

A simple kink based linear Interest Rate Model (IRM).

Can be used for any number of markets as long as the officer address is non-zero.

Based on the RareSkills article <https://www.rareskills.io/post/aave-interest-rate-model>.


## State Variables
### OFFICE
The Office contract which will consume the data from this IRM.


```solidity
Office public immutable OFFICE
```


### irmParams
Mapping from reserve key to IRM parameters


```solidity
mapping(ReserveKey key => IRMParams params) public irmParams
```


## Functions
### constructor


```solidity
constructor(Office office_) ;
```

### borrowRate

Returns the updated borrow rate for a given reserve key.

Assumes that the implementation is non-view to allow for any state changes in the implementation.


```solidity
function borrowRate(ReserveKey key) external view returns (uint256 ratePerSecond);
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


### setParams

Set the interest rate parameters for a specific reserve.


```solidity
function setParams(ReserveKey key, IRMParams calldata newParams) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key for which the parameters are being set.|
|`newParams`|`IRMParams`|The new IRM parameters to be set.|


### getUtilization

Calculate the current utilization rate for a reserve.


```solidity
function getUtilization(ReserveKey key) public view returns (uint256 utilization);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`utilization`|`uint256`|The utilization rate in WAD format.|


### _calculateBorrowRate

Calculate the borrow rate based on utilization and IRM parameters.

[!WARNING]: This function doesn't revert if IRM parameters are not set.
It will just return 0 instead.


```solidity
function _calculateBorrowRate(ReserveKey key) internal view returns (uint256 ratePerSecond);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`ratePerSecond`|`uint256`|The borrow rate per second.|


## Events
### LinearKinkIRM__ParametersModified

```solidity
event LinearKinkIRM__ParametersModified(ReserveKey indexed key, IRMParams oldParams, IRMParams newParams);
```

## Errors
### LinearKinkIRM__NotOfficer

```solidity
error LinearKinkIRM__NotOfficer(address officer);
```

### LinearKinkIRM__InvalidOptimalUtilization

```solidity
error LinearKinkIRM__InvalidOptimalUtilization(uint256 optimalUtilization);
```

## Structs
### IRMParams
Interest rate parameters for each reserve.


```solidity
struct IRMParams {
    uint256 baseRatePerSecond;
    uint256 slope1PerSecond;
    uint256 slope2PerSecond;
    uint256 optimalUtilization;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`baseRatePerSecond`|`uint256`|Min rate when utilization > 0 (in per second format).|
|`slope1PerSecond`|`uint256`|Rate of increase below optimal utilization (in per second format).|
|`slope2PerSecond`|`uint256`|Rate of increase above optimal utilization (in per second format).|
|`optimalUtilization`|`uint256`|The optimal utilization rate (in WAD format, e.g., 0.8e18 = 80%).|

