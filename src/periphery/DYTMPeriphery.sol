// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.29;

import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {IERC20Metadata} from "@openzeppelin-contracts/interfaces/IERC20Metadata.sol";

import {IWeights} from "../interfaces/IWeights.sol";
import {IOracleModule} from "../interfaces/IOracleModule.sol";
import {IMarketConfig} from "../interfaces/IMarketConfig.sol";
import {IIRM} from "../interfaces/IIRM.sol";
import {OfficeStorage} from "../abstracts/storages/OfficeStorage.sol";

import {MarketId, AccountId, ReserveKey} from "../types/Types.sol";
import {AccountIdLibrary} from "../types/AccountId.sol";
import {ReserveKeyLibrary} from "../types/ReserveKey.sol";
import {TokenHelpers, TokenType} from "../libraries/TokenHelpers.sol";
import {SharesMathLib} from "../libraries/SharesMathLib.sol";
import "../libraries/Constants.sol" as Constants;

import {Office} from "../Office.sol";

/// @title DYTMPeriphery
/// @author Chinmay <chinmay@dhedge.org>
/// @notice Periphery contract providing helper functions for DYTM protocol integrations and frontend purposes.
/// @dev This contract provides read-only helper functions that are not part of the core protocol
///      but are useful for integrators, frontends, and external applications.
///      Note that the functions may modify state and hence use `eth_call`/`simulateContract` (in viem)
///      to invoke them off-chain.
contract DYTMPeriphery {
    using Math for uint256;
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;
    using TokenHelpers for uint256;
    using SharesMathLib for uint256;
    using FixedPointMathLib for uint256;

    /////////////////////////////////////////////
    //                 Errors                 //
    /////////////////////////////////////////////

    error DYTMPeriphery__ZeroAddress();

    /////////////////////////////////////////////
    //                 Structs                //
    /////////////////////////////////////////////

    /// @notice Struct containing account's debt information.
    /// @param debtShares The amount of debt shares held by the account.
    /// @param debtAssets The amount of debt assets (underlying tokens) owed by the account.
    /// @param debtValueUSD The USD value of the debt.
    /// @param debtKey The reserve key identifying the debt asset.
    /// @param debtAsset The ERC20 token interface for the debt asset.
    struct DebtInfo {
        uint256 debtShares;
        uint256 debtAssets;
        uint256 debtValueUSD;
        ReserveKey debtKey;
        IERC20 debtAsset;
    }

    /// @notice Struct containing collateral information.
    /// @param tokenId The unique token ID for the collateral.
    /// @param shares The amount of collateral shares held by the account.
    /// @param assets The amount of collateral assets (underlying tokens).
    /// @param valueUSD The USD value of the collateral.
    /// @param weightedValueUSD The weighted USD value of the collateral (valueUSD * weight).
    /// @param weight The weight assigned to this collateral.
    /// @param key The reserve key identifying the collateral asset.
    /// @param asset The ERC20 token interface for the collateral asset.
    /// @param tokenType The type of token (LEND, ESCROW, etc.).
    struct CollateralInfo {
        uint256 tokenId;
        uint256 shares;
        uint256 assets;
        uint256 valueUSD;
        uint256 weightedValueUSD;
        uint64 weight;
        ReserveKey key;
        IERC20 asset;
        TokenType tokenType;
    }

    /// @notice Struct containing account's complete position information.
    /// @param debt The debt information for the account.
    /// @param collaterals Array of collateral information for the account.
    /// @param totalCollateralValueUSD The total USD value of all collaterals.
    /// @param totalWeightedCollateralValueUSD The total weighted USD value of all collaterals.
    /// @param healthFactor The health factor of the position (WAD). Values > 1e18 indicate healthy positions.
    /// @param isHealthy Boolean indicating if the account is healthy.
    struct AccountPosition {
        DebtInfo debt;
        CollateralInfo[] collaterals;
        uint256 totalCollateralValueUSD;
        uint256 totalWeightedCollateralValueUSD;
        uint256 healthFactor;
        bool isHealthy;
    }

    /// @notice Struct for reserve information.
    /// @param asset The ERC20 token interface for the reserve asset.
    /// @param supplied The total amount of assets supplied to this reserve.
    /// @param borrowed The total amount of assets borrowed from this reserve.
    /// @param availableLiquidity The amount of assets available for borrowing (supplied - borrowed).
    /// @param utilizationRate The current utilization rate of the reserve (borrowed / supplied).
    /// @param supplyRate The current annual supply rate for lenders.
    /// @param borrowRate The current annual borrow rate for borrowers.
    /// @param totalSupplyShares The total supply shares outstanding for this reserve.
    /// @param totalBorrowShares The total borrow shares outstanding for this reserve.
    /// @param exchangeRateSupply The current exchange rate for supply shares (assets per share).
    /// @param exchangeRateBorrow The current exchange rate for borrow shares (assets per share).
    /// @param lastUpdateTimestamp The timestamp when this reserve was last updated.
    struct ReserveInfo {
        IERC20 asset;
        uint256 supplied;
        uint256 borrowed;
        uint256 availableLiquidity;
        uint256 utilizationRate;
        uint256 supplyRate;
        uint256 borrowRate;
        uint256 totalSupplyShares;
        uint256 totalBorrowShares;
        uint256 exchangeRateSupply;
        uint256 exchangeRateBorrow;
        uint128 lastUpdateTimestamp;
    }

    /////////////////////////////////////////////
    //            State Variables              //
    /////////////////////////////////////////////

    /// @notice The main Office contract.
    Office public immutable OFFICE;

    /////////////////////////////////////////////
    //              Constructor                //
    /////////////////////////////////////////////

    /// @notice Constructor to initialize the periphery contract.
    /// @param _office The address of the main Office contract.
    constructor(Office _office) {
        require(address(_office) != address(0), DYTMPeriphery__ZeroAddress());

        OFFICE = _office;
    }

    /////////////////////////////////////////////
    //       Account Position Functions       //
    /////////////////////////////////////////////

    /// @notice Get complete position information for an account in a market.
    /// @param account The account to query.
    /// @param market The market to query.
    /// @return position Complete position information.
    function getAccountPosition(AccountId account, MarketId market) public returns (AccountPosition memory position) {
        IMarketConfig marketConfig = OFFICE.getMarketConfig(market);
        IOracleModule oracleModule = marketConfig.oracleModule();
        IWeights weights = marketConfig.weights();

        // Get debt information.
        position.debt = _getDebtInfo({account: account, market: market, oracleModule: oracleModule});

        // Get collateral information.
        position.collaterals = _getCollateralInfo({
            account: account,
            market: market,
            oracleModule: oracleModule,
            weights: weights,
            debtKey: position.debt.debtKey
        });

        (position.totalCollateralValueUSD, position.totalWeightedCollateralValueUSD) =
            _getTotalCollateralAndWeightedValueUSD(position.collaterals);

        // Calculate health factor and status.
        position.isHealthy = OFFICE.isHealthyAccount(account, market);
        if (position.debt.debtValueUSD > 0) {
            position.healthFactor = position.totalWeightedCollateralValueUSD.divWadDown(position.debt.debtValueUSD);
        } else {
            position.healthFactor = type(uint256).max; // Infinite health factor when no debt.
        }
    }

    /// @notice Get debt value for an account in USD.
    /// @param account The account to query.
    /// @param market The market to query.
    /// @return debtValueUSD The total debt value in USD (in WAD).
    function getAccountDebtValueUSD(AccountId account, MarketId market) external returns (uint256 debtValueUSD) {
        IMarketConfig marketConfig = OFFICE.getMarketConfig(market);
        IOracleModule oracleModule = marketConfig.oracleModule();

        DebtInfo memory debt = _getDebtInfo({account: account, market: market, oracleModule: oracleModule});
        return debt.debtValueUSD;
    }

    /// @notice Get collateral value for an account in USD.
    /// @param account The account to query.
    /// @param market The market to query.
    /// @return totalValueUSD The total collateral value in USD (in WAD).
    /// @return weightedValueUSD The total weighted collateral value in USD (in WAD).
    function getAccountCollateralValueUSD(
        AccountId account,
        MarketId market
    )
        external
        returns (uint256 totalValueUSD, uint256 weightedValueUSD)
    {
        IMarketConfig marketConfig = OFFICE.getMarketConfig(market);
        IOracleModule oracleModule = marketConfig.oracleModule();
        IWeights weights = marketConfig.weights();

        uint256 debtId = OFFICE.getDebtId(account, market);
        ReserveKey debtKey = debtId > 0 ? debtId.getReserveKey() : Constants.RESERVE_KEY_ZERO;

        CollateralInfo[] memory collaterals = _getCollateralInfo({
            account: account, market: market, oracleModule: oracleModule, weights: weights, debtKey: debtKey
        });

        return _getTotalCollateralAndWeightedValueUSD(collaterals);
    }

    /////////////////////////////////////////////
    //         Reserve Information            //
    /////////////////////////////////////////////

    /// @notice Get comprehensive information about a reserve.
    /// @param key The reserve key.
    /// @return info Complete reserve information.
    function getReserveInfo(ReserveKey key) external returns (ReserveInfo memory info) {
        IMarketConfig marketConfig = OFFICE.getMarketConfig(key.getMarketId());

        info.asset = key.getAsset();

        // Accrue interest to get up-to-date borrowed and supplied amounts.
        OFFICE.accrueInterest(key);

        // Get reserve data.
        OfficeStorage.ReserveData memory reserveData = OFFICE.getReserveData(key);
        info.supplied = reserveData.supplied;
        info.borrowed = reserveData.borrowed;
        info.lastUpdateTimestamp = reserveData.lastUpdateTimestamp;

        // Calculate derived values.
        info.availableLiquidity = info.supplied - info.borrowed;
        info.utilizationRate = info.supplied > 0 ? info.borrowed.divWadDown(info.supplied) : 0;

        // Get share information.
        uint256 lendTokenId = key.toLentId();
        uint256 debtTokenId = key.toDebtId();
        info.totalSupplyShares = OFFICE.totalSupply(lendTokenId);
        info.totalBorrowShares = OFFICE.totalSupply(debtTokenId);

        // Calculate exchange rates.
        info.exchangeRateSupply = getExchangeRate(lendTokenId);
        info.exchangeRateBorrow = getExchangeRate(debtTokenId);

        // Calculate interest rates from IRM.
        if (address(marketConfig) != address(0) && marketConfig.isBorrowableAsset(info.asset)) {
            uint64 feePercentage = marketConfig.feePercentage();

            // Get the actual borrow rate from the IRM.
            info.borrowRate = marketConfig.irm().borrowRateView(key);

            // Calculate supply rate: borrowRate * utilizationRate * (1 - feePercentage).
            info.supplyRate = info.borrowRate.mulWadDown(info.utilizationRate).mulWadDown(1e18 - feePercentage);
        }
    }

    /////////////////////////////////////////////
    //        Conversion Functions            //
    /////////////////////////////////////////////

    /// @notice Convert shares to assets for a given token.
    /// @param tokenId The token ID.
    /// @param shares The amount of shares.
    /// @return assets The equivalent amount of assets.
    function sharesToAssets(uint256 tokenId, uint256 shares) public returns (uint256 assets) {
        if (tokenId.isDebt()) {
            return _sharesToAssetsDebt(tokenId, shares);
        } else if (tokenId.isCollateral()) {
            return _sharesToAssetsCollateral(tokenId, shares);
        } else {
            return 0; // Invalid token type.
        }
    }

    /// @notice Convert assets to shares for a given token.
    /// @param tokenId The token ID.
    /// @param assets The amount of assets.
    /// @return shares The equivalent amount of shares.
    function assetsToShares(uint256 tokenId, uint256 assets) public returns (uint256 shares) {
        if (tokenId.isDebt()) {
            return _assetsToSharesDebt(tokenId, assets);
        } else if (tokenId.isCollateral()) {
            return _assetsToSharesCollateral(tokenId, assets);
        } else {
            return 0; // Invalid token type.
        }
    }

    /// @notice Get the current exchange rate for a token (assets per unit of shares).
    /// @param tokenId The token ID.
    /// @return exchangeRate The exchange rate in underlying asset decimal terms.
    function getExchangeRate(uint256 tokenId) public returns (uint256 exchangeRate) {
        ReserveKey key = tokenId.getReserveKey();
        IERC20Metadata asset = IERC20Metadata(address(key.getAsset()));

        // For LEND and DEBT tokens (and any other non-ESCROW token types), shares include a 6-decimal
        // offset (VIRTUAL_SHARES = 1e6). For ESCROW tokens, shares are 1:1 with assets (no offset).
        // If an invalid token type (e.g. NONE or ISOLATED_ACCOUNT) reaches this branch, the subsequent
        // `sharesToAssets` call is expected to return 0.
        uint256 oneShare;
        if (tokenId.getTokenType() == TokenType.ESCROW) {
            oneShare = 10 ** asset.decimals();
        } else {
            // Non-ESCROW token type (e.g. LEND or DEBT).
            oneShare = 10 ** (asset.decimals() + 6);
        }

        return sharesToAssets(tokenId, oneShare);
    }

    /////////////////////////////////////////////
    //          Internal Functions            //
    /////////////////////////////////////////////

    /// @dev Get debt information for an account.
    function _getDebtInfo(
        AccountId account,
        MarketId market,
        IOracleModule oracleModule
    )
        internal
        returns (DebtInfo memory debt)
    {
        uint256 debtId = OFFICE.getDebtId(account, market);
        if (debtId == 0) {
            return debt;
        }

        debt.debtKey = debtId.getReserveKey();
        debt.debtAsset = debt.debtKey.getAsset();
        debt.debtShares = OFFICE.balanceOf(account, debtId);

        if (debt.debtShares > 0) {
            debt.debtAssets = _sharesToAssetsDebt(debtId, debt.debtShares);
            debt.debtValueUSD = oracleModule.getQuote({
                inAmount: debt.debtAssets, base: address(debt.debtAsset), quote: Constants.USD_ISO_ADDRESS
            });
        }
    }

    /// @dev Get collateral information for an account.
    function _getCollateralInfo(
        AccountId account,
        MarketId market,
        IOracleModule oracleModule,
        IWeights weights,
        ReserveKey debtKey
    )
        internal
        returns (CollateralInfo[] memory collaterals)
    {
        uint256[] memory collateralIds = OFFICE.getAllCollateralIds(account, market);
        collaterals = new CollateralInfo[](collateralIds.length);

        for (uint256 i = 0; i < collateralIds.length; i++) {
            uint256 tokenId = collateralIds[i];
            CollateralInfo memory info = collaterals[i];

            info.tokenId = tokenId;
            info.key = tokenId.getReserveKey();
            info.asset = info.key.getAsset();
            info.tokenType = tokenId.getTokenType();
            info.shares = OFFICE.balanceOf(account, tokenId);

            if (info.shares > 0) {
                info.assets = _sharesToAssetsCollateral(tokenId, info.shares);
                info.valueUSD = oracleModule.getQuote({
                    inAmount: info.assets, base: address(info.asset), quote: Constants.USD_ISO_ADDRESS
                });

                if (debtKey != Constants.RESERVE_KEY_ZERO) {
                    uint64 weight =
                        weights.getWeight({account: account, collateralTokenId: tokenId, debtAsset: debtKey});

                    info.weight = weight;
                    info.weightedValueUSD = info.valueUSD.mulWadDown(weight);
                } else {
                    info.weight = 0;
                    info.weightedValueUSD = 0;
                }
            }

            collaterals[i] = info;
        }
    }

    /// @dev Convert shares to assets for debt tokens.
    function _sharesToAssetsDebt(uint256 debtTokenId, uint256 shares) internal returns (uint256 assets) {
        ReserveKey key = debtTokenId.getReserveKey();

        // Accrue interest to get up-to-date borrowed and supplied amounts.
        OFFICE.accrueInterest(key);

        uint256 totalAssets = OFFICE.getReserveData(key).borrowed;
        uint256 totalShares = OFFICE.totalSupply(debtTokenId);

        return shares.toAssetsUp({totalAssets: totalAssets, totalShares: totalShares});
    }

    /// @dev Convert assets to shares for debt tokens.
    function _assetsToSharesDebt(uint256 debtTokenId, uint256 assets) internal returns (uint256 shares) {
        ReserveKey key = debtTokenId.getReserveKey();

        // Accrue interest to get up-to-date borrowed and supplied amounts.
        OFFICE.accrueInterest(key);

        uint256 totalAssets = OFFICE.getReserveData(key).borrowed;
        uint256 totalShares = OFFICE.totalSupply(debtTokenId);

        return assets.toSharesUp({totalAssets: totalAssets, totalShares: totalShares});
    }

    /// @dev Convert shares to assets for collateral tokens.
    function _sharesToAssetsCollateral(uint256 tokenId, uint256 shares) internal returns (uint256 assets) {
        ReserveKey key = tokenId.getReserveKey();

        // Accrue interest to get up-to-date borrowed and supplied amounts.
        OFFICE.accrueInterest(key);

        if (tokenId.getTokenType() == TokenType.ESCROW) {
            // 1:1 for escrow tokens.
            // While this doesn't require interest accrual given they are not part of lending market,
            // we do it above for consistency and if any other function relies on up-to-date state.
            return shares;
        } else {
            uint256 totalAssets = OFFICE.getReserveData(key).supplied;
            uint256 totalShares = OFFICE.totalSupply(tokenId);

            return shares.toAssetsDown(totalAssets, totalShares);
        }
    }

    /// @dev Convert assets to shares for collateral tokens.
    function _assetsToSharesCollateral(uint256 tokenId, uint256 assets) internal returns (uint256 shares) {
        ReserveKey key = tokenId.getReserveKey();

        // Accrue interest to get up-to-date borrowed and supplied amounts.
        OFFICE.accrueInterest(key);

        if (tokenId.getTokenType() == TokenType.ESCROW) {
            // 1:1 for escrow tokens.
            // While this doesn't require interest accrual given they are not part of lending market,
            // we do it above for consistency and if any other function relies on up-to-date state.
            return assets;
        } else {
            uint256 totalAssets = OFFICE.getReserveData(key).supplied;
            uint256 totalShares = OFFICE.totalSupply(tokenId);

            return assets.toSharesDown({totalAssets: totalAssets, totalShares: totalShares});
        }
    }

    /// @dev Calculate total collateral and weighted value in USD.
    function _getTotalCollateralAndWeightedValueUSD(CollateralInfo[] memory collaterals)
        internal
        pure
        returns (uint256 totalValueUSD, uint256 totalWeightedValueUSD)
    {
        for (uint256 i; i < collaterals.length; ++i) {
            totalValueUSD += collaterals[i].valueUSD;
            totalWeightedValueUSD += collaterals[i].weightedValueUSD;
        }
    }
}
