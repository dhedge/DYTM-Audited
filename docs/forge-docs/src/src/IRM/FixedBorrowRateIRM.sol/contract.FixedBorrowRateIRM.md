# FixedBorrowRateIRM
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/IRM/FixedBorrowRateIRM.sol)

**Inherits:**
[IIRM](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IIRM.sol/interface.IIRM.md)

**Title:**
FixedBorrowRateIRM

**Author:**
Chinmay <chinmay@dhedge.org>

A simple fixed borrow rate Interest Rate Model (IRM).

Can be used for any number of markets as long as the officer address is non-zero.


## State Variables
### OFFICE
The Office contract which will consume the data from this IRM.


```solidity
Office public immutable OFFICE
```


### borrowRateView

```solidity
mapping(ReserveKey key => uint256 ratePerSecond) public borrowRateView
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


### setRate

Set a new interest rate for a specific reserve.


```solidity
function setRate(ReserveKey key, uint256 newRatePerSecond) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key for which the interest rate is being set.|
|`newRatePerSecond`|`uint256`|The new interest rate per second to be set.|


## Events
### FixedBorrowRateIRM__RateModified

```solidity
event FixedBorrowRateIRM__RateModified(ReserveKey indexed key, uint256 newRate, uint256 oldRate);
```

## Errors
### FixedBorrowRateIRM__NotOfficer

```solidity
error FixedBorrowRateIRM__NotOfficer(address officer);
```

