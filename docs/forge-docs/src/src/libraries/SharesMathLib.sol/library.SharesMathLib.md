# SharesMathLib
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/libraries/SharesMathLib.sol)

**Title:**
SharesMathLib

**Authors:**
Morpho Labs, Chinmay <chinmay@dhedge.org>

Shares management library.

Mostly adapted from Morpho's SharesMathLib:
https://github.com/morpho-org/morpho-blue/blob/d89ca53ff6cbbacf8717a8ce819ee58f49bcc592/src/libraries/SharesMathLib.sol

This implementation mitigates share price manipulations, using OpenZeppelin's method of virtual shares:
https://docs.openzeppelin.com/contracts/4.x/erc4626#inflation-attack.


## State Variables
### VIRTUAL_SHARES
The number of virtual shares has been chosen low enough to prevent overflows, and high enough to ensure
high precision computations.
- Virtual shares can never be redeemed for the assets they are entitled to, but it is assumed the share price
stays low enough not to inflate these assets to a significant value.
Warning: The assets to which virtual borrow shares are entitled behave like unrealizable bad debt.


```solidity
uint256 internal constant VIRTUAL_SHARES = 1e6
```


### VIRTUAL_ASSETS
A number of virtual assets of 1 enforces a conversion rate between shares and assets when a market is
empty.


```solidity
uint256 internal constant VIRTUAL_ASSETS = 1
```


## Functions
### toSharesDown

Calculates the value of `assets` quoted in shares, rounding down.


```solidity
function toSharesDown(
    uint256 assets,
    uint256 totalAssets,
    uint256 totalShares
)
    internal
    pure
    returns (uint256 shares);
```

### toAssetsDown

Calculates the value of `shares` quoted in assets, rounding down.


```solidity
function toAssetsDown(
    uint256 shares,
    uint256 totalAssets,
    uint256 totalShares
)
    internal
    pure
    returns (uint256 assets);
```

### toSharesUp

Calculates the value of `assets` quoted in shares, rounding up.


```solidity
function toSharesUp(
    uint256 assets,
    uint256 totalAssets,
    uint256 totalShares
)
    internal
    pure
    returns (uint256 shares);
```

### toAssetsUp

Calculates the value of `shares` quoted in assets, rounding up.


```solidity
function toAssetsUp(
    uint256 shares,
    uint256 totalAssets,
    uint256 totalShares
)
    internal
    pure
    returns (uint256 assets);
```

