# SupplyParams
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/ParamStructs.sol)

Parameters for supply operations.


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
|`assets`|`uint256`|The amount of the asset as encoded in the tokenId to supply. Use `type(uint256).max` to supply all the balance.|
|`extraData`|`bytes`|Extra data that can be used by the hooks.|

