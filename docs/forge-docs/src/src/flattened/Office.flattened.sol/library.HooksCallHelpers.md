# HooksCallHelpers
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

**Author:**
Chinmay <chinmay@dhedge.org>

*A library to dispatch calls to hook functions in the Hooks contract.
Inspired by Uniswap v4's hooks.*


## Functions
### callHook

*Calls a hook function on the provided hooks contract if the flag is set.*


```solidity
function callHook(IHooks hooks, bytes4 hookSelector, uint160 flag) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`hooks`|`IHooks`|The hooks contract to call.|
|`hookSelector`|`bytes4`|The selector of the hook function to call.|
|`flag`|`uint160`|The flag to check for permission.|


### hasPermission

*Checks if the hooks contract has permission to call a specific hook function based on the flag.*


```solidity
function hasPermission(IHooks hooks, uint160 flag) internal pure returns (bool permitted);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`hooks`|`IHooks`|The hooks contract to check.|
|`flag`|`uint160`|The flag to check for permission.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`permitted`|`bool`|True if the hooks contract has permission, false otherwise.|


## Errors
### HookCallHelpers__HookCallFailed

```solidity
error HookCallHelpers__HookCallFailed(bytes4 selector, bytes errorData);
```

