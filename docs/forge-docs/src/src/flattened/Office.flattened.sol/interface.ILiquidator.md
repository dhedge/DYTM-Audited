# ILiquidator
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


## Functions
### onLiquidationCallback

Function which is called during liquidation of an account for repayment.


```solidity
function onLiquidationCallback(uint256 debtAssetAmount, bytes calldata callbackData) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`debtAssetAmount`|`uint256`|The amount of the debt asset that needs to be approved to the Office contract.|
|`callbackData`|`bytes`|Additional data that can be used by the liquidator to perform the liquidation.|


