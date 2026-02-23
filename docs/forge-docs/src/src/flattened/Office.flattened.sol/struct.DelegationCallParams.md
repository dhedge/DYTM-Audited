# DelegationCallParams
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


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

