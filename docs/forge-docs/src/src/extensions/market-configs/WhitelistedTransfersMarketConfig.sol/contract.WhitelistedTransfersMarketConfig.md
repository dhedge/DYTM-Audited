# WhitelistedTransfersMarketConfig
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/market-configs/WhitelistedTransfersMarketConfig.sol)

**Inherits:**
[SimpleMarketConfig](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/extensions/market-configs/SimpleMarketConfig.sol/contract.SimpleMarketConfig.md)

**Title:**
WhitelistedTransfersMarketConfig

**Author:**
Chinmay <chinmay@dhedge.org>

Market config contract that restricts share transfers to whitelisted accounts only.

Requires the `hooks` contract to implement `IAddressAccountBaseWhitelist` but
does not enforce this given that the `hooks` contract is configurable.


## Functions
### constructor


```solidity
constructor(address initialOwner, ConfigInitParams memory params) SimpleMarketConfig(initialOwner, params);
```

### canTransferShares

Overrides the default share transfer permission logic to include whitelist checks.

Only verifies whether the receiver account is whitelisted.


```solidity
function canTransferShares(
    AccountId,
    AccountId to,
    uint256,
    uint256
)
    external
    view
    override
    returns (bool canTransfer);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`AccountId`||
|`to`|`AccountId`|The account to which shares are being transferred.|
|`<none>`|`uint256`||
|`<none>`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`canTransfer`|`bool`|`true` if the transfer is allowed, `false` otherwise.|


