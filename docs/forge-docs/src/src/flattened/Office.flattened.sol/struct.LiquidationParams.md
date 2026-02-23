# LiquidationParams
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


```solidity
struct LiquidationParams {
    AccountId account;
    MarketId market;
    CollateralLiquidationParams[] collateralShares;
    bytes callbackData;
    bytes extraData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account that has a debt in a market.|
|`market`|`MarketId`|The market identifier that the `account` has a debt in.|
|`collateralShares`|`CollateralLiquidationParams[]`|The collateral tokenId shares and corresponding amounts to be liquidated.|
|`callbackData`|`bytes`|Additional data that can be used by the liquidator to perform the liquidation. The `liquidator` must implement the `ILiquidator` interface.|
|`extraData`|`bytes`|Extra data that can be used by the hooks.|

