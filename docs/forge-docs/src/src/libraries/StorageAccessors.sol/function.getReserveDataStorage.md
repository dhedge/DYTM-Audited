# getReserveDataStorage
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/libraries/StorageAccessors.sol)

Function to get the storage pointer for the reserve data.


```solidity
function getReserveDataStorage(ReserveKey key) view returns (OfficeStorage.ReserveData storage reserveData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`key`|`ReserveKey`|The reserve key for the asset.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`reserveData`|`OfficeStorage.ReserveData`|The storage pointer for the reserve data.|


