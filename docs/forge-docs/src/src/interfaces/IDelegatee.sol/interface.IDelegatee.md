# IDelegatee
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/IDelegatee.sol)

**Title:**
IDelegatee

**Author:**
Chinmay <chinmay@dhedge.org>

Interface for the delegatee contract to handle delegation calls.

Be extremely cautious when creating a delegatee contract regarding security implications
in case a delegatee is ever authorized as an operator. It's best to check for access control
within the delegatee contract itself in case operating on an account. There can be cases where
someone can invoke an action on behalf of an account via a delegatee contract which is set as an
operator for that account.


## Functions
### onDelegationCallback

Callback function to be called by the Office contract for a delegation call.


```solidity
function onDelegationCallback(bytes calldata callbackData) external returns (bytes memory returnData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`callbackData`|`bytes`|The data to be passed to the callback function of the delegatee.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`returnData`|`bytes`|An array of return data from the delegatee's calls.|


