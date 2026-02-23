# IERC6909ContentURI
[Git Source](https://github.com/dhedge/DYTM/blob/53ed8af1f87798b2e7f6a7a00a2503297cafc7da/src/flattened/Office.flattened.sol)

**Inherits:**
[IERC6909](/src/flattened/Office.flattened.sol/interface.IERC6909.md)

*Optional extension of {IERC6909} that adds content URI functions.*


## Functions
### contractURI

*Returns URI for the contract.*


```solidity
function contractURI() external view returns (string memory);
```

### tokenURI

*Returns the URI for the token of type `id`.*


```solidity
function tokenURI(uint256 id) external view returns (string memory);
```

