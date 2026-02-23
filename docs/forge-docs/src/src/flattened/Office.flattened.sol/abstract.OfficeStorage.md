# OfficeStorage
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

**Author:**
Chinmay <chinmay@dhedge.org>


## Functions
### onlyOfficer


```solidity
modifier onlyOfficer(MarketId market);
```

### setMarketConfig

Sets the market configuration for a given market.


```solidity
function setMarketConfig(MarketId market, IMarketConfig marketConfig) external onlyOfficer(market);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`market`|`MarketId`|The market ID for which to set the configuration.|
|`marketConfig`|`IMarketConfig`|The market configuration to set.|


### changeOfficer

Changes the officer for a given market.

*Note: The officer can be the zero address for immutable markets.*


```solidity
function changeOfficer(MarketId market, address newOfficer) external onlyOfficer(market);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`market`|`MarketId`|The market ID for which to change the officer.|
|`newOfficer`|`address`|The address of the new officer.|


### getMarketConfig

Returns the market configuration contract for a given market.


```solidity
function getMarketConfig(MarketId market) public view returns (IMarketConfig marketConfig);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`market`|`MarketId`|The market ID for which to retrieve the configuration.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`marketConfig`|`IMarketConfig`|The market configuration contract for the specified market.|


### getOfficer

Returns the officer address for a given market.


```solidity
function getOfficer(MarketId market) public view returns (address officer);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`market`|`MarketId`|The market ID for which to retrieve the officer.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`officer`|`address`|The address of the officer for the specified market.|


### getReserveData

Returns the reserve data for a given reserve key.


```solidity
function getReserveData(ReserveKey key) public view returns (ReserveData memory reserveData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key for the asset.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`reserveData`|`ReserveData`|The reserve data for the asset.|


### _setMarketConfig


```solidity
function _setMarketConfig(MarketId market, IMarketConfig newMarketConfig) internal;
```

### _setOfficer


```solidity
function _setOfficer(MarketId market, address newOfficer) internal;
```

### _verifyOfficer


```solidity
function _verifyOfficer(MarketId market) internal view;
```

## Events
### OfficeStorage__OfficerModified

```solidity
event OfficeStorage__OfficerModified(MarketId indexed market, address newOfficer, address oldOfficer);
```

### OfficeStorage__MarketConfigModified

```solidity
event OfficeStorage__MarketConfigModified(
    MarketId indexed market, IMarketConfig prevMarketConfig, IMarketConfig newMarketConfig
);
```

## Errors
### OfficeStorage__ZeroAddress

```solidity
error OfficeStorage__ZeroAddress();
```

### OfficeStorage__NotOfficer

```solidity
error OfficeStorage__NotOfficer(MarketId market, address caller);
```

## Structs
### OfficeStorageStruct
**Note:**
storage-location: erc7201:DYTM.storage.Office


```solidity
struct OfficeStorageStruct {
    uint88 marketCount;
    mapping(MarketId market => address officer) officers;
    mapping(ReserveKey key => ReserveData data) reserveData;
    mapping(MarketId market => IMarketConfig config) configs;
}
```

### ReserveData
*Struct to store the asset amounts supplied and borrowed to/from a reserve.*

*`supplied` and `borrowed` accounts for interest accrued until the last update timestamp.*


```solidity
struct ReserveData {
    uint256 supplied;
    uint256 borrowed;
    uint128 lastUpdateTimestamp;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`supplied`|`uint256`|The amount of the asset supplied (lent) to the reserve.|
|`borrowed`|`uint256`|The amount of the asset borrowed from the reserve.|
|`lastUpdateTimestamp`|`uint128`|The last time the reserve data was updated.|

