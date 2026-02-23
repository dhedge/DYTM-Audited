# IHooks
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/IHooks.sol)

**Title:**
IHooks

**Author:**
Chinmay <chinmay@dhedge.org>

Interface for implementing hook callbacks in the DYTM protocol.

Hooks allow custom logic to be executed before and after key market operations.
Implementations can choose to implement only the hooks they need.


## Functions
### beforeSupply

Hook called before a supply operation.


```solidity
function beforeSupply(SupplyParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`SupplyParams`|The supply parameters.|


### afterSupply

Hook called after a supply operation.


```solidity
function afterSupply(SupplyParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`SupplyParams`|The supply parameters.|


### beforeSwitchCollateral

Hook called before a collateral switch operation.


```solidity
function beforeSwitchCollateral(SwitchCollateralParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`SwitchCollateralParams`|The switch collateral parameters.|


### afterSwitchCollateral

Hook called after a collateral switch operation.


```solidity
function afterSwitchCollateral(SwitchCollateralParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`SwitchCollateralParams`|The switch collateral parameters.|


### beforeWithdraw

Hook called before a withdraw operation.


```solidity
function beforeWithdraw(WithdrawParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`WithdrawParams`|The withdraw parameters.|


### afterWithdraw

Hook called after a withdraw operation.


```solidity
function afterWithdraw(WithdrawParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`WithdrawParams`|The withdraw parameters.|


### beforeBorrow

Hook called before a borrow operation.


```solidity
function beforeBorrow(BorrowParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`BorrowParams`|The borrow parameters.|


### afterBorrow

Hook called after a borrow operation.


```solidity
function afterBorrow(BorrowParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`BorrowParams`|The borrow parameters.|


### beforeRepay

Hook called before a repay operation.


```solidity
function beforeRepay(RepayParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`RepayParams`|The repay parameters.|


### afterRepay

Hook called after a repay operation.


```solidity
function afterRepay(RepayParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`RepayParams`|The repay parameters.|


### beforeLiquidate

Hook called before a liquidation operation.


```solidity
function beforeLiquidate(LiquidationParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`LiquidationParams`|The liquidation parameters.|


### afterLiquidate

Hook called after a liquidation operation.


```solidity
function afterLiquidate(LiquidationParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`LiquidationParams`|The liquidation parameters.|


### beforeMigrateSupply

Hook called before a supply migration operation.


```solidity
function beforeMigrateSupply(MigrateSupplyParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`MigrateSupplyParams`|The migrate supply parameters.|


### afterMigrateSupply

Hook called after a supply migration operation.


```solidity
function afterMigrateSupply(MigrateSupplyParams calldata params) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`MigrateSupplyParams`|The migrate supply parameters.|


