# Context
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/abstracts/storages/Context.sol)

**Inherits:**
[IContext](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IContext.sol/interface.IContext.md)

**Title:**
Context

**Author:**
Chinmay <chinmay@dhedge.org>

Abstract contract to manage transient state context for delegation calls.

Transient storage variables have completely independent address space from storage,
which means the order of the transient state variables does not affect the layout of the
storage state variables and vice-versa.


## State Variables
### callerContext
The original caller of the delegation call (if ongoing).


```solidity
address public transient callerContext
```


### delegateeContext
The delegatee address for the delegation call (if ongoing).

This is not to be confused with the `msg.sender` of the delegation call
which is the `callerContext`.


```solidity
IDelegatee public transient delegateeContext
```


### requiresHealthCheck
Indicates if an account health check is required after the delegation call.


```solidity
bool public transient requiresHealthCheck
```


## Functions
### useContext

Can be used to enable delegation calls.


```solidity
modifier useContext(IDelegatee delegatee) ;
```

### isOngoingDelegationCall

Checks if the ongoing call is a delegation call.

Only checks if the delegatee context is set (not address(0)).


```solidity
function isOngoingDelegationCall() public view returns (bool callStatus);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`callStatus`|`bool`|True if a delegation call is currently in progress.|


### _setContext

Sets the context of the delegation call.
- Sets the caller, delegatee, account, and market context for the delegation call.
- Should be called at the beginning of a delegation call.
- Once set, the context cannot be changed until deleted so the function utilising `useContext` modifier
is effectively non-reentrant.


```solidity
function _setContext(IDelegatee delegatee) private;
```

### _deleteContext

Deletes the context of the delegation call.
Should be called at the end of a delegation call.


```solidity
function _deleteContext() private;
```

