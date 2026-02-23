# DYTM (Do Your Thing Mate)

DYTM is a protocol designed to simplify leverage/margin trading using any DeFi protocol. Anyone can create a credit market tailored to their needs (yes permissionless). Think of it as a protocol which provides credit to use across different DeFi platforms.

At the core, DYTM is pretty similar to any other lending protocol. One of the major difference is that it allows for a high level of customization and flexibility. DYTM is designed to be modular and extensible, allowing developers to build on top of it and create new features and functionalities. At its core, all that a market does is to allow a user to lend and borrow specific assets. They can re-supply the assets they borrowed (assuming they swapped it for some other asset) as long as the re-supplied assets are supported by the market. They can choose to either lend their assets or escrow them (not subject to lending risks) as collateral for any asset(s) that they borrow.

## Architecture

All markets in DYTM live in a single contract called [`Office`](../src/Office.sol). We use a heavily modified version of [ERC6909](https://eips.ethereum.org/EIPS/eip-6909) tokenization standard to represent assets, debt and accounts (more about this later) in a market. All market functions have a `before` and `after` hook which allows us to execute custom logic before and after the market function is executed. This is what allows for a high level of customization.

To create a leveraged position, a user never needs to loop (i.e. call supply then borrow then supply and so on). The user can simply call the `supply` function with the amount of asset they want to supply and then `borrow` multiples of the supplied amount if they choose to do so provided they re-deposit some assets as part of their position's collateral. We have a delegation feature to provide multicall like features for any user (smart account or EOA, doesn't matter). This allows batching complex actions not just restricted DYTM.

## Roles

### Officer

An officer is an address which governs a market's configuration. They can set parameters such as the assets allowed, weights, hooks contract, oracle module, IRM etc. The officer can be null address meaning anyone can create an immutable market (similar to a Morpho market). All of the parameters of a market are configurable and not immutable by default. A user must trust the officer of a market as they can change the configuration of the market at any time. There are many ways in which a malicious officer can exploit users of the market which is out of scope for this document.

### Operator

An operator is an address which can act on behalf of an account using any or all the market functions. They can also transfer assets from the account to any other account or address. However, they cannot transfer the account to another address unless explicitly approved by the owner of the account. Operators can be set temporarily for the duration of a transaction using delegation calls or as long as the owner of the account desires using the `setOperator` function. An operator cannot set another operator using `setOperator` but they can using delegation calls (only for the duration of a transaction). A user must trust the operator(s) of their account as they can potentially drain all assets from the account.

## Key Terms

### Markets

A market contains assets that can be supplied and borrowed. The parameters of a market are stored in the [`IMarketConfig`](../src/interfaces/IMarketConfig.sol) contract. The address of this contract is provided when the market is created and is also not immutable and controlled by the officer. The market config contract is used to retrieve the parameters of the market such as the assets allowed, weights, oracle module, hooks contract, IRM etc.

Each market has an ID associated with it starting from 1 and theoretically, the Office can contain at most `2^88 - 2` markets. 

### Reserves

Each asset part of the market has a reserve. Think of it like a bucket of a particular asset. If a market permits supplying and borrowing USDC and WETH, then it has 2 reserves (USDC and WETH). Each reserve is encoded as a key and utilised in a variety of functions in the `Office` contract. A reserve encoding involves encoding the market ID and the ERC20 token address of the asset. See more in [`ReserveKeysEncoding`](./dev/ReserveKeyEncoding.md).

### TokenId

The following components have a tokenId (akin to ERC6909 tokenIds):

1. Lent assets
2. Escrowed assets
3. Debt assets
4. Account token

Don't worry if you don't understand some of the above terms, we will explore them later. TokenId is encoded specifically to distinguish each component listed above. Most of the `Office` contract functions' parameters include a tokenId. Each tokenId has a specific `TokenType` associated with it. Read more about tokenId encoding in [`TokenIdEncoding`](./dev/TokenIdEncoding.md).

### Accounts

We use `Accounts` type instead of addresses to represent a user and their assets or liabilities. There are 2 types of accounts:

1. User Accounts

Each user has an associated user account by default derived from their public key (or address). This account cannot be transferred and can be controlled by the owner of the private key or operators as set by the address.

2. Isolated Accounts

Anyone can create an isolated account on behalf of anyone. The isolated account is not bound to any address or market permanently. This account can be transferred to any other address (user account). The `Office` contract can accommodate at most `2^96 - 2` accounts. Rest of the functionality is exactly the same as user accounts.

Each account can only take debt in one asset per market. This means although an account can take debt from any market, only one asset in that market can be borrowed at a time. This simplifies the accounting and liquidations or repayments. Accounts allow us to isolate positions for any address and allow transferability of positions. There is no discrimination between the 2 account types. Read more in [`Accounts`](./Accounts.md).

Assets can be withdrawn or borrowed subject to health checks based on the weighted collateral value and debt asset.

### Hooks

Inspired by Uni-v4 and the customization it offers, hooks will be an integral part of DYTM. Hooks are contracts that can be set by the officer of a market. They allow for custom logic to be executed before and after a market function is executed. Hooks can be used to implement custom logic such as:

- KYC-compliant pools. Only KYC compliant addresses can participate in a market.
- Sweeping approvals for certain type of borrowers. For example, all Toros vaults can participate in a market.
- 1-click limit-order modifications during a borrow, liquidation or position modification actions.
- Partial customization of liquidations logic such as allowing specific addresses to liquidate a positions, or modifying bonus percentage based on certain conditions (quality of collateral, LTVs etc).
- Efficient reward distributions. Distribution of incentives just after a withdrawal or supply action.
- Instant bad debt coverage. Donating to a reserve from a fund specifically for covering bad debts.
- Supply/borrow caps.

The hooks contract will be a configurable parameter of a market. However, the functions will be invoked based on the address similar to how Uni-v4 hook function invocation works. This means, the address of the hook contract needs to be mined according to the functions to be invoked.

### Weights

The amount an account can borrow is determined by the weights assigned between the collateral asset(s) and the debt asset. Higher the weight for a pair of collateral and debt asset, the more leverage an account can take using that pair. Weights are provided by a contract as specified by the officer of the market in the market config contract. Read more about it in [`Weights`](./Weights.md).

### Interest Rate Model (IRM)

Any officer can set any interest rate model (IRM) they want for their markets. It needs to adhere to a specific interface. We have implemented a couple of IRMs as follows:

1. [Linear Kink IRM](./LinearKinkIRM.md)
2. [Fixed Borrow Rate IRM](../src/IRM/FixedBorrowRateIRM.sol)
   
The former is similar to how IRMs in Aave and Compound work (utlisation based interest rates). The latter is similar to Morpho's [FixedRateIRM](https://github.com/morpho-org/morpho-blue-irm/blob/0e99e647c9bd6d3207f450144b6053cf807fa8c4/src/fixed-rate-irm/FixedRateIrm.sol) meant to fix the borrow rates regardless of reserve utilisation.

## Market Functions

### Supplying Assets

A user can supply assets in 2 ways:

1. Escrowed Assets

If the user wishes to provide collateral for a debt position they have taken or plan to take without lending it out, they can simply escrow their assets in the market. It won't earn any interest and will not increase lending reserve amount. This means it will also not be subject to liquidity constraints and bad-debt accrual risks. These assets can be withdrawn any time as long as the account remains healthy afterwards. The shares are priced 1:1 with their underlying. It's similar to the amount one gets back when one wraps ETH to WETH and vice-versa.

1. Lent Assets
   
If the user wishes to lend their collateral or just lend it as an LP, they can do so using the same `supply` function. They will be subject to liquidity constraints during withdrawals and also bad-debt accrual risks but they will earn interest.

The user is minted shares proportional to their supplied amount. The tokenId for both of these share types are different by 1 bit. Read more about this in [`TokenIdEncoding`](./dev/TokenIdEncoding.md).

### Switch Collateral Type

A user can switch their supplied assets between lent and escrowed types using the `switchCollateral` function. This is useful when a user wants to lend their escrowed assets to earn interest or wants to escrow their lent assets to avoid bad-debt risks or for taking a debt position in the market.

### Borrow Assets

Each account can have at most one debt asset per market. This simplifies liquidations and avoids complex collateral valuation, as weights are defined pair-wise between collateral and debt assets. If a user wants even more customization then they can use different accounts and use different collateral and debt assets or amounts.

To borrow, the user can use already supplied assets or provide collateral during the borrow call. For the latter, they will need to use the `delegationCall` function. More about this later.

The amount an account can borrow depends on the valuation of the collateral assets (which depends on the weights). The health checks are done right after the borrow call.

### Withdrawing Assets

A user can withdraw their assets (lent or escrowed) as long as:

- There is enough liquidity in the reserve to cover the withdrawal.
- The account remains healthy after the withdrawal.

Note that users can withdraw their escrowed assets at any time without any liquidity constraints as long as the account remains healthy. This is because they are not lent out.

### Repay Debt

A user can repay their debt provided they have enough of the debt asset while repaying. They can also use collateral assets to repay their debt but this involves using the `delegationCall` function to withdraw the collateral, swap it to the debt asset (if required) and then repay the debt.

Repayment transaction will fail in case the account becomes unhealthy after the repayment.

### Liquidations

When the weighted collateral value of an account falls below the debt asset value, the account is considered unhealthy. Anyone can liquidate an unhealthy account as long as the officer of the market doesn't restrict liquidations to specific addresses via hooks. Liquidator can use the `isHealthyAccount` function to check if an account is healthy or not.

The liquidator needs to provide an array of collateral shares and amounts to liquidate. The debt shares amount to be burned is calculated based on the amount of collateral shares being liquidated and the liquidation bonus percentage set by the officer of the market. For example if the debt value is $100 in USDC and total collateral value is $120 in ETH, the liquidation bonus is 10%, the liquidator would need to liquidate collateral shares worth:

$$\text{collateralValueToLiquidate} = \frac{\text{debtValue}}{1 - \text{liquidationBonus}} = \frac{100}{1 - 0.1} = \$111.11$$

If using a smart contract to repay debt, you can take a look at the `getLiquidationCollaterals` function in [`CommonFunctions`](../test/helpers/CommonFunctions.sol). Otherwise, implement the same logic offchain and pass the calculated collateral shares and amounts to the `liquidate` function.

The liquidator can also provide additional data which will be used for liquidation callback. This is useful for custom liquidation logic such as swapping the collateral to the debt asset and then repaying the debt. The liquidator must approve enough debt asset amount to the Office for repayment.

The liquidator is always paid a bonus amount as long as the bonus percentage is greater than 0 regardless of the position having accrued bad debt or not. The bonus is either deducted from the liquidation repayment obligation of the liquidator or directly transferred to the liquidator the latter being the case if the bonus is greater than the repayment obligation which could happen if the collateral asset and debt asset are the same.

Liquidations can't be done during a `delegationCall`. This is because an account can be made temporarily unhealthy and forcefully liquidated.

#### Using DEX Aggregators

If a liquidator attempts to liquidate an account completely and they use a dex aggregator swap route data, it's possible that the account might not be completely liquidated due to the debt value increasing between the time they fetched the swap route and the time they executed the liquidation. 

Estimating when a liquidation may happen is difficult and the liquidation transaction could fail if fetching the swap route using estimated debt and collateral values. 

If the weighted collateral value being liquidated is greater than the debt value, the liquidation will fail as the liquidated collateral value, when converted to debt shares, will be greater than the actual debt shares owned by the account.

Theoretically, the liquidator can use some of the bonus amount received to cover the difference in debt shares and ensure the liquidation is successful. A combination of using DEX aggregator routes and onchain swaps (using Uni-v3 or similar) can be employed to avoid covering the difference from the bonus amount. To confirm the account has been completely liquidated, the liquidator can check the balance of the debt shares of the account after the liquidation.

### Migrating Supplied Assets

A user can migrate their supplied assets to another market provided:

- The source market doesn't restrict migrations via hooks.
- The source market has enough withdrawal liquidity (this is not an issue for escrowed assets).
- The target market allows the asset to be supplied.
- The target market doesn't restrict migrations via hooks.
- The account remains healthy in the source market after the migration.

Assets are not transferred anywhere since all markets live in the same `Office` contract. Only internal accounting is updated to reflect the migration.

### Reserve Donations

An officer of a market can donate assets to reserves. This increases the supplied amount of the asset in the lending reserve. These assets can't be clawed back (at least directly). This functionality can be used to cover bad debts out of pocket or as another mechanism to incentivize lenders.

### Flashloan

Any address can take a flashloan of any available asset in the `Office` contract. There are no fees or restrictions for any address. Works exactly like a flashloan in other lending protocols like Morpho.

### Delegation Calls

An authorized caller (can also be an operator) of an account can approve another address temporarily (for the duration of the transaction) to be the operator of the account. This is useful for batching actions natively without requiring smart contract accounts or EIP7702 support. The operator can then call any market function on behalf of the account. This is useful for:

- Supplying collateral and borrowing assets in a single transaction.
- Repaying debt using the supplied collateral of the account.
- Migrating debt from one market to another.

And a lot more. Operators cannot transfer authority of the account to another address except when the owner of the account has explicitly approved the operator to do so. However, operators can transfer collateral assets to another address or accounts. It's crucial to understand what the `delegatee` (the temporary operator) can and cannot do before giving them the authorization as they can potentially drain the account of all its assets in several ways. 

A crucial advantage of delegation calls is that the health checks are done at the end of the call. This means the operator can do anything with the account (within the operator's scope) as long as the account remains healthy at the end of the call. This allows for complex actions to be batched without worrying about the account becoming unhealthy in between which could happen for example when swapping one of the collateral assets to another asset for the same debt position.

During delegation calls, the `delegatee` can operator on a maximum of 10 accounts/markets (arbitrarily hardcoded as a constant in [Constants](./src/libraries/Constants.sol)) at a time provided the account made a health-modifying action (such as `borrow`, `withdraw`, `migrateSupply`). This limit is mainly due to gas constraints.
