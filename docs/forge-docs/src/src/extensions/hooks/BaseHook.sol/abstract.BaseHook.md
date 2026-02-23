# BaseHook
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/extensions/hooks/BaseHook.sol)

**Inherits:**
[IHooks](/Volumes/Storage/Blockchain-Projects/dHEDGE/DYTM/docs/forge-docs/src/src/interfaces/IHooks.sol/interface.IHooks.md)

**Title:**
BaseHook

**Author:**
Chinmay <chinmay@dhedge.org>

Base contract for implementing hooks that can be called by the Office contract.

All hook functions revert if called by any address other than the authorized Office contract.


## State Variables
### OFFICE
The authorized Office contract address.


```solidity
address public immutable OFFICE
```


## Functions
### onlyOffice


```solidity
modifier onlyOffice() ;
```

### constructor

Constructor


```solidity
constructor(uint160 flags, address office) ;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`flags`|`uint160`|The required hook flags.|
|`office`|`address`|The address of the Office contract.|


### beforeSupply

Hook called before a supply operation.


```solidity
function beforeSupply(
    SupplyParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SupplyParams`||


### afterSupply

Hook called after a supply operation.


```solidity
function afterSupply(
    SupplyParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SupplyParams`||


### beforeSwitchCollateral

Hook called before a collateral switch operation.


```solidity
function beforeSwitchCollateral(
    SwitchCollateralParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SwitchCollateralParams`||


### afterSwitchCollateral

Hook called after a collateral switch operation.


```solidity
function afterSwitchCollateral(
    SwitchCollateralParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SwitchCollateralParams`||


### beforeWithdraw

Hook called before a withdraw operation.


```solidity
function beforeWithdraw(
    WithdrawParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`WithdrawParams`||


### afterWithdraw

Hook called after a withdraw operation.


```solidity
function afterWithdraw(
    WithdrawParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`WithdrawParams`||


### beforeBorrow

Hook called before a borrow operation.


```solidity
function beforeBorrow(
    BorrowParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`BorrowParams`||


### afterBorrow

Hook called after a borrow operation.


```solidity
function afterBorrow(
    BorrowParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`BorrowParams`||


### beforeRepay

Hook called before a repay operation.


```solidity
function beforeRepay(
    RepayParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`RepayParams`||


### afterRepay

Hook called after a repay operation.


```solidity
function afterRepay(
    RepayParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`RepayParams`||


### beforeLiquidate

Hook called before a liquidation operation.


```solidity
function beforeLiquidate(
    LiquidationParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`LiquidationParams`||


### afterLiquidate

Hook called after a liquidation operation.


```solidity
function afterLiquidate(
    LiquidationParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`LiquidationParams`||


### beforeMigrateSupply

Hook called before a supply migration operation.


```solidity
function beforeMigrateSupply(
    MigrateSupplyParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`MigrateSupplyParams`||


### afterMigrateSupply

Hook called after a supply migration operation.


```solidity
function afterMigrateSupply(
    MigrateSupplyParams calldata /* params */
)
    public
    virtual
    onlyOffice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`MigrateSupplyParams`||


### _onlyOffice

Internal function to check if the caller is the authorized Office contract


```solidity
function _onlyOffice() internal view;
```

## Errors
### BaseHook_OnlyOffice

```solidity
error BaseHook_OnlyOffice();
```

### BaseHook_ZeroAddress

```solidity
error BaseHook_ZeroAddress();
```

### BaseHook_IncorrectHooks

```solidity
error BaseHook_IncorrectHooks(uint160 required, uint160 enabled);
```

