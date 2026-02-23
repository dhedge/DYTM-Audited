# TransientEnumerableHashTableStorage
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/abstracts/storages/TransientEnumerableHashTableStorage.sol)

**Title:**
TransientEnumerableHashTableStorage

**Author:**
Chinmay <chinmay@dhedge.org>

Abstract contract which stores the account Id and market Id of the account for which
health check is required, into a queue with duplication checks using a hash table approach.

The hash table isn't cleared after use and we rely on the fact that the transient storage
is automatically cleared after the transaction ends.


## State Variables
### __length

```solidity
uint8 private transient __length
```


## Functions
### _insert

Inserts the `account` and the `market` in the transient queue if there is space and not already inserted.
This function will revert if the queue is full.


```solidity
function _insert(AccountId account, MarketId market) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID to be stored.|
|`market`|`MarketId`|The market ID to be stored.|


### _get

Gets the account Id and market Id at the `index` from the transient queue.


```solidity
function _get(uint8 index) internal view returns (AccountId account, MarketId market);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`index`|`uint8`|The index of the element to be retrieved.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account Id at the given index.|
|`market`|`MarketId`|The market Id at the given index.|


### _getLength

Gets the current length of the transient queue.


```solidity
function _getLength() internal view returns (uint8 length);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`length`|`uint8`|The current length of the transient queue.|


### __addToHashTable

Marks the encoded value as inserted.

Given that `__encodeAccountMarket` is a bijective function and the least value of
this function is `2^168 + 2`, One could safely assume that there will never be collisions.


```solidity
function __addToHashTable(uint256 encodedValue) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`encodedValue`|`uint256`|The pre-encoded account and market combination.|


### __isDuplicate

Checks if account and market combination is already in the queue using a hash table approach.
The check loads the value at the slot `encodedValue` and checks if it is 1 indicating duplication.


```solidity
function __isDuplicate(uint256 encodedValue) private view returns (bool isDuplicate);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`encodedValue`|`uint256`|The account and market id combination encoded value.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isDuplicate`|`bool`|True if the combination is a duplicate.|


### __encodeAccountMarket

We encode the account Id, market Id and the account type into a single uint256 and store it in the table.
This is possible because the market Id is at most 88 bits and the account Id is at most 160 bits
even though the underlying account Id type is 256 bits, only the upper 96 bits are useful for isolated accounts
and only the lower 160 bits are useful for user accounts. The LSB is used to differentiate between
isolated and user accounts (0 for user accounts, 1 for isolated accounts). In short, this is a bijective function.


```solidity
function __encodeAccountMarket(AccountId account, MarketId market) private pure returns (uint256 encoded);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID to encode.|
|`market`|`MarketId`|The market ID to encode.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`encoded`|`uint256`|The encoded value containing both IDs.|


### __decodeAccountMarket

Decodes the encoded value back to account and market IDs.


```solidity
function __decodeAccountMarket(uint256 encoded) private pure returns (AccountId account, MarketId market);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`encoded`|`uint256`|The encoded value to decode.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The decoded account ID.|
|`market`|`MarketId`|The decoded market ID.|


## Errors
### TransientEnumerableHashTableStorage__QueueFull

```solidity
error TransientEnumerableHashTableStorage__QueueFull();
```

### TransientEnumerableHashTableStorage__IndexOutOfBounds

```solidity
error TransientEnumerableHashTableStorage__IndexOutOfBounds();
```

