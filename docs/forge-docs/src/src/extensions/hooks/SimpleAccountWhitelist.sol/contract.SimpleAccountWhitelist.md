# SimpleAccountWhitelist
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/hooks/SimpleAccountWhitelist.sol)

**Inherits:**
[AddressAccountBaseWhitelist](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/extensions/hooks/AddressAccountBaseWhitelist.sol/abstract.AddressAccountBaseWhitelist.md), [BaseHook](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/extensions/hooks/BaseHook.sol/abstract.BaseHook.md)

**Title:**
SimpleAccountWhitelist

**Author:**
Chinmay <chinmay@dhedge.org>

A simple whitelist contract that can be used to restrict access to DYTM protocol
to a predefined set of whitelisted accounts and owners. The owner of this contract can add or
remove accounts from the whitelist. This contract is intended to be used as a hook contract
in the DYTM protocol. The following hooks are enabled:
1. beforeSupply
2. beforeBorrow
3. beforeMigrateSupply
This means only certain addresses or actions on certain accounts are allowed to be performed.
We don't explicitly enable/disable other hooks given that the above hooks are sufficient to
restrict access to the protocol.


## State Variables
### MARKET_ID
The market id for which this hook contract is enabled.


```solidity
MarketId public immutable MARKET_ID
```


## Functions
### constructor

SimpleAccountWhitelist constructor.


```solidity
constructor(
    address admin,
    address office,
    MarketId marketId
)
    AddressAccountBaseWhitelist(IRegistry(office), admin)
    BaseHook(BEFORE_SUPPLY_FLAG | BEFORE_BORROW_FLAG | BEFORE_MIGRATE_SUPPLY_FLAG, office);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`admin`|`address`|The admin/owner of this contract.|
|`office`|`address`|The address of the Office contract.|
|`marketId`|`MarketId`|The market id for which this hook contract is enabled.|


### beforeSupply

Only allows whitelisted accounts/owners to supply.


```solidity
function beforeSupply(SupplyParams calldata params) public override onlyAuthorized(params.account);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`SupplyParams`|The supply parameters.|


### beforeBorrow

Only allows whitelisted accounts/owners to borrow.


```solidity
function beforeBorrow(BorrowParams calldata params) public override onlyAuthorized(params.account);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`BorrowParams`|The borrow parameters.|


### beforeMigrateSupply

Only allows whitelisted accounts/owners to migrate supply.

Verifies that the account is whitelisted only if the destination market is the hook's designated market.


```solidity
function beforeMigrateSupply(MigrateSupplyParams calldata params) public override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`MigrateSupplyParams`|The migrate supply parameters.|


## Errors
### SimpleAccountWhitelist_ZeroMarketId

```solidity
error SimpleAccountWhitelist_ZeroMarketId();
```

