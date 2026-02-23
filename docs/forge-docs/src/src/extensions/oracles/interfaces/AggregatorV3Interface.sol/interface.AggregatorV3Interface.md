# AggregatorV3Interface
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/oracles/interfaces/AggregatorV3Interface.sol)

**Title:**
AggregatorV3Interface

**Author:**
smartcontractkit (https://github.com/smartcontractkit/chainlink/blob/e87b83cd78595c09061c199916c4bb9145e719b7/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol)

Partial interface for Chainlink Data Feeds.


## Functions
### decimals

Returns the feed's decimals.


```solidity
function decimals() external view returns (uint8);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint8`|The decimals of the feed.|


### latestRoundData

Get data about the latest round.


```solidity
function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`roundId`|`uint80`|The round ID from the aggregator for which the data was retrieved.|
|`answer`|`int256`|The answer for the given round.|
|`startedAt`|`uint256`|The timestamp when the round was started. (Only some AggregatorV3Interface implementations return meaningful values)|
|`updatedAt`|`uint256`|The timestamp when the round last was updated (i.e. answer was last computed).|
|`answeredInRound`|`uint80`|is the round ID of the round in which the answer was computed.|


