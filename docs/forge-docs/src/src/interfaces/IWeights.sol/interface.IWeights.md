# IWeights
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/IWeights.sol)

**Title:**
IWeights

**Author:**
Chinmay <chinmay@dhedge.org>

Interface for calculating collateral weights in the DYTM protocol.

Weights determine how much collateral value counts towards borrowing capacity.
A weight of 1e18 (100%) means the collateral is fully equivalent to the debt asset.


## Functions
### getWeight

Returns the weight of the collateral asset in relation to the debt asset.

The weight should be a value between 0 and 1e18, where 1e18 means the collateral asset
is fully equivalent to the debt asset.
- If the weight between the two assets doesn't exist, it may revert or return 0.
- May return a value less than 1e18 even if the collateral asset is fully equivalent to the debt asset.


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


