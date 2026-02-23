# MigrateSupplyParams
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


```solidity
struct MigrateSupplyParams {
    AccountId account;
    uint256 fromTokenId;
    uint256 toTokenId;
    uint256 shares;
    bytes fromExtraData;
    bytes toExtraData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account whose assets will be migrated.|
|`fromTokenId`|`uint256`|The tokenId that one wants to redeem/withdraw.|
|`toTokenId`|`uint256`|The tokenId that one wants to get in exchange for the `fromTokenId`.|
|`shares`|`uint256`|The amount of shares to redeem and migrate.|
|`fromExtraData`|`bytes`|Extra data that can be used by the hooks of the market of the `fromTokenId`.|
|`toExtraData`|`bytes`|Extra data that can be used by the hooks of the market of the `toTokenId`.|

