# SimpleDelegatee
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/delegatees/SimpleDelegatee.sol)

**Inherits:**
[IDelegatee](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IDelegatee.sol/interface.IDelegatee.md)

**Title:**
SimpleDelegatee

**Author:**
Chinmay <chinmay@dhedge.org>

A simple delegatee contract that aggregates multiple calls to different targets.

Adapted from the Multicall contract.


## Functions
### onDelegationCallback


```solidity
function onDelegationCallback(bytes calldata callbackData) external returns (bytes memory returnData);
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
error SimpleDelegatee__CallFailed(Call call);
```

