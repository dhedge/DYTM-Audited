# IERC6909Metadata
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

**Inherits:**
[IERC6909](/src/flattened/Office.flattened.sol/interface.IERC6909.md)

*Optional extension of {IERC6909} that adds metadata functions.*


## Functions
### name

*Returns the name of the token of type `id`.*


```solidity
function name(uint256 id) external view returns (string memory);
```

### symbol

*Returns the ticker symbol of the token of type `id`.*


```solidity
function symbol(uint256 id) external view returns (string memory);
```

### decimals

*Returns the number of decimals for the token of type `id`.*


```solidity
function decimals(uint256 id) external view returns (uint8);
```

