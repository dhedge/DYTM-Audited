# IFlashloanReceiver
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/IFlashloanReceiver.sol)

**Title:**
IFlashloanReceiver

**Author:**
Chinmay <chinmay@dhedge.org>

Interface for the flashloan receiver contract to handle flashloan callbacks.


## Functions
### onFlashloanCallback

Callback function to be implemented by the flashloan receiver contract.


```solidity
function onFlashloanCallback(uint256 assets, bytes calldata callbackData) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets to be returned to clear the flashloan debt. Not to be confused with the amount borrowed or transferred to the receiver.|
|`callbackData`|`bytes`|Additional data that can be used by the receiver to perform operations.|


