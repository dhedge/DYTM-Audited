# AI Audit Run - Issues Report

## Run Information

**Run UUID:** 3b8df71e-00fe-448c-a052-cc46a3f2c1e2
**Run Number:** 275
**Status:** FINISHED
**Created:** 2025-12-01 19:04:06.021567
**Started:** 2025-12-01 19:04:07.825566
**Ended:** 2025-12-01 19:33:52.362186
**Repository:** dhedge/DYTM
**Branch:** main
**Commit:** 16207b8fb661abe42c81ec4159392a0b9f282daa

**Total Issues:** 7


## Advanced Options

## Issues

### Issue #1: `beforeMigrateSupply` Hook Allows Whitelist Bypass, Enabling Unauthorized Supply Migration

**Severity:** Medium
**Issue Validity:** Protocol didn't classify

**Description:**
## Description

The `SimpleAccountWhitelist` contract is designed to enforce whitelist checks for supply and borrow operations by overriding the `beforeSupply` and `beforeBorrow` hooks to invoke the `_verify` function. However, it does not override the `beforeMigrateSupply` hook, which defaults to the implementation in `BaseHook`. This default implementation only enforces the `onlyOffice` modifier and does not perform any whitelist verification. As a result, when the `Office` contract uses this hook during the migration of a user's supplied position, an unwhitelisted account can migrate its supply without restriction. This bypasses the whitelist and allows unauthorized supply positions to be established in the destination market.

## Attack Path

The attack path involves the following sequence of actions:

1. A whitelisted account owner supplies assets to Market A.
2. The admin subsequently removes the account owner from the whitelist.
3. The account owner then calls the `Office.migrateSupply` function to move their supply from Market A to Market B.
4. The `onlyAuthorizedCaller` modifier in `Office.migrateSupply` passes, and the `beforeMigrateSupply` hooks for both the source and destination markets are called.
5. Since the `beforeMigrateSupply` hook in `BaseHook` does not perform a whitelist check, the migration proceeds without restriction.
6. The `_supply` function mints new shares for Market B, allowing the account owner to establish an unauthorized supply position in the destination market.

## Impact

This vulnerability allows users who are no longer whitelisted, or who were never intended to supply in a particular market, to migrate their existing supplied assets into that market. This bypasses the intended access control mechanisms and enables unauthorized supply positions. While this does not directly result in fund theft, it undermines the integrity of the whitelist system and could lead to unauthorized users gaining access to markets they should not be able to participate in. This access-control failure is rated as medium severity due to the potential for unauthorized enablement rather than direct financial loss.

## Suggested Fix

Add whitelist enforcement to migrate supply hook in SimpleAccountWhitelist.

```diff
--- a/src/extensions/hooks/SimpleAccountWhitelist.sol
+++ b/src/extensions/hooks/SimpleAccountWhitelist.sol
@@
-    constructor(
-        address admin,
-        address office
-    )
-        BaseHook(uint160(BEFORE_SUPPLY_FLAG | BEFORE_BORROW_FLAG), office)
-        Ownable(admin)
-    {}
+    constructor(
+        address admin,
+        address office
+    )
+        BaseHook(uint160(BEFORE_SUPPLY_FLAG | BEFORE_BORROW_FLAG | BEFORE_MIGRATE_SUPPLY_FLAG), office)
+        Ownable(admin)
+    {}
@@
     /// @notice Only allows whitelisted accounts/owners to borrow.
     function beforeBorrow(BorrowParams calldata params) public override {
         super.beforeBorrow(params);
         _verify(params.account);
     }
+
+    /// @notice Enforces whitelist checks during supply migrations.
+    function beforeMigrateSupply(MigrateSupplyParams calldata params) public override {
+        super.beforeMigrateSupply(params);
+        _verify(params.account);
+    }
```

---

### Issue #2: `createMarket` lacks access control for market configurations, allowing arbitrary market creation and potential fund drainage

**Severity:** High
**Issue Validity:** Protocol didn't classify

**Description:**
## Description

The `createMarket` function in the `Office` contract is externally callable without any access control modifiers. This function allows any address to create a new market and immediately set an arbitrary `IMarketConfig` via the `_setMarketConfig` function. The market configuration includes critical parameters such as hooks, oracle modules, asset weights, and borrow limits, which are trusted across the protocol's borrowing and supplying logic. As a result, an attacker can register a market with a configuration that overvalues worthless collateral and authorizes malicious hooks. This setup enables the attacker to attract liquidity and borrow genuine assets while maintaining a "healthy" account status, effectively draining depositor funds from the market.

## Attack Path

The attack sequence is as follows:

1. The attacker deploys a malicious `IMarketConfig` contract that returns favorable conditions for a junk collateral token, including pointing oracle and weight parameters to contracts that massively overvalue the token.
2. The attacker calls `createMarket` with their address and the malicious market configuration to list the market.
3. Liquidity, either from unsuspecting depositors or attacker-seeded, is moved into the market using the `supply` function, which trusts the market configuration's `isSupportedAsset` method.
4. The attacker mints and supplies the junk collateral, then calls the `borrow` function to withdraw genuine assets. The `_checkHealth` function relies on the malicious oracle and weight parameters, allowing the health check to pass.
5. The attacker withdraws the borrowed tokens, effectively draining the market of genuine assets.

## Impact

This vulnerability allows an attacker to create a market with a malicious configuration that overvalues worthless collateral. By exploiting this setup, the attacker can attract or seed liquidity, deposit junk collateral, and borrow genuine assets while maintaining a healthy account status. This results in the unrestricted theft of supplier funds from the market, leading to a significant financial loss for depositors and potential insolvency of the protocol. The lack of access control on the `createMarket` function makes this a high-severity issue, as it enables unprivileged and fully exploitable fund drainage.

## Suggested Fix

Restrict createMarket to the governor officer to prevent unauthorized market setup.

```diff
@@
     using HooksCallHelpers for IHooks;
     using FixedPointMathLib for uint256;
     using EnumerableSet for EnumerableSet.UintSet;
     using EnumerableSet for EnumerableSet.AddressSet;
 
+    MarketId private constant GOVERNOR_MARKET = MarketId.wrap(0);
+
+    constructor() {
+        _setOfficer(GOVERNOR_MARKET, msg.sender);
+    }
+
@@
-    function createMarket(address officer, IMarketConfig marketConfig) external returns (MarketId marketId) {
+    function createMarket(address officer, IMarketConfig marketConfig)
+        external
+        onlyOfficer(GOVERNOR_MARKET)
+        returns (MarketId marketId)
+    {
         // Note that we are pre-incrementing the market count here to ensure that the marketId starts from 1.
         marketId = (++getOfficeStorageStruct().marketCount).toMarketId();
 
         _setOfficer(marketId, officer);
         _setMarketConfig(marketId, marketConfig);
```

---

### Issue #3: `switchCollateral` function allows burning of collateral shares without transferring equivalent assets, leading to potential loss of user funds.

**Severity:** Medium
**Issue Validity:** Protocol didn't classify

**Description:**
## Description

The `switchCollateral` function in the `Office` contract is designed to switch collateral from one reserve to another. However, when the function is called with a small `shares` value, it can result in the burning of collateral shares without transferring the equivalent amount of assets. This occurs because the `toAssetsDown` conversion in the `_withdraw` function floors the result, potentially returning zero assets for small share amounts. Despite this, the `_burn` function still destroys the full `sharesRedeemed`, leading to a loss of collateral for the user. This vulnerability can be exploited by a malicious operator approved through the `onlyAuthorizedCaller` modifier to intentionally burn a victim's collateral without transferring any funds elsewhere.

## Attack Path

The attack can be executed as follows:

1. A user supplies a small amount of collateral to the market, receiving a corresponding number of shares.
2. An authorized operator calls the `switchCollateral` function with a `shares` value that is small enough to result in `assetsWithdrawn` being zero due to the flooring in the `toAssetsDown` conversion.
3. The `_burn` function is called, destroying the specified number of shares without transferring any assets.
4. The operator can repeat this process with dust-sized share amounts to systematically wipe out the user's collateral without transferring any value.

## Impact

This vulnerability allows an authorized operator to burn a user's collateral shares without transferring the equivalent assets, resulting in a permanent loss of the user's collateral. The user is left with no collateral in the market, and the operator can continue to exploit this vulnerability to wipe out additional collateral. This can lead to significant financial losses for users and undermine trust in the protocol.

## Suggested Fix

Revert share-based withdrawals that redeem zero assets to prevent silent burns.

```diff
--- a/src/Office.sol
+++ b/src/Office.sol
@@
     using HooksCallHelpers for IHooks;
     using FixedPointMathLib for uint256;
     using EnumerableSet for EnumerableSet.UintSet;
     using EnumerableSet for EnumerableSet.AddressSet;
 
+    error Office__ZeroAssetsWithdrawn(uint256 shares);
+
     //////////////////////////////////////////////
     //                 Modifiers                //
     //////////////////////////////////////////////
@@
             if (assets != 0) {
                 assetsWithdrawn = assets;
                 sharesRedeemed = assets.toSharesUp($reserveData.supplied, totalSupply(tokenId));
             } else {
                 sharesRedeemed = Utils.someOrMaxShares({account: account, tokenId: tokenId, requested: shares});
                 assetsWithdrawn = sharesRedeemed.toAssetsDown($reserveData.supplied, totalSupply(tokenId));
+                if (sharesRedeemed != 0 && assetsWithdrawn == 0) {
+                    revert Office__ZeroAssetsWithdrawn(sharesRedeemed);
+                }
             }
 
             $reserveData.supplied -= assetsWithdrawn;
```

---

### Issue #4: Allowance charged to receiver enables unauthorized spends

**Severity:** High
**Issue Validity:** Protocol didn't classify

**Description:**
## Description

The `transferFrom` function in the `Registry` contract deducts allowance by passing the `receiver` as the `spender` argument to the `_spendAllowance` function. This occurs in lines 18-28 of the `Registry.sol` file. Inside `_spendAllowance`, located at lines 12-21, the allowance mapping at `allowances[from][tokenId][spender]` is reduced for the receiver account. This implementation allows any `msg.sender` to consume another party’s allowance as long as they set the same receiver. Consequently, arbitrary callers can drain allowances that owners intended only specific spenders to use, forcing owners’ tokens to be transferred to third-party receivers without authorization. This results in a loss of funds when the receiver, such as a protocol contract, does not credit the owner.

## Attack Path

The attack follows this sequence: an attacker identifies an allowance set for a specific receiver account. The attacker then calls `transferFrom` with the sender as the victim, the receiver as the account with the allowance, and the desired token and amount. The function checks if the caller is neither the owner nor an operator, and if so, it routes the allowance check through `_spendAllowance` with the `spender` set to the receiver. `_spendAllowance` then deducts the allowance for the receiver, allowing the transfer to proceed. The tokens are transferred from the victim to the receiver, even though the attacker was never approved as a spender.

## Impact

This vulnerability allows unrestricted third-party use of every allowance, enabling full theft of tokens. Any caller can drain an allowance by calling `transferFrom` with the receiver that was originally approved. Since there is no requirement that `msg.sender` match the approved spender, an attacker can force transfers from a victim’s account to a permitted receiver without that receiver’s participation. This leads to an unauthorized loss of the victim’s tokens, as the tokens are transferred to the receiver without the owner's consent. The severity of this issue is high, as it results in a complete loss of control over token allowances and potential financial loss for token owners.

## Suggested Fix

Pass msg.sender as spender when debiting allowances in transferFrom.

```diff
@@
-        address caller = msg.sender;
-        address currentOwner = ownerOf(sender);
+        address caller = msg.sender;
+        AccountId callerAccount = AccountId.wrap(uint256(uint160(caller)));
+        address currentOwner = ownerOf(sender);
@@
             _spendAllowance({
                 currentOwner: currentOwner,
                 from: sender,
-                spender: receiver,
+                spender: callerAccount,
                 tokenId: tokenId,
                 amount: amount
             });
```

---

### Issue #5: `setOracle` function causes exponent overflow, blocking high-decimal oracle setup

**Severity:** Medium
**Issue Validity:** Protocol didn't classify

**Description:**
## Description

The `setOracle` function in the `dHEDGEPoolPriceAggregator` contract is responsible for configuring oracle data for assets. It calculates a `scale` value using the formula `10 ** (assetDecimals + oracleDecimals)`. This calculation is intended to adjust asset prices according to their respective decimal places. However, if an asset has a high number of decimals, such as 60, and the associated Chainlink oracle feed has 18 decimals, the sum of these decimals reaches 78. This results in an exponentiation of `10 ** 78`, which exceeds the maximum value for a `uint256` type in Solidity, causing an overflow. Under Solidity 0.8, this overflow triggers a revert due to built-in overflow checks, preventing the function from completing successfully. As a result, the oracle entry for such assets cannot be set, effectively denying service to any pools that rely on these high-decimal tokens.

## Attack Path

The attack path involves attempting to set an oracle for an asset with a high number of decimals:

1. The owner calls `setOracle` with an asset that has 60 decimals and a Chainlink oracle feed with 18 decimals.
2. The function retrieves the asset's decimals using `_getDecimals(asset)`, which returns 60.
3. It then retrieves the oracle's decimals using `AggregatorV3Interface(oracle).decimals()`, which returns 18.
4. The function attempts to compute `scale = 10 ** (assetDecimals + oracleDecimals)`, resulting in `10 ** 78`.
5. This computation exceeds the maximum value for a `uint256`, causing an overflow and triggering a revert.
6. The oracle mapping remains unset, and the asset cannot be onboarded.

## Impact

This vulnerability results in a denial of service for any assets with a high number of decimals that exceed the overflow threshold when combined with their oracle's decimals. Such assets cannot be onboarded or priced, disrupting any pools that depend on them. This limitation prevents the protocol from supporting a broader range of tokens, particularly those with legitimate high decimal counts, thereby reducing its flexibility and utility.

---

### Issue #6: `tx.origin` Gating Allows Phishing to Hijack Delegatee

**Severity:** High
**Issue Validity:** Protocol didn't classify

**Description:**
## Description

The `aggregate` function in the `OwnableDelegatee` contract authorizes callers using the condition `require(tx.origin == owner())`. This check is intended to ensure that only the owner of the contract can execute the function. However, this approach is vulnerable to phishing attacks. If the owner, an externally owned account (EOA), is tricked into interacting with a malicious contract, that contract can synchronously invoke `aggregate` while `tx.origin` remains the owner. This allows the attacker to supply arbitrary `Call` structs that execute privileged actions via `onDelegationCallback(...) → aggregate()`, enabling theft or misuse of any assets or permissions the delegatee controls.

## Attack Path

The attack sequence begins with the deployment of a malicious contract by the attacker. This contract, referred to as `Evil`, contains a function `phish` that takes the address of the `OwnableDelegatee` contract and an array of `Call` structs as parameters. The owner of the `OwnableDelegatee` contract is then tricked into sending a transaction to `Evil.phish`. Inside this function, `Evil` immediately invokes `delegatee.aggregate(calls)`. Since the owner remains `tx.origin`, the check `require(tx.origin == owner())` passes, allowing the attacker to execute the supplied `Call[]`. For example, the first element in the array could target an ERC20 contract with calldata to transfer tokens to the attacker, effectively enabling the attacker to drain assets or perform other privileged operations.

## Impact

This vulnerability exposes the `OwnableDelegatee` contract to complete compromise whenever the owner is tricked into interacting with a malicious contract. The attacker can execute arbitrary operations, such as transferring ERC20 tokens or changing permissions, leading to potential theft or misuse of the delegatee's assets and permissions. This flaw undermines the security model of the contract, as it relies on `tx.origin` for authorization, which is insufficient to prevent phishing attacks. The impact is significant, as it allows attackers to fully exploit the delegatee's capabilities without any additional safeguards.

## Suggested Fix

Authorize aggregate using msg.sender to prevent tx.origin phishing bypasses.

```diff
-        require(tx.origin == owner(), OwnableDelegatee__NotOwner());
+        if (msg.sender != owner()) revert OwnableDelegatee__NotOwner();
```

---

### Issue #7: Re-registering swaps wrapper and locks prior deposits

**Severity:** Medium
**Issue Validity:** Protocol didn't classify

**Description:**
## Description

The `register` function in `OfficeERC6909ToERC20Wrapper.sol` allows the market officer to deploy a new `WrappedERC6909ERC20` contract for a given token ID using the CREATE2 opcode. This function can be called repeatedly with different parameters, such as name, symbol, and decimals, which results in the deployment of a new wrapper contract at a different address. However, the function overwrites the `getERC20[id]` mapping with the new contract address, while the old wrapper contract still exists. Consequently, when users attempt to unwrap their tokens using the `unwrap` function, the contract interacts with the latest wrapper contract, causing the burn operation to fail if the user holds tokens from the previous wrapper. This results in the permanent locking of the user's ERC6909 collateral within the contract, as there is no mechanism to revert the mapping to the original wrapper.

## Attack Path

The attack path involves the following sequence of actions:

1. The market officer calls the `register` function with a specific token ID and initial parameters (e.g., name "Old", symbol "SYM", decimals 18), deploying the first wrapper contract (Wrapper A) and storing its address in `getERC20[id]`.
2. A user wraps their ERC6909 tokens using Wrapper A, which mints the corresponding ERC20 tokens to the user.
3. The market officer calls the `register` function again with the same token ID but different parameters (e.g., name "New", symbol "NSYM", decimals 6), deploying a new wrapper contract (Wrapper B) and overwriting the `getERC20[id]` mapping with the new address.
4. When the user attempts to unwrap their tokens, the `unwrap` function interacts with Wrapper B, where the user has no balance, causing the burn operation to revert.
5. The user's ERC6909 collateral remains locked in Wrapper A, as the mapping cannot be restored to the original wrapper address.

## Impact

This vulnerability allows a malicious or careless market officer to permanently lock user deposits for a specific token ID. Users who have wrapped their ERC6909 tokens using an earlier wrapper contract will be unable to unwrap their tokens, as the `unwrap` function will fail due to the overwritten `getERC20[id]` mapping. This results in the permanent loss of access to their collateral, as there is no mechanism to revert the mapping to the original wrapper contract. The issue requires action by the privileged market officer, so the impact is rated as medium severity.

## Suggested Fix

Disallow re-registering an existing wrapper to prevent overwriting mappings.

```diff
@@
-    error OfficeERC6909ToERC20Wrapper__NotOfficer(MarketId market, address caller);
+    error OfficeERC6909ToERC20Wrapper__NotOfficer(MarketId market, address caller);
+    error OfficeERC6909ToERC20Wrapper__AlreadyRegistered(uint256 id);
@@
         require(
             msg.sender == IOfficeStorage(OFFICE).getOfficer(market),
             OfficeERC6909ToERC20Wrapper__NotOfficer(market, msg.sender)
         );
 
+        if (getERC20[id] != address(0)) {
+            revert OfficeERC6909ToERC20Wrapper__AlreadyRegistered(id);
+        }
+
         erc20 = address(new WrappedERC6909ERC20{salt: keccak256(abi.encodePacked(id))}(name, symbol, decimals));
```

---
