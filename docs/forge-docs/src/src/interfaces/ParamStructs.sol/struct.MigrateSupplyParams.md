# MigrateSupplyParams
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/ParamStructs.sol)

Parameters for supply migration operations between markets.

Exactly one of `assets` or `shares` must be zero.


```solidity
struct MigrateSupplyParams {
AccountId account;
uint256 fromTokenId;
uint256 toTokenId;
uint256 assets;
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
|`assets`|`uint256`|The amount of the asset (as encoded in the `fromTokenId`) to redeem and migrate.|
|`shares`|`uint256`|The amount of shares to redeem and migrate. Use `type(uint256).max` to redeem and migrate all the shares.|
|`fromExtraData`|`bytes`|Extra data that can be used by the hooks of the market of the `fromTokenId`.|
|`toExtraData`|`bytes`|Extra data that can be used by the hooks of the market of the `toTokenId`.|

