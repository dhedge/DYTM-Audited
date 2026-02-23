# DefaultMarketConfig
[Git Source](https://github.com/dhedge/DYTM/blob/b861f88620abe965bc87fe355cbb9cb461faa9b9/src/helpers/DefaultMarketConfig.sol)

**Inherits:**
[IMarketConfig](/src/interfaces/IMarketConfig.sol/interface.IMarketConfig.md), Ownable

**Author:**
Chinmay <chinmay@dhedge.org>

A simple implementation for the market configuration contract.


## State Variables
### irm
The Interest Rate Model (IRM) for the market.

*MUST NOT be null address.*


```solidity
IIRM public irm;
```


### hooks
The Hooks contract for the market.

*MAY BE null address if no hooks are used.*


```solidity
IHooks public hooks;
```


### weights
The Weights contract for the market.

*MUST NOT be null address.*


```solidity
IWeights public weights;
```


### oracleModule
The Oracle Module for the market.

*MUST NOT be null address.*


```solidity
IOracleModule public oracleModule;
```


### feeRecipient
The recipient of the performance fees for the market.

*MAY BE null address only if `feePercentage` is zero.*


```solidity
address public feeRecipient;
```


### feePercentage
The percentage of the performance fee for the market.

*- MAY BE zero.
- MUST BE in the range of 0 to 1e18 (WAD units).*


```solidity
uint64 public feePercentage;
```


### liquidationBonusPercentage
The liquidation bonus percentage for liquidators in the market.

*MUST BE in the range of 0 to 1e18 (WAD units).*


```solidity
uint64 public liquidationBonusPercentage;
```


### minMarginAmountUSD
The minimum margin amount in USD for the market.

*- MUST BE in WAD units (e.g. $1 = 1e18).
- MAY BE zero.*


```solidity
uint128 public minMarginAmountUSD;
```


### _assets
*- Enumerable mapping containing the supported assets and their borrowable status.
- Maps asset address to its borrowable status (0 = not borrowable, 1 = borrowable).*


```solidity
EnumerableMap.AddressToUintMap private _assets;
```


## Functions
### constructor


```solidity
constructor(address initialOwner, ConfigInitParams memory initParams) Ownable(initialOwner);
```

### isSupportedAsset

Checks if the asset is supported.

*MUST NOT revert if the asset is not supported.*


```solidity
function isSupportedAsset(IERC20 asset) external view returns (bool isSupported);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`IERC20`|The asset to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isSupported`|`bool`|`true` if the asset is supported, `false` otherwise.|


### isBorrowableAsset

Checks if the asset is borrowable.

*MUST NOT revert if the asset is not supported and/or not borrowable.*


```solidity
function isBorrowableAsset(IERC20 asset) external view returns (bool isBorrowable);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`IERC20`|The asset to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isBorrowable`|`bool`|`true` if the asset is borrowable, `false` otherwise.|


### getAssetConfigs

Gets all asset configurations.

*Supposed to be used for frontend purposes.*


```solidity
function getAssetConfigs() external view returns (AssetConfig[] memory configs);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`configs`|`AssetConfig[]`|An array of `AssetConfig` structs containing the asset and its borrowable status.|


### setPerformanceFee

Function to set performance fee for the entire market.

*The fee percentage should be in the range of 0 to 1e18 (WAD).*


```solidity
function setPerformanceFee(uint64 newFeePercentage) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFeePercentage`|`uint64`|The new performance fee percentage to set.|


### addSupportedAssets

Sets supported assets for the market.

*If the asset is already in the market, it will only change its borrowable status.*


```solidity
function addSupportedAssets(AssetConfig[] calldata assetsConfig) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assetsConfig`|`AssetConfig[]`|An array of `AssetConfig` structs containing the asset and its borrowable status.|


### removeSupportedAssets

Removes supported assets from the market.

*If the asset is not in the market, it will simply do nothing.*


```solidity
function removeSupportedAssets(address[] calldata assets) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`address[]`|An array of asset addresses to remove from the market.|


### setFeeRecipient

Sets the fee recipient for the market.

*Once set, the fee recipient cannot be set to zero address.*


```solidity
function setFeeRecipient(address newFeeRecipient) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFeeRecipient`|`address`|The address of the new fee recipient.|


### setIRM

Sets the interest rate model for the market.


```solidity
function setIRM(IIRM newIrm) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newIrm`|`IIRM`|The address of the new interest rate model.|


### setHooks

Sets the new hooks contract for the market.


```solidity
function setHooks(IHooks newHooks) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newHooks`|`IHooks`|The address of the new hooks contract.|


### setWeights

Sets the new weights contract for the market.


```solidity
function setWeights(IWeights newWeights) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newWeights`|`IWeights`|The address of the new weights contract.|


### setOracleModule

Sets the new oracle module for the market.


```solidity
function setOracleModule(IOracleModule newOracleModule) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOracleModule`|`IOracleModule`|The address of the new oracle module.|


### setLiquidationBonusPercentage

Sets the liquidation bonus percentage for the market.

*The percentage should be in the range of 0 to 1e18 (WAD).*


```solidity
function setLiquidationBonusPercentage(uint64 newBonusPercentage) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newBonusPercentage`|`uint64`|The new liquidation bonus percentage to set.|


### setMinMarginAmountUSD


```solidity
function setMinMarginAmountUSD(uint128 newMinMarginAmountUSD) external onlyOwner;
```

### _setMarketParams


```solidity
function _setMarketParams(ConfigInitParams memory initParams) internal;
```

## Events
### DefaultMarketConfig__IrmModified

```solidity
event DefaultMarketConfig__IrmModified(IIRM newIrm, IIRM oldIrm);
```

### DefaultMarketConfig__MarketAssetsRemoved

```solidity
event DefaultMarketConfig__MarketAssetsRemoved(address[] assets);
```

### DefaultMarketConfig__MarketParamsSet

```solidity
event DefaultMarketConfig__MarketParamsSet(ConfigInitParams params);
```

### DefaultMarketConfig__MarketAssetsSet

```solidity
event DefaultMarketConfig__MarketAssetsSet(AssetConfig[] assetsConfig);
```

### DefaultMarketConfig__HooksModified

```solidity
event DefaultMarketConfig__HooksModified(IHooks newHooks, IHooks oldHooks);
```

### DefaultMarketConfig__WeightsModified

```solidity
event DefaultMarketConfig__WeightsModified(IWeights newWeights, IWeights oldWeights);
```

### DefaultMarketConfig__FeeRecipientModified

```solidity
event DefaultMarketConfig__FeeRecipientModified(address newFeeRecipient, address oldFeeRecipient);
```

### DefaultMarketConfig__PerformanceFeeModified

```solidity
event DefaultMarketConfig__PerformanceFeeModified(uint64 newPercentageFee, uint64 oldPercentageFee);
```

### DefaultMarketConfig__OracleModuleModified

```solidity
event DefaultMarketConfig__OracleModuleModified(IOracleModule newOracleModule, IOracleModule oldOracleModule);
```

### DefaultMarketConfig__MinMarginAmountUSDModified

```solidity
event DefaultMarketConfig__MinMarginAmountUSDModified(uint128 newMinMarginAmountUSD, uint128 oldMinMarginAmountUSD);
```

### DefaultMarketConfig__LiquidationBonusPercentageModified

```solidity
event DefaultMarketConfig__LiquidationBonusPercentageModified(uint64 newBonusPercentage, uint64 oldBonusPercentage);
```

## Errors
### DefaultMarketConfig__ZeroAddress

```solidity
error DefaultMarketConfig__ZeroAddress();
```

### DefaultMarketConfig__ParamsNotSet

```solidity
error DefaultMarketConfig__ParamsNotSet();
```

### DefaultMarketConfig__InvalidPercentage

```solidity
error DefaultMarketConfig__InvalidPercentage(uint64 givenPercentage);
```

## Structs
### AssetConfig

```solidity
struct AssetConfig {
    IERC20 asset;
    bool isBorrowable;
}
```

### ConfigInitParams

```solidity
struct ConfigInitParams {
    IIRM irm;
    IHooks hooks;
    IWeights weights;
    IOracleModule oracleModule;
    address feeRecipient;
    uint64 feePercentage;
    uint64 liquidationBonusPercentage;
    uint128 minMarginAmountUSD;
}
```

