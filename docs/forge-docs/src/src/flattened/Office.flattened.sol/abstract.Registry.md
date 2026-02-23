# Registry
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

**Inherits:**
[IRegistry](/src/flattened/Office.flattened.sol/interface.IRegistry.md), [Context](/src/flattened/Office.flattened.sol/abstract.Context.md)

**Author:**
Chinmay <chinmay@dhedge.org>

Tokenization as inspired by ERC6909.

*May not be fully compliant with the ERC6909 standard because of the following reasons:
- The `transferFrom` function does not allow transferring isolated account tokens by operators
unless the caller explicitly approved them.
- The operator scope is not limited to transfers but allows full market functions' access except for transferring
the account itself.
- The `approve` function does not allow approving debt tokens.*


## Functions
### approve

*Implicitly uses the caller's and spender's user accounts.*


```solidity
function approve(address spender, uint256 tokenId, uint256 amount) external virtual override returns (bool success);
```

### transfer

For isolated account transfers, the `amount` must be 1.

*Implicitly uses the caller's and receiver's user accounts.*


```solidity
function transfer(address receiver, uint256 tokenId, uint256 amount) external virtual returns (bool success);
```

### transferFrom

*Implicitly uses the caller's and receiver's user accounts.*


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

*Implicitly uses the caller's user account.*


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

*Implicitly uses the caller's user account.*


```solidity
function balanceOf(address owner, uint256 id) external view returns (uint256 balance);
```

### totalSupply


```solidity
function totalSupply(uint256 id) public view virtual returns (uint256 supply);
```

### allowance

*Implicitly uses the owner's and spender's user account.*


```solidity
function allowance(address owner, address spender, uint256 id) external view returns (uint256 remaining);
```

### isOperator

*Provides temporary operator access to the delegatee in a delegation call context.*


```solidity
function isOperator(address owner, address spender) public view virtual returns (bool approved);
```

### supportsInterface

*Returns `true` if `interfaceId` is that of IERC6909 or IERC165.*


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool isSupported);
```

### createIsolatedAccount

*Creates a new isolated account with the given `newOwner`.*


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

*Implicitly uses the caller's and spender's user accounts.*


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

### transferFrom

*Implicitly uses the caller's and receiver's user accounts.*


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

### setOperator

Provides authorization to invoke market functions on behalf of the `spender`.

*Implicitly uses the caller's user account.*


```solidity
function setOperator(address operator, AccountId account, bool approved) public virtual returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`||
|`account`|`AccountId`||
|`approved`|`bool`|Whether the operator is approved or not.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|Returns true if the operation was successful.|


### _mint

*Creates `amount` of token `tokenId` and assigns them to `account`, by transferring it from ACCOUNT_ID_ZERO.
Relies on the `_update` mechanism.
Emits a {Transfer} event with `from` set to the zero AccountId.
NOTE: This function is not virtual, {_update} should be overridden instead.*


```solidity
function _mint(AccountId to, uint256 tokenId, uint256 amount) internal;
```

### _transfer

*Moves `amount` of token `tokenId` from `from` to `to` without checking for approvals. This function
verifies
that neither the sender nor the receiver are ACCOUNT_ID_ZERO, which means it cannot mint or burn tokens.
Relies on the `_update` mechanism.
Emits a {Transfer} event.
NOTE: This function is not virtual, {_update} should be overridden instead.*


```solidity
function _transfer(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal;
```

### _burn

*Destroys a `amount` of token `tokenId` from `account`.
Relies on the `_update` mechanism.
Emits a {Transfer} event with `to` set to the zero AccountId.
NOTE: This function is not virtual, {_update} should be overridden instead*


```solidity
function _burn(AccountId from, uint256 tokenId, uint256 amount) internal;
```

### _update

*Transfers `amount` of token `tokenId` from `from` to `to`, or alternatively mints (or burns) if `from`
(or `to`) is the zero AccountId. All customizations to transfers, mints, and burns should be done by overriding
this function.
Emits a {Transfer} event.*


```solidity
function _update(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal virtual;
```

### _approve

*Sets `amount` as the allowance of `spender` over the `from`'s `tokenId` tokens.
This internal function is equivalent to `approve`, and can be used to e.g. set automatic allowances for certain
subsystems, etc.
Emits an {Approval} event.
Requirements:
- `from` cannot be the zero AccountId.
- `spender` cannot be the zero AccountId.
- `tokenId` cannot be a debt token.
> [!WARNING]
> - This function does not check if `currentOwner` is the zero address given that the only other place
it is used is in the `approve` function which already checks for it.
> - This function does not check if the `tokenId` actually exists. As long as it's in the correct format
(i.e., is encoded as a valid token Id), it will be accepted.
> - Could be breaking the ERC6909 standard given debt token approval is not allowed.*


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

*Approve `operator` to operate on all of `owner`'s tokens*

*This internal function is equivalent to `setOperator`, and can be used to e.g. set automatic allowances for
certain subsystems, etc.
Emits an {OperatorSet} event.
Requirements:
- `owner` cannot be the zero address.
- `operator` cannot be the zero address.*


```solidity
function _setOperator(address owner, AccountId account, address operator, bool approved) internal virtual;
```

### _spendAllowance

*Updates `from`'s allowance for `spender` based on spent `amount`.
- Does not update the allowance value in case of infinite allowance.
- Revert if not enough allowance is available.
- Does not emit an {Approval} event.*


```solidity
function _spendAllowance(
    address currentOwner,
    AccountId from,
    AccountId spender,
    uint256 tokenId,
    uint256 amount
)
    internal
    virtual;
```

### ownerOf

Returns the owner of the `account`.

*Reverts if the `account` is not created.*


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

*Provides temporary operator access to the delegatee in a delegation call context.*


```solidity
function isOperator(AccountId account, address operator) public view virtual returns (bool approved);
```

### balanceOf

*Implicitly uses the caller's user account.*


```solidity
function balanceOf(AccountId account, uint256 tokenId) public view virtual returns (uint256 balance);
```

### allowance

*Implicitly uses the owner's and spender's user account.*


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

### getDebtId

Returns the debt token ID for a given market and user.

*Implicitly converts `owner` address to user account.*


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

Returns the debt token ID for a given market and user.

*Implicitly converts `owner` address to user account.*


```solidity
function getDebtId(AccountId account, MarketId market) public view returns (uint256 debtId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`||
|`market`|`MarketId`|The market ID of the market.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`debtId`|`uint256`|The debt token ID for the account in the market.|


### getAllCollateralIds

Returns the collateral token IDs for a given market and owner.

*Implicitly converts `owner` address to user account.*


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

Returns the collateral token IDs for a given market and owner.

*Implicitly converts `owner` address to user account.*


```solidity
function getAllCollateralIds(AccountId account, MarketId market) public view returns (uint256[] memory collateralIds);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`||
|`market`|`MarketId`|The market ID of the market.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralIds`|`uint256[]`|Array of collateral token IDs.|


## Structs
### AccountsStorageStruct
**Note:**
storage-location: erc7201:DYTM.storage.Accounts


```solidity
struct AccountsStorageStruct {
    uint96 accountCount;
    mapping(AccountId account => address owner) ownerOf;
    mapping(uint256 tokenId => uint256 supply) totalSupplies;
    mapping(address owner => OwnerSpecificData data) ownerData;
    mapping(AccountId account => mapping(uint256 tokenId => uint256 amount)) balances;
    mapping(AccountId account => mapping(MarketId market => TokensData tokens)) marketWiseData;
}
```

### OwnerSpecificData

```solidity
struct OwnerSpecificData {
    mapping(AccountId account => mapping(address operator => bool isApproved)) operatorApprovals;
    mapping(AccountId account => mapping(uint256 tokenId => mapping(AccountId spender => uint256 amount))) allowances;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`operatorApprovals`|`mapping(AccountId account => mapping(address operator => bool isApproved))`|Owner specific mapping of operator approvals per account.|
|`allowances`|`mapping(AccountId account => mapping(uint256 tokenId => mapping(AccountId spender => uint256 amount)))`|Owner specific mapping of allowances per account and tokenId.|

