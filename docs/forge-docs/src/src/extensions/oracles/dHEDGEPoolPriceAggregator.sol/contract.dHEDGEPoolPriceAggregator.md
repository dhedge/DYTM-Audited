# dHEDGEPoolPriceAggregator
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/oracles/dHEDGEPoolPriceAggregator.sol)

**Inherits:**
[BaseOracleModule](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/extensions/oracles/BaseOracleModule.sol/abstract.BaseOracleModule.md), Ownable

**Title:**
dHEDGEPoolPriceAggregator

**Author:**
Chinmay <chinmay@dhedge.org>

Oracle module that fetches prices from dHEDGE Vaults and converts them to USD (ISO 4217 code 840)
or other Chainlink price oracles supported assets if whitelisted.

Implements the IOracleModule interface.
- The contract is ownable and the owner can set whitelisted assets.
- Whitelisting is required only for non-dHEDGE vault assets.
- For dHEDGE vaults, the price is fetched from the vault's `tokenPrice` function.
- Only Chainlink price oracles (or oracles with the same interface) are supported for non-dHEDGE vault assets.
- Will return price in WAD (18 decimals) if quote is USD.


## State Variables
### _POOL_FACTORY

```solidity
IdHEDGEPoolFactory internal immutable _POOL_FACTORY
```


### oracles

```solidity
mapping(address asset => OracleData data) public oracles
```


## Functions
### constructor


```solidity
constructor(address admin, address poolFactory) Ownable(admin);
```

### _getQuote


```solidity
function _getQuote(
    uint256 inAmount,
    address base,
    address quote
)
    internal
    view
    override
    returns (uint256 outAmount);
```

### _getPrice


```solidity
function _getPrice(address asset) internal view returns (uint256 priceUSD, uint256 scale);
```

### setOracle

Sets the oracle for an asset.
- Useful only for whitelisting non-dHEDGE vault assets.
- Can modify the existing oracle data for an asset.
- Can be used to unset an oracle by passing zero address.


```solidity
function setOracle(address asset, address oracle, uint256 maxStaleness) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The asset for which the oracle is being set.|
|`oracle`|`address`|The Chainlink AggregatorV3Interface oracle address for the asset.|
|`maxStaleness`|`uint256`|The maximum allowed staleness for the oracle price.|


## Errors
### dHEDGEPoolPriceAggregator__ZeroValue

```solidity
error dHEDGEPoolPriceAggregator__ZeroValue();
```

### dHEDGEPoolPriceAggregator__ZeroAddress

```solidity
error dHEDGEPoolPriceAggregator__ZeroAddress();
```

### dHEDGEPoolPriceAggregator__PriceNotFound

```solidity
error dHEDGEPoolPriceAggregator__PriceNotFound(address asset);
```

### dHEDGEPoolPriceAggregator__StalePrice

```solidity
error dHEDGEPoolPriceAggregator__StalePrice(address asset, uint256 staleness);
```

## Structs
### OracleData

```solidity
struct OracleData {
    AggregatorV3Interface oracle;
    uint256 maxStaleness;
    uint256 scale;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`oracle`|`AggregatorV3Interface`|Chainlink AggregatorV3Interface oracle for the asset.|
|`maxStaleness`|`uint256`|Maximum allowed staleness for the oracle price.|
|`scale`|`uint256`|Sum of asset decimals and oracle feed decimals raised to the power of 10.|

