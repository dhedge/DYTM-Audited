# WithdrawParams
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/ParamStructs.sol)

Parameters for withdraw operations.

Exactly one of `assets` or `shares` must be zero.


```solidity
struct WithdrawParams {
AccountId account;
uint256 tokenId;
address receiver;
uint256 assets;
uint256 shares;
bytes extraData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account from which the assets should be withdrawn.|
|`tokenId`|`uint256`|The tokenId of the receipt token shares to withdraw. A user has a choice to withdraw the assets from either the lending market or from escrow.|
|`receiver`|`address`|The address that will receive the withdrawn assets.|
|`assets`|`uint256`|The amount of the asset (as encoded in the tokenId) to withdraw.|
|`shares`|`uint256`|The amount of shares to redeem. Use `type(uint256).max` to redeem all the shares.|
|`extraData`|`bytes`|Extra data that can be used by the hooks.|

