# IERC6909
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

**Inherits:**
[IERC165](/src/flattened/Office.flattened.sol/interface.IERC165.md)

*Required interface of an ERC-6909 compliant contract, as defined in the
https://eips.ethereum.org/EIPS/eip-6909[ERC].*


## Functions
### balanceOf

*Returns the amount of tokens of type `id` owned by `owner`.*


```solidity
function balanceOf(address owner, uint256 id) external view returns (uint256);
```

### allowance

*Returns the amount of tokens of type `id` that `spender` is allowed to spend on behalf of `owner`.
NOTE: Does not include operator allowances.*


```solidity
function allowance(address owner, address spender, uint256 id) external view returns (uint256);
```

### isOperator

*Returns true if `spender` is set as an operator for `owner`.*


```solidity
function isOperator(address owner, address spender) external view returns (bool);
```

### approve

*Sets an approval to `spender` for `amount` of tokens of type `id` from the caller's tokens. An `amount` of
`type(uint256).max` signifies an unlimited approval.
Must return true.*


```solidity
function approve(address spender, uint256 id, uint256 amount) external returns (bool);
```

### setOperator

*Grants or revokes unlimited transfer permission of any token id to `spender` for the caller's tokens.
Must return true.*


```solidity
function setOperator(address spender, bool approved) external returns (bool);
```

### transfer

*Transfers `amount` of token type `id` from the caller's account to `receiver`.
Must return true.*


```solidity
function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);
```

### transferFrom

*Transfers `amount` of token type `id` from `sender` to `receiver`.
Must return true.*


```solidity
function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool);
```

## Events
### Approval
*Emitted when the allowance of a `spender` for an `owner` is set for a token of type `id`.
The new allowance is `amount`.*


```solidity
event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);
```

### OperatorSet
*Emitted when `owner` grants or revokes operator status for a `spender`.*


```solidity
event OperatorSet(address indexed owner, address indexed spender, bool approved);
```

### Transfer
*Emitted when `amount` tokens of type `id` are moved from `sender` to `receiver` initiated by `caller`.*


```solidity
event Transfer(address caller, address indexed sender, address indexed receiver, uint256 indexed id, uint256 amount);
```

