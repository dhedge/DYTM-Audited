// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.29;

import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";
import {SafeCast} from "@openzeppelin-contracts/utils/math/SafeCast.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {SafeERC20} from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin-contracts/utils/structs/EnumerableSet.sol";

import {MarketIdLibrary} from "./types/MarketId.sol";
import {ReserveKeyLibrary} from "./types/ReserveKey.sol";
import {AccountIdLibrary} from "./types/AccountId.sol";
import {MarketId, AccountId, ReserveKey} from "./types/Types.sol";

import {IHooks} from "./interfaces/IHooks.sol";
import {IOffice} from "./interfaces/IOffice.sol";
import {IWeights} from "./interfaces/IWeights.sol";
import {IDelegatee} from "./interfaces/IDelegatee.sol";
import {ILiquidator} from "./interfaces/ILiquidator.sol";
import {IOracleModule} from "./interfaces/IOracleModule.sol";
import {IMarketConfig} from "./interfaces/IMarketConfig.sol";
import {IFlashloanReceiver} from "./interfaces/IFlashloanReceiver.sol";
import {
    DelegationCallParams,
    SupplyParams,
    SwitchCollateralParams,
    WithdrawParams,
    BorrowParams,
    RepayParams,
    LiquidationParams,
    MigrateSupplyParams
} from "./interfaces/ParamStructs.sol";

import {Registry} from "./abstracts/Registry.sol";
import {Context} from "./abstracts/storages/Context.sol";
import {OfficeStorage} from "./abstracts/storages/OfficeStorage.sol";
import {TransientEnumerableHashTableStorage} from "./abstracts/storages/TransientEnumerableHashTableStorage.sol";

import "./libraries/Constants.sol" as Constants;
import {Utils} from "./libraries/Utils.sol";
import {SharesMathLib} from "./libraries/SharesMathLib.sol";
import {HooksCallHelpers} from "./libraries/HooksCallHelpers.sol";
import {TokenHelpers, TokenType} from "./libraries/TokenHelpers.sol";
import {
    getOfficeStorageStruct,
    getRegistryStorageStruct,
    getReserveDataStorage
} from "./libraries/StorageAccessors.sol";

/// @title Office
/// @notice Core contract of the DYTM protocol.
/// @author Chinmay <chinmay@dhedge.org>
contract Office is IOffice, OfficeStorage, Context, Registry, TransientEnumerableHashTableStorage {
    using Math for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;
    using TokenHelpers for uint256;
    using SharesMathLib for uint256;
    using MarketIdLibrary for uint88;
    using HooksCallHelpers for IHooks;
    using FixedPointMathLib for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @inheritdoc IOffice
    function createMarket(address officer, IMarketConfig marketConfig) external returns (MarketId marketId) {
        // Note that we are pre-incrementing the market count here to ensure that the marketId starts from 1.
        marketId = (++getOfficeStorageStruct().marketCount).toMarketId();

        _setOfficer(marketId, officer);
        _setMarketConfig(marketId, marketConfig);

        emit Office__MarketCreated({officer: officer, marketConfig: marketConfig, market: marketId});
    }

    /// @inheritdoc IOffice
    function delegationCall(DelegationCallParams calldata params)
        external
        useContext(params.delegatee)
        returns (bytes memory returnData)
    {
        returnData = IDelegatee(params.delegatee).onDelegationCallback(params.callbackData);

        // If the `delegatee` called any function which reduces the account's health,
        // we need to check if the account is still healthy.
        if (requiresHealthCheck) {
            uint8 length = TransientEnumerableHashTableStorage._getLength();

            for (uint8 i; i < length; ++i) {
                (AccountId account, MarketId market) = TransientEnumerableHashTableStorage._get(i);
                require(isHealthyAccount(account, market), Office__AccountNotHealthy(account, market));
            }
        }
    }

    ///////////////////////////////////////////////
    //              Market Functions             //
    ///////////////////////////////////////////////

    /// @inheritdoc IOffice
    function supply(SupplyParams calldata params) external returns (uint256 shares) {
        ReserveKey key = params.tokenId.getReserveKey();
        MarketId market = key.getMarketId();
        IMarketConfig marketConfig = getMarketConfig(market);
        IHooks hooks = marketConfig.hooks();
        IERC20 supplyAsset = key.getAsset();
        uint256 assets = Utils.someOrMaxAssets(supplyAsset, params.assets);

        hooks.callHook({hookSelector: IHooks.beforeSupply.selector, flag: Constants.BEFORE_SUPPLY_FLAG});

        // Check if the asset is allowed for supply.
        require(marketConfig.isSupportedAsset(supplyAsset), Office__ReserveNotSupported(key));

        // Mint shares to the account and update reserve data.
        shares = _supply({marketConfig: marketConfig, tokenId: params.tokenId, account: params.account, assets: assets});

        // Transfer the asset from the caller to the Office contract.
        supplyAsset.safeTransferFrom({from: msg.sender, to: address(this), value: assets});

        hooks.callHook({hookSelector: IHooks.afterSupply.selector, flag: Constants.AFTER_SUPPLY_FLAG});

        emit Office__AssetSupplied({account: params.account, tokenId: params.tokenId, shares: shares, assets: assets});
    }

    /// @inheritdoc IOffice
    function switchCollateral(SwitchCollateralParams calldata params)
        external
        onlyAuthorizedCaller(params.account)
        returns (uint256 assets, uint256 shares)
    {
        ReserveKey key = params.tokenId.getReserveKey();
        MarketId market = key.getMarketId();
        IMarketConfig marketConfig = getMarketConfig(market);
        IHooks hooks = marketConfig.hooks();
        IWeights weights = marketConfig.weights();
        uint256 toTokenId = (params.tokenId.getTokenType() == TokenType.LEND) ? key.toEscrowId() : key.toLentId();

        hooks.callHook({
            hookSelector: IHooks.beforeSwitchCollateral.selector, flag: Constants.BEFORE_SWITCH_COLLATERAL_FLAG
        });

        // Withdraw the assets from the lending reserve or escrow and supply them to the other reserve.
        uint256 fromShares;
        (assets, fromShares,) = _withdraw({
            marketConfig: marketConfig,
            account: params.account,
            tokenId: params.tokenId,
            assets: params.assets,
            shares: params.shares,
            inKind: false
        });

        // We skip the asset support check given that the asset is already supplied to the market
        // and hence supported.
        shares = _supply({marketConfig: marketConfig, tokenId: toTokenId, account: params.account, assets: assets});

        // Note: DO NOT MOVE THIS DECLARATION TO THE TOP OF THE FUNCTION along with other variable declarations.
        // Hooks may provide execution control to the caller or someone who can borrow funds and
        // transfer them to create a barely healthy account.
        ReserveKey debtKey = getDebtId(params.account, market).getReserveKey();

        // If the account has debt and if the weight of the collateral being switched from
        // is higher than the weight of the collateral being switched to,
        // we need to check the health of the account.
        if (
            debtKey != Constants.RESERVE_KEY_ZERO
                && (weights.getWeight(params.account, params.tokenId, debtKey)
                        > weights.getWeight(params.account, toTokenId, debtKey))
        ) {
            _checkHealth(params.account, market);
        }

        hooks.callHook({
            hookSelector: IHooks.afterSwitchCollateral.selector, flag: Constants.AFTER_SWITCH_COLLATERAL_FLAG
        });

        emit Office__CollateralSwitched({
            account: params.account,
            fromTokenId: params.tokenId,
            oldShares: fromShares,
            newShares: shares,
            assets: assets
        });
    }

    /// @inheritdoc IOffice
    function withdraw(WithdrawParams calldata params)
        external
        onlyAuthorizedCaller(params.account)
        returns (uint256 assets)
    {
        MarketId market = params.tokenId.getMarketId();
        IMarketConfig marketConfig = getMarketConfig(market);
        IHooks hooks = marketConfig.hooks();

        hooks.callHook({hookSelector: IHooks.beforeWithdraw.selector, flag: Constants.BEFORE_WITHDRAW_FLAG});

        uint256 shares;
        (assets, shares,) = _withdraw({
            marketConfig: marketConfig,
            account: params.account,
            tokenId: params.tokenId,
            assets: params.assets,
            shares: params.shares,
            inKind: false
        });

        // Since `_withdraw` function does not check if the account is healthy after the withdrawal,
        // we need to check it here.
        _checkHealth(params.account, market);

        // Transfer the withdrawn assets to the receiver.
        params.tokenId.getAsset().safeTransfer({to: params.receiver, value: assets});

        hooks.callHook({hookSelector: IHooks.afterWithdraw.selector, flag: Constants.AFTER_WITHDRAW_FLAG});

        emit Office__AssetWithdrawn({
            account: params.account, receiver: params.receiver, tokenId: params.tokenId, shares: shares, assets: assets
        });
    }

    /// @inheritdoc IOffice
    function borrow(BorrowParams calldata params)
        external
        onlyAuthorizedCaller(params.account)
        returns (uint256 debtShares)
    {
        ReserveData storage $reserveData = getReserveDataStorage(params.key);
        MarketId market = params.key.getMarketId();
        IERC20 debtAsset = params.key.getAsset();
        IMarketConfig marketConfig = getMarketConfig(market);
        IHooks hooks = marketConfig.hooks();

        hooks.callHook({hookSelector: IHooks.beforeBorrow.selector, flag: Constants.BEFORE_BORROW_FLAG});

        require(marketConfig.isBorrowableAsset(debtAsset), Office__AssetNotBorrowable(params.key));

        // Accrue interest to update the reserve data before minting debt shares
        // to price the debt shares correctly.
        _accrueInterest(params.key, marketConfig);

        // We first mint the debt shares and update the reserve data.
        {
            uint256 debtId = params.key.toDebtId();

            debtShares = params.assets.toSharesUp($reserveData.borrowed, totalSupply(debtId));
            $reserveData.borrowed += params.assets;

            // Before interacting with the receiver, we check if there was enough liquidity in the reserve.
            require($reserveData.borrowed <= $reserveData.supplied, Office__InsufficientLiquidity(params.key));

            _mint({to: params.account, tokenId: debtId, amount: debtShares});
        }

        // Check if the account is undercollateralized after the borrowing.
        _checkHealth(params.account, market);

        // Check if the debt is above the minimum debt amount USD.
        _checkDebtAboveMinimum(params.account, market);

        // Transfer the borrow asset to the receiver.
        debtAsset.safeTransfer(params.receiver, params.assets);

        hooks.callHook({hookSelector: IHooks.afterBorrow.selector, flag: Constants.AFTER_BORROW_FLAG});

        emit Office__AssetBorrowed({account: params.account, key: params.key, assets: params.assets});
    }

    /// @inheritdoc IOffice
    function repay(RepayParams calldata params)
        external
        onlyAuthorizedCaller(params.account)
        returns (uint256 assetsRepaid)
    {
        // Check that only one of `assets` or `shares` is non-zero.
        require(
            Utils.exactlyOneZero(params.assets, params.shares),
            Office__AssetsAndSharesNonZero(params.assets, params.shares)
        );

        MarketId market = params.key.getMarketId();
        IMarketConfig marketConfig = getMarketConfig(market);
        IHooks hooks = marketConfig.hooks();
        IERC20 debtAsset = params.key.getAsset();

        hooks.callHook({hookSelector: IHooks.beforeRepay.selector, flag: Constants.BEFORE_REPAY_FLAG});

        // Accrue interest to update the reserve data before burning debt shares
        // to price the debt shares correctly.
        _accrueInterest(params.key, marketConfig);

        // We first burn the debt shares and update the reserve data.
        uint256 shares;
        {
            ReserveData storage $reserveData = getReserveDataStorage(params.key);
            uint256 debtId = params.key.toDebtId();
            uint256 totalDebtSupply = totalSupply(debtId);

            // The user wants to repay as much as possible using assets available with them.
            if (params.assets != 0) {
                uint256 totalUserDebtShares = balanceOf(params.account, debtId);

                assetsRepaid = Utils.someOrMaxAssets(debtAsset, params.assets);
                shares = assetsRepaid.toSharesDown($reserveData.borrowed, totalDebtSupply);

                // If the calculated shares exceeds the user's debt shares, we cap it to the user's debt shares.
                // We also calculate the assetsRepaid again to ensure that we don't over-repay.
                if (shares > totalUserDebtShares) {
                    shares = totalUserDebtShares;
                    assetsRepaid = shares.toAssetsUp($reserveData.borrowed, totalDebtSupply);
                }
            } else {
                // The user wants to repay using exact amount of shares.
                shares = Utils.someOrMaxShares({account: params.account, tokenId: debtId, requested: params.shares});
                assetsRepaid = shares.toAssetsUp($reserveData.borrowed, totalDebtSupply);
            }

            $reserveData.borrowed = $reserveData.borrowed.saturatingSub(assetsRepaid);

            _burn({from: params.account, tokenId: debtId, amount: shares});
        }

        // Check if the remaining debt is above the minimum debt amount USD
        // or if the debt is fully repaid.
        _checkDebtAboveMinimum(params.account, market);

        // If the repayment is to be done via collateral, we need to withdraw the assets
        // from the account balance.
        if (params.withCollateralType != TokenType.NONE) {
            require(
                params.withCollateralType == TokenType.ESCROW || params.withCollateralType == TokenType.LEND,
                Office__InvalidCollateralType(params.withCollateralType)
            );

            // Note that we are not checking for the health of the account after this action
            // given that repaying debt via collateral cannot deteriorate the account's health.
            _withdraw({
                marketConfig: marketConfig,
                account: params.account,
                tokenId: (params.withCollateralType == TokenType.ESCROW)
                    ? params.key.toEscrowId()
                    : params.key.toLentId(),
                assets: assetsRepaid,
                shares: 0,
                inKind: false
            });
        } else {
            // Transfer the exact amount of assets from the repayer to this contract.
            // No need to check for the health of the account after this action given that
            // repaying debt via external assets can only improve the account's health.
            debtAsset.safeTransferFrom({from: msg.sender, to: address(this), value: assetsRepaid});
        }

        hooks.callHook({hookSelector: IHooks.afterRepay.selector, flag: Constants.AFTER_REPAY_FLAG});

        emit Office__DebtRepaid({
            account: params.account, repayer: msg.sender, key: params.key, assets: assetsRepaid, shares: shares
        });
    }

    /// @inheritdoc IOffice
    function liquidate(LiquidationParams calldata params) external returns (uint256 assetsRepaid) {
        IMarketConfig marketConfig = getMarketConfig(params.market);
        IHooks hooks = marketConfig.hooks();

        hooks.callHook({hookSelector: IHooks.beforeLiquidate.selector, flag: Constants.BEFORE_LIQUIDATE_FLAG});

        // DO NOT MOVE THIS TO THE TOP OF THE FUNCTION for the same reasons as mentioned in `switchCollateral`
        // function.
        ReserveKey debtKey = getDebtId(params.account, params.market).getReserveKey();
        IERC20 debtAsset = debtKey.getAsset();

        _accrueInterest(debtKey, marketConfig);

        // Given that it's possible to liquidate an account which is otherwise healthy during
        // a delegation call, we need to ensure that the transaction is not in the middle of a delegation call
        // regardless of the context.
        require(!isOngoingDelegationCall(), Office__CannotLiquidateDuringDelegationCall());

        // Check that the account is unhealthy before liquidating.
        require(
            !isHealthyAccount(params.account, params.market), Office__AccountStillHealthy(params.account, params.market)
        );

        // Process collaterals and calculate liquidator's repayment obligation
        int256 liquidatorRepaymentObligation;
        (assetsRepaid, liquidatorRepaymentObligation) = _processCollateralsAndCalculateObligation({
            params: params, debtKey: debtKey, debtAsset: debtAsset, marketConfig: marketConfig
        });

        // Handle debt share accounting and bad debt socialization
        (uint256 debtSharesRepaid, uint256 debtSharesUnpaid, uint256 debtAssetsUnpaid) =
            _handleDebtSharesAndBadDebt({params: params, debtKey: debtKey, assetsRepaid: assetsRepaid});

        // Invoke the liquidator's callback function to allow them to perform any additional actions
        // if the callback data is present.
        if (params.callbackData.length > 0) {
            ILiquidator(msg.sender).onLiquidationCallback(uint256(liquidatorRepaymentObligation), params.callbackData);
        }

        // Transfer the debt asset from the liquidator to this contract thus reducing/repaying the debt.
        // If the flow has reached here, it means that the `liquidatorRepaymentObligation` is non-negative.
        if (liquidatorRepaymentObligation != 0) {
            debtAsset.safeTransferFrom({
                from: msg.sender, to: address(this), value: uint256(liquidatorRepaymentObligation)
            });
        }

        hooks.callHook({hookSelector: IHooks.afterLiquidate.selector, flag: Constants.AFTER_LIQUIDATE_FLAG});

        emit Office__AccountLiquidated({
            account: params.account,
            liquidator: msg.sender,
            market: params.market,
            repaidShares: debtSharesRepaid,
            repaidAssets: assetsRepaid,
            unpaidShares: debtSharesUnpaid,
            unpaidAssets: debtAssetsUnpaid
        });
    }

    /// @inheritdoc IOffice
    function migrateSupply(MigrateSupplyParams calldata params)
        external
        onlyAuthorizedCaller(params.account)
        returns (uint256 assetsRedeemed, uint256 newSharesMinted)
    {
        MarketId fromMarket = params.fromTokenId.getMarketId();
        MarketId toMarket = params.toTokenId.getMarketId();
        IMarketConfig fromMarketConfig = getMarketConfig(fromMarket);
        IMarketConfig toMarketConfig = getMarketConfig(toMarket);
        IHooks fromHooks = fromMarketConfig.hooks();
        IHooks toHooks = toMarketConfig.hooks();

        fromHooks.callHook({
            hookSelector: IHooks.beforeMigrateSupply.selector, flag: Constants.BEFORE_MIGRATE_SUPPLY_FLAG
        });
        toHooks.callHook({
            hookSelector: IHooks.beforeMigrateSupply.selector, flag: Constants.BEFORE_MIGRATE_SUPPLY_FLAG
        });

        // Pre-migration checks.
        {
            ReserveKey toKey = params.toTokenId.getReserveKey();
            IERC20 fromAsset = params.fromTokenId.getReserveKey().getAsset();
            IERC20 toAsset = toKey.getAsset();

            // Ensure that both token IDs represent the same underlying asset.
            require(fromAsset == toAsset, Office__MismatchedAssetsInMigration(fromAsset, toAsset));

            // Check if the `toAsset` is supported in the `toMarket`.
            require(toMarketConfig.isSupportedAsset(toAsset), Office__ReserveNotSupported(toKey));

            // The `fromMarket` and `toMarket` must be different otherwise, this can be used to switch collateral.
            // Switching collateral by this method may not be malicious but hook implementations may not
            // take this scenario into account.
            require(fromMarket != toMarket, Office__SameMarketInMigration(params.fromTokenId, params.toTokenId));
        }

        // Withdraw the assets from the `fromTokenId` reserve and supply them to the `toTokenId` reserve.
        uint256 sharesRedeemed;
        (assetsRedeemed, sharesRedeemed,) = _withdraw({
            marketConfig: fromMarketConfig,
            account: params.account,
            tokenId: params.fromTokenId,
            assets: params.assets,
            shares: params.shares,
            inKind: false
        });
        newSharesMinted = _supply({
            marketConfig: toMarketConfig, tokenId: params.toTokenId, account: params.account, assets: assetsRedeemed
        });

        // Because we are withdrawing from one market and transferring value to another market, we need to check
        // the account's health in the old market.
        _checkHealth(params.account, fromMarket);

        fromHooks.callHook({
            hookSelector: IHooks.afterMigrateSupply.selector, flag: Constants.AFTER_MIGRATE_SUPPLY_FLAG
        });
        toHooks.callHook({hookSelector: IHooks.afterMigrateSupply.selector, flag: Constants.AFTER_MIGRATE_SUPPLY_FLAG});

        emit Office__SupplyMigrated({
            account: params.account,
            fromTokenId: params.fromTokenId,
            toTokenId: params.toTokenId,
            oldSharesRedeemed: sharesRedeemed,
            assetsRedeemed: assetsRedeemed,
            newSharesMinted: newSharesMinted
        });
    }

    /// @inheritdoc IOffice
    function donateToReserve(ReserveKey key, uint256 assets) external onlyOfficer(key.getMarketId()) {
        OfficeStorage.ReserveData storage $reserveData = getReserveDataStorage(key);

        // It isn't worth donating to a reserve which has no assets supplied as all it does is
        // increase the initial exchange rate of the reserve.
        require($reserveData.supplied != 0, Office__ReserveIsEmpty(key));

        _accrueInterest(key, getMarketConfig(key.getMarketId()));

        $reserveData.supplied += assets;

        // Transfer the donation from the caller to the Office contract.
        key.getAsset().safeTransferFrom({from: msg.sender, to: address(this), value: assets});

        emit Office__AssetDonated({key: key, assets: assets});
    }

    /// @inheritdoc IOffice
    function flashloan(IERC20 token, uint256 assets, bytes calldata callbackData) external {
        token.safeTransfer({to: msg.sender, value: assets});

        IFlashloanReceiver(msg.sender).onFlashloanCallback({assets: assets, callbackData: callbackData});

        token.safeTransferFrom({from: msg.sender, to: address(this), value: assets});

        emit Office__AssetFlashloaned({receiver: msg.sender, token: token, assets: assets});
    }

    /// @inheritdoc IOffice
    function accrueInterest(ReserveKey key) public returns (uint256 interest) {
        return _accrueInterest(key, getMarketConfig(key.getMarketId()));
    }

    //////////////////////////////////////////////////
    //                View Functions                //
    /////////////////////////////////////////////////

    /// @inheritdoc IOffice
    function isHealthyAccount(AccountId account, MarketId market) public returns (bool isHealthy) {
        // First we calculate the debt value in USD.
        uint256 debtValueUSD = _getDebtValueUSD(account, market);

        // If the debt value is zero, the account is healthy by definition.
        if (debtValueUSD == 0) {
            return true;
        }

        IMarketConfig marketConfig = getMarketConfig(market);
        IWeights weights = marketConfig.weights();
        IOracleModule oracleModule = marketConfig.oracleModule();
        ReserveKey debtKey = getDebtId(account, market).getReserveKey();
        uint256[] memory collateralIds = getAllCollateralIds(account, market);
        uint256 weightedCollateralValueUSD;

        // Next, we calculate the collateral assets' value in USD.
        for (uint256 i; i < collateralIds.length; ++i) {
            ReserveKey collateralKey = collateralIds[i].getReserveKey();

            _accrueInterest(collateralKey, marketConfig);

            // If the collateralId represents an escrow token, we simply convert the balance of the account
            // to the asset amount.
            // Otherwise, we need to calculate the asset amount using shares math lib.
            uint256 assetAmount;
            if (collateralIds[i].getTokenType() == TokenType.ESCROW) {
                assetAmount = balanceOf(account, collateralIds[i]);
            } else {
                assetAmount = balanceOf(account, collateralIds[i])
                    .toAssetsDown(getReserveDataStorage(collateralKey).supplied, totalSupply(collateralIds[i]));
            }

            // Fetch the collateral asset's value in USD and multiply it by the weight of the collateral asset
            // in relation to the debt asset and the account in context.
            weightedCollateralValueUSD += oracleModule.getQuote({
                    inAmount: assetAmount, base: address(collateralKey.getAsset()), quote: Constants.USD_ISO_ADDRESS
                })
                .mulWadDown(
                    weights.getWeight({account: account, collateralTokenId: collateralIds[i], debtAsset: debtKey})
                );

            // If at any point the weighted collateral value equals/exceeds the debt value,
            // we can conclude that the account is healthy and return early.
            // If the account isn't healthy even after accounting for the last collateral asset,
            // the function will return false as it never entered this block.
            if (weightedCollateralValueUSD >= debtValueUSD) {
                return true;
            }
        }
    }

    ////////////////////////////////////////////////
    //               Internal Functions           //
    ////////////////////////////////////////////////

    /// @dev Internal function to supply assets to the Office contract.
    ///      - This function checks if the `tokenId` is a valid collateral token.
    ///      - This function DOES NOT check if the `tokenId` is accepted in the market.
    function _supply(
        IMarketConfig marketConfig,
        uint256 tokenId,
        AccountId account,
        uint256 assets
    )
        internal
        returns (uint256 shares)
    {
        ReserveKey key = tokenId.getReserveKey();

        // Check if the tokenId is a valid collateral token.
        require(tokenId.isCollateral(), Office__IncorrectTokenId(tokenId));

        _accrueInterest(key, marketConfig);

        // If lending the token, shares are minted based on the amount supplied and the total supply of the shares.
        if (tokenId.getTokenType() == TokenType.LEND) {
            OfficeStorage.ReserveData storage $reserveData = getReserveDataStorage(key);

            shares = assets.toSharesDown($reserveData.supplied, totalSupply(tokenId));
            $reserveData.supplied += assets;
        } else {
            shares = assets;
        }

        _mint({to: account, tokenId: tokenId, amount: shares});
    }

    /// @dev Internal function to withdraw assets from the Office contract.
    ///      - This function DOES NOT check if the account will be healthy after the withdrawal.
    ///      - Exactly one of `assets` or `shares` must be non-zero.
    ///      - Guarantees that `assets` worth of shares will be withdrawn if `assets` is non-zero.
    ///        Otherwise, the transaction will revert.
    ///      - Make sure to pass `inKind` as true ONLY during a liquidation.
    ///        In all other cases, it should be false.
    ///      - `withdrawnInKind` indicates if the withdrawal was done in-kind due to insufficient liquidity
    ///         AND if `inKind` was set to true during a liquidation.
    ///      - If `withdrawnInKind` is true, technically, `assetsWithdrawn` should be zero as no assets were withdrawn.
    ///        However, during liquidations, we still need to know the value of assets that were withdrawn in-kind
    ///        to calculate the liquidation bonus and debt repaid hence we return this amount.
    function _withdraw(
        IMarketConfig marketConfig,
        AccountId account,
        uint256 tokenId,
        uint256 assets,
        uint256 shares,
        bool inKind
    )
        internal
        returns (uint256 assetsWithdrawn, uint256 sharesRedeemed, bool withdrawnInKind)
    {
        // Check if the tokenId is valid.
        require(tokenId.isCollateral(), Office__IncorrectTokenId(tokenId));

        // Check that only one of `assets` or `shares` is non-zero.
        require(Utils.exactlyOneZero(assets, shares), Office__AssetsAndSharesNonZero(assets, shares));

        ReserveKey key = tokenId.getReserveKey();

        // Accrue interest to update the reserve data before burning shares.
        _accrueInterest(key, marketConfig);

        if (tokenId.getTokenType() == TokenType.LEND) {
            OfficeStorage.ReserveData storage $reserveData = getReserveDataStorage(key);

            // If `assets` is non-zero, we calculate the shares to be redeemed based on the assets requested.
            if (assets != 0) {
                assetsWithdrawn = assets;
                sharesRedeemed = assets.toSharesUp($reserveData.supplied, totalSupply(tokenId));
            } else {
                sharesRedeemed = Utils.someOrMaxShares({account: account, tokenId: tokenId, requested: shares});
                assetsWithdrawn = sharesRedeemed.toAssetsDown($reserveData.supplied, totalSupply(tokenId));
            }

            uint256 newSupplied = $reserveData.supplied - assetsWithdrawn;

            // If the reserve doesn't have enough liquidity, we can only allow
            // withdrawal in-kind if specified. Otherwise, we revert.
            if ($reserveData.borrowed > newSupplied) {
                require(inKind, Office__InsufficientLiquidity(key));

                withdrawnInKind = true;
            } else {
                $reserveData.supplied = newSupplied;
            }
        } else {
            // If the tokenId is an escrow token, shares are priced 1:1 with the assets.
            // It is assumed that the escrow reserve will always have sufficient liquidity for withdrawals
            // given that it is not borrowable and is not at a risk of bad debt accrual.
            if (assets != 0) {
                assetsWithdrawn = sharesRedeemed = assets;
            } else {
                sharesRedeemed = Utils.someOrMaxShares({account: account, tokenId: tokenId, requested: shares});
                assetsWithdrawn = sharesRedeemed;
            }
        }

        // It's possible that due to rounding errors, the `assetsWithdrawn` is zero even though `sharesRedeemed` is non-zero
        // during normal withdrawal flow. In such a case, we don't want shares to be burned and instead revert.
        // However, during liquidation, it's acceptable for `assetsWithdrawn` to be zero.
        // While `sharesRedeemed` cannot be zero (due to rounding errors), we still check for it to be safe.
        require(
            (assetsWithdrawn != 0 && sharesRedeemed != 0) || _isOngoingLiquidationCall(),
            Office__ZeroAssetsOrSharesWithdrawn(account, key)
        );

        // Burn the shares from the account ONLY if the withdrawal is not in-kind.
        if (!withdrawnInKind) {
            _burn({from: account, tokenId: tokenId, amount: sharesRedeemed});
        }
    }

    /// @dev This function WILL NOT revert even if the asset is not borrowable.
    function _accrueInterest(ReserveKey key, IMarketConfig marketConfig) internal returns (uint256 interest) {
        ReserveData storage $reserveData = getReserveDataStorage(key);
        uint256 dt = block.timestamp - $reserveData.lastUpdateTimestamp;

        // In case no time has passed since the last update, we simply return 0.
        // Note that if the asset is not borrowable but its borrow rate is non-zero,
        // interest will still accrue depending on the utilization.
        if (dt == 0) {
            return 0;
        }

        // Computing the compounded interest accrued over the time interval `dt`.
        // We use first 3 terms of the Taylor series expansion for e^(rt) - 1 as an approximation.
        {
            uint256 ratePerSecond = marketConfig.irm().borrowRate(key);
            uint256 rt = ratePerSecond * dt;
            uint256 rt2 = rt.mulDivDown(rt, 2 * Constants.WAD);
            uint256 rt3 = rt2.mulDivDown(rt, 3 * Constants.WAD);

            interest = $reserveData.borrowed.mulWadDown(rt + rt2 + rt3);

            // Update both the reserve data.
            $reserveData.supplied += interest;
            $reserveData.borrowed += interest;
            $reserveData.lastUpdateTimestamp = uint128(block.timestamp);
        }

        // If performance fee is set, calculate and mint the fee shares.
        uint64 feePercentage = marketConfig.feePercentage();
        if (feePercentage > 0) {
            uint256 shareId = key.toLentId();
            uint256 feeAmount = interest.mulWadDown(feePercentage);

            // Since the fee amount is accounted for already in the supplied amount, we need to subtract it
            // when calculating the fee shares to mint. This is equivalent to assuming that the fee amount is
            // being supplied to the reserve.
            uint256 feeSharesToMint = feeAmount.toSharesDown($reserveData.supplied - feeAmount, totalSupply(shareId));

            if (feeSharesToMint > 0) {
                _mint({to: marketConfig.feeRecipient().toUserAccount(), tokenId: shareId, amount: feeSharesToMint});

                emit Office__PerformanceFeeMinted({key: key, shares: feeSharesToMint});
            }
        }
    }

    /// @notice Processes collaterals and calculates the liquidator's repayment obligation.
    /// @dev The `liquidatorRepaymentObligation` cannot be negative when this function returns.
    /// @param params The liquidation parameters containing collateral information.
    /// @param debtKey The reserve key for the debt asset.
    /// @param debtAsset The debt asset being liquidated.
    /// @param marketConfig The market configuration.
    /// @return assetsRepaid The total assets repaid from collateral seizure.
    /// @return liquidatorRepaymentObligation The amount the liquidator must repay.
    function _processCollateralsAndCalculateObligation(
        LiquidationParams calldata params,
        ReserveKey debtKey,
        IERC20 debtAsset,
        IMarketConfig marketConfig
    )
        internal
        returns (uint256 assetsRepaid, int256 liquidatorRepaymentObligation)
    {
        IOracleModule oracleModule = marketConfig.oracleModule();

        for (uint256 i; i < params.collateralParams.length; ++i) {
            require(
                params.collateralParams[i].tokenId.getMarketId() == params.market,
                Office__IncorrectTokenId(params.collateralParams[i].tokenId)
            );

            IERC20 collateralAsset = params.collateralParams[i].tokenId.getAsset();

            (uint256 assets, uint256 shares, bool withdrawnInKind) = _withdraw({
                marketConfig: marketConfig,
                account: params.account,
                tokenId: params.collateralParams[i].tokenId,
                assets: params.collateralParams[i].assets,
                shares: params.collateralParams[i].shares,
                inKind: params.collateralParams[i].inKind
            });

            uint256 seizedAssetsQuote =
                oracleModule.getQuote({inAmount: assets, base: address(collateralAsset), quote: address(debtAsset)});

            // We are accounting for the liquidation bonus while calculating the obligation
            // of the liquidator for this particular collateral asset.
            // Although rounding down the result benefits the liquidator slightly, it's acceptable
            // given that the alternate issue which is reversion while burning the debt shares
            // due to rounding errors is worse.
            uint256 obligationQuote = seizedAssetsQuote.divWadDown(
                Constants.WAD
                    + marketConfig.liquidationBonusPercentage({
                        account: params.account, collateralTokenId: params.collateralParams[i].tokenId, debtKey: debtKey
                    })
            );

            // If the obligation quote is zero despite assets being seized, it implies that the
            // collateral seized is worth less than 1 unit of debt asset (dust).
            // To prevent liquidators from stealing collateral by seizing dust amounts repeatedly without
            // repaying any debt, we only allow this if the liquidator is liquidating the entire collateral asset amount.
            if (obligationQuote == 0 && assets != 0) {
                uint256 collateralSharesBalance = balanceOf(params.account, params.collateralParams[i].tokenId);

                // The latter condition allows dust collateral liquidation when the withdrawal is done in-kind
                // and the liquidator is seizing the entire remaining collateral balance. In this case, the
                // collateral shares will be transferred to the liquidator after this check.
                require(
                    collateralSharesBalance == 0 || (withdrawnInKind && collateralSharesBalance == shares),
                    Office__NoAssetsRepaid()
                );
            }

            assetsRepaid += obligationQuote;

            // Transfer the underlying asset to the liquidator and update the repayment obligation
            // if withdrawal was not in-kind.
            if (!withdrawnInKind) {
                if (collateralAsset != debtAsset) {
                    // Note that we have accounted for the bonus amount in the `obligationQuote` calculation itself.
                    liquidatorRepaymentObligation += obligationQuote.toInt256();

                    if (assets != 0) {
                        collateralAsset.safeTransfer({to: msg.sender, value: assets});
                    }
                } else {
                    // If the collateral asset is same as debt asset, and withdrawal is not in-kind,
                    // the bonus amount effectively reduces the repayment obligation.
                    liquidatorRepaymentObligation -= (seizedAssetsQuote - obligationQuote).toInt256();
                }
            } else {
                liquidatorRepaymentObligation += obligationQuote.toInt256();

                // If withdrawn in-kind then transfer the collateral shares instead of the underlying asset
                // regardless of whether the collateral asset is same as debt asset or not.
                _transfer({
                    from: params.account,
                    to: msg.sender.toUserAccount(),
                    tokenId: params.collateralParams[i].tokenId,
                    amount: shares
                });
            }
        }

        // If the liquidator repayment obligation is negative, the liquidator should be compensated.
        // This can happen when one of the collateral assets is the same as the debt asset,
        // and its value dominates the liquidation value.
        if (liquidatorRepaymentObligation < 0) {
            debtAsset.safeTransfer({to: msg.sender, value: uint256(-liquidatorRepaymentObligation)});

            liquidatorRepaymentObligation = 0;
        }
    }

    /// @notice Handles debt share accounting and socializes bad debt if necessary during liquidation.
    /// @param params The liquidation parameters.
    /// @param debtKey The reserve key for the debt asset.
    /// @param assetsRepaid The amount of assets repaid.
    /// @return debtSharesRepaid The shares burned from the liquidated repayment.
    /// @return debtSharesUnpaid The shares of unpaid debt.
    /// @return debtAssetsUnpaid The unpaid debt assets (bad debt).
    function _handleDebtSharesAndBadDebt(
        LiquidationParams calldata params,
        ReserveKey debtKey,
        uint256 assetsRepaid
    )
        internal
        returns (uint256 debtSharesRepaid, uint256 debtSharesUnpaid, uint256 debtAssetsUnpaid)
    {
        ReserveData storage $reserveData = getReserveDataStorage(debtKey);
        uint256 debtId = debtKey.toDebtId();
        debtSharesRepaid = assetsRepaid.toSharesDown($reserveData.borrowed, totalSupply(debtId));
        $reserveData.borrowed = $reserveData.borrowed.saturatingSub(assetsRepaid);

        _burn({from: params.account, tokenId: debtId, amount: debtSharesRepaid});

        // If the position has accrued bad debt, we need to socialise the losses and remove the debt
        // from the account.
        debtSharesUnpaid = balanceOf(params.account, debtId);
        if (
            getRegistryStorageStruct().marketWiseData[params.account][params.market].collateralIds.length() == 0
                && debtSharesUnpaid > 0
        ) {
            debtAssetsUnpaid = debtSharesUnpaid.toAssetsUp($reserveData.borrowed, totalSupply(debtId));

            $reserveData.borrowed = $reserveData.borrowed.saturatingSub(debtAssetsUnpaid);
            $reserveData.supplied = $reserveData.supplied.saturatingSub(debtAssetsUnpaid);

            _burn({from: params.account, tokenId: debtId, amount: debtSharesUnpaid});
        }
    }

    /// @dev Overriden to ensure that it:
    ///      - Checks the health of the `from` account after transferring collateral tokens out.
    ///      - Checks the health of the `to` account after transferring debt tokens in.
    ///      - Allows an authorized caller to transfer debt tokens between `from` and `to` accounts.
    ///      - Checks if `shares` of `tokenId` can be transferred between `from` and `to` accounts as per market config.
    ///      - [!WARNING] Doesn't prevent minting/redemption of shares even if the account is explicitly restricted
    ///                   from transferring/receiving shares.
    function _update(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal override {
        super._update({from: from, to: to, tokenId: tokenId, amount: amount});

        TokenType tokenType = tokenId.getTokenType();

        // Additional checks if transferring collateral or debt tokens between non-zero accounts.
        // No checks are needed if minting or burning tokens.
        // No checks are needed for account token type transfers.
        if (
            from != Constants.ACCOUNT_ID_ZERO && to != Constants.ACCOUNT_ID_ZERO
                && (tokenType != TokenType.ISOLATED_ACCOUNT && tokenType != TokenType.NONE)
        ) {
            if (amount != 0) {
                MarketId market = tokenId.getMarketId();
                IMarketConfig marketConfig = getMarketConfig(market);

                // Check if the transfer is allowed as per market config.
                require(
                    marketConfig.canTransferShares({from: from, to: to, tokenId: tokenId, shares: amount}),
                    Office__TransferNotAllowed({from: from, to: to, tokenId: tokenId, shares: amount})
                );

                // If the `tokenId` is a collateral token, we need to ensure that the `from` account
                // is healthy after the transfer. For debt tokens, it's not necessary to check health
                // of the `from` account as transferring debt tokens out only reduces the debt obligation.
                if (tokenType != TokenType.DEBT) {
                    // In-kind withdrawals can cause the account to stay unhealthy thus we skip health checks
                    // during liquidations. Otherwise, since transferring collateral out can cause the account to become
                    // unhealthy, we always check the health of the `from` account.
                    if (!_isOngoingLiquidationCall()) {
                        _checkHealth(from, market);
                    }
                } else {
                    _checkHealth(to, market);

                    // Check if the remaining debt for each of the `from` and `to` accounts is above the minimum debt amount USD
                    // or if the debt is fully transferred out.
                    _checkDebtAboveMinimum(from, market);
                    _checkDebtAboveMinimum(to, market);
                }
            }
        }
    }

    /// @dev Checks if the account is healthy after a market operation.
    ///      If the ongoing call is a delegation call, we defer the health checks.
    function _checkHealth(AccountId account, MarketId market) internal {
        if (isOngoingDelegationCall()) {
            requiresHealthCheck = true;
            TransientEnumerableHashTableStorage._insert(account, market);
        } else {
            require(isHealthyAccount(account, market), Office__AccountNotHealthy(account, market));
        }
    }

    /// @dev Checks if the debt of an account in a market is above the minimum debt amount USD.
    ///      Note that the `debtValueUSD == 0` check is useless when this function is invoked
    ///      during a `borrow` operation but this approach keeps the function reusable.
    function _checkDebtAboveMinimum(AccountId account, MarketId market) internal {
        uint256 debtValueUSD = _getDebtValueUSD(account, market);
        uint256 minDebtValueUSD = getMarketConfig(market).minDebtAmountUSD();

        require(
            debtValueUSD == 0 || debtValueUSD >= minDebtValueUSD,
            Office__DebtBelowMinimum(debtValueUSD, minDebtValueUSD)
        );
    }

    /// @dev Internal function to get the debt value of an account in a market in USD.
    ///      Accrues interest on the debt reserve before calculating the debt value.
    function _getDebtValueUSD(AccountId account, MarketId market) internal returns (uint256 debtValueUSD) {
        IMarketConfig marketConfig = getMarketConfig(market);
        uint256 debtId = getDebtId(account, market);
        ReserveKey debtKey = debtId.getReserveKey();

        // If the account has no debt, return 0.
        if (debtId == 0) {
            return 0;
        }

        _accrueInterest(debtKey, marketConfig);

        // Rounding up in favour of the lenders.
        uint256 debtAmount =
            balanceOf(account, debtId).toAssetsUp(getReserveDataStorage(debtKey).borrowed, totalSupply(debtId));

        return marketConfig.oracleModule()
            .getQuote({inAmount: debtAmount, base: address(debtKey.getAsset()), quote: Constants.USD_ISO_ADDRESS});
    }

    /// @dev Returns `true` if the ongoing call is a liquidation call.
    function _isOngoingLiquidationCall() internal pure returns (bool isLiquidation) {
        return msg.sig == this.liquidate.selector;
    }
}
