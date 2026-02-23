# IContext
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


## Functions
### callerContext

The original caller of the delegation call (if ongoing).


```solidity
function callerContext() external view returns (address caller);
```

### delegateeContext

The delegatee address for the delegation call (if ongoing).

*This is not to be confused with the `msg.sender` of the delegation call
which is the `callerContext`.*


```solidity
function delegateeContext() external view returns (IDelegatee delegatee);
```

### requiresHealthCheck

Indicates if an account health check is required after the delegation call.


```solidity
function requiresHealthCheck() external view returns (bool healthCheck);
```

### isOngoingDelegationCall

Checks if the ongoing call is a delegation call.

*Only checks if the delegatee context is set (not address(0)).*


```solidity
function isOngoingDelegationCall() external view returns (bool callStatus);
```

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

