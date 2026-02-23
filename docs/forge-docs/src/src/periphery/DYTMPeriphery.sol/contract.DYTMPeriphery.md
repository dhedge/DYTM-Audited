# DYTMPeriphery
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/periphery/DYTMPeriphery.sol)

**Title:**
DYTMPeriphery

**Author:**
Chinmay <chinmay@dhedge.org>

Periphery contract providing helper functions for DYTM protocol integrations and frontend purposes.

This contract provides read-only helper functions that are not part of the core protocol
but are useful for integrators, frontends, and external applications.
Note that the functions may modify state and hence use `eth_call`/`simulateContract` (in viem)
to invoke them off-chain.


## State Variables
### OFFICE
The main Office contract.


```solidity
Office public immutable OFFICE
```


## Functions
### constructor

Constructor to initialize the periphery contract.


```solidity
constructor(Office _office) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_office`|`Office`|The address of the main Office contract.|


### getAccountPosition

Get complete position information for an account in a market.


```solidity
function getAccountPosition(AccountId account, MarketId market) public returns (AccountPosition memory position);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account to query.|
|`market`|`MarketId`|The market to query.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`position`|`AccountPosition`|Complete position information.|


### getAccountDebtValueUSD

Get debt value for an account in USD.


```solidity
function getAccountDebtValueUSD(AccountId account, MarketId market) external returns (uint256 debtValueUSD);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account to query.|
|`market`|`MarketId`|The market to query.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`debtValueUSD`|`uint256`|The total debt value in USD (in WAD).|


### getAccountCollateralValueUSD

Get collateral value for an account in USD.


```solidity
function getAccountCollateralValueUSD(
    AccountId account,
    MarketId market
)
    external
    returns (uint256 totalValueUSD, uint256 weightedValueUSD);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account to query.|
|`market`|`MarketId`|The market to query.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalValueUSD`|`uint256`|The total collateral value in USD (in WAD).|
|`weightedValueUSD`|`uint256`|The total weighted collateral value in USD (in WAD).|


### getReserveInfo

Get comprehensive information about a reserve.


```solidity
function getReserveInfo(ReserveKey key) external returns (ReserveInfo memory info);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`info`|`ReserveInfo`|Complete reserve information.|


### sharesToAssets

Convert shares to assets for a given token.


```solidity
function sharesToAssets(uint256 tokenId, uint256 shares) public returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID.|
|`shares`|`uint256`|The amount of shares.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The equivalent amount of assets.|


### assetsToShares

Convert assets to shares for a given token.


```solidity
function assetsToShares(uint256 tokenId, uint256 assets) public returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID.|
|`assets`|`uint256`|The amount of assets.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The equivalent amount of shares.|


### getExchangeRate

Get the current exchange rate for a token (assets per unit of shares).


```solidity
function getExchangeRate(uint256 tokenId) public returns (uint256 exchangeRate);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`exchangeRate`|`uint256`|The exchange rate in underlying asset decimal terms.|


### _getDebtInfo

Get debt information for an account.


```solidity
function _getDebtInfo(
    AccountId account,
    MarketId market,
    IOracleModule oracleModule
)
    internal
    returns (DebtInfo memory debt);
```

### _getCollateralInfo

Get collateral information for an account.


```solidity
function _getCollateralInfo(
    AccountId account,
    MarketId market,
    IOracleModule oracleModule,
    IWeights weights,
    ReserveKey debtKey
)
    internal
    returns (CollateralInfo[] memory collaterals);
```

### _sharesToAssetsDebt

Convert shares to assets for debt tokens.


```solidity
function _sharesToAssetsDebt(uint256 debtTokenId, uint256 shares) internal returns (uint256 assets);
```

### _assetsToSharesDebt

Convert assets to shares for debt tokens.


```solidity
function _assetsToSharesDebt(uint256 debtTokenId, uint256 assets) internal returns (uint256 shares);
```

### _sharesToAssetsCollateral

Convert shares to assets for collateral tokens.


```solidity
function _sharesToAssetsCollateral(uint256 tokenId, uint256 shares) internal returns (uint256 assets);
```

### _assetsToSharesCollateral

Convert assets to shares for collateral tokens.


```solidity
function _assetsToSharesCollateral(uint256 tokenId, uint256 assets) internal returns (uint256 shares);
```

### _getTotalCollateralAndWeightedValueUSD

Calculate total collateral and weighted value in USD.


```solidity
function _getTotalCollateralAndWeightedValueUSD(CollateralInfo[] memory collaterals)
    internal
    pure
    returns (uint256 totalValueUSD, uint256 totalWeightedValueUSD);
```

## Errors
### DYTMPeriphery__ZeroAddress

```solidity
error DYTMPeriphery__ZeroAddress();
```

## Structs
### DebtInfo
Struct containing account's debt information.


```solidity
struct DebtInfo {
    uint256 debtShares;
    uint256 debtAssets;
    uint256 debtValueUSD;
    ReserveKey debtKey;
    IERC20 debtAsset;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`debtShares`|`uint256`|The amount of debt shares held by the account.|
|`debtAssets`|`uint256`|The amount of debt assets (underlying tokens) owed by the account.|
|`debtValueUSD`|`uint256`|The USD value of the debt.|
|`debtKey`|`ReserveKey`|The reserve key identifying the debt asset.|
|`debtAsset`|`IERC20`|The ERC20 token interface for the debt asset.|

### CollateralInfo
Struct containing collateral information.


```solidity
struct CollateralInfo {
    uint256 tokenId;
    uint256 shares;
    uint256 assets;
    uint256 valueUSD;
    uint256 weightedValueUSD;
    uint64 weight;
    ReserveKey key;
    IERC20 asset;
    TokenType tokenType;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The unique token ID for the collateral.|
|`shares`|`uint256`|The amount of collateral shares held by the account.|
|`assets`|`uint256`|The amount of collateral assets (underlying tokens).|
|`valueUSD`|`uint256`|The USD value of the collateral.|
|`weightedValueUSD`|`uint256`|The weighted USD value of the collateral (valueUSD * weight).|
|`weight`|`uint64`|The weight assigned to this collateral.|
|`key`|`ReserveKey`|The reserve key identifying the collateral asset.|
|`asset`|`IERC20`|The ERC20 token interface for the collateral asset.|
|`tokenType`|`TokenType`|The type of token (LEND, ESCROW, etc.).|

### AccountPosition
Struct containing account's complete position information.


```solidity
struct AccountPosition {
    DebtInfo debt;
    CollateralInfo[] collaterals;
    uint256 totalCollateralValueUSD;
    uint256 totalWeightedCollateralValueUSD;
    uint256 healthFactor;
    bool isHealthy;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`debt`|`DebtInfo`|The debt information for the account.|
|`collaterals`|`CollateralInfo[]`|Array of collateral information for the account.|
|`totalCollateralValueUSD`|`uint256`|The total USD value of all collaterals.|
|`totalWeightedCollateralValueUSD`|`uint256`|The total weighted USD value of all collaterals.|
|`healthFactor`|`uint256`|The health factor of the position (WAD). Values > 1e18 indicate healthy positions.|
|`isHealthy`|`bool`|Boolean indicating if the account is healthy.|

### ReserveInfo
Struct for reserve information.


```solidity
struct ReserveInfo {
    IERC20 asset;
    uint256 supplied;
    uint256 borrowed;
    uint256 availableLiquidity;
    uint256 utilizationRate;
    uint256 supplyRate;
    uint256 borrowRate;
    uint256 totalSupplyShares;
    uint256 totalBorrowShares;
    uint256 exchangeRateSupply;
    uint256 exchangeRateBorrow;
    uint128 lastUpdateTimestamp;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`IERC20`|The ERC20 token interface for the reserve asset.|
|`supplied`|`uint256`|The total amount of assets supplied to this reserve.|
|`borrowed`|`uint256`|The total amount of assets borrowed from this reserve.|
|`availableLiquidity`|`uint256`|The amount of assets available for borrowing (supplied - borrowed).|
|`utilizationRate`|`uint256`|The current utilization rate of the reserve (borrowed / supplied).|
|`supplyRate`|`uint256`|The current annual supply rate for lenders.|
|`borrowRate`|`uint256`|The current annual borrow rate for borrowers.|
|`totalSupplyShares`|`uint256`|The total supply shares outstanding for this reserve.|
|`totalBorrowShares`|`uint256`|The total borrow shares outstanding for this reserve.|
|`exchangeRateSupply`|`uint256`|The current exchange rate for supply shares (assets per share).|
|`exchangeRateBorrow`|`uint256`|The current exchange rate for borrow shares (assets per share).|
|`lastUpdateTimestamp`|`uint128`|The timestamp when this reserve was last updated.|

