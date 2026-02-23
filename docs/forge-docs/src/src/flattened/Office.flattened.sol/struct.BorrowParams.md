# BorrowParams
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


```solidity
struct BorrowParams {
    AccountId account;
    ReserveKey key;
    address receiver;
    uint256 assets;
    bytes extraData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account whose debt will be increased.|
|`key`|`ReserveKey`|The reserve key for the asset.|
|`receiver`|`address`|The address that will be given the borrowed asset.|
|`assets`|`uint256`|The amount to be borrowed.|
|`extraData`|`bytes`|Extra data that can be used by the hooks.|

