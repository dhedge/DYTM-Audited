# IOracleModule
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

*Adapted from Euler's `IPriceOracle` interface
<https://github.com/euler-xyz/euler-price-oracle/blob/ffc3cb82615fc7d003a7f431175bd1eaf0bf41c5/src/interfaces/IPriceOracle.sol>
- DYTM aims to use oracles as used by Euler.
- For getting prices in USD, as required by the Euler oracles (ERC7726), ISO 4217 code is used.
For USD, it is 840 so we use `address(840)` as the address for USD.*


## Functions
### getQuote

One-sided price: How much quote token you would get for inAmount of base token, assuming no price spread.

*If `quote` is USD, the `outAmount` is in WAD.*


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


