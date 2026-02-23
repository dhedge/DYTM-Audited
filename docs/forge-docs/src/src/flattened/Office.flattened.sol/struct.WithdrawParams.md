# WithdrawParams
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)


```solidity
struct WithdrawParams {
    AccountId account;
    uint256 tokenId;
    address receiver;
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
|`shares`|`uint256`|The amount of shares to redeem.|
|`extraData`|`bytes`|Extra data that can be used by the hooks.|

