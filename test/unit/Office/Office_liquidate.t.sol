// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Office_liquidate is CommonScenarios {
    using TokenHelpers for *;
    using ReserveKeyLibrary for *;
    using SharesMathLib for uint256;
    using FixedPointMathLib for uint256;
    using AccountIdLibrary for *;

    uint256 debtId;
    ReserveKey debtKey;
    IERC20Metadata debtAsset;

    // State before
    OfficeStorage.ReserveData debtReserveDataBefore;
    uint256 totalDebtSharesBefore;
    uint256 accountDebtSharesBefore;
    uint256 totalDebtAssets;
    uint256 liquidatorDebtAssetBalanceBefore;

    uint256[] collateralIds;
    uint256[] liquidatorCollateralBalancesBefore;
    uint256[] accountCollateralSharesBefore;
    uint256[] totalCollateralSharesBefore;
    OfficeStorage.ReserveData[] collateralReserveDataBefore;
    bool withdrawnInKind;

    modifier storeBeforeState(uint256 debtId_) {
        caller = liquidator;

        debtId = debtId_;
        debtKey = debtId.getReserveKey();
        debtAsset = IERC20Metadata(address(debtId.getAsset()));
        debtReserveDataBefore = office.getReserveData(debtKey);
        totalDebtSharesBefore = office.totalSupply(debtId);
        accountDebtSharesBefore = office.balanceOf(account, debtId);
        totalDebtAssets = accountDebtSharesBefore.toAssetsUp(debtReserveDataBefore.borrowed, totalDebtSharesBefore);
        liquidatorDebtAssetBalanceBefore = debtAsset.balanceOf(caller);
        collateralIds = office.getAllCollateralIds(account, market);

        for (uint256 i; i < collateralIds.length; ++i) {
            uint256 collateralId = collateralIds[i];
            ReserveKey collateralKey = collateralId.getReserveKey();

            liquidatorCollateralBalancesBefore.push(collateralId.getAsset().balanceOf(caller));
            accountCollateralSharesBefore.push(office.balanceOf(account, collateralId));
            collateralReserveDataBefore.push(office.getReserveData(collateralKey));
            totalCollateralSharesBefore.push(office.totalSupply(collateralId));
        }
        _;
    }

    modifier givenNotEnoughLiquidityInTheReserve() {
        // This modifier should be used AFTER whenTheAccountHasADebtPosition
        // Bob (who lent 100,000 USDC via givenEnoughLiquidityInTheReserve) withdraws most of it
        // leaving no liquidity for repayment during liquidation (supplied == borrowed)
        vm.startPrank(bob);

        uint256 bobLendTokenId = market.toReserveKey(usdc).toLentId();
        Office.ReserveData memory reserveData = office.getReserveData(usdcKey);

        // Bob withdraws enough liquidity so that supplied == borrowed
        // borrowed = 2000 USDC
        // Currently: supplied = 101,000 (Alice: 1,000 + Bob: 100,000)
        // Bob needs to withdraw: 101,000 - 2,000 = 99,000 USDC
        // This leaves supplied = borrowed = 2,000 USDC (no liquidity for withdrawals)
        office.withdraw(
            WithdrawParams({
                tokenId: bobLendTokenId,
                account: bob.toUserAccount(),
                receiver: bob,
                assets: reserveData.supplied - reserveData.borrowed,
                shares: 0,
                extraData: ""
            })
        );

        vm.stopPrank();
        _;
    }

    modifier givenWithdrawnInKind() {
        withdrawnInKind = true;
        _;
    }

    // Test case 1
    function test_GivenNoBadDebtAndCompleteLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        uint256 expectedAssetsRepaid = totalDebtAssets;

        // Liquidate the account completely.
        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should repay correct amount to the lenders.
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - assetsRepaid,
            "Reserve borrowed incorrect"
        );

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 2
    function test_GivenNoBadDebtAndPartialLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        // Repay half of the debt.
        totalDebtAssets = totalDebtAssets / 2;

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        // Liquidate the account partially.
        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // Calculate expected remaining shares accounting for rounding (match contract's toSharesDown behavior)
        uint256 expectedRemainingShares =
            accountDebtSharesBefore - assetsRepaid.toSharesDown(debtReserveDataBefore.borrowed, totalDebtSharesBefore);

        // It should reduce the debt correctly.
        assertEq(office.balanceOf(account, debtId), expectedRemainingShares, "Debt should be partially reduced");

        // It should repay correct amount to the lenders.
        assertEq(assetsRepaid, totalDebtAssets, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - assetsRepaid,
            "Reserve borrowed incorrect"
        );

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 3
    function test_Revert_GivenNoBadDebtAndLiquidatorTriesToLiquidateDustAmountOfCollateral()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        // Try to liquidate 1 wei WETH (Partial liquidation of account's 1 WETH position)
        // 1 wei WETH at $1200 (unhealthy but not bad debt price) in USDC terms is 0 due to rounding.
        CollateralLiquidationParams[] memory collaterals = new CollateralLiquidationParams[](1);
        collaterals[0] = CollateralLiquidationParams({
            tokenId: market.toReserveKey(weth).toEscrowId(),
            assets: 1, // 1 wei - partial amount
            shares: 0,
            inKind: withdrawnInKind
        });

        // It should revert with Office__NoAssetsRepaid error
        // Because liquidator is trying to seize dust without repaying debt and not clearing the full position
        vm.expectRevert(IOffice.Office__NoAssetsRepaid.selector);
        office.liquidate(
            LiquidationParams({
                market: market, account: account, collateralParams: collaterals, callbackData: "", extraData: ""
            })
        );
    }

    // Test case 4
    function test_GivenNoBadDebtAndCollateralConsistsMostlyOfDebtAssetAndCompleteLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        givenEnoughLiquidityInTheReserve
        givenAccountHasCollateralMostlyInDebtAsset
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        // Liquidate the account completely.
        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should repay correct amount to the lenders for complete liquidation.
        assertEq(assetsRepaid, totalDebtAssets, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - totalDebtAssets,
            "Reserve borrowed incorrect"
        );

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        // The liquidator's final balance should be consistent with the bonus optimization
        // Verify this through the helper function which accounts for all asset flows
        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 5
    function test_GivenNoBadDebtAndEnoughLiquidityInTheReserve_GivenInKindIsTrue_WhenCompleteLiquidation_ItShouldLiquidateCompletelyAndTransferUnderlyingAssets()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
        givenWithdrawnInKind
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets, withdrawnInKind);

        // Liquidate the account completely with inKind = true but enough liquidity exists
        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should remove the debt from the account.
        assertEq(assetsRepaid, totalDebtAssets, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - totalDebtAssets,
            "Reserve borrowed incorrect"
        );

        // It should transfer the underlying collateral assets to the liquidator (not shares).
        for (uint256 i; i < collateralToLiquidate.length; ++i) {
            // Since there is enough liquidity, inKind should be false even if requested
            assertFalse(collateralToLiquidate[i].inKind, "Should not be withdrawn in-kind when liquidity exists");

            // Liquidator should not have received shares
            assertEq(
                office.balanceOf(caller, collateralToLiquidate[i].tokenId),
                0,
                "Liquidator should not receive collateral shares"
            );
        }

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 6
    function test_GivenNoBadDebtAndNotEnoughLiquidity_InKindTrue_PartialLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenNotEnoughLiquidityInTheReserve
        givenAccountIsUnhealthy
        givenWithdrawnInKind
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets / 2, withdrawnInKind);

        uint256 expectedAssetsRepaid = totalDebtAssets / 2;

        // It should reduce the debt correctly.
        uint256 expectedAccountDebtSharesAfter = accountDebtSharesBefore
            - expectedAssetsRepaid.toSharesDown(debtReserveDataBefore.borrowed, totalDebtSharesBefore);

        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should reduce the debt.
        assertEq(
            office.getReserveData(debtId.getReserveKey()).borrowed,
            debtReserveDataBefore.borrowed - expectedAssetsRepaid,
            "Reserve borrowed incorrect"
        );

        // It should liquidate the account partially.
        assertEq(office.balanceOf(account, debtId), expectedAccountDebtSharesAfter, "Account should still have debt");

        // It should repay correct amount to the lenders.
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 7
    function test_GivenNoBadDebtAndNotEnoughLiquidity_InKindTrue_CompleteLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenNotEnoughLiquidityInTheReserve
        givenAccountIsUnhealthy
        givenWithdrawnInKind
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets, withdrawnInKind);

        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should repay correct amount to the lenders.
        assertEq(assetsRepaid, totalDebtAssets, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - totalDebtAssets,
            "Reserve borrowed incorrect"
        );

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 8
    function test_GivenNoBadDebtAndNotEnoughLiquidity_InKindTrue_CollateralMostlyDebtAsset_CompleteLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        givenAccountHasCollateralMostlyInDebtAsset
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenNotEnoughLiquidityInTheReserve
        givenAccountIsUnhealthy
        givenWithdrawnInKind
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets, withdrawnInKind);

        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should repay correct amount to the lenders.
        assertEq(assetsRepaid, totalDebtAssets, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - totalDebtAssets,
            "Reserve borrowed incorrect"
        );

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 9
    function test_Revert_GivenNoBadDebtAndNotEnoughLiquidity_InKindTrue_WhenLiquidatorTriesToLiquidateDustAmountOfCollateral()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenNotEnoughLiquidityInTheReserve
        givenAccountIsUnhealthy
        givenWithdrawnInKind
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collaterals = new CollateralLiquidationParams[](1);
        collaterals[0] = CollateralLiquidationParams({
            tokenId: market.toReserveKey(weth).toEscrowId(), assets: 1, shares: 0, inKind: withdrawnInKind
        });

        // It should revert with Office__NoAssetsRepaid error.
        vm.expectRevert(IOffice.Office__NoAssetsRepaid.selector);
        office.liquidate(
            LiquidationParams({
                market: market, account: account, collateralParams: collaterals, callbackData: "", extraData: ""
            })
        );
    }

    // Test case 10
    function test_Revert_GivenNoBadDebtAndNotEnoughLiquidity_InKindFalse_ItShouldRevert()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenNotEnoughLiquidityInTheReserve
        givenAccountIsUnhealthy
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        // It should revert with Office__InsufficientLiquidity error.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__InsufficientLiquidity.selector, debtKey));
        office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );
    }

    // Test case 11
    function test_GivenBadDebtAndCompleteLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountHasBadDebt
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        // Calculate expected assets repaid by summing across all collateral.
        uint256 expectedAssetsRepaid = _calculateExpectedAssetsRepaid(collateralToLiquidate);

        // Liquidate the account completely.
        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should socialise the bad debt correctly.
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - totalDebtAssets,
            "Reserve borrowed incorrect"
        );

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 12
    function test_GivenBadDebtAndPartialLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountHasBadDebt
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets / 2);

        uint256 expectedAssetsRepaid = totalDebtAssets / 2;

        uint256 expectedAccountDebtSharesAfter = accountDebtSharesBefore
            - expectedAssetsRepaid.toSharesDown(debtReserveDataBefore.borrowed, totalDebtSharesBefore);

        // Liquidate the account partially.
        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account partially.
        assertEq(office.balanceOf(account, debtId), expectedAccountDebtSharesAfter, "Debt should be partially reduced");

        // It should socialise the bad debt correctly.
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - expectedAssetsRepaid,
            "Reserve borrowed incorrect"
        );

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 13
    function test_GivenBadDebtAndDustAmountOfCollateralIsLiquidatedCompletely()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountHasBadDebt
        storeBeforeState(office.getDebtId(account, market))
    {
        // First, liquidate most of the WETH except for 1 wei to simulate dust remaining
        vm.startPrank(caller);

        uint256 wethTokenId = market.toReserveKey(weth).toEscrowId();
        uint256 accountWethBalance = office.balanceOf(account, wethTokenId);

        // Liquidate all but 1 wei of WETH
        CollateralLiquidationParams[] memory collaterals1 = new CollateralLiquidationParams[](1);
        collaterals1[0] = CollateralLiquidationParams({
            tokenId: wethTokenId, assets: accountWethBalance - 1, shares: 0, inKind: false
        });

        // Expected assets repaid for the first liquidation (reduce debt correctly)
        uint256 expectedAssetsRepaidFirst =
            oracleModule.getQuote({inAmount: accountWethBalance - 1, base: address(weth), quote: address(debtAsset)});
        uint64 bonusPctFirst = office.getMarketConfig(market).liquidationBonusPercentage(account, wethTokenId, debtKey);
        expectedAssetsRepaidFirst = expectedAssetsRepaidFirst.divWadDown(WAD + bonusPctFirst);

        uint256 assetsRepaidFirst = office.liquidate(
            LiquidationParams({
                market: market, account: account, collateralParams: collaterals1, callbackData: "", extraData: ""
            })
        );

        // It should reduce the debt correctly (first liquidation amount matches expectation).
        assertEq(assetsRepaidFirst, expectedAssetsRepaidFirst, "First liquidation assets repaid mismatch");

        // It should update the reserve data correctly after first liquidation.
        uint256 borrowedAfterFirst = office.getReserveData(debtKey).borrowed;
        assertEq(
            borrowedAfterFirst,
            debtReserveDataBefore.borrowed - expectedAssetsRepaidFirst,
            "Reserve borrowed incorrect after first liquidation"
        );

        // Verify 1 wei remains
        assertEq(office.balanceOf(account, wethTokenId), 1, "Should have 1 wei remaining");

        uint256 liquidatorWethBalanceBefore = weth.balanceOf(caller);

        // Now liquidate the final 1 wei (dust)
        // 1 wei WETH at $100 (crashed price) in USDC terms is 0 due to rounding.
        CollateralLiquidationParams[] memory collaterals2 = new CollateralLiquidationParams[](1);
        collaterals2[0] = CollateralLiquidationParams({
            tokenId: wethTokenId,
            assets: 1, // Final 1 wei
            shares: 0,
            inKind: false
        });

        office.liquidate(
            LiquidationParams({
                market: market, account: account, collateralParams: collaterals2, callbackData: "", extraData: ""
            })
        );

        // Reserve borrowed should remain unchanged after dust liquidation.
        assertEq(office.getReserveData(debtKey).borrowed, borrowedAfterFirst, "Borrowed changed on dust liquidation");

        // It should clear the entire collateral position
        // Because liquidator seized all remaining dust collateral, enabling bad debt socialization
        assertEq(office.balanceOf(account, wethTokenId), 0, "Collateral balance should be 0");

        // It should transfer the dust collateral to the liquidator
        assertEq(weth.balanceOf(caller), liquidatorWethBalanceBefore + 1, "Liquidator should receive dust collateral");
    }

    // Test case 14
    function test_GivenBadDebtAndCollateralConsistsMostlyOfDebtAssetAndCompleteLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        givenEnoughLiquidityInTheReserve
        givenAccountHasCollateralMostlyInDebtAsset
        whenTheAccountHasADebtPosition
        givenAccountHasBadDebt
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        uint256 expectedAssetsRepaid = _calculateExpectedAssetsRepaid(collateralToLiquidate);

        // Liquidate the account completely.
        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should not transfer entire asset amount which is the debt asset.
        // The liquidator should receive a net benefit due to the bonus optimization when most collateral is debt asset
        assertTrue(
            debtAsset.balanceOf(caller) > liquidatorDebtAssetBalanceBefore,
            "Liquidator should have net positive debt asset balance due to bonus optimization"
        );

        // It should socialise the bad debt correctly.
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - totalDebtAssets,
            "Reserve borrowed incorrect"
        );

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 15
    function test_GivenBadDebtAndEnoughLiquidityInTheReserve_GivenInKindIsTrue_WhenCompleteLiquidation_ItShouldLiquidateCompletelyAndSocialiseBadDebt()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountHasBadDebt
        givenWithdrawnInKind
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets, withdrawnInKind);

        uint256 expectedAssetsRepaid = _calculateExpectedAssetsRepaid(collateralToLiquidate);

        // Liquidate the account completely with inKind = true but enough liquidity exists
        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should remove the debt from the account.
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        // It should socialise the bad debt correctly - the borrowed should be 0 after complete liquidation with bad debt.
        // Both repaid and unpaid (bad) debt are removed from the reserve.
        assertEq(
            office.getReserveData(debtKey).borrowed, 0, "Reserve borrowed should be 0 after bad debt socialization"
        );

        // It should transfer the underlying collateral assets to the liquidator (not shares).
        for (uint256 i; i < collateralToLiquidate.length; ++i) {
            // Since there is enough liquidity, inKind should be false even if requested
            assertFalse(collateralToLiquidate[i].inKind, "Should not be withdrawn in-kind when liquidity exists");

            // Liquidator should not have received shares
            assertEq(
                office.balanceOf(caller, collateralToLiquidate[i].tokenId),
                0,
                "Liquidator should not receive collateral shares"
            );
        }

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 16
    function test_GivenBadDebtAndNotEnoughLiquidity_InKindTrue_PartialLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenNotEnoughLiquidityInTheReserve
        givenAccountHasBadDebt
        givenWithdrawnInKind
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets / 2, withdrawnInKind);

        uint256 expectedAssetsRepaid = totalDebtAssets / 2;

        // It should reduce the debt correctly.
        uint256 expectedAccountDebtSharesAfter = accountDebtSharesBefore
            - expectedAssetsRepaid.toSharesDown(debtReserveDataBefore.borrowed, totalDebtSharesBefore);

        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should reduce the debt correctly.
        assertEq(office.balanceOf(account, debtId), expectedAccountDebtSharesAfter, "Debt should be reduced");

        // It should socialise the bad debt correctly.
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - expectedAssetsRepaid,
            "Reserve borrowed incorrect"
        );

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 17
    function test_GivenBadDebtAndNotEnoughLiquidity_InKindTrue_CompleteLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenNotEnoughLiquidityInTheReserve
        givenAccountHasBadDebt
        givenWithdrawnInKind
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets, withdrawnInKind);

        uint256 expectedAssetsRepaid = _calculateExpectedAssetsRepaid(collateralToLiquidate);

        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should socialise the bad debt correctly.
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - totalDebtAssets,
            "Reserve borrowed incorrect"
        );

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 18
    function test_GivenBadDebtAndNotEnoughLiquidity_InKindTrue_CollateralMostlyDebtAsset_CompleteLiquidation()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        givenAccountHasCollateralMostlyInDebtAsset
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenNotEnoughLiquidityInTheReserve
        givenAccountHasBadDebt
        givenWithdrawnInKind
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets, withdrawnInKind);

        uint256 expectedAssetsRepaid = _calculateExpectedAssetsRepaid(collateralToLiquidate);

        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should socialise the bad debt correctly.
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        // It should not transfer any debt asset to the liquidator.
        assertEq(
            debtAsset.balanceOf(caller),
            liquidatorDebtAssetBalanceBefore - assetsRepaid,
            "Liquidator should not receive any debt asset"
        );

        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - totalDebtAssets,
            "Reserve borrowed incorrect"
        );

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 19
    // This test doesn't follow many of the conventions used in other tests in this file due to the very specific scenario
    // we needed to replicate.
    function test_GivenBadDebtAndNotEnoughLiquidity_InKindTrue_WhenLiquidatorLiquidatesDustAmountOfUsdcCollateralCompletely_BorrowingWeth()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        givenWithdrawnInKind
    {
        uint256 usdcTokenId = usdcKey.toLentId();
        debtKey = wethKey;
        debtAsset = weth;
        uint256 accountSuppliedAmount = 5000e6; // 5000 USDC

        /* Create an illiquid USDC reserve scenario */

        vm.startPrank(caller);

        // Supply USDC
        office.supply(
            SupplyParams({
                tokenId: usdcTokenId,
                account: account,
                assets: accountSuppliedAmount, // 5000 USDC
                extraData: ""
            })
        );

        vm.startPrank(bob);

        // First supply WETH to the market so bob can borrow from the USDC reserve.
        office.supply(
            SupplyParams({
                tokenId: wethKey.toLentId(),
                account: bob.toUserAccount(),
                assets: 100e18, // 100 WETH
                extraData: ""
            })
        );

        Office.ReserveData memory reserveData = office.getReserveData(usdcKey);

        // Now borrow all USDC liquidity.
        office.borrow(
            BorrowParams({
                key: usdcKey,
                account: bob.toUserAccount(),
                receiver: bob,
                assets: reserveData.supplied - reserveData.borrowed,
                extraData: ""
            })
        );

        /* Setup WETH reserve */

        // Make the WETH reserve borrowable.
        vm.startPrank(admin);

        SimpleMarketConfig.AssetConfig[] memory assets = new SimpleMarketConfig.AssetConfig[](1);
        assets[0] = SimpleMarketConfig.AssetConfig({asset: weth, isBorrowable: true});
        marketConfig.addSupportedAssets(assets);

        /* Create a debt position */

        // Let owner borrow WETH using supplied assets.
        vm.startPrank(caller);
        office.borrow(
            BorrowParams({
                key: wethKey,
                account: account,
                receiver: caller,
                assets: 1e18, // 1 WETH
                extraData: ""
            })
        );

        /* Liquidate */
        caller = liquidator;
        vm.startPrank(caller);

        // Raise the WETH price to $1,000,000,000,000 to ensure USDC collateral is worth very little in WETH terms.
        oracleModule.setPrice(address(weth), 1_000_000_000_000e8);

        uint256 borrowedBeforeFirst = office.getReserveData(debtKey).borrowed;

        // Liquidate all but 1 wei of USDC collateral to leave dust.
        CollateralLiquidationParams[] memory collaterals1 = new CollateralLiquidationParams[](1);
        collaterals1[0] = CollateralLiquidationParams({
            tokenId: usdcTokenId, assets: accountSuppliedAmount - 1, shares: 0, inKind: withdrawnInKind
        });

        // Expected assets repaid for the first liquidation (reduce debt correctly)
        uint256 expectedAssetsRepaidFirst = oracleModule.getQuote({
            inAmount: accountSuppliedAmount - 1, base: address(usdc), quote: address(debtAsset)
        });
        uint64 bonusPctFirst = office.getMarketConfig(market).liquidationBonusPercentage(account, usdcTokenId, debtKey);
        expectedAssetsRepaidFirst = expectedAssetsRepaidFirst.divWadDown(WAD + bonusPctFirst);

        uint256 assetsRepaidFirst = office.liquidate(
            LiquidationParams({
                market: market, account: account, collateralParams: collaterals1, callbackData: "", extraData: ""
            })
        );

        // It should reduce the debt correctly (first liquidation amount matches expectation).
        assertEq(assetsRepaidFirst, expectedAssetsRepaidFirst, "First liquidation assets repaid mismatch");

        // It should update the reserve data correctly after first liquidation.
        uint256 borrowedAfterFirst = office.getReserveData(debtKey).borrowed;
        assertEq(
            borrowedAfterFirst,
            borrowedBeforeFirst - expectedAssetsRepaidFirst,
            "Reserve borrowed incorrect after first liquidation"
        );

        // Verify 1 wei remains (after scaling up)
        assertEq(office.balanceOf(account, usdcTokenId), 1e6, "Should have 1 wei remaining");

        uint256 liquidatorUsdcSharesBalanceBefore = office.balanceOf(liquidator, usdcTokenId);

        // Now liquidate the final 1 wei (dust)
        CollateralLiquidationParams[] memory collaterals2 = new CollateralLiquidationParams[](1);
        collaterals2[0] = CollateralLiquidationParams({
            tokenId: usdcTokenId,
            assets: 1, // Final 1 wei
            shares: 0,
            inKind: withdrawnInKind
        });

        office.liquidate(
            LiquidationParams({
                market: market, account: account, collateralParams: collaterals2, callbackData: "", extraData: ""
            })
        );

        // Reserve borrowed should be 0 after dust liquidation due to bad debt socialization.
        assertEq(office.getReserveData(debtKey).borrowed, 0, "Borrowed should be 0 after bad debt re-distribution");

        // It should clear the entire collateral position
        // Because liquidator seized all remaining dust collateral, enabling bad debt socialization
        assertEq(office.balanceOf(account, usdcTokenId), 0, "Collateral balance should be 0");

        // It should transfer the dust collateral (scaled up in share terms) to the liquidator
        assertEq(
            office.balanceOf(caller, usdcTokenId),
            liquidatorUsdcSharesBalanceBefore + 1e6,
            "Liquidator should receive dust collateral"
        );
    }

    // Test case 20
    function test_Revert_GivenBadDebtAndNotEnoughLiquidity_InKindFalse_ItShouldRevert()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenNotEnoughLiquidityInTheReserve
        givenAccountHasBadDebt
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        // It should revert with Office__InsufficientLiquidity error.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__InsufficientLiquidity.selector, debtKey));
        office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );
    }

    // Test case 21
    function test_GivenSomeCallbackData()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        // Mock the return data for the liquidator's callback.
        vm.mockCall(liquidator, abi.encodeWithSelector(ILiquidator.onLiquidationCallback.selector), abi.encode(""));

        // It should call the liquidator with the callback data.
        vm.expectCall(liquidator, abi.encodeWithSelector(ILiquidator.onLiquidationCallback.selector));

        // Liquidate the account completely.
        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "0xdeadbeef",
                extraData: ""
            })
        );

        // It should liquidate the account completely.
        assertEq(office.balanceOf(account, debtId), 0, "Debt should be cleared");

        // It should repay correct amount to the lenders.
        assertEq(assetsRepaid, totalDebtAssets, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - totalDebtAssets,
            "Reserve borrowed incorrect"
        );

        assertTrue(office.isHealthyAccount(account, market), "Account should be healthy");

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 22
    // Given bad debt and the liquidator provides max uint256 collateral shares
    function test_GivenBadDebtAndLiquidatorProvidesMaxUint256CollateralShares_ItShouldUseEntireCollateralShares_ReduceDebt_RewardLiquidator_RepayLenders()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountHasBadDebt
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate = new CollateralLiquidationParams[](1);
        collateralToLiquidate[0] = CollateralLiquidationParams({
            tokenId: collateralIds[0], shares: type(uint256).max, assets: 0, inKind: false
        });

        uint256 expectedAssetsRepaid;
        uint256 expectedDebtSharesAfter;
        {
            // Convert the shares to assets using the reserve data.
            uint256 collateralShares = accountCollateralSharesBefore[0];
            uint256 expectedCollateralAssetsUsed =
                collateralShares.toAssetsDown(collateralReserveDataBefore[0].supplied, totalCollateralSharesBefore[0]);

            // Convert this amount to debt asset terms.
            expectedAssetsRepaid = oracleModule.getQuote({
                inAmount: expectedCollateralAssetsUsed,
                base: address(collateralToLiquidate[0].tokenId.getAsset()),
                quote: address(debtAsset)
            });

            // Subtract the liquidation bonus.
            uint64 bonusPercentage = office.getMarketConfig(market)
                .liquidationBonusPercentage(account, collateralToLiquidate[0].tokenId, debtKey);
            expectedAssetsRepaid = expectedAssetsRepaid.divWadDown(WAD + bonusPercentage);

            expectedDebtSharesAfter = accountDebtSharesBefore
                - expectedAssetsRepaid.toSharesDown(debtReserveDataBefore.borrowed, totalDebtSharesBefore);
        }

        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should use the entire collateral shares of the account.
        assertEq(office.balanceOf(account, collateralIds[0]), 0, "Account should have no collateral shares remaining");

        // It should reduce the debt of the account.
        assertEq(office.balanceOf(account, debtId), expectedDebtSharesAfter, "Debt should be reduced correctly");

        // It should repay correct amount to the lenders (in debt asset terms).
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - expectedAssetsRepaid,
            "Reserve borrowed incorrect"
        );

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 23
    // Given bad debt and the liquidator provides assets amount instead of shares
    // Given the amount is less than the collateral balance of the account
    function test_GivenBadDebtAndLiquidatorProvidesAssetsAmountInsteadOfShares_AmountLessThanCollateralBalance_ItShouldUseSpecifiedAmount_ReduceDebt_RewardLiquidator_RepayLenders()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountHasBadDebt
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        // For partial liquidation, specify assets amount for USDC collateral only
        // Use 500 USDC worth of collateral (half of the USDC collateral)
        uint256 collateralAssetsToUse = 500e6;

        CollateralLiquidationParams[] memory collateralToLiquidate = new CollateralLiquidationParams[](1);
        collateralToLiquidate[0] = CollateralLiquidationParams({
            tokenId: collateralIds[0], // USDC lend token
            assets: collateralAssetsToUse, // Providing assets amount instead of shares
            shares: 0, // Set shares to 0 to indicate we're using assets
            inKind: false
        });

        // Expected: collateralValue / (1 + bonus) = 500 / 1.1 = ~454.54 USDC
        uint64 bonusPercentage =
            office.getMarketConfig(market).liquidationBonusPercentage(account, collateralIds[0], debtKey);
        uint256 expectedAssetsRepaid = collateralAssetsToUse.divWadDown(WAD + bonusPercentage);

        uint256 expectedAccountDebtSharesAfter = accountDebtSharesBefore
            - expectedAssetsRepaid.toSharesDown(debtReserveDataBefore.borrowed, totalDebtSharesBefore);

        // Store the shares equivalent for verification
        uint256 collateralSharesUsed =
            collateralAssetsToUse.toSharesUp(collateralReserveDataBefore[0].supplied, totalCollateralSharesBefore[0]);

        uint256 assetsRepaid = office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );

        // It should reduce the debt of the account.
        assertEq(office.balanceOf(account, debtId), expectedAccountDebtSharesAfter, "Debt should be reduced");

        // It should repay correct amount of assets (in debt asset terms).
        assertEq(assetsRepaid, expectedAssetsRepaid, "Repaid assets mismatch");

        // It should update the reserve data correctly.
        assertEq(
            office.getReserveData(debtKey).borrowed,
            debtReserveDataBefore.borrowed - expectedAssetsRepaid,
            "Reserve borrowed incorrect"
        );

        // Set the shares for verification (convert assets back to shares for the helper function)
        collateralToLiquidate[0].shares = collateralSharesUsed;

        _verifyBalancesAfterLiquidation(assetsRepaid, collateralToLiquidate);
    }

    // Test case 24
    // Given the liquidator provides assets amount instead of shares during complete liquidation
    // Given the amount is more than the collateral balance of the account
    function test_Revert_GivenBadDebtAndLiquidatorProvidesAssetsAmountInsteadOfShares_AmountMoreThanCollateralBalance_ItShouldRevert()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountHasBadDebt
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        uint256 assetsToLiquidate = totalDebtAssets + 1;
        CollateralLiquidationParams[] memory collateralToLiquidate = new CollateralLiquidationParams[](1);

        collateralToLiquidate[0] = CollateralLiquidationParams({
            tokenId: collateralIds[0], shares: 0, assets: assetsToLiquidate, inKind: withdrawnInKind
        });

        // It should revert.
        //    With `IRegistry.Registry__InsufficientBalance`.
        uint256 sharesToBurn =
            assetsToLiquidate.toSharesUp(collateralReserveDataBefore[0].supplied, totalCollateralSharesBefore[0]);

        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientBalance.selector,
                account,
                accountCollateralSharesBefore[0],
                sharesToBurn,
                collateralIds[0]
            )
        );
        office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );
    }

    // Test case 25
    // Given the liquidator provides both shares and assets amount
    function test_Revert_GivenLiquidatorProvidesBothSharesAndAssetsAmount_ItShouldRevertWithAssetsAndSharesNonZeroError()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);
        CollateralLiquidationParams[] memory collateralToLiquidate = new CollateralLiquidationParams[](1);
        collateralToLiquidate[0] =
            CollateralLiquidationParams({tokenId: collateralIds[0], shares: 1, assets: 1, inKind: withdrawnInKind});

        // It should revert with IOffice.Office__AssetsAndSharesNonZero error.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AssetsAndSharesNonZero.selector, uint256(1), uint256(1)));
        office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );
    }

    // Test case 26
    function test_Revert_GivenAccountIsHealthy()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
        storeBeforeState(office.getDebtId(account, market))
    {
        vm.startPrank(caller);

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        // It should revert.
        //     With `Office__AccountStillHealthy`.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountStillHealthy.selector, account, market));

        office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );
    }

    /////////////////////////////////////////////
    //                 Helpers                 //
    /////////////////////////////////////////////

    /// @dev Calculates the expected assets repaid based on the collateral to liquidate.
    ///      It accounts for per-collateral liquidation bonus percentages.
    function _calculateExpectedAssetsRepaid(CollateralLiquidationParams[] memory collateralToLiquidate)
        internal
        view
        returns (uint256 expectedAssetsRepaid)
    {
        for (uint256 i; i < collateralToLiquidate.length; ++i) {
            uint256 collateralShares = collateralToLiquidate[i].shares;
            uint256 collateralAssets;

            // Check if the collateral is an escrow token or a lent token
            bool isLentToken = collateralToLiquidate[i].tokenId.getTokenType() == TokenType.LEND;
            if (!isLentToken) {
                // For escrow tokens, shares = assets (1:1)
                collateralAssets = collateralShares;
            } else {
                // For lent tokens, convert shares to assets using reserve data
                collateralAssets = collateralShares.toAssetsDown(
                    collateralReserveDataBefore[i].supplied, totalCollateralSharesBefore[i]
                );
            }

            // Convert collateral to debt asset terms
            uint256 collateralValueInDebt = oracleModule.getQuote(
                collateralAssets, address(collateralToLiquidate[i].tokenId.getAsset()), address(debtAsset)
            );

            // Get the bonus percentage for this specific collateral-debt pair
            uint64 bonusPercentage = office.getMarketConfig(market)
                .liquidationBonusPercentage(account, collateralToLiquidate[i].tokenId, debtKey);

            // Calculate debt repaid: collateralValue / (1 + bonus)
            expectedAssetsRepaid += collateralValueInDebt.divWadDown(WAD + bonusPercentage);
        }
    }

    /// @dev Asserts the changes in the collateral amount of the account after liquidation.
    ///      It will also assert the liquidator's collateral asset balances.
    function _verifyBalancesAfterLiquidation(
        uint256 assetsRepaid,
        CollateralLiquidationParams[] memory collateralToLiquidate
    )
        internal
        view
    {
        uint256 expectedLiquidatorDebtAssetBalance = liquidatorDebtAssetBalanceBefore - assetsRepaid;

        for (uint256 i; i < collateralToLiquidate.length; ++i) {
            uint256 liquidatedCollateralId = collateralToLiquidate[i].tokenId;
            IERC20 collateralAsset = liquidatedCollateralId.getAsset();
            uint256 liquidatedShares = (collateralToLiquidate[i].shares == type(uint256).max)
                ? accountCollateralSharesBefore[i]
                : collateralToLiquidate[i].shares;

            // Search if the collateral ID is in the list of the liquidated collateral IDs.
            uint256 j;
            for (j = 0; j < collateralIds.length; ++j) {
                if (collateralIds[j] == liquidatedCollateralId) {
                    break;
                }
            }

            uint256 liquidatedAssets;
            if (liquidatedCollateralId.getTokenType() == TokenType.ESCROW) {
                // If the collateral is an escrow asset, we simply convert shares to assets 1:1.
                liquidatedAssets = liquidatedShares;
            } else {
                // Convert shares to assets using the reserve data.
                liquidatedAssets = liquidatedShares.toAssetsDown(
                    collateralReserveDataBefore[j].supplied, totalCollateralSharesBefore[j]
                );
            }

            // Assert account collateral balance change
            assertEq(
                office.balanceOf(account, liquidatedCollateralId),
                accountCollateralSharesBefore[j] - liquidatedShares,
                "Account collateral shares incorrect"
            );

            // If in-kind liquidation, liquidator receives shares
            // Assumes the liquidator doesn't already have any collateral shares.
            if (collateralToLiquidate[i].inKind) {
                assertEq(
                    office.balanceOf(caller, liquidatedCollateralId),
                    liquidatedShares,
                    "Liquidator collateral shares incorrect"
                );
                continue;
            }

            // Calculate expected liquidator balance
            if (collateralAsset == debtAsset && !collateralToLiquidate[i].inKind) {
                expectedLiquidatorDebtAssetBalance += liquidatedAssets;
            } else {
                assertEq(
                    collateralAsset.balanceOf(caller),
                    liquidatorCollateralBalancesBefore[j] + liquidatedAssets,
                    "Liquidator collateral balance incorrect"
                );
            }
        }

        // It should reward liquidator correctly.
        assertEq(
            debtAsset.balanceOf(caller), expectedLiquidatorDebtAssetBalance, "Liquidator debt asset balance incorrect"
        );
    }
}

// Generated using co-pilot: Claude Sonnet 4.5
