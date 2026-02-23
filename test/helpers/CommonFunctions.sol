// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "./Setup.sol";

abstract contract CommonFunctions is Setup {
    using SharesMathLib for uint256;
    using stdStorage for StdStorage;
    using ReserveKeyLibrary for *;
    using MarketIdLibrary for *;
    using SharesMathLib for uint256;
    using TokenHelpers for *;
    using FixedPointMathLib for uint256;

    bool private _initialized;

    function createDefaultNoHooksMarket() public returns (MarketId marketId) {
        return _createDefaultMarket(NO_HOOKS_SET);
    }

    function createDefaultAllHooksMarket() public returns (MarketId marketId) {
        return _createDefaultMarket(ALL_HOOKS_SET);
    }

    function getRatePerSecond(uint256 rate) public pure returns (uint256 ratePerSecond) {
        // Convert the rate to rate per second
        return rate / SECONDS_IN_YEAR;
    }

    function scaleDownByOffset(uint256 value) public pure returns (uint256 scaledValue) {
        // Scale the value by the offset
        return value / SharesMathLib.VIRTUAL_SHARES;
    }

    function mockBorrow(ReserveKey key_, uint256 amount) public returns (uint256 borrowed) {
        // Set the borrowed amount to the specified amount.
        stdstore.enable_packed_slots().target(address(office)).sig("getReserveData(uint248)")
            .with_key(ReserveKey.unwrap(key_)).depth(1).checked_write(amount);

        borrowed = amount;
    }

    function mockSupply(ReserveKey key_, uint256 amount) public returns (uint256 supplied) {
        // Set the supplied amount to the specified amount.
        stdstore.enable_packed_slots().target(address(office)).sig("getReserveData(uint248)")
            .with_key(ReserveKey.unwrap(key_)).depth(0).checked_write(amount);

        supplied = amount;
    }

    function getLiquidationCollaterals(
        AccountId account_,
        MarketId market_,
        uint256 debtAssetsToRepay_
    )
        public
        view
        returns (CollateralLiquidationParams[] memory collateralToLiquidate_)
    {
        return getLiquidationCollaterals(account_, market_, debtAssetsToRepay_, false);
    }

    /// @dev Helper function to get the collateral assets to liquidate.
    ///      It will parse the collateral shares of the account and calculate
    ///      the amount of shares to liquidate based on the debt shares to repay.
    ///      By default, the liquidation is not done in-kind i.e., if there isn't enough
    ///      liquidity in the reserve, the liquidation will fail.
    /// @dev If `inKind_` is true, it will create a `CollateralLiquidationParams` object
    ///      with in-kind withdrawal ONLY if there isn't enough liquidity.
    /// @dev Now accounts for per-collateral liquidation bonus percentages based on
    ///      the collateral-debt relationship as per the updated liquidation logic.
    function getLiquidationCollaterals(
        AccountId account_,
        MarketId market_,
        uint256 debtAssetsToRepay_,
        bool inKind_
    )
        public
        view
        returns (CollateralLiquidationParams[] memory collateralToLiquidate_)
    {
        ReserveKey debtKey = office.getDebtId(account_, market_).getReserveKey();
        IERC20 debtAsset = debtKey.getAsset();
        uint256[] memory collateralIds = office.getAllCollateralIds(account_, market_);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            new CollateralLiquidationParams[](collateralIds.length);

        uint256 remainingDebtToRepay = debtAssetsToRepay_;

        uint256 liquidatedCount = 0;
        for (uint256 i; i < collateralIds.length; ++i) {
            uint256 collateralId = collateralIds[i];
            ReserveKey collateralKey = collateralId.getReserveKey();
            uint256 totalCollateralShares = office.totalSupply(collateralId);
            uint256 accountCollateralShares = office.balanceOf(account_, collateralId);

            OfficeStorage.ReserveData memory collateralReserveData = office.getReserveData(collateralKey);
            bool isLentToken = collateralId.getTokenType() == TokenType.LEND;

            // Get the liquidation bonus percentage for this specific collateral-debt pair
            uint256 bonusPercentage = marketConfig.liquidationBonusPercentage(account_, collateralId, debtKey);

            // If collateral is an escrow asset, we simply convert shares to assets 1:1.
            uint256 accountCollateralAssets;
            if (!isLentToken) {
                accountCollateralAssets = accountCollateralShares;
            } else {
                // Convert shares to assets using the reserve data.
                accountCollateralAssets =
                    accountCollateralShares.toAssetsDown(collateralReserveData.supplied, totalCollateralShares);
            }

            // Calculate the collateral value needed to seize (including bonus)
            // seizedValue = debtToRepay * (1 + bonus%)
            uint256 collateralValueNeeded = oracleModule.getQuote(
                remainingDebtToRepay.mulWadUp(WAD + bonusPercentage),
                address(debtAsset),
                address(collateralKey.getAsset())
            );

            // Get the total collateral value available
            uint256 availableCollateralAssets = accountCollateralAssets;

            if (collateralValueNeeded >= availableCollateralAssets) {
                // Need to seize all collateral from this position
                collateralToLiquidate[liquidatedCount++] = CollateralLiquidationParams({
                    tokenId: collateralId,
                    assets: 0,
                    shares: accountCollateralShares,
                    inKind: (isLentToken && inKind_
                            && accountCollateralAssets
                                > collateralReserveData.supplied - collateralReserveData.borrowed)
                });

                // Calculate how much debt this collateral covers (reverse calculation)
                // debtCovered = seizedValue / (1 + bonus%)
                uint256 seizedValueInDebt = oracleModule.getQuote(
                    availableCollateralAssets, address(collateralKey.getAsset()), address(debtAsset)
                );
                uint256 debtCovered = seizedValueInDebt.divWadDown(WAD + bonusPercentage);
                remainingDebtToRepay -= debtCovered;
            } else {
                // Can satisfy remaining debt with this collateral
                uint256 sharesToLiquidate;
                if (!isLentToken) {
                    sharesToLiquidate = collateralValueNeeded;
                } else {
                    // Convert assets to shares using the reserve data.
                    sharesToLiquidate =
                        collateralValueNeeded.toSharesUp(collateralReserveData.supplied, totalCollateralShares);
                }

                // Cap shares to account's actual balance to avoid rounding issues
                if (sharesToLiquidate > accountCollateralShares) {
                    sharesToLiquidate = accountCollateralShares;
                }

                // If there isn't enough liquidity in the lending reserve and `inKind_` is true, we withdraw in-kind.
                collateralToLiquidate[liquidatedCount++] = CollateralLiquidationParams({
                    tokenId: collateralId,
                    assets: 0,
                    shares: sharesToLiquidate,
                    inKind: (isLentToken && inKind_
                            && collateralValueNeeded > collateralReserveData.supplied - collateralReserveData.borrowed)
                });

                break;
            }
        }

        CollateralLiquidationParams[] memory result = new CollateralLiquidationParams[](liquidatedCount);
        for (uint256 i; i < liquidatedCount; ++i) {
            result[i] = collateralToLiquidate[i];
        }

        return result;
    }

    /// @dev Re-uses the `marketConfig` contract for markets without hooks.
    ///      Creates a new config for markets with hooks.
    function _createDefaultMarket(IHooks hooks) internal returns (MarketId marketId) {
        SimpleMarketConfig.ConfigInitParams memory initParams = SimpleMarketConfig.ConfigInitParams({
            feeRecipient: feeRecipient,
            irm: irm,
            weights: weights,
            oracleModule: oracleModule,
            hooks: hooks,
            feePercentage: 0,
            minDebtAmountUSD: 0
        });

        SimpleMarketConfig.AssetConfig[] memory assets = new SimpleMarketConfig.AssetConfig[](2);
        assets[0] = SimpleMarketConfig.AssetConfig({asset: usdc, isBorrowable: true});
        assets[1] = SimpleMarketConfig.AssetConfig({asset: weth, isBorrowable: false});

        if (!_initialized || hooks != NO_HOOKS_SET) {
            marketConfig = new SimpleMarketConfig(admin, office, initParams);
            marketConfig.addSupportedAssets(assets);

            // Set oracle prices for the assets
            address[] memory assetsAddresses = new address[](3);
            assetsAddresses[0] = address(usdc);
            assetsAddresses[1] = address(weth);
            assetsAddresses[2] = Constants.USD_ISO_ADDRESS;
            uint256[] memory prices = new uint256[](3);
            prices[0] = 1e8; // 1 USDC = 1 USD
            prices[1] = 2000e8; // 1 WETH = 2000 USD
            prices[2] = 1e8; // 1 USD = 1 USD

            oracleModule.setPrices(assetsAddresses, prices);

            _initialized = true;
        }

        marketId = office.createMarket(admin, marketConfig);

        // Set weights for the assets.
        weights.setWeight(marketId.toReserveKey(usdc), marketId.toReserveKey(weth), 0.6e18);

        // Set liquidation bonus percentages for the assets.
        marketConfig.setLiquidationBonusPercentage(
            marketId.toReserveKey(usdc).toLentId(),
            marketId.toReserveKey(weth),
            0.05e18 // 5% bonus
        );
        marketConfig.setLiquidationBonusPercentage(
            marketId.toReserveKey(usdc).toEscrowId(),
            marketId.toReserveKey(weth),
            0.05e18 // 5% bonus
        );
        marketConfig.setLiquidationBonusPercentage(
            marketId.toReserveKey(weth).toLentId(),
            marketId.toReserveKey(usdc),
            0.05e18 // 5% bonus
        );
        marketConfig.setLiquidationBonusPercentage(
            marketId.toReserveKey(weth).toEscrowId(),
            marketId.toReserveKey(usdc),
            0.05e18 // 5% bonus
        );
        marketConfig.setLiquidationBonusPercentage(
            marketId.toReserveKey(usdc).toLentId(),
            marketId.toReserveKey(usdc),
            0.05e18 // 5% bonus
        );
    }
}
