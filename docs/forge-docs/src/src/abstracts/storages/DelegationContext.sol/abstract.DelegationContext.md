# DelegationContext
[Git Source](https://github.com/dhedge/DYTM/blob/b861f88620abe965bc87fe355cbb9cb461faa9b9/src/abstracts/storages/DelegationContext.sol)

**Author:**
Chinmay <chinmay@dhedge.org>

*Transient storage variables have completely independent address space from storage,
so that the order of transient state variables does not affect the layout of storage state variables and
vice-versa.*


## State Variables
### delegateeContext
The address of the caller that initiated the original transaction.


```solidity
IDelegatee public transient delegateeContext;
```


### accountContext
The account context of the delegated call.


```solidity
AccountId public transient accountContext;
```


### marketContext
The market context of the delegated call.


```solidity
MarketId public transient marketContext;
```


### requiresHealthCheck
Indicates if an account health check is required after the delegated call.


```solidity
bool public transient requiresHealthCheck;
```


## Functions
### useContext

*Can be used to enable delegation calls.*


```solidity
modifier useContext(IDelegatee delegatee, AccountId account, MarketId market);
```

### maintainContext

*Can be used to ensure that the delegation call context is maintained
and that the account matches the context set by the authorized caller.*


```solidity
modifier maintainContext(AccountId account);
```

### isOngoingDelegationCall

Checks if the ongoing call is a delegation call.

*If the delegatee context is set, it means we are in a delegation call regardless of the account or market.*


```solidity
function isOngoingDelegationCall() public view returns (bool callStatus);
```

### isOngoingDelegationCallForAccount

Checks if the ongoing call is a delegation call for a specific account.

*If the delegatee context is set and the account matches the context, it means we are in a delegation call
for that account.*


```solidity
function isOngoingDelegationCallForAccount(AccountId account) public view returns (bool callStatus);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account in context to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`callStatus`|`bool`|`true` if the ongoing call is a delegation call for the specified account, `false` otherwise.|


### _verifyContext

*Function to verify if delegation call context is maintained or not.
If a delegation call is underway, we need to ensure that the account matches
the context set by the authorized caller of the delegation call.
Note: We don't check if `msg.sender` is the same as `delegateeContext` here,
given that the only function which can change the `delegateeContext` is
`delegationCall` which is non-reentrant and thus cannot be called recursively.*


```solidity
function _verifyContext(AccountId account) internal view;
```

### _setContext

*Sets the caller to the address of the caller that initiated the transaction.
- Should be called at the beginning of a delegation call.
- Once set, the context cannot be changed until deleted so the function utilising `useContext` modifier
is effectively non-reentrant.*


```solidity
function _setContext(IDelegatee delegatee, AccountId account, MarketId market) private;
```

### _deleteContext

*Deletes the context of the delegation call.
Should be called at the end of a delegation call.*


```solidity
function _deleteContext() private;
```

## Events
### DelegationContext__DelegationCallCompleted

```solidity
event DelegationContext__DelegationCallCompleted(
    IDelegatee indexed delegatee, AccountId indexed account, MarketId indexed market
);
```

## Errors
### DelegationContext__ContextAlreadySet

```solidity
error DelegationContext__ContextAlreadySet();
```

### DelegationContext__DelegationCallWithDifferentAccount

```solidity
error DelegationContext__DelegationCallWithDifferentAccount(AccountId expected, AccountId actual);
```

