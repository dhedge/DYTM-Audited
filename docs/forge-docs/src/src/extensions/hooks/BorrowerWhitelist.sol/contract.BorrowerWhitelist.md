# BorrowerWhitelist
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/hooks/BorrowerWhitelist.sol)

**Inherits:**
[AddressAccountBaseWhitelist](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/extensions/hooks/AddressAccountBaseWhitelist.sol/abstract.AddressAccountBaseWhitelist.md), [BaseHook](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/extensions/hooks/BaseHook.sol/abstract.BaseHook.md)

**Title:**
BorrowerWhitelist

**Author:**
Chinmay <chinmay@dhedge.org>

A simple whitelist contract that can be used to restrict borrowing access to DYTM protocol
to a predefined set of whitelisted accounts and owners. The owner of this contract can add or
remove accounts from the whitelist. This contract is intended to be used as a hook contract
in the DYTM protocol. The following hook is enabled:
1. beforeBorrow
This means only certain addresses or actions on certain accounts are allowed to borrow.


## State Variables
### MARKET_ID
The market id for which this hook contract is enabled.


```solidity
MarketId public immutable MARKET_ID
```


## Functions
### constructor

Constructor


```solidity
constructor(
    address admin,
    address office,
    MarketId marketId
)
    AddressAccountBaseWhitelist(IRegistry(office), admin)
    BaseHook(BEFORE_BORROW_FLAG, office);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`admin`|`address`|The admin address for the Ownable contract.|
|`office`|`address`|The DYTM office address.|
|`marketId`|`MarketId`|The market id for which this hook contract is enabled.|


### beforeBorrow

Only allows whitelisted accounts/owners to borrow.


```solidity
function beforeBorrow(BorrowParams calldata params) public override onlyAuthorized(params.account);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`BorrowParams`|The borrow parameters.|


## Errors
### BorrowerWhitelist_ZeroMarketId

```solidity
error BorrowerWhitelist_ZeroMarketId();
```

