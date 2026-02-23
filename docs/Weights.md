# Weights

Not every asset is the same when it comes to risk. Some assets are more volatile than others, some have more liquidity than others, some are backed by better quality collateral etc. So how do we decide how much of an asset can be borrowed against a collateral? This is where confidence weights (or simply weights) come into play.

Weights are assigned on a scale of 0 to 1 (in WAD for higher precision). The higher the weight, the more correlated a collateral is with the debt. Note that weights are assigned to a pair of collateral and debt assets. For example, a USDC-ETH pair (either can be collateral or debt) will have weights less than 1 (maybe 0.7 or anything deemed appropriate) while a stablecoin pair may have a weight closer to 1 (0.95 or similar). Weights of the same asset pair (USDC-USDC for example) will be 1. The higher the weight, the more leverage can be taken on that pair of assets. One can think weights as being similar to LTV or LLTV in other lending protocols.

The following equation governs the health of an account:

```math
\sum_{i=1}^{n}(C_i \times W_i) \ge D
```

Where $C_i$ represents the value of the i-th collateral asset, $W_i$ represents the weight of the i-th collateral asset and $D$ represents the total value of the debt.

If we rewrite the inequality as ratio of the valuation of collateral to the valuation of debt, we get:

```math
\frac{\sum_{i=1}^{n}(C_i \times W_i)}{D} \ge 1
```

This ratio is a more familiar concept similar to Aave's health factors. As long as this ratio is greater than 1, the account is healthy and can borrow more assets. If the ratio is less than 1, the account is unhealthy and needs to be liquidated.

While the benefits of using weights in the above manner are straightforward, there is one crucial drawback; one can't determine the maximum leverage that can be taken by an account involving certain assets easily. The market needs to use hooks to restrict max leverage an account can take.

## Derivation of Maximum Price Exposure Leverage

In practice, users are interested in **price exposure leverage**—how much their position is exposed to price changes in the re-supplied asset after swapping the borrowed funds. The following derivation and formulas focus on this definition.

>[!WARNING]
The maximum price exposure leverage is at the limit of the health equation and therefore it's the limit where liquidation occurs so one must take a safe margin below this limit to avoid liquidation.

#### 1. Define Core Variables

*   $C_{initial}$: The initial value of collateral supplied by the user.
*   $D$: The total value of the single debt asset (the debt), which is swapped into the re-supplied asset.
*   $W_{initial-debt}$: The weight assigned to the initial collateral and the debt asset pair.
*   $W_{debt-collateral}$: The weight assigned to the re-supplied collateral and the debt asset pair.

#### 2. Health Equation at its Limit

At maximum leverage, the health of the account is at its limit:
$$
(C_{initial} \times W_{initial-debt}) + (D \times W_{debt-collateral}) = D
$$

#### 3. Solve for the Borrowed Amount ($D$)

$$
C_{initial} \times W_{initial-debt} = D \times (1 - W_{debt-collateral})
$$
$$
D = \frac{C_{initial} \times W_{initial-debt}}{1 - W_{debt-collateral}}
$$

#### 4. Calculate Maximum Price Exposure Leverage ($L_{exposure}$)

Price exposure leverage is defined as the ratio of the re-supplied asset value (i.e., the borrowed amount swapped into the new asset) to the initial supplied collateral:
$$
L_{exposure} = \frac{D}{C_{initial}} = \frac{W_{initial-debt}}{1 - W_{debt-collateral}}
$$

### Example Calculations

#### Example 1 (ETH Supplied, USDC Borrowed, ETH Re-supplied)

- $W_{initial-debt} = 0.8$ (ETH to USDC)
- $W_{debt-collateral} = 0.8$ (ETH to USDC)

$$
L_{exposure} = \frac{0.8}{1 - 0.8} = \frac{0.8}{0.2} = 4.0
$$

**Interpretation:**
A 10% increase in ETH price results in a 40% increase in account value (4x exposure). Note that this doesn't include the profit due to price increase of the supplied ETH in which case it would be 5x exposure.

#### Example 2 (USDC Supplied, USDC Borrowed, ETH Re-supplied)

- $W_{initial-debt} = 1.0$ (USDC to USDC)
- $W_{debt-collateral} = 0.8$ (ETH to USDC)

$$
L_{exposure} = \frac{1.0}{1 - 0.8} = \frac{1.0}{0.2} = 5.0
$$

**Interpretation:**
A 10% increase in ETH price results in a 50% increase in account value (5x exposure).

#### Example 3 (USDC and USDe Supplied, USDe Borrowed, WETH and WBTC Re-supplied)

- $W_{initial-debt} = (0.50 \times 0.9) + (0.50 \times 1.0) = 0.95$
- $W_{debt-collateral} = (0.50 \times 0.6) + (0.50 \times 0.6) = 0.6$

$$
L_{exposure} = \frac{0.95}{1 - 0.6} = \frac{0.95}{0.4} = 2.375
$$

**Interpretation:**
A 10% increase in the value of the re-supplied asset basket results in a 23.75% increase in account value (2.375x exposure).

### Liquidation Buffer Calculation

At the time of liquidation, the protocol sells enough collateral to cover the actual debt $D$. The buffer is the value of collateral left after repaying the debt, which is a direct result of the discounting effect of the weights in the health equation.

#### Derivation

At the health limit:
$$
(C_{initial} \times W_{initial-debt}) + (D \times W_{debt-collateral}) = D
$$

Recall from the leverage derivation:
$$
D = \frac{C_{initial} \times W_{initial-debt}}{1 - W_{debt-collateral}}
$$

The total collateral at the health limit is:
$$
C_{total} = C_{initial} + D
$$

The liquidation buffer is:
$$
C_{buffer,liquidation} = C_{total} - D = C_{initial}
$$

The **percentage of collateral buffer compared to the debt to be repaid** is:
$$
\text{Buffer Percentage} = \frac{C_{buffer,liquidation}}{D} \times 100\%
$$

#### Example (using previous values)

- $C_{initial} = 1$ (normalized)
- $D = 2.375$ (from the example calculation)
- $C_{total} = 1 + 2.375 = 3.375$
- $C_{buffer,liquidation} = 1.0$

So,
$$
\text{Buffer Percentage} = \frac{1.0}{2.375} \times 100\% \approx 42.1\%
$$

**Interpretation:**
At the health limit, after repaying the debt, there is $1.0$ unit of collateral value left, which is approximately **42.1%** of the debt value. This percentage buffer is a direct result of the discounting effect of the weights and is essential for protocol safety.

## Additional Condition on Weights to Ensure Re-supplied Collateral Exceeds Initial Collateral

In some cases, if weights are set too low or too high, the value of the re-supplied collateral ($C_N$) may not exceed the sum of all initially supplied collateral ($C_1 + C_2 + ... + C_{N-1}$).

$$
C_N > \sum_{i=1}^{N-1} C_i
$$

### Derivation

At the health limit, assuming all borrowed is re-supplied:
$$
\sum_{i=1}^{N-1} C_i W_i + C_N W_N = D
$$
But $C_N = D$, so:
$$
\sum_{i=1}^{N-1} C_i W_i + C_N W_N = C_N
$$
$$
\sum_{i=1}^{N-1} C_i W_i = C_N (1 - W_N)
$$
$$
C_N = \frac{\sum_{i=1}^{N-1} C_i W_i}{1 - W_N}
$$

To ensure $C_N > \sum_{i=1}^{N-1} C_i$:
$$
\frac{\sum_{i=1}^{N-1} C_i W_i}{1 - W_N} > \sum_{i=1}^{N-1} C_i
$$
$$
\sum_{i=1}^{N-1} C_i W_i > (1 - W_N) \sum_{i=1}^{N-1} C_i
$$
$$
\sum_{i=1}^{N-1} C_i (W_i - 1) + W_N \sum_{i=1}^{N-1} C_i > 0
$$
$$
W_N > \frac{\sum_{i=1}^{N-1} C_i (1 - W_i)}{\sum_{i=1}^{N-1} C_i}
$$

### Example Where the Condition Fails

Suppose:
- $C_1 = 1$ (initial collateral)
- $W_1 = 0.9$
- $W_N = 0.1$

At the health limit:
$$
1 \cdot 0.9 + C_N \cdot 0.1 = C_N
$$
$$
0.9 = C_N - 0.1 C_N \implies 0.9 = 0.9 C_N \implies C_N = 1
$$

But the condition $C_N > C_1$ is $1 > 1$, which is **not satisfied**.

### Summary

**To guarantee that the re-supplied collateral always exceeds the sum of the initially supplied collateral, the following must hold:**
$$
W_N > \frac{\sum_{i=1}^{N-1} C_i (1 - W_i)}{\sum_{i=1}^{N-1} C_i}
$$




