# IOffice
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

**Author:**
Chinmay <chinmay@dhedge.org>

Main Office contract interface.

*Note that certain functions have the `extraData` parameter which is not used by the Office contract
directly but are passed to the hooks contract if:
- it is not address(0)
- if the hooks contract has subscribed to the hooks.*


## Functions
### createMarket

Function to create a new market.
Call will revert if the market already exists or the params are invalid.


```solidity
function createMarket(address officer, IMarketConfig marketConfig) external returns (MarketId marketId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`officer`|`address`|The address of the officer of the new market.|
|`marketConfig`|`IMarketConfig`|The market configuration contract for the new market.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`marketId`|`MarketId`|The Id of the newly created market.|


### delegationCall

Function to perform multiple calls on behalf of an account.
The delegatee must implement the `IDelegatee` interface and must be able to handle the `onDelegationCallback`
function.
> [!WARNING]
>  - This function temporarily grants the delegatee operator access to all the callers' authorized accounts.
>  - Health checks for the accounts involved in the delegation call are performed only after the call if necessary.


```solidity
function delegationCall(DelegationCallParams calldata params) external returns (bytes memory returnData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`DelegationCallParams`|The parameters for the delegation call in the form of a `DelegationCallParams` struct.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`returnData`|`bytes`|The return data from the delegatee's `onDelegationCallback` function.|


### supply

Function to deposit loan asset into a market.
- Anyone can supply tokens for an account even if the account is not created yet.
- One can lend a supported asset even if the the asset is not borrowable. If it is enabled for borrowing,
interest will start accruing automatically.
> [!WARNING]
If supplying for a non-existent account which the caller assumes will be theirs in the next transaction, make sure you consider front-running risk as
you may end up supplying tokens for an account that belongs to someone else.


```solidity
function supply(SupplyParams calldata params) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`SupplyParams`|The parameters for supplying tokens in the form of a `SupplyParams` struct.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares minted for the supplied amount.|


### switchCollateral

Function to switch a collateral from escrow to lending market or vice versa.
- Although the same can be achieved by withdrawing and then supplying the asset
using `delegationCall`, this function is more gas efficient and easier to use as it doesn't transfer assets.


```solidity
function switchCollateral(SwitchCollateralParams calldata params) external returns (uint256 assets, uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`SwitchCollateralParams`|The parameters for switching collateral in the form of a `SwitchCollateralParams` struct.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets switched from escrow to lending market or vice versa.|
|`shares`|`uint256`|The new amount of shares minted for the `assets`.|


### withdraw

Function to withdraw an asset from a market.
- Allows only authorized callers of the account to withdraw assets.
- Will revert if the account is unhealthy after withdrawal.


```solidity
function withdraw(WithdrawParams calldata params) external returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`WithdrawParams`|The parameters for withdrawing tokens in the form of a `WithdrawParams` struct.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets withdrawn from the market.|


### borrow

Function to borrow an asset from a market and then escrow some asset(s) in the account.
- Allows users to take out an undercollateralized loan before escrowing/lending asset(s) to
meet the required health check condition via `delegationCall`.
- Operators of an account can invoke this function.


```solidity
function borrow(BorrowParams calldata params) external returns (uint256 debtShares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`BorrowParams`|The parameters for borrowing in the form of `BorrowParams` struct|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`debtShares`|`uint256`|The amount of debt shares created for the borrowed amount.|


### repay

Function to repay a debt position in a market.
- Allows authorized callers of the account to repay the debt.
- Will revert if the account is unhealthy after withdrawal.


```solidity
function repay(RepayParams calldata params) external returns (uint256 assetsRepaid);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`RepayParams`|The parameters for repaying tokens in the form of a `RepayParams` struct.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assetsRepaid`|`uint256`|The amount of assets worth of debt repaid in the market.|


### liquidate

Function to liquidate an unhealthy account in a market.
- Allows anyone to liquidate an unhealthy account.
- The liquidator must calculate the collateral shares to liquidate for partial or full liquidation.
- The liquidator must approve enough debt asset amount to the Office for repayment.
> [!WARNING]
> - Regardless of bad debt accrual, the liquidator will always receive a bonus.
> - To change this behaviour, the officer can change the bonus percentage to 0 using the before liquidation hook.
However, this will make the job of liquidators harder as they need to calculate the exact amount of
shares/assets to liquidate after the bonus percentage modification.


```solidity
function liquidate(LiquidationParams calldata params) external returns (uint256 assetsRepaid);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`LiquidationParams`|The parameters for liquidation in the form of a `LiquidationParams` struct.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assetsRepaid`|`uint256`|The amount of assets worth of debt repaid in the market.|


### migrateSupply

Function to migrate supply from one market to another.
- The asset being migrated must be the same and accepted in the new market.


```solidity
function migrateSupply(MigrateSupplyParams calldata params)
    external
    returns (uint256 assetsRedeemed, uint256 newSharesMinted);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`MigrateSupplyParams`|The parameters for migrating supply in the form of a `MigrateSupplyParams` struct.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assetsRedeemed`|`uint256`|The amount of assets redeemed from the old market.|
|`newSharesMinted`|`uint256`|The amount of new shares minted in the new market.|


### donateToReserve

Function to split an account into two accounts.
- Creates a new isolated account that gets a portion of the debt asset and collateral assets.
- The original account retains the remaining portion of the assets.
- Particularly useful for vaults which don't want to maintain instant withdrawal liquidity and to ease withdrawals.
- Only the original account's health is checked before splitting given that the portion receiver will always be a new account
and a proportional split will not affect the original account's health.
> [!WARNING]
> If the market values health of accounts differently (for example using hooks),
> then use the function hook(s) to determine the health after the split.

Function to donate to a lending reserve of a market.
- This function increases the `supplied` amount of the reserve.
- Can only be called by the officer of the market.
- Doesn't check if the asset of the reserve is borrowable or not.
- Once donated, the assets can't be clawed back.
- Can't donate if reserve `supplied` amount is 0.
- It's possible to donate to a reserve whose `supplied` amount is not 0 but is currently
not supported.


```solidity
function donateToReserve(ReserveKey key, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key for which the donation is being made.|
|`amount`|`uint256`|The amount of the token to be donated to the reserve.|


### flashloan

Function to perform a flashloan.
- The receiver must implement the `IFlashloanReceiver` interface and must
be able to handle the `onFlashloanCallback` function.
- The receiver must also approve the Office contract to transfer the borrowed amount back.


```solidity
function flashloan(IERC20 token, uint256 amount, bytes calldata callbackData) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`IERC20`|The token to be borrowed in the flashloan.|
|`amount`|`uint256`|The amount of the token to be borrowed in the flashloan.|
|`callbackData`|`bytes`|Additional data that can be used by the receiver.|


### accrueInterest

Function to accrue interest for a reserve.
- No effect if the reserve is not borrowable.


```solidity
function accrueInterest(ReserveKey key) external returns (uint256 interest);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key for which the reserves are being updated.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`interest`|`uint256`|The amount of interest accrued for the borrowers of the reserve since the last update.|


### isHealthyAccount

Checks if the `account` is healthy for a debt position in a `market`.
- If the `account` has no debt position in the market, it's considered healthy even if
the account has no collateral in the market.
- If the weighted collaterals' value in USD is less than (necessary conditions):
- the debt value in USD for the market
- the minimum margin amount in USD for the market
then the account is considered unhealthy.


```solidity
function isHealthyAccount(AccountId account, MarketId market) external view returns (bool isHealthy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID to check.|
|`market`|`MarketId`|The market ID to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isHealthy`|`bool`|True if the account is healthy, false otherwise.|


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


## Events
### Office__AssetDonated

```solidity
event Office__AssetDonated(ReserveKey indexed key, uint256 assets);
```

### Office__PerformanceFeeMinted

```solidity
event Office__PerformanceFeeMinted(ReserveKey indexed key, uint256 shares);
```

### Office__AssetBorrowed

```solidity
event Office__AssetBorrowed(AccountId indexed account, ReserveKey indexed key, uint256 assets);
```

### Office__AssetFlashloaned

```solidity
event Office__AssetFlashloaned(address indexed receiver, IERC20 indexed token, uint256 assets);
```

### Office__AssetSupplied

```solidity
event Office__AssetSupplied(AccountId indexed account, uint256 indexed tokenId, uint256 shares, uint256 assets);
```

### Office__MarketCreated

```solidity
event Office__MarketCreated(address indexed officer, IMarketConfig indexed marketConfig, MarketId indexed market);
```

### Office__CollateralSwitched

```solidity
event Office__CollateralSwitched(
    AccountId indexed account, uint256 indexed fromTokenId, uint256 oldShares, uint256 newShares, uint256 assets
);
```

### Office__AssetWithdrawn

```solidity
event Office__AssetWithdrawn(
    AccountId indexed account, address indexed receiver, uint256 indexed tokenId, uint256 shares, uint256 assets
);
```

### Office__DebtRepaid

```solidity
event Office__DebtRepaid(
    AccountId indexed account, address indexed repayer, ReserveKey indexed key, uint256 shares, uint256 assets
);
```

### Office__AccountSplit

```solidity
event Office__AccountSplit(
    AccountId indexed originalAccount,
    AccountId indexed newAccount,
    MarketId indexed market,
    address receiver,
    uint256 fraction
);
```

### Office__SupplyMigrated

```solidity
event Office__SupplyMigrated(
    AccountId indexed account,
    uint256 indexed fromTokenId,
    uint256 indexed toTokenId,
    uint256 assetsRedeemed,
    uint256 newSharesMinted
);
```

### Office__AccountLiquidated

```solidity
event Office__AccountLiquidated(
    AccountId indexed account,
    address indexed liquidator,
    MarketId indexed market,
    uint256 repaidShares,
    uint256 repaidAssets,
    uint256 unpaidShares,
    uint256 unpaidAssets
);
```

## Errors
### Office__ReserveIsEmpty

```solidity
error Office__ReserveIsEmpty(ReserveKey key);
```

### Office__IncorrectTokenId

```solidity
error Office__IncorrectTokenId(uint256 tokenId);
```

### Office__AssetNotBorrowable

```solidity
error Office__AssetNotBorrowable(ReserveKey key);
```

### Office__ReserveNotSupported

```solidity
error Office__ReserveNotSupported(ReserveKey key);
```

### Office__InvalidHooksContract

```solidity
error Office__InvalidHooksContract(address hooks);
```

### Office__AccountNotCreated

```solidity
error Office__AccountNotCreated(AccountId account);
```

### Office__InsufficientLiquidity

```solidity
error Office__InsufficientLiquidity(ReserveKey key);
```

### Office__CannotLiquidateDuringDelegationCall

```solidity
error Office__CannotLiquidateDuringDelegationCall();
```

### Office__InvalidFraction

```solidity
error Office__InvalidFraction(uint64 givenFraction);
```

### Office__AccountNotHealthy

```solidity
error Office__AccountNotHealthy(AccountId account, MarketId market);
```

### Office__NotAuthorizedCaller

```solidity
error Office__NotAuthorizedCaller(AccountId account, address caller);
```

### Office__AccountStillHealthy

```solidity
error Office__AccountStillHealthy(AccountId account, MarketId market);
```

