# ILiquidator
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/ILiquidator.sol)

**Title:**
ILiquidator

**Author:**
Chinmay <chinmay@dhedge.org>

Interface for liquidator contracts.


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


