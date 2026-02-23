# DelegationCallParams
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/ParamStructs.sol)

**Title:**
ParamStructs

**Author:**
Chinmay <chinmay@dhedge.org>

Parameter structures used across the DYTM protocol interfaces.

Parameters for delegation calls.

These structs define the parameters for various market operations including
supply, borrow, repay, liquidation, and other core functionality.


```solidity
struct DelegationCallParams {
IDelegatee delegatee;
bytes callbackData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`delegatee`|`IDelegatee`|The delegatee that will be called to perform batch operations.|
|`callbackData`|`bytes`|Additional data that can be used by the delegatee to perform the operations.|

