# Utils
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/libraries/Utils.sol)

**Title:**
Utils

**Author:**
Chinmay <chinmay@dhedge.org>

Utility functions for handling `type(uint256).max` conditions and other common operations.

Requires the inheriting contract to implement `IRegistry` for balance checks.


## Functions
### someOrMaxAssets

Returns the requested assets or the maximum assets held by the caller if requested is `type(uint256).max`.


```solidity
function someOrMaxAssets(IERC20 asset, uint256 requested) internal view returns (uint256 assets);
```

### someOrMaxShares

Returns the requested shares or the maximum shares held by the account if requested is `type(uint256).max`.


```solidity
function someOrMaxShares(
    AccountId account,
    uint256 tokenId,
    uint256 requested
)
    internal
    view
    returns (uint256 shares);
```

### exactlyOneZero

Returns true if exactly one of `a` or `b` is zero but not both.


```solidity
function exactlyOneZero(uint256 a, uint256 b) internal pure returns (bool isExactlyOneZero);
```

