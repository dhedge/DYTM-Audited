# RepayParams
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/ParamStructs.sol)

Parameters for repay operations.

Exactly one of `assets` or `shares` must be zero.


```solidity
struct RepayParams {
AccountId account;
ReserveKey key;
TokenType withCollateralType;
uint256 assets;
uint256 shares;
bytes extraData;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`account`|`AccountId`|The account whose debt will be repaid.|
|`key`|`ReserveKey`|The reserve key for the asset.|
|`withCollateralType`|`TokenType`|The TokenType of the collateral to be used for repaying the debt. Can be used to repay using the supplied collateral (same as debt asset). Only TokenType.ESCROW and TokenType.LEND are supported. Use TokenType.NONE to indicate repayment is not done via collateral.|
|`assets`|`uint256`|The amount of the asset to repay. Use `type(uint256).max` to repay debt using entire repayer balance. If repayer balance is greater than debt obligation, only the required amount will be pulled.|
|`shares`|`uint256`|The amount of debt shares to repay. Use `type(uint256).max` to repay all the debt shares.|
|`extraData`|`bytes`|Extra data that can be used by the hooks.|

