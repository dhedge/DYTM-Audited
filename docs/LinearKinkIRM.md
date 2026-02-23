# Linear Kink IRM Documentation

## Overview

The [`LinearKinkIRM`](../src/IRM/LinearKinkIRM.sol) is a kink-based interest rate model similar to those used by Aave and Euler V2, but adapted for the DYTM protocol's multi-market and multi-reserve architecture. Based on the article published by [RareSkills](https://www.rareskills.io/post/aave-interest-rate-model).

## How It Works

### Key Components

1. **Multi-Market Support**: Each reserve is identified by a [`ReserveKey`](../src/types/Types.sol) that encodes both the market ID and asset address, allowing the same IRM to be used across multiple markets.

2. **Kink-Based Model**: The interest rate follows a two-slope linear model:
   - **Below optimal utilization**: Gradual increase from base rate
   - **Above optimal utilization**: Steep increase to discourage over-borrowing


3. **Dynamic Parameters**: Each reserve can have its own set of parameters (base rate, slopes, optimal utilization).

### Interest Rate Formula

The interest rate is calculated directly in per-second format:

```
if utilization <= optimalUtilization:
    ratePerSecond = baseRatePerSecond + (utilization * slope1PerSecond) / optimalUtilization

if utilization > optimalUtilization:
    ratePerSecond = baseRatePerSecond + slope1PerSecond + ((utilization - optimal) * slope2PerSecond) / (1 - optimal)
```

### Parameters

- **baseRatePerSecond**: Base interest rate per second when utilization = 0%
- **slope1PerSecond**: Rate of increase per second below optimal utilization  
- **slope2PerSecond**: Rate of increase per second above optimal utilization
- **optimalUtilization**: Target utilization rate (e.g., 80% = 0.8e18)

## Usage Example

```solidity
// 2% base rate, 10% slope1, 100% slope2, 80% optimal utilization (all per second)
irm.setParameters(
    usdcKey,
    0.02e18 / 365 days,  // 2% APY base rate converted to per second
    0.10e18 / 365 days,  // 10% APY slope1 converted to per second  
    1.00e18 / 365 days,  // 100% APY slope2 converted to per second
    0.8e18               // 80% optimal utilization
);
```

## Comparison with FixedBorrowRateIRM

| Feature           | [`FixedBorrowRateIRM`](../src/IRM/FixedBorrowRateIRM.sol) | [`LinearKinkIRM`](../src/IRM/LinearKinkIRM.sol) |
| ----------------- | --------------------------------------------------------- | ----------------------------------------------- |
| Rate Model        | Fixed rate                                                | Dynamic based on utilization                    |
| Parameters        | Single rate per reserve                                   | Four parameters per reserve                     |
| Market Volatility | None                                                      | Responds to supply/demand                       |
| Use Case          | Stable, predictable rates                                 | Market-driven rates                             |

## Integration with Office Contract

The IRM integrates with the [`Office`](../src/Office.sol) contract by:

1. **Getting Reserve Data**: Fetches supplied/borrowed amounts to calculate utilization.
2. **Access Control**: Uses the Officer pattern for parameter updates.
3. **Interest Accrual**: Calls `accrueInterest()` before parameter changes.

## Security Considerations

1. **Officer-Only Access**: Only market officers can modify parameters.
2. **Interest Accrual**: Always accrues interest before parameter changes.
3. **Fixed Point Math**: Uses `FixedPointMathLib` for WAD math.
