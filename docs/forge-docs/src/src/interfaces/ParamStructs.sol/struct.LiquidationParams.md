# LiquidationParams
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/ParamStructs.sol)

Parameters for liquidation operations.


```solidity
struct LiquidationParams {
AccountId account;
MarketId market;
CollateralLiquidationParams[] collateralParams;
bytes callbackData;
bytes extraData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account that has a debt in a market.|
|`market`|`MarketId`|The market identifier that the `account` has a debt in.|
|`collateralParams`|`CollateralLiquidationParams[]`|The collateral tokenId shares and corresponding amounts to be liquidated.|
|`callbackData`|`bytes`|Additional data that can be used by the liquidator to perform the liquidation. The `liquidator` must implement the `ILiquidator` interface.|
|`extraData`|`bytes`|Extra data that can be used by the hooks.|

