# OwnableDelegatee
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/delegatees/OwnableDelegatee.sol)

**Inherits:**
[IDelegatee](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IDelegatee.sol/interface.IDelegatee.md), Ownable

**Title:**
OwnableDelegatee

**Author:**
Chinmay <chinmay@dhedge.org>

An ownable delegatee contract that aggregates multiple calls to different targets.
- The aggregate function can only be called by the owner of the contract (checked via tx.origin).
- The owner MUST be an EOA address (isn't checked in the contract though).
- The delegation call initiator MUST be the owner of this contract.

Adapted from the Multicall contract and SimpleDelegatee.


## Functions
### constructor


```solidity
constructor(address initialOwner) Ownable(initialOwner);
```

### onDelegationCallback

DYTM Office callback function to handle delegation calls.
The delegation call initiator MUST be the owner of this contract.


```solidity
function onDelegationCallback(bytes calldata callbackData) external returns (bytes memory returnData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`callbackData`|`bytes`|Encoded array of `Call` structs.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`returnData`|`bytes`|Encoded array of return data from each call.|


### aggregate

Executes multiple calls if the transaction origin is the owner.

Make sure you are using an EOA which is the owner of this contract to perform delegation calls.


```solidity
function aggregate(Call[] memory calls) public returns (bytes[] memory returnData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`calls`|`Call[]`|An array of `Call` structs.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`returnData`|`bytes[]`|An array of return data from each call.|


## Errors
### OwnableDelegatee__NotOwner

```solidity
error OwnableDelegatee__NotOwner();
```

### OwnableDelegatee__CallFailed

```solidity
error OwnableDelegatee__CallFailed(Call call);
```

