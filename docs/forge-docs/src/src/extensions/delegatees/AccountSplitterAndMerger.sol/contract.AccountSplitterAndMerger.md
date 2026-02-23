# AccountSplitterAndMerger
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/delegatees/AccountSplitterAndMerger.sol)

**Inherits:**
[IDelegatee](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IDelegatee.sol/interface.IDelegatee.md)

**Title:**
AccountSplitterAndMerger

**Author:**
Chinmay <chinmay@dhedge.org>

This contract provides functionality to split and merge accounts within DYTM.
> [!WARNING]
DO NOT SET THIS CONTRACT AS AN OPERATOR FOR ANY ACCOUNT.
THIS CONTRACT DOES NOT HAVE ACCESS CONTROLS AND ANYONE CAN OPERATE ON BEHALF OF AN ACCOUNT
VIA A DELEGATION CALL.

This contract can only be used via delegation calls from the Office contract.


## State Variables
### OFFICE

```solidity
address public immutable OFFICE
```


## Functions
### constructor


```solidity
constructor(address _office) ;
```

### onDelegationCallback

Callback function for handling delegation calls for split and merge account operations.
- The `data` parameter is expected to be an encoded `CallbackData` struct.
- The `data` field of the `CallbackData` struct is further decoded (either into `SplitAccountParams` or `MergeAccountsParams`)
based on the `operation` type.
- The `returnData` for the `SPLIT_ACCOUNT` operation is the `AccountId` of the newly created account.
- The `returnData` for the `MERGE_ACCOUNTS` operation is empty.


```solidity
function onDelegationCallback(bytes calldata data) external returns (bytes memory returnData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`bytes`|Encoded data containing the operation type and parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`returnData`|`bytes`|Encoded return data from the operation.|


### _splitAccount


```solidity
function _splitAccount(SplitAccountParams memory params) internal returns (AccountId newAccount);
```

### _mergeAccounts


```solidity
function _mergeAccounts(MergeAccountsParams memory params) internal;
```

### __transferAssetsAndDebt


```solidity
function __transferAssetsAndDebt(
    AccountId sourceAccount,
    AccountId recipientAccount,
    MarketId market,
    uint64 fraction
)
    private;
```

## Events
### AccountSplitterAndMerger_AccountSplit

```solidity
event AccountSplitterAndMerger_AccountSplit(
    AccountId indexed originalAccount,
    AccountId newAccount,
    MarketId indexed market,
    address indexed caller,
    address receiver,
    uint256 fraction
);
```

### AccountSplitterAndMerger_AccountsMerged

```solidity
event AccountSplitterAndMerger_AccountsMerged(
    AccountId indexed recipientAccount,
    AccountId indexed sourceAccount,
    MarketId indexed market,
    address caller,
    uint256 fraction
);
```

## Errors
### AccountSplitterAndMerger_ZeroAddress

```solidity
error AccountSplitterAndMerger_ZeroAddress();
```

### AccountSplitterAndMerger_OnlyOffice

```solidity
error AccountSplitterAndMerger_OnlyOffice(address caller);
```

### AccountSplitterAndMerger_InvalidFraction

```solidity
error AccountSplitterAndMerger_InvalidFraction(uint256 fraction);
```

### AccountSplitterAndMerger_InvalidOperation

```solidity
error AccountSplitterAndMerger_InvalidOperation(Operation operation);
```

## Structs
### CallbackData

```solidity
struct CallbackData {
    Operation operation;
    bytes data;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`operation`|`Operation`|The type of operation to be performed (split or merge).|
|`data`|`bytes`|The encoded parameters for the operation (SplitAccountParams or MergeAccountsParams).|

### SplitAccountParams

```solidity
struct SplitAccountParams {
    AccountId sourceAccount;
    MarketId market;
    address receiver;
    uint64 fraction;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`sourceAccount`|`AccountId`|The account to be split.|
|`market`|`MarketId`||
|`receiver`|`address`|The address that will receive the new account containing the split assets.|
|`fraction`|`uint64`|The fraction of the account's assets to split. Must be a value between 0 and 1e18.|

### MergeAccountsParams

```solidity
struct MergeAccountsParams {
    AccountId sourceAccount;
    AccountId recipientAccount;
    MarketId market;
    uint64 fraction;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`sourceAccount`|`AccountId`|The account from which assets will be merged into the recipient account.|
|`recipientAccount`|`AccountId`|The account that will receive the merged assets and debt.|
|`market`|`MarketId`|The market in which the accounts' position exists.|
|`fraction`|`uint64`|The fraction of the source account's assets to merge. Must be a value between 0 and 1e18.|

## Enums
### Operation

```solidity
enum Operation {
    INVALID, // 0
    SPLIT_ACCOUNT, // 1
    MERGE_ACCOUNTS // 2
}
```

