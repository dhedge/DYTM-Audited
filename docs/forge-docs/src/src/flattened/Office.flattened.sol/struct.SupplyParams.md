# SupplyParams
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


```solidity
struct SupplyParams {
    AccountId account;
    uint256 tokenId;
    uint256 assets;
    bytes extraData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account which should receive the lending/escrow receipt tokens.|
|`tokenId`|`uint256`|The tokenId of the receipt token token shares to mint. A user has a choice to supply the assets to either the lending market or to escrow.|
|`assets`|`uint256`|The amount of the asset as encoded in the tokenId to supply. The last 160 bits of the tokenId are reserved for the asset address which is what will be supplied.|
|`extraData`|`bytes`|Extra data that can be used by the hooks.|

