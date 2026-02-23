# BaseOracleModule
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/oracles/BaseOracleModule.sol)

**Inherits:**
[IOracleModule](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IOracleModule.sol/interface.IOracleModule.md)

**Title:**
BaseOracleModule

**Author:**
Euler Labs <https://www.eulerlabs.com/>, Chinmay <chinmay@dhedge.org>

Base contract for oracle modules.

**Note:**
attribution: Adapted from Euler's `BaseAdapter` contract <https://github.com/euler-xyz/euler-price-oracle/blob/ffc3cb82615fc7d003a7f431175bd1eaf0bf41c5/src/adapter/BaseAdapter.sol>


## State Variables
### _ADDRESS_RESERVED_RANGE

```solidity
uint256 internal constant _ADDRESS_RESERVED_RANGE = 0xffffffff
```


## Functions
### getQuote

One-sided price: How much quote token you would get for inAmount of base token, assuming no price spread.

If `quote` is USD, the `outAmount` is in WAD.


```solidity
function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`inAmount`|`uint256`|The amount of `base` to convert.|
|`base`|`address`|The token that is being priced.|
|`quote`|`address`|The token that is the unit of account.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`outAmount`|`uint256`|The amount of `quote` that is equivalent to `inAmount` of `base`.|


### _getDecimals

Determine the decimals of an asset.

Oracles can use ERC-7535, ISO 4217 or other conventions to represent non-ERC20 assets as addresses.
Integrator Note: `_getDecimals` will return 18 if `asset` is:
- any address <= 0x00000000000000000000000000000000ffffffff (4294967295)
- an EOA or a to-be-deployed contract (which may implement `decimals()` after deployment).
- a contract that does not implement `decimals()`.


```solidity
function _getDecimals(address asset) internal view returns (uint8 decimals);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|ERC20 token address or other asset.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`decimals`|`uint8`|The decimals of the asset.|


### _getQuote

Return the quote for the given price query.

Must be overridden in the inheriting contract.


```solidity
function _getQuote(uint256 inAmount, address base, address quote) internal view virtual returns (uint256 outAmount);
```

