# AccountIdLibrary
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/types/AccountId.sol)

**Title:**
AccountIdLibrary

**Author:**
Chinmay <chinmay@dhedge.org>

Library for AccountId conversions related functions.


## Functions
### toUserAccount

Converts a user address to an account ID.


```solidity
function toUserAccount(address user) internal pure returns (AccountId account);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The user address to be converted.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID corresponding to the user address.|


### toTokenId

Converts an account ID to a token ID.

The token ID is the same as the account ID.
Note: A user account can't be tokenized, so this function is only valid for isolated accounts.


```solidity
function toTokenId(AccountId account) internal pure returns (uint256 tokenId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID to be converted.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID corresponding to the account ID.|


### toIsolatedAccount

Converts an account count to an isolated account ID.

An isolated account is one where the least significant 160 bits are zero
and the top 96 bits are set to the count.
- Reverts if the count is zero.


```solidity
function toIsolatedAccount(uint96 count) internal pure returns (AccountId account);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`count`|`uint96`|The account count to be converted.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The isolated account ID corresponding to the count.|


### toUserAddress

Validates and converts an account ID to a user address.

- Reverts if the account ID is not a user account.
- Revert if the account ID is a null account (i.e., zero address).


```solidity
function toUserAddress(AccountId account) internal pure returns (address user);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID to be converted.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The user address corresponding to the user account ID.|


### isUserAccount

Function to check if an account is a user account.
Will revert if the `account` is not a valid account type.

A user account is one where the least significant 160 bits are non-zero and
the top 96 bits are zero.


```solidity
function isUserAccount(AccountId account) internal pure returns (bool isUser);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID to be checked.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isUser`|`bool`|True if the account is a user account, false otherwise.|


### isIsolatedAccount

Function to check if an account is an isolated account.
Will revert if the `account` is not a valid account type.

An isolated account is one where the least significant 160 bits are zero
and the top 96 bits are non-zero.


```solidity
function isIsolatedAccount(AccountId account) internal pure returns (bool isIsolated);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID to be checked.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isIsolated`|`bool`|True if the account is an isolated account, false otherwise.|


### getAccountType

Determines the type of account based on its raw uint256 representation.

Reverts if the raw account ID does not conform to either type.


```solidity
function getAccountType(uint256 rawAccount) internal pure returns (AccountType accountType);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rawAccount`|`uint256`|The raw uint256 representation of the account ID.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`accountType`|`AccountType`|The type of the account (USER_ACCOUNT or ISOLATED_ACCOUNT).|


## Errors
### AccountIdLibrary__ZeroAddress

```solidity
error AccountIdLibrary__ZeroAddress();
```

### AccountIdLibrary__ZeroAccountNumber

```solidity
error AccountIdLibrary__ZeroAccountNumber();
```

### AccountIdLibrary__InvalidRawAccountId

```solidity
error AccountIdLibrary__InvalidRawAccountId(uint256 rawAccount);
```

### AccountIdLibrary__InvalidUserAccountId

```solidity
error AccountIdLibrary__InvalidUserAccountId(AccountId account);
```

### AccountIdLibrary__InvalidIsolatedAccountId

```solidity
error AccountIdLibrary__InvalidIsolatedAccountId(AccountId account);
```

## Enums
### AccountType

```solidity
enum AccountType {
    INVALID_ACCOUNT, // 0
    USER_ACCOUNT, // 1
    ISOLATED_ACCOUNT // 2
}
```

