# IAddressAccountBaseWhitelist
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/IAddressAccountBaseWhitelist.sol)

**Title:**
IAddressAccountBaseWhitelist

**Author:**
Chinmay <chinmay@dhedge.org>

Interface for the AddressAccountBaseWhitelist contract.


## Functions
### REGISTRY

The registry contract to fetch account owner from.


```solidity
function REGISTRY() external view returns (IRegistry registry);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`registry`|`IRegistry`|The registry contract interface.|


### isWhitelistedAccount

Mapping to track whitelisted accounts.


```solidity
function isWhitelistedAccount(AccountId account) external view returns (bool allowed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account id.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`allowed`|`bool`|Whether the account is whitelisted.|


### isWhitelistedAddress

Mapping to track whitelisted account owners.


```solidity
function isWhitelistedAddress(address accountOwner) external view returns (bool allowed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`accountOwner`|`address`|The account owner address.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`allowed`|`bool`|Whether the account owner is whitelisted.|


### hasAccess

Verifies if the given account or its owner is whitelisted.

Implicitly verifies access for the owner address of the given account.


```solidity
function hasAccess(AccountId account) external view returns (bool allowed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account to verify access for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`allowed`|`bool`|`true` if either the account or its owner is whitelisted.|


## Events
### AddressAccountBaseWhitelist_AccountWhitelistModified

```solidity
event AddressAccountBaseWhitelist_AccountWhitelistModified(AccountId indexed account, bool isWhitelisted);
```

### AddressAccountBaseWhitelist_AddressWhitelistModified

```solidity
event AddressAccountBaseWhitelist_AddressWhitelistModified(address indexed accountOwner, bool isWhitelisted);
```

## Errors
### AddressAccountBaseWhitelist_ZeroAddress

```solidity
error AddressAccountBaseWhitelist_ZeroAddress();
```

### AddressAccountBaseWhitelist_NotWhitelisted

```solidity
error AddressAccountBaseWhitelist_NotWhitelisted(AccountId account, address accountOwner);
```

