# RepayParams
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


```solidity
struct RepayParams {
    AccountId account;
    ReserveKey key;
    uint256 shares;
    bytes extraData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account whose debt will be repaid.|
|`key`|`ReserveKey`|The reserve key for the asset.|
|`shares`|`uint256`|The amount of debt shares to repay.|
|`extraData`|`bytes`|Extra data that can be used by the hooks.|

