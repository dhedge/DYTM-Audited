# SimpleDelegatee
[Git Source](https://github.com/dhedge/DYTM/blob/b861f88620abe965bc87fe355cbb9cb461faa9b9/src/helpers/SimpleDelegatee.sol)

**Inherits:**
[IDelegatee](/src/interfaces/IDelegatee.sol/interface.IDelegatee.md)

**Author:**
Chinmay <chinmay@dhedge.org>

A simple delegatee contract that aggregates multiple calls to different targets.

*Adapted from the Multicall contract.*


## Functions
### onDelegationCallback


```solidity
function onDelegationCallback(bytes calldata callbackData) external returns (bytes[] memory returnData);
```

### aggregate


```solidity
function aggregate(Call[] memory calls) public returns (bytes[] memory returnData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`calls`|`Call[]`|An array of Call structs|


## Errors
### SimpleDelegatee__CallFailed

```solidity
error SimpleDelegatee__CallFailed(address target, bytes callData);
```

