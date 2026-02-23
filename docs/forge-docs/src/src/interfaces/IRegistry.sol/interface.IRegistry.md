# IRegistry
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/IRegistry.sol)

**Inherits:**
IERC6909TokenSupply

**Title:**
IRegistry

**Author:**
Chinmay <chinmay@dhedge.org>

Interface for the Registry contract which manages tokenization for the DYTM protocol.


## Functions
### createIsolatedAccount

Creates a new isolated account with the given `newOwner`.


```solidity
function createIsolatedAccount(address newOwner) external returns (AccountId newAccount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address of the new owner of the account.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newAccount`|`AccountId`|The newly created AccountId.|


### allowance

Implicitly uses the owner's and spender's user account.

Read more the behaviour of allowances in the natspec of `allowance` in
the 'Account Functions' section of this interface.


```solidity
function allowance(address owner, address spender, uint256 id) external view returns (uint256 remaining);
```

### approve

Implicitly uses the caller's and spender's user accounts.


```solidity
function approve(address spender, uint256 tokenId, uint256 amount) external returns (bool success);
```

### balanceOf

Implicitly uses the caller's user account.


```solidity
function balanceOf(address owner, uint256 id) external view returns (uint256 balance);
```

### getAllCollateralIds

Returns the collateral token IDs for a given market and owner.

Implicitly converts `owner` address to user account.


```solidity
function getAllCollateralIds(address owner, MarketId market) external view returns (uint256[] memory collateralIds);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The user address.|
|`market`|`MarketId`|The market ID of the market.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralIds`|`uint256[]`|Array of collateral token IDs.|


### getDebtId

Returns the debt token ID for a given market and user.

Implicitly converts `owner` address to user account.


```solidity
function getDebtId(address owner, MarketId market) external view returns (uint256 debtId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The user address.|
|`market`|`MarketId`|The market ID of the market.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`debtId`|`uint256`|The debt token ID for the account in the market.|


### isOperator

Provides temporary operator access to the delegatee in a delegation call context.


```solidity
function isOperator(address owner, address spender) external view returns (bool approved);
```

### setOperator

Provides authorization to invoke market functions on behalf of the `spender`.

Implicitly uses the caller's user account.


```solidity
function setOperator(address spender, bool approved) external returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`spender`|`address`|The address of the spender to authorize.|
|`approved`|`bool`|Whether the operator is approved or not.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|Returns true if the operation was successful.|


### supportsInterface

Returns `true` if `interfaceId` is that of IERC6909 or IERC165.


```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool isSupported);
```

### totalSupply

Returns the total supply of the token of type `id`.


```solidity
function totalSupply(uint256 id) external view returns (uint256 supply);
```

### transfer

For isolated account transfers, the `amount` must be 1.

Implicitly uses the caller's and receiver's user accounts.


```solidity
function transfer(address receiver, uint256 tokenId, uint256 amount) external returns (bool success);
```

### transferFrom

Implicitly uses the caller's and receiver's user accounts.

- If caller is not the current owner or the operator, the transfer happens
using the allowance amount as configured by the current account owner.
- If the caller is an operator and the tokenId represents an isolated account,
the transfer will only take place if the operator is approved by the current account owner.


```solidity
function transferFrom(
    address sender,
    address receiver,
    uint256 tokenId,
    uint256 amount
)
    external
    returns (bool success);
```

### allowance

Returns the allowance of `spender` for `tokenId` tokens of `account` as configured by
a particular account owner.
> [!NOTE]
> The allowances are tied to the owner of the account, not the account itself.
> If an account is transferred to a new owner and back to the previous owner, the allowances
> set by the original owner will remain.

This function does not include operator allowances.
To check operator allowances, use `isOperator`.


```solidity
function allowance(
    address owner,
    AccountId account,
    AccountId spender,
    uint256 tokenId
)
    external
    view
    returns (uint256 remaining);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address of the owner of the account.|
|`account`|`AccountId`|The AccountId of the account.|
|`spender`|`AccountId`|The AccountId of the spender.|
|`tokenId`|`uint256`|The ID of the token to check the allowance for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`remaining`|`uint256`|The allowance of the spender for the token of the account.|


### approve

Approves a `spender` to operate on `tokenId` tokens of the `account`.
Can only be called by the owner of the `account`.


```solidity
function approve(
    AccountId account,
    AccountId spender,
    uint256 tokenId,
    uint256 amount
)
    external
    returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The AccountId of the account.|
|`spender`|`AccountId`|The AccountId of the spender.|
|`tokenId`|`uint256`|The ID of the token to approve.|
|`amount`|`uint256`|The amount of tokens to approve.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|Returns true if the operation was successful.|


### balanceOf

Returns the balance of `tokenId` tokens for the given `account`.


```solidity
function balanceOf(AccountId account, uint256 tokenId) external view returns (uint256 balance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The AccountId of the account.|
|`tokenId`|`uint256`|The ID of the token to check the balance for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`balance`|`uint256`|The balance of the token for the account.|


### getAllCollateralIds

Returns the collateral token IDs for a given market and account.

A collateral token ID is technically a token ID but with additional details like
the token type (e.g. escrowed or lent).
> [!Note]
> This function is gas-intensive and this limits the amount of collateral assets
> that can be allowed per market or per account.


```solidity
function getAllCollateralIds(
    AccountId account,
    MarketId market
)
    external
    view
    returns (uint256[] memory collateralIds);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID.|
|`market`|`MarketId`|The market ID of the market.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralIds`|`uint256[]`|Array of collateral token IDs.|


### getDebtId

Returns the debt token ID for a given market and account.


```solidity
function getDebtId(AccountId account, MarketId market) external view returns (uint256 debtId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID.|
|`market`|`MarketId`|The market ID of the market.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`debtId`|`uint256`|The debt token ID for the account in the market.|


### isAuthorizedCaller

Checks if the `caller` is authorized to operate on the `account`.
The caller is authorized if:
- The caller is the owner of the account (includes user accounts).
- The caller is an operator of the account.
- The caller is the delegatee of the account for the duration of a delegation call.


```solidity
function isAuthorizedCaller(AccountId account, address caller) external view returns (bool isAuthorized);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The AccountId of the account to check authorization for.|
|`caller`|`address`|The address of the caller.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isAuthorized`|`bool`|Returns true if the caller is authorized to operate on the account.|


### isOperator

Returns true if:
- The `operator` is approved by the owner of the `account` to operate on behalf of the owner.
- If in a delegation call:
- The `callerContext` is the owner of the `account` or an operator approved by the owner.
- AND the `operator` is the `delegateeContext`.

During a delegation call for `account`, if the `operator` is the same as the `delegateeContext`,
it returns true.


```solidity
function isOperator(AccountId account, address operator) external view returns (bool approved);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The AccountId of the account.|
|`operator`|`address`|The address of the operator to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`approved`|`bool`|True if the operator is authorized to operate on the account.|


### ownerOf

Returns the owner of the `account`.

Reverts if the `account` is not created.

In case the `account` is a user account, it returns the address of the user.


```solidity
function ownerOf(AccountId account) external view returns (address owner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The AccountId of the account.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address of the owner of the account.|


### setOperator

Sets an operator for the `account` that can perform actions on behalf of the owner of the `account`.
If the account is transferred to a new owner, the previously set operators won't have any permissions by default.
However, if the same account is transferred back to the previous owner, the operators will regain their permissions.
This behaviour is similar to how allowances work in this system.
> [!WARNING]
> If setting a contract as an operator, ensure that the contract has access controls to prevent unauthorized invocation of
> privileged functions. For example, contract `A` is set as an operator for account `X`. If `A` doesn't verify
> that the caller is authorized to perform actions on behalf of `X`, then anyone can call `A` to perform actions on behalf of `X`.


```solidity
function setOperator(address operator, AccountId account, bool approved) external returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator.|
|`account`|`AccountId`|The AccountId of the account.|
|`approved`|`bool`|Whether the operator is approved or not.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|Returns true if the operation was successful.|


### transferFrom

Transfers `amount` of token `tokenId` from the caller's account to `receiver`.
> [!NOTE]
> This function could deviate from the ERC6909 standard given that an operator cannot transfer
> a specific type of token (isolated account token) unless approved by the current account owner.


```solidity
function transferFrom(
    AccountId sender,
    AccountId receiver,
    uint256 tokenId,
    uint256 amount
)
    external
    returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sender`|`AccountId`|The AccountId of the sender.|
|`receiver`|`AccountId`|The AccountId of the receiver.|
|`tokenId`|`uint256`|The ID of the token to transfer.|
|`amount`|`uint256`|The amount of tokens to transfer.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|Returns true if the operation was successful.|


## Events
### Registry__AccountCreated

```solidity
event Registry__AccountCreated(AccountId indexed account, address indexed owner);
```

### Registry__AccountTransfer

```solidity
event Registry__AccountTransfer(AccountId indexed account, address indexed oldOwner, address indexed newOwner);
```

### Registry__Approval

```solidity
event Registry__Approval(
    AccountId indexed account, AccountId indexed spender, uint256 indexed tokenId, uint256 amount
);
```

### Registry__Transfer

```solidity
event Registry__Transfer(
    address indexed caller, AccountId indexed from, AccountId indexed to, uint256 tokenId, uint256 amount
);
```

### Registry__OperatorSet

```solidity
event Registry__OperatorSet(
    address indexed owner, AccountId indexed account, address indexed operator, bool approved
);
```

## Errors
### Registry__ZeroAddress

```solidity
error Registry__ZeroAddress();
```

### Registry__ZeroAccount

```solidity
error Registry__ZeroAccount();
```

### Registry__NoAccountOwner

```solidity
error Registry__NoAccountOwner(AccountId account);
```

### Registry__DebtTokensCannotBeTransferred

```solidity
error Registry__DebtTokensCannotBeTransferred(uint256 tokenId);
```

### Registry__IsNotAccountOwner

```solidity
error Registry__IsNotAccountOwner(AccountId account, address caller);
```

### Registry__NotAuthorizedCaller

```solidity
error Registry__NotAuthorizedCaller(AccountId account, address caller);
```

### Registry__TokenRemovalFromSetFailed

```solidity
error Registry__TokenRemovalFromSetFailed(AccountId account, uint256 tokenId);
```

### Registry__DebtIdMismatch

```solidity
error Registry__DebtIdMismatch(AccountId account, uint256 expectedDebtId, uint256 actualDebtId);
```

### Registry__InsufficientBalance

```solidity
error Registry__InsufficientBalance(AccountId account, uint256 balance, uint256 needed, uint256 tokenId);
```

### Registry__InsufficientAllowance

```solidity
error Registry__InsufficientAllowance(
    AccountId account, AccountId spender, uint256 allowance, uint256 needed, uint256 tokenId
);
```

## Structs
### TokensData
Struct which stores the collateral token IDs and debt token ID per account and market.


```solidity
struct TokensData {
    uint256 debtId;
    EnumerableSet.UintSet collateralIds;
}
```

