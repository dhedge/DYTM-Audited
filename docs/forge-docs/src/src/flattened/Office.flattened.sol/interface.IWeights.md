# IWeights
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


## Functions
### getWeight

Returns the weight of the collateral asset in relation to the debt asset.

*The weight should be a value between 0 and 1, where 1 means the collateral asset is fully equivalent to the
debt asset.
- If the weight between the two assets doesn't exist, it may revert or return 0.
- May return a value less than 1 even if the collateral asset is fully equivalent to the debt asset.*


```solidity
function getWeight(
    AccountId account,
    uint256 collateralTokenId,
    ReserveKey debtAsset
)
    external
    view
    returns (uint64 weight);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account ID for more context.|
|`collateralTokenId`|`uint256`|The token ID of the collateral asset to differentiate between escrowed and lent collateral.|
|`debtAsset`|`ReserveKey`|The reserve key of the debt asset.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`weight`|`uint64`|The weight of the collateral asset in relation to the debt asset.|


