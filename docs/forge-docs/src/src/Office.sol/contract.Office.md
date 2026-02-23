# Office
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/Office.sol)

**Inherits:**
[IOffice](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IOffice.sol/interface.IOffice.md), [OfficeStorage](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/abstracts/storages/OfficeStorage.sol/abstract.OfficeStorage.md), [Context](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/abstracts/storages/Context.sol/abstract.Context.md), [Registry](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/abstracts/Registry.sol/abstract.Registry.md), [TransientEnumerableHashTableStorage](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/abstracts/storages/TransientEnumerableHashTableStorage.sol/abstract.TransientEnumerableHashTableStorage.md)

**Title:**
Office

**Author:**
Chinmay <chinmay@dhedge.org>

Core contract of the DYTM protocol.


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
function delegationCall(DelegationCallParams calldata params)
    external
    useContext(params.delegatee)
    returns (bytes memory returnData);
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
- Anyone can supply tokens for an account even if the account is not yet created
- One can lend a supported asset even if the the asset is not borrowable. If it is enabled for borrowing,
interest will start accruing automatically. However, this collateral may not be considered for borrowing
until the appropriate weights are set by the officer.
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
> [!WARNING]
> The function doesn't check the health of the account after this action given that the collateral
> value remains the same. However, if the market values the escrowed and lent assets
> differently (due to difference in weights), the account health has to be checked using appropriate hooks.


```solidity
function switchCollateral(SwitchCollateralParams calldata params)
    external
    onlyAuthorizedCaller(params.account)
    returns (uint256 assets, uint256 shares);
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
function withdraw(WithdrawParams calldata params)
    external
    onlyAuthorizedCaller(params.account)
    returns (uint256 assets);
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
- Will revert if:
- The account is unhealthy after borrowing.
- The asset address provided is not borrowable in the market.
- The account already has a debt in an asset and is trying to borrow a different asset.


```solidity
function borrow(BorrowParams calldata params)
    external
    onlyAuthorizedCaller(params.account)
    returns (uint256 debtShares);
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
- Allows repayment using collateral shares of the same asset as the debt asset.


```solidity
function repay(RepayParams calldata params)
    external
    onlyAuthorizedCaller(params.account)
    returns (uint256 assetsRepaid);
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
    onlyAuthorizedCaller(params.account)
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

Function to donate to a lending reserve of a market.
- This function increases the `supplied` amount of the reserve.
- Can only be called by the officer of the market.
- Doesn't check if the asset of the reserve is borrowable or not.
- Once donated, the assets can't be clawed back.
- Can't donate if reserve `supplied` amount is 0.
- It's possible to donate to a reserve whose `supplied` amount is not 0 but is currently
not supported.


```solidity
function donateToReserve(ReserveKey key, uint256 assets) external onlyOfficer(key.getMarketId());
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key for which the donation is being made.|
|`assets`|`uint256`||


### flashloan

Function to perform a flashloan.
- The receiver must implement the `IFlashloanReceiver` interface and must
be able to handle the `onFlashloanCallback` function.
- The receiver must also approve the Office contract to transfer the borrowed amount back.


```solidity
function flashloan(IERC20 token, uint256 assets, bytes calldata callbackData) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`IERC20`|The token to be borrowed in the flashloan.|
|`assets`|`uint256`||
|`callbackData`|`bytes`|Additional data that can be used by the receiver.|


### accrueInterest

Function to accrue interest for a reserve.
- No effect if the reserve is not borrowable.


```solidity
function accrueInterest(ReserveKey key) public returns (uint256 interest);
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
function isHealthyAccount(AccountId account, MarketId market) public view returns (bool isHealthy);
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


### _supply

Internal function to supply assets to the Office contract.
- This function checks if the `tokenId` is a valid collateral token.
- This function DOES NOT check if the `tokenId` is accepted in the market.


```solidity
function _supply(
    IMarketConfig marketConfig,
    uint256 tokenId,
    AccountId account,
    uint256 assets
)
    internal
    returns (uint256 shares);
```

### _withdraw

Internal function to withdraw assets from the Office contract.
- This function DOES NOT check if the account will be healthy after the withdrawal.
- Exactly one of `assets` or `shares` must be non-zero.
- Guarantees that `assets` worth of shares will be withdrawn if `assets` is non-zero.
Otherwise, the transaction will revert.


```solidity
function _withdraw(
    IMarketConfig marketConfig,
    AccountId account,
    uint256 tokenId,
    uint256 assets,
    uint256 shares
)
    internal
    returns (uint256 assetsWithdrawn, uint256 sharesRedeemed);
```

### _accrueInterest

This function WILL NOT revert even if the asset is not borrowable.


```solidity
function _accrueInterest(ReserveKey key, IMarketConfig marketConfig) internal returns (uint256 interest);
```

### _update

Overriden to ensure that it:
- Checks the health of the `from` account after transferring collateral tokens out.
- Checks the health of the `to` account after transferring debt tokens in.
- Allows an authorized caller to transfer debt tokens between `from` and `to` accounts.
- Checks if `shares` of `tokenId` can be transferred between `from` and `to` accounts as per market config.
- [!WARNING] Doesn't prevent minting/redemption of shares even if the account is explicitly restricted
from transferring/receiving shares.


```solidity
function _update(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal override;
```

### _checkHealth

Checks if the account is healthy after a market operation.
If the ongoing call is a delegation call, we defer the health checks.


```solidity
function _checkHealth(AccountId account, MarketId market) internal;
```

