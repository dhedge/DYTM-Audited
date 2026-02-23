# OfficeERC6909ToERC20Wrapper
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/periphery/OfficeERC6909ToERC20Wrapper.sol)

**Inherits:**
ReentrancyGuardTransient

**Title:**
OfficeERC6909ToERC20Wrapper

**Author:**
Chinmay <chinmay@dhedge.org>

Wrapper singleton contract for ERC6909 <> ERC20 tokens.

Ideally, should be deployed at the same address across all networks.
Since we use CREATE2, the deployed wrapped ERC20 token addresses can be the same across networks.
provided the ERC6909 token ID is the same, which means the address of the
ERC20 asset it represents should also be the same.

**Note:**
attribution: Adapted from <https://etherscan.io/address/0x000000000020979cc92752fa2708868984a7f746?s=09#code>


## State Variables
### OFFICE

```solidity
address public immutable OFFICE
```


### getERC20

```solidity
mapping(uint256 id => address erc20) public getERC20
```


## Functions
### constructor


```solidity
constructor(address office) ;
```

### register

Creates a new wrapped ERC20 token for the given ERC6909 token ID.

Can only be called by the officer of the market to which the token ID belongs.


```solidity
function register(
    uint256 id,
    string calldata name,
    string calldata symbol,
    uint8 decimals
)
    external
    returns (address erc20);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint256`|The ERC6909 token ID to create a wrapped ERC20 token for.|
|`name`|`string`|The name of the wrapped ERC20 token.|
|`symbol`|`string`|The symbol of the wrapped ERC20 token.|
|`decimals`|`uint8`|The decimals of the wrapped ERC20 token.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`erc20`|`address`|The address of the newly created wrapped ERC20 token.|


### wrap

Wraps `amount` of ERC6909 tokens of `id` into the corresponding wrapped ERC20 tokens.

The caller must have approved this contract to transfer their ERC6909 tokens of `id`.
Reverts if there is no wrapped ERC20 token registered for the given `id`.


```solidity
function wrap(uint256 id, uint256 amount) public nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint256`|The ERC6909 token ID to wrap.|
|`amount`|`uint256`|The amount of ERC6909 tokens to wrap.|


### unwrap

Unwraps `amount` of wrapped ERC20 tokens of `id` into the corresponding ERC6909 tokens.

The caller must have approved this contract to transfer their wrapped ERC20 tokens of `id`.
Reverts if there is no wrapped ERC20 token registered for the given `id`.


```solidity
function unwrap(uint256 id, uint256 amount) public nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint256`|The ERC6909 token ID to unwrap.|
|`amount`|`uint256`|The amount of wrapped ERC20 tokens to unwrap.|


## Events
### OfficeERC6909ToERC20Wrapper__Registered

```solidity
event OfficeERC6909ToERC20Wrapper__Registered(uint256 indexed id, address indexed erc20);
```

### OfficeERC6909ToERC20Wrapper__Wrapped

```solidity
event OfficeERC6909ToERC20Wrapper__Wrapped(uint256 indexed id, address indexed erc20, uint256 amount);
```

### OfficeERC6909ToERC20Wrapper__Unwrapped

```solidity
event OfficeERC6909ToERC20Wrapper__Unwrapped(uint256 indexed id, address indexed erc20, uint256 amount);
```

## Errors
### OfficeERC6909ToERC20Wrapper__Reentrancy

```solidity
error OfficeERC6909ToERC20Wrapper__Reentrancy();
```

### OfficeERC6909ToERC20Wrapper__ZeroAddress

```solidity
error OfficeERC6909ToERC20Wrapper__ZeroAddress();
```

### OfficeERC6909ToERC20Wrapper__ERC20AlreadyRegistered

```solidity
error OfficeERC6909ToERC20Wrapper__ERC20AlreadyRegistered(uint256 id);
```

### OfficeERC6909ToERC20Wrapper__NotOfficer

```solidity
error OfficeERC6909ToERC20Wrapper__NotOfficer(MarketId market, address caller);
```

### OfficeERC6909ToERC20Wrapper__TransferFailed

```solidity
error OfficeERC6909ToERC20Wrapper__TransferFailed(address from, address to, uint256 id, uint256 amount);
```

