# IContext
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/IContext.sol)

**Title:**
IContext

**Author:**
Chinmay <chinmay@dhedge.org>

Interface for managing delegation call context in the DYTM protocol.

This interface tracks the state during delegation calls, including the caller,
delegatee, and health check requirements.


## Functions
### callerContext

The original caller of the delegation call (if ongoing).


```solidity
function callerContext() external view returns (address caller);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`caller`|`address`|The address of the original caller, or address(0) if no delegation call is ongoing.|


### delegateeContext

The delegatee address for the delegation call (if ongoing).

This is not to be confused with the `msg.sender` of the delegation call
which is the `callerContext`.


```solidity
function delegateeContext() external view returns (IDelegatee delegatee);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`delegatee`|`IDelegatee`|The delegatee contract, or IDelegatee(address(0)) if no delegation call is ongoing.|


### requiresHealthCheck

Indicates if an account health check is required after the delegation call.


```solidity
function requiresHealthCheck() external view returns (bool healthCheck);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`healthCheck`|`bool`|True if a health check should be performed after the delegation call.|


### isOngoingDelegationCall

Checks if the ongoing call is a delegation call.

Only checks if the delegatee context is set (not address(0)).


```solidity
function isOngoingDelegationCall() external view returns (bool callStatus);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`callStatus`|`bool`|True if a delegation call is currently in progress.|


## Events
### Context__DelegationCallCompleted

```solidity
event Context__DelegationCallCompleted(address indexed caller, IDelegatee indexed delegatee);
```

## Errors
### Context__ContextAlreadySet

```solidity
error Context__ContextAlreadySet();
```

