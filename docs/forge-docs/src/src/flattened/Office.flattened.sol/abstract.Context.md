# Context
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

**Inherits:**
[IContext](/src/flattened/Office.flattened.sol/interface.IContext.md)

**Author:**
Chinmay <chinmay@dhedge.org>

*Transient storage variables have completely independent address space from storage,
so that the order of transient state variables does not affect the layout of storage state variables and
vice-versa.*


## State Variables
### callerContext
The original caller of the delegation call (if ongoing).


```solidity
address public transient callerContext;
```


### delegateeContext
The delegatee address for the delegation call (if ongoing).

*This is not to be confused with the `msg.sender` of the delegation call
which is the `callerContext`.*


```solidity
IDelegatee public transient delegateeContext;
```


### requiresHealthCheck
Indicates if an account health check is required after the delegation call.


```solidity
bool public transient requiresHealthCheck;
```


## Functions
### useContext

*Can be used to enable delegation calls.*


```solidity
modifier useContext(IDelegatee delegatee);
```

### isOngoingDelegationCall

Checks if the ongoing call is a delegation call.

*Only checks if the delegatee context is set (not address(0)).*


```solidity
function isOngoingDelegationCall() public view returns (bool callStatus);
```

### _setContext

*Sets the context of the delegation call.
- Sets the caller, delegatee, account, and market context for the delegation call.
- Should be called at the beginning of a delegation call.
- Once set, the context cannot be changed until deleted so the function utilising `useContext` modifier
is effectively non-reentrant.*


```solidity
function _setContext(IDelegatee delegatee) private;
```

### _deleteContext

*Deletes the context of the delegation call.
Should be called at the end of a delegation call.*


```solidity
function _deleteContext() private;
```

