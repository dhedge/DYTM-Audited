// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../helpers/Setup.sol";

contract Office_createMarket is Setup {
    using ReserveKeyLibrary for *;

    SimpleMarketConfig.AssetConfig[] assets;

    function setUp() public override {
        super.setUp();

        assets.push(SimpleMarketConfig.AssetConfig({asset: usdc, isBorrowable: true}));
        assets.push(SimpleMarketConfig.AssetConfig({asset: weth, isBorrowable: false}));
    }

    function test_GivenValidParameters() external {
        // It should create a market.

        vm.startPrank(admin);

        // Create a market with no hooks.
        SimpleMarketConfig.ConfigInitParams memory initParams = SimpleMarketConfig.ConfigInitParams({
            feeRecipient: feeRecipient,
            irm: irm,
            weights: weights,
            oracleModule: oracleModule,
            hooks: NO_HOOKS_SET,
            feePercentage: 0,
            minDebtAmountUSD: 0
        });

        marketConfig = new SimpleMarketConfig(admin, office, initParams);
        marketConfig.addSupportedAssets(assets);

        MarketId market = office.createMarket(admin, marketConfig);

        IMarketConfig fetchedMarketConfig = office.getMarketConfig(market);

        assertEq(MarketId.unwrap(market), 1, "Market ID should be 1");
        assertEq(office.getOfficer(market), admin, "Officer should be admin");
        assertEq(address(fetchedMarketConfig.irm()), address(irm), "IRM should be mockIRM");
        assertEq(
            address(fetchedMarketConfig.oracleModule()), address(oracleModule), "Oracle module should be oracleModule"
        );
        assertEq(address(fetchedMarketConfig.hooks()), address(NO_HOOKS_SET), "Hooks should be NO_HOOKS_SET");
        assertEq(fetchedMarketConfig.minDebtAmountUSD(), 0, "Min margin amount should be 0");
        assertTrue(marketConfig.isSupportedAsset(usdc), "USDC should be a supported asset");
        assertTrue(marketConfig.isSupportedAsset(weth), "WETH should be a supported asset");
        assertTrue(marketConfig.isBorrowableAsset(usdc), "USDC should be a borrowable asset");
        assertFalse(marketConfig.isBorrowableAsset(weth), "WETH should not be a borrowable asset");
    }

    modifier whenParametersAreInvalid() {
        _;
    }

    function test_RevertGiven_NullAddressForIRM() external whenParametersAreInvalid {
        // It should revert.
        //     With `SimpleMarketConfig__ZeroAddress`.

        // Create a market with no hooks.
        SimpleMarketConfig.ConfigInitParams memory initParams = SimpleMarketConfig.ConfigInitParams({
            feeRecipient: feeRecipient,
            irm: IIRM(address(0)), // Null address for IRM
            weights: weights,
            oracleModule: oracleModule,
            hooks: NO_HOOKS_SET,
            feePercentage: 0,
            minDebtAmountUSD: 0
        });

        vm.expectRevert(SimpleMarketConfig.SimpleMarketConfig__ZeroAddress.selector);
        new SimpleMarketConfig(admin, office, initParams);
    }

    function test_RevertGiven_NullAddressForWeights() external whenParametersAreInvalid {
        // It should revert.
        //     With `SimpleMarketConfig__ZeroAddress`.

        SimpleMarketConfig.ConfigInitParams memory initParams = SimpleMarketConfig.ConfigInitParams({
            feeRecipient: feeRecipient,
            irm: irm,
            weights: IWeights(address(0)), // Null address for Weights
            oracleModule: oracleModule,
            hooks: NO_HOOKS_SET,
            feePercentage: 0,
            minDebtAmountUSD: 0
        });

        vm.expectRevert(SimpleMarketConfig.SimpleMarketConfig__ZeroAddress.selector);
        new SimpleMarketConfig(admin, office, initParams);
    }

    function test_RevertGiven_NullAddressForOracleModule() external whenParametersAreInvalid {
        // It should revert.
        //     With `SimpleMarketConfig__ZeroAddress`.

        SimpleMarketConfig.ConfigInitParams memory initParams = SimpleMarketConfig.ConfigInitParams({
            feeRecipient: feeRecipient,
            irm: irm,
            weights: weights,
            oracleModule: IOracleModule(address(0)), // Null address for OracleModule
            hooks: NO_HOOKS_SET,
            feePercentage: 0,
            minDebtAmountUSD: 0
        });

        vm.expectRevert(SimpleMarketConfig.SimpleMarketConfig__ZeroAddress.selector);
        new SimpleMarketConfig(admin, office, initParams);
    }
}
