# SimpleWeights
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/weights/SimpleWeights.sol)

**Inherits:**
[IWeights](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IWeights.sol/interface.IWeights.md), Ownable

**Title:**
SimpleWeights

**Author:**
Chinmay <chinmay@dhedge.org>

A simple weights contract that can be used to set weights between different assets.

[!WARNING] This contract doesn't discount the collateral asset if it's the same as the debt asset.
Theoretically, an account can borrow up to 100% of their collateral value if both assets are the same.


## State Variables
### rawWeights

```solidity
mapping(uint256 collateralTokenId => mapping(ReserveKey debtKey => uint64 weight)) public rawWeights
```


## Functions
### constructor


```solidity
constructor(address admin) Ownable(admin);
```

### getWeight

- Returns the weight of the collateral asset in relation to the debt asset.
- If the assets are the same, returns 1 (WAD).
- If the weight between the two assets doesn't exist, it reverts.
- Doesn't differeniate between escrowed and lent collateral.
- Doesn't consider the `account` parameter.


```solidity
function getWeight(
    AccountId,
    /* account */
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
|`<none>`|`AccountId`||
|`collateralTokenId`|`uint256`|The token ID of the collateral asset.|
|`debtAsset`|`ReserveKey`|The reserve key of the debt asset.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`weight`|`uint64`|The weight of the collateral asset in relation to the debt asset.|


### setWeight

Sets the weight of a collateral asset in relation to a debt asset.

- Doesn't revert if the weight is already set to the desired value.
- Isn't symmetric. Must set both directions if needed.
- Weights must be set for lent collateral and escrowed collateral separately.


```solidity
function setWeight(uint256 collateralTokenId, ReserveKey debtAsset, uint64 weight) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralTokenId`|`uint256`|The token ID of the collateral asset in a particular market.|
|`debtAsset`|`ReserveKey`|The reserve key of the debt asset.|
|`weight`|`uint64`|The weight of the collateral asset in relation to the debt asset. Must be less than or equal to WAD.|


## Errors
### SimpleWeights__InvalidWeight

```solidity
error SimpleWeights__InvalidWeight();
```

### SimpleWeights__WeightNotFound

```solidity
error SimpleWeights__WeightNotFound(uint256 collateralTokenId, ReserveKey debtAsset);
```

