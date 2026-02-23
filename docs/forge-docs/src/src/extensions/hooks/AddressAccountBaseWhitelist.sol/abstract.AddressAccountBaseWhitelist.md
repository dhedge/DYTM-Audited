# AddressAccountBaseWhitelist
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/hooks/AddressAccountBaseWhitelist.sol)

**Inherits:**
[IAddressAccountBaseWhitelist](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IAddressAccountBaseWhitelist.sol/interface.IAddressAccountBaseWhitelist.md), Ownable

**Title:**
AddressAccountBaseWhitelist

**Author:**
Chinmay <chinmay@dhedge.org>

Base contract for whitelisting accounts and account owners by address.


## State Variables
### REGISTRY
The registry contract to fetch account owner from.


```solidity
IRegistry public immutable override REGISTRY
```


### isWhitelistedAccount

```solidity
mapping(AccountId account => bool allowed) public isWhitelistedAccount
```


### isWhitelistedAddress

```solidity
mapping(address accountOwner => bool allowed) public isWhitelistedAddress
```


## Functions
### onlyAuthorized


```solidity
modifier onlyAuthorized(AccountId account) ;
```

### constructor

Constructor


```solidity
constructor(IRegistry registry_, address admin_) Ownable(admin_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`registry_`|`IRegistry`|The registry contract to fetch account owner from.|
|`admin_`|`address`|The admin address which will be set as the owner.|


### hasAccess

Verifies if the given account or its owner is whitelisted.

Implicitly verifies access for the owner address of the given account.


```solidity
function hasAccess(AccountId account) public view returns (bool allowed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account to verify access for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`allowed`|`bool`|`true` if either the account or its owner is whitelisted.|


### setAccountWhitelist

Adds or removes an account from the whitelist.

Doesn't revert if the account is already in the desired state.


```solidity
function setAccountWhitelist(AccountId account, bool allowed) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account to add or remove.|
|`allowed`|`bool`|`true` to add the account, `false` to remove it.|


### setAddressWhitelist

Adds or removes an account owner from the whitelist.

Doesn't revert if the account owner is already in the desired state.


```solidity
function setAddressWhitelist(address accountOwner, bool allowed) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`accountOwner`|`address`|The account owner to add or remove.|
|`allowed`|`bool`|`true` to add the account owner, `false` to remove it.|


### _verifyAccess


```solidity
function _verifyAccess(AccountId account) internal view;
```

