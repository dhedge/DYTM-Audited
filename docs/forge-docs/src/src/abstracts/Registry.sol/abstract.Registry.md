# Registry
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/abstracts/Registry.sol)

**Inherits:**
[IRegistry](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IRegistry.sol/interface.IRegistry.md), [Context](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/abstracts/storages/Context.sol/abstract.Context.md)

**Title:**
Registry

**Author:**
Chinmay <chinmay@dhedge.org>

Tokenization as inspired by OpenZeppelin's ERC6909 implementation.

May not be fully compliant with the ERC6909 standard because of the following reasons:
- The `transferFrom` function does not allow transferring isolated account tokens by operators
unless the caller explicitly approved them.
- The operator scope is not just limited to transfers but also allows all market functions' access except
for transferring the account itself.


## Functions
### onlyAuthorizedCaller


```solidity
modifier onlyAuthorizedCaller(AccountId account) ;
```

### approve

Implicitly uses the caller's and spender's user accounts.


```solidity
function approve(address spender, uint256 tokenId, uint256 amount)
    external
    virtual
    override
    returns (bool success);
```

### transfer

For isolated account transfers, the `amount` must be 1.

Implicitly uses the caller's and receiver's user accounts.


```solidity
function transfer(address receiver, uint256 tokenId, uint256 amount) external virtual returns (bool success);
```

### transferFrom

Implicitly uses the caller's and receiver's user accounts.


```solidity
function transferFrom(
    address sender,
    address receiver,
    uint256 tokenId,
    uint256 amount
)
    external
    virtual
    returns (bool success);
```

### setOperator

Provides authorization to invoke market functions on behalf of the `spender`.

Implicitly uses the caller's user account.


```solidity
function setOperator(address spender, bool approved) public virtual returns (bool success);
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


### balanceOf

Implicitly uses the caller's user account.


```solidity
function balanceOf(address owner, uint256 id) external view returns (uint256 balance);
```

### totalSupply


```solidity
function totalSupply(uint256 id) public view virtual returns (uint256 supply);
```

### allowance

Implicitly uses the owner's and spender's user account.


```solidity
function allowance(address owner, address spender, uint256 id) external view returns (uint256 remaining);
```

### isOperator

Provides temporary operator access to the delegatee in a delegation call context.


```solidity
function isOperator(address owner, address spender) public view virtual returns (bool approved);
```

### supportsInterface

Returns `true` if `interfaceId` is that of IERC6909 or IERC165.


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool isSupported);
```

### createIsolatedAccount

Creates a new isolated account with the given `newOwner`.


```solidity
function createIsolatedAccount(address newOwner) public returns (AccountId newAccount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address of the new owner of the account.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newAccount`|`AccountId`|The newly created AccountId.|


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
    public
    virtual
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
    public
    virtual
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
function setOperator(address operator, AccountId account, bool approved) public virtual returns (bool success);
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


### _mint

Creates `amount` of token `tokenId` and assigns them to `account`, by transferring it from ACCOUNT_ID_ZERO.
Relies on the `_update` mechanism.
Emits a {Transfer} event with `from` set to the zero AccountId.
NOTE: This function is not virtual, [_update](//Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/abstracts/Registry.sol/abstract.Registry.md#_update) should be overridden instead.


```solidity
function _mint(AccountId to, uint256 tokenId, uint256 amount) internal;
```

### _transfer

Moves `amount` of token `tokenId` from `from` to `to` without checking for approvals. This function
verifies that neither the sender nor the receiver are ACCOUNT_ID_ZERO, which means it cannot mint or burn tokens.
Relies on the `_update` mechanism.
Emits a {Transfer} event.
NOTE: This function is not virtual, [_update](//Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/abstracts/Registry.sol/abstract.Registry.md#_update) should be overridden instead.


```solidity
function _transfer(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal;
```

### _burn

Destroys a `amount` of token `tokenId` from `account`.
Relies on the `_update` mechanism.
Emits a {Transfer} event with `to` set to the zero AccountId.
NOTE: This function is not virtual, [_update](//Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/abstracts/Registry.sol/abstract.Registry.md#_update) should be overridden instead


```solidity
function _burn(AccountId from, uint256 tokenId, uint256 amount) internal;
```

### _update

Transfers `amount` of token `tokenId` from `from` to `to`, or alternatively mints (or burns) if `from`
(or `to`) is the zero AccountId. All customizations to transfers, mints, and burns should be done by overriding
this function.
Emits a {Transfer} event.


```solidity
function _update(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal virtual;
```

### _approve

Sets `amount` as the allowance of `spender` over the `from`'s `tokenId` tokens.
This internal function is equivalent to `approve`, and can be used to e.g. set automatic allowances for certain
subsystems, etc.
Emits an {Approval} event.
Requirements:
- `from` cannot be the zero AccountId.
- `spender` cannot be the zero AccountId.
> [!WARNING]
> - This function does not check if `currentOwner` is the zero address given that the only other place
it is used is in the `approve` function which already checks for it.
> - This function does not check if the `tokenId` actually exists. As long as it's in the correct format
(i.e., is encoded as a valid token Id), it will be accepted.


```solidity
function _approve(
    address currentOwner,
    AccountId from,
    AccountId spender,
    uint256 tokenId,
    uint256 amount
)
    internal
    virtual;
```

### _setOperator

Approve `operator` to operate on all of `owner`'s tokens

This internal function is equivalent to `setOperator`, and can be used to e.g. set automatic allowances for
certain subsystems, etc.
Emits an {OperatorSet} event.
Requirements:
- `owner` cannot be the zero address.
- `operator` cannot be the zero address.


```solidity
function _setOperator(address owner, AccountId account, address operator, bool approved) internal virtual;
```

### _spendAllowance

Updates `from`'s allowance for `spender` based on spent `amount`.
- Does not update the allowance value in case of infinite allowance.
- Reverts if enough allowance is not available.
- Does not emit an {Approval} event.


```solidity
function _spendAllowance(
    address currentOwner,
    AccountId from,
    AccountId spender,
    uint256 tokenId,
    uint256 amount
)
    internal
    virtual
    onlyAuthorizedCaller(spender);
```

### isAuthorizedCaller

Checks if the `caller` is authorized to operate on the `account`.
The caller is authorized if:
- The caller is the owner of the account (includes user accounts).
- The caller is an operator of the account.
- The caller is the delegatee of the account for the duration of a delegation call.


```solidity
function isAuthorizedCaller(AccountId account, address caller) public view returns (bool isAuthorized);
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


### ownerOf

Returns the owner of the `account`.

Reverts if the `account` is not created.


```solidity
function ownerOf(AccountId account) public view virtual returns (address owner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The AccountId of the account.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address of the owner of the account.|


### isOperator

Returns true if:
- The `operator` is approved by the owner of the `account` to operate on behalf of the owner.
- If in a delegation call:
- The `callerContext` is the owner of the `account` or an operator approved by the owner.
- AND the `operator` is the `delegateeContext`.

During a delegation call for `account`, if the `operator` is the same as the `delegateeContext`,
it returns true.


```solidity
function isOperator(AccountId account, address operator) public view virtual returns (bool approved);
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


### balanceOf

Returns the balance of `tokenId` tokens for the given `account`.


```solidity
function balanceOf(AccountId account, uint256 tokenId) public view virtual returns (uint256 balance);
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
    public
    view
    virtual
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


### getDebtId

Returns the debt token ID for a given market and user.

Implicitly converts `owner` address to user account.


```solidity
function getDebtId(address owner, MarketId market) public view returns (uint256 debtId);
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


### getDebtId

Returns the debt token ID for a given market and account.


```solidity
function getDebtId(AccountId account, MarketId market) public view returns (uint256 debtId);
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


### getAllCollateralIds

Returns the collateral token IDs for a given market and owner.

Implicitly converts `owner` address to user account.


```solidity
function getAllCollateralIds(address owner, MarketId market) public view returns (uint256[] memory collateralIds);
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
    public
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


### _verifyCallerAuthorization

Reverts if the caller is not authorized as per `isAuthorizedCaller` function.


```solidity
function _verifyCallerAuthorization(AccountId account) internal view;
```

## Structs
### RegistryStorageStruct
**Note:**
storage-location: erc7201:DYTM.storage.Accounts


```solidity
struct RegistryStorageStruct {
    uint96 accountCount;
    mapping(AccountId account => address owner) ownerOf;
    mapping(uint256 tokenId => uint256 supply) totalSupplies;
    mapping(address owner => OwnerSpecificData data) ownerData;
    mapping(AccountId account => mapping(uint256 tokenId => uint256 amount)) balances;
    mapping(AccountId account => mapping(MarketId market => TokensData tokens)) marketWiseData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`accountCount`|`uint96`|Counter for isolated accounts, incremented each time a new isolated account is created|
|`ownerOf`|`mapping(AccountId account => address owner)`|Maps isolated accounts to their owner addresses|
|`totalSupplies`|`mapping(uint256 tokenId => uint256 supply)`|Tracks the total supply of each token ID across all accounts|
|`ownerData`|`mapping(address owner => OwnerSpecificData data)`|Stores owner-specific data including operator approvals and allowances|
|`balances`|`mapping(AccountId account => mapping(uint256 tokenId => uint256 amount))`|Tracks token balances for each account and token ID|
|`marketWiseData`|`mapping(AccountId account => mapping(MarketId market => TokensData tokens))`|Stores market-specific data per account, including debt IDs and collateral token sets|

### OwnerSpecificData

```solidity
struct OwnerSpecificData {
    mapping(AccountId account => mapping(address operator => bool isApproved)) operatorApprovals;
    mapping(AccountId account => mapping(uint256 tokenId => mapping(AccountId spender => uint256 amount)))
        allowances;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`operatorApprovals`|`mapping(AccountId account => mapping(address operator => bool isApproved))`|Owner specific mapping of operator approvals per account.|
|`allowances`|`mapping(AccountId account => mapping(uint256 tokenId => mapping(AccountId spender => uint256 amount)))`|Owner specific mapping of allowances per account and tokenId.|

