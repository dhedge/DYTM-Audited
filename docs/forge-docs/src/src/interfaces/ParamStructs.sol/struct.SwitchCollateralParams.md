# SwitchCollateralParams
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/ParamStructs.sol)

Parameters for switching collateral between escrow and lending market.

Exactly one of `assets` or `shares` must be zero.


```solidity
struct SwitchCollateralParams {
AccountId account;
uint256 tokenId;
uint256 assets;
uint256 shares;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account whose collateral will be switched to escrow or lending market.|
|`tokenId`|`uint256`|The collateral tokenId to switch. - If an escrow tokenId is provided, the shares will be switched to the lending market. - If a lending market tokenId is provided, the shares will be switched to escrow.|
|`assets`|`uint256`|The amount of the asset (as encoded in the tokenId) to switch.|
|`shares`|`uint256`|The amount of shares to switch. Use `type(uint256).max` to switch all shares.|

