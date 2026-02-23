# SwitchCollateralParams
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


```solidity
struct SwitchCollateralParams {
    AccountId account;
    uint256 tokenId;
    uint256 shares;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account whose collateral will be switched to escrow or lending market.|
|`tokenId`|`uint256`|The collateral tokenId to switch. - If an escrow tokenId is provided, the shares will be switched to the lending market. - If a lending market tokenId is provided, the shares will be switched to escrow.|
|`shares`|`uint256`|The amount of shares to switch.|

