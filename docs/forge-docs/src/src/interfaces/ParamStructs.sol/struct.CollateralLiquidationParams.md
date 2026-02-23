# CollateralLiquidationParams
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/ParamStructs.sol)

Parameters for collateral liquidation within a liquidation operation.

At least one of `assets` or `shares` must be non-zero.


```solidity
struct CollateralLiquidationParams {
uint256 tokenId;
uint256 assets;
uint256 shares;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The collateral tokenId to withdraw from the account for liquidations.|
|`assets`|`uint256`|The amount of the asset (as encoded in the tokenId) to liquidate.|
|`shares`|`uint256`|The amount of shares to liquidate. Use `type(uint256).max` to liquidate all the shares.|

