// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

// Import periphery contract
import {DYTMPeriphery} from "../../../src/periphery/DYTMPeriphery.sol";

contract DYTMPeripheryTest is CommonScenarios {
    using ReserveKeyLibrary for *;

    DYTMPeriphery internal _periphery;

    function setUp() public override {
        super.setUp();
        
        _periphery = new DYTMPeriphery(office);
    }

    // Test case 1
    function test_WhenTheAccountHasADebtPosition_WhenGetAccountPositionIsCalled_ItShouldReturnTheCorrectPositionDetails(
    )
        public
        whenReserveExists
        givenEnoughLiquidityInTheReserve
        givenAccountIsIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
    {
        // It should return the correct position details.
        DYTMPeriphery.AccountPosition memory position = _periphery.getAccountPosition(account, market);

        // It should have debt of 2000 USDC = $2000 USD
        assertEq(position.debt.debtAssets, 2000e6, "Expected debt assets to be 2000 USDC");
        assertEq(position.debt.debtValueUSD, 2000e18, "Expected debt value to be $2000 USD");

        // It should have 2 collaterals (USDC lent + WETH escrowed)
        assertEq(position.collaterals.length, 2, "Expected 2 collateral types");

        // It should have total collateral value of $3000 (1000 USDC + 1 WETH worth $2000)
        assertEq(position.totalCollateralValueUSD, 3000e18, "Expected total collateral value to be $3000 USD");

        // It should have weighted collateral value of $2200 (1000 USDC + 1 WETH * 0.6 weight = 2200)
        assertEq(
            position.totalWeightedCollateralValueUSD, 2200e18, "Expected weighted collateral value to be $2200 USD"
        );

        // It should be healthy
        assertTrue(position.isHealthy, "Expected account to be healthy");

        // It should have health factor of 1.1 (2200/2000)
        assertEq(position.healthFactor, 1.1e18, "Expected health factor to be 1.1");
    }

    // Test case 2
    function test_WhenTheAccountHasADebtPosition_WhenGetAccountDebtValueUSDIsCalled_ItShouldReturnTheCorrectDebtValueInUSD(
    )
        public
        whenReserveExists
        givenEnoughLiquidityInTheReserve
        givenAccountIsIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
    {
        // It should return the correct debt value in USD.
        uint256 debtValueUSD = _periphery.getAccountDebtValueUSD(account, market);

        // It should return $2000 USD (2000 USDC borrowed at $1 each)
        assertEq(debtValueUSD, 2000e18, "Expected debt value to be $2000 USD");
    }

    // Test case 3
    function test_WhenTheAccountHasADebtPosition_WhenGetAccountCollateralValueUSDIsCalled_ItShouldReturnTheCorrectCollateralValueInUSD(
    )
        public
        whenReserveExists
        givenEnoughLiquidityInTheReserve
        givenAccountIsIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
    {
        // It should return the correct collateral value in USD.
        (uint256 totalValueUSD, uint256 weightedValueUSD) = _periphery.getAccountCollateralValueUSD(account, market);

        // It should return total collateral value of $3000 (1000 USDC + 1 WETH worth $2000)
        assertEq(totalValueUSD, 3000e18, "Expected total collateral value to be $3000 USD");

        // It should return weighted collateral value of $2200 (1000 USDC + 1 WETH * 0.6 weight = $1200)
        assertEq(weightedValueUSD, 2200e18, "Expected weighted collateral value to be $2200 USD");
    }

    // Test case 4
    function test_WhenTheAccountHasADebtPosition_WhenGetAccountCollateralValueUSDIsCalled_ItShouldReturnTheCorrectWeightedCollateralValueInUSD(
    )
        public
        whenReserveExists
        givenEnoughLiquidityInTheReserve
        givenAccountIsIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
    {
        // It should return the correct weighted collateral value in USD.
        (, uint256 weightedValueUSD) = _periphery.getAccountCollateralValueUSD(account, market);

        // It should return weighted collateral value of $2200 (1000 USDC + 1 WETH * 0.6 weight = $1200)
        assertEq(weightedValueUSD, 2200e18, "Expected weighted collateral value to be $2200 USD");
    }

    // Test case 5
    function test_WhenShareToAssetsIsCalled_ItShouldReturnTheCorrectAssetValue()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        // It should return the correct asset value.
        uint256 lendTokenId = usdcKey.toLentId();
        uint256 shares = office.balanceOf(account, lendTokenId);

        uint256 assets = _periphery.sharesToAssets(lendTokenId, shares);

        // It should return approximately 1000 USDC (1000e6) since the account supplied 1000 USDC
        assertEq(assets, 1000e6, "Expected assets to equal 1000 USDC");
    }

    // Test case 6
    function test_WhenAssetsToShareIsCalled_ItShouldReturnTheCorrectShareValue()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        // It should return the correct share value.
        uint256 lendTokenId = usdcKey.toLentId();
        uint256 assets = 1000e6; // 1000 USDC

        uint256 shares = _periphery.assetsToShares(lendTokenId, assets);

        // It should return shares equivalent to 1000 USDC
        uint256 expectedShares = office.balanceOf(account, lendTokenId);
        assertEq(shares, expectedShares, "Expected shares to match account's actual shares for 1000 USDC");
    }

    // Test case 7
    function test_WhenGetExchangeRateIsCalled_ItShouldReturnTheCorrectExchangeRate()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        // It should return the correct exchange rate.
        uint256 lendTokenId = usdcKey.toLentId();
        uint256 exchangeRate = _periphery.getExchangeRate(lendTokenId);

        // Exchange rate should be 1e6 (1 USDC in 6-decimal representation per 1e12 shares)
        // 1 share unit for LEND tokens = 10^(decimals + 6) = 10^12 for USDC
        assertEq(exchangeRate, 1e6, "Expected USDC exchange rate to be 1e6 (1 USDC)");

        // For escrow tokens, should be 1:1 (1 WETH = 1e18 per 1e18 shares)
        uint256 escrowTokenId = wethKey.toEscrowId();
        uint256 escrowExchangeRate = _periphery.getExchangeRate(escrowTokenId);
        assertEq(escrowExchangeRate, 1e18, "Expected WETH escrow exchange rate to be 1e18 (1:1)");
    }

    // Test case 8
    function test_WhenGetReserveInfoIsCalled_ItShouldReturnTheCorrectReserveInformation()
        public
        whenReserveExists
        givenEnoughLiquidityInTheReserve
        givenAccountIsIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        // It should return the correct reserve information.
        DYTMPeriphery.ReserveInfo memory reserveInfo = _periphery.getReserveInfo(usdcKey);

        // It should have USDC as the asset
        assertEq(address(reserveInfo.asset), address(usdc), "Expected asset to be USDC");

        // It should have supplied amount of 101,000 USDC (100,000 from Bob + 1,000 from Alice)
        assertEq(reserveInfo.supplied, 101_000e6, "Expected supplied to be 101,000 USDC");

        // It should have borrowed amount of 2,000 USDC
        assertEq(reserveInfo.borrowed, 2000e6, "Expected borrowed to be 2,000 USDC");

        // It should have available liquidity of 99,000 USDC (101,000 - 2,000)
        assertEq(reserveInfo.availableLiquidity, 99_000e6, "Expected available liquidity to be 99,000 USDC");

        // It should have utilization rate of ~1.98% (2000/101000)
        assertEq(reserveInfo.utilizationRate, 19_801_980_198_019_801, "Expected utilization rate to be ~1.98%");

        // It should have correct share amounts
        // This is manually calculated using the formulas in `SharesMathLib`.
        assertEq(
            reserveInfo.totalSupplyShares, 101e15, "Expected total supply shares to be 101e15"
        );
        assertEq(reserveInfo.totalBorrowShares, 2e15, "Expected total borrow shares to be 2e15");

        // Exchange rates should be exact values
        // For USDC (6 decimals), supply/borrow exchange rate should be 1e6 (1 USDC)
        assertEq(reserveInfo.exchangeRateSupply, 1e6, "Expected supply exchange rate to be 1e6 (1 USDC)");
        assertEq(reserveInfo.exchangeRateBorrow, 1e6, "Expected borrow exchange rate to be 1e6 (1 USDC)");

        // It should have specific interest rates (5% annual = 1585489599 per second)
        assertEq(reserveInfo.borrowRate, 1_585_489_599, "Expected borrow rate to be 1585489599 (5% annual)");
        assertEq(reserveInfo.supplyRate, 31_395_833, "Expected supply rate to be 31395833 (5% * 1.98% utilization)");
    }
}

// Generated using co-pilot: Claude 3.5 Sonnet
