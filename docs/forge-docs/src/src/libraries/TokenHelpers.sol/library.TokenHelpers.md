# TokenHelpers
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/libraries/TokenHelpers.sol)

**Title:**
TokenHelpers

**Author:**
Chinmay <chinmay@dhedge.org>

A library for handling tokenId related operations.


## Functions
### getTokenType

Function to get the token type from a tokenId.

If the least significant 160 bits of the tokenId are zero and the top 96 bits are non-zero, it's an
isolated account token. Otherwise, provided the next 88 bits and the most significant byte bits are non-zero,
the token type is stored in the most significant byte of the tokenId.

[!WARNING] It will return `TokenType.NONE` instead of reverting.


```solidity
function getTokenType(uint256 tokenId) internal pure returns (TokenType tokenType);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID to convert.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenType`|`TokenType`|The type of the token, represented as a uint8.|


### getMarketId

Function to get the MarketId from a tokenId.

The MarketId is stored in the bits [247:160] of the tokenId.

We can extract it by right shifting the tokenId by 160 bits and casting it to a uint88.


```solidity
function getMarketId(uint256 tokenId) internal pure returns (MarketId marketId);
```

### getAsset

Function to get the asset address from a tokenId.

The asset address is the last 160 bits of the token ID.


```solidity
function getAsset(uint256 tokenId) internal pure returns (IERC20 asset);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID to convert.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`IERC20`|The IERC20 asset corresponding to the tokenId.|


### getReserveKey

Function to get the ReserveKey from a tokenId.

The ReserveKey is the last 248 bits of the tokenId consisting of the MarketId and the asset address.

We can extract it by casting the tokenId to a uint248 and then wrapping it in a ReserveKey.


```solidity
function getReserveKey(uint256 tokenId) internal pure returns (ReserveKey key);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID to convert.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The ReserveKey corresponding to the tokenId.|


### isCollateral

Function to check if a tokenId is a collateral token.

A token is considered collateral if it is either an escrow token or a share token.


```solidity
function isCollateral(uint256 tokenId) internal pure returns (bool result);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`result`|`bool`|True if the tokenId is a collateral token, false otherwise.|


### isDebt

Function to check if a tokenId is a debt token.


```solidity
function isDebt(uint256 tokenId) internal pure returns (bool result);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`result`|`bool`|True if the tokenId is a debt token, false otherwise.|


