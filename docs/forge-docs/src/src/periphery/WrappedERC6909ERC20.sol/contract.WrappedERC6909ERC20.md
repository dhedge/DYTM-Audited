# WrappedERC6909ERC20
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/periphery/WrappedERC6909ERC20.sol)

**Inherits:**
ERC20

**Title:**
WrappedERC6909ERC20

**Author:**
Chinmay <chinmay@dhedge.org>

ERC20 token contract used as the underlying for wrapped ERC6909 tokens.

**Note:**
attribution: Adapted from <https://etherscan.io/address/0x000000000020979cc92752fa2708868984a7f746?s=09#code>


## State Variables
### SOURCE
Wrapper singleton contract.


```solidity
address public immutable SOURCE = msg.sender
```


### _DECIMALS

```solidity
uint8 internal immutable _DECIMALS
```


## Functions
### onlySource


```solidity
modifier onlySource() ;
```

### constructor


```solidity
constructor(string memory name_, string memory symbol_, uint8 decimals_) payable ERC20(name_, symbol_);
```

### mint

Mints `amount` tokens to `to`.

Can only be called by the SOURCE contract.


```solidity
function mint(address to, uint256 amount) external onlySource;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to mint tokens to.|
|`amount`|`uint256`|The amount of tokens to mint.|


### burn

Burns `amount` tokens from `from`.

Can only be called by the SOURCE contract.


```solidity
function burn(address from, uint256 amount) external onlySource;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address to burn tokens from.|
|`amount`|`uint256`|The amount of tokens to burn.|


### decimals

Returns the number of decimals as set at deployment.


```solidity
function decimals() public view override returns (uint8 decimals_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`decimals_`|`uint8`|The number of decimals.|


## Errors
### WrappedERC6909ERC20__Unauthorized

```solidity
error WrappedERC6909ERC20__Unauthorized();
```

