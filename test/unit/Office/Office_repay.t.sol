// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Office_repay is CommonScenarios {
    using ReserveKeyLibrary for *;
    using SharesMathLib for uint256;

    Call[] batchCalls;

    // Test case 1: When repaying the debt completely with external funds and caller is owner
    function test_WhenRepayingTheDebtCompletelyWithExternalFundsAndCallerIsOwner()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        uint256 reserveSuppliedBefore = office.getReserveData(key).supplied;
        uint256 callerBalanceBefore = usdc.balanceOf(caller);

        RepayParams memory params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType(0),
            assets: 0,
            shares: office.balanceOf(account, key.toDebtId()), // Repay all debt shares
            extraData: ""
        });

        uint256 assetsRepaid = office.repay(params);

        // It should burn all debt shares of the account.
        assertEq(office.balanceOf(account, key.toDebtId()), 0, "Debt shares should be burned");

        // It should decrease the borrowed assets amount.
        assertEq(office.getReserveData(key).borrowed, 0, "Borrowed assets should be zero");

        // It should not modify the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, reserveSuppliedBefore, "Supplied assets should remain unchanged");

        // The caller's assets should be decreased by the amount of debt repaid.
        assertEq(
            usdc.balanceOf(caller),
            callerBalanceBefore - assetsRepaid,
            "Caller balance should decrease by repaid amount"
        );
    }

    // Test case 2: When repaying the debt partially with external funds and caller is owner
    function test_WhenRepayingTheDebtPartiallyWithExternalFundsAndCallerIsOwner()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        OfficeStorage.ReserveData memory reserveDataBefore = office.getReserveData(key);
        uint256 callerBalanceBefore = usdc.balanceOf(caller);
        uint256 debtSharesBefore = office.balanceOf(account, key.toDebtId());

        RepayParams memory params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType(0),
            assets: 0,
            shares: debtSharesBefore / 2, // Repay half of the debt shares
            extraData: ""
        });

        uint256 assetsRepaid = office.repay(params);

        // It should burn all debt shares of the account.
        assertEq(office.balanceOf(account, key.toDebtId()), debtSharesBefore / 2, "Debt shares should be burned");

        // It should decrease the borrowed assets amount.
        assertEq(office.getReserveData(key).borrowed, reserveDataBefore.borrowed / 2, "Borrowed assets should be zero");

        // It should not modify the supplied assets amount.
        assertEq(
            office.getReserveData(key).supplied, reserveDataBefore.supplied, "Supplied assets should remain unchanged"
        );

        // The caller's assets should be decreased by the amount of debt repaid.
        assertEq(
            usdc.balanceOf(caller),
            callerBalanceBefore - assetsRepaid,
            "Caller balance should decrease by repaid amount"
        );
    }

    // Test case 3: When repaying the debt partially and below minimum debt with external funds and caller is owner
    function test_RevertWhen_RepayingTheDebtPartiallyAndBelowMinimumDebtWithExternalFundsAndCallerIsOwner()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(admin);

        // Set a high minimum debt requirement (e.g., $1500 USD).
        // The account currently has $2000 debt (2000 USDC).
        marketConfig.setMinDebtAmountUSD(1500e18);

        vm.startPrank(caller);

        // Try to repay $1000 worth of debt (half of the debt).
        // This would leave $1000 debt remaining, which is below the $1500 minimum.
        RepayParams memory params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType.NONE,
            assets: 1000e6, // Repay 1000 USDC, leaving 1000 USDC debt (below $1500 minimum)
            shares: 0,
            extraData: ""
        });

        // It should revert.
        //     With `Office__DebtBelowMinimum` error.
        vm.expectPartialRevert(IOffice.Office__DebtBelowMinimum.selector);
        office.repay(params);

        // Repay the full debt just to be sure it works.
        params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType.NONE,
            assets: 0,
            shares: type(uint256).max, // Repay all debt shares
            extraData: ""
        });

        office.repay(params);

        // It should burn all debt shares of the account.
        assertEq(office.balanceOf(account, key.toDebtId()), 0, "Debt shares should be burned");
    }

    // Test case 4: When repaying the debt with external funds and caller is operator
    function test_WhenRepayingTheDebtWithExternalFundsAndCallerIsOperator()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        uint256 reserveSuppliedBefore = office.getReserveData(key).supplied;
        uint256 callerBalanceBefore = usdc.balanceOf(caller);

        RepayParams memory params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType(0),
            assets: 0,
            shares: office.balanceOf(account, key.toDebtId()), // Repay all debt shares
            extraData: ""
        });

        uint256 assetsRepaid = office.repay(params);

        // It should burn all debt shares of the account.
        assertEq(office.balanceOf(account, key.toDebtId()), 0, "Debt shares should be burned");

        // It should decrease the borrowed assets amount.
        assertEq(office.getReserveData(key).borrowed, 0, "Borrowed assets should be zero");

        // It should not modify the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, reserveSuppliedBefore, "Supplied assets should remain unchanged");

        // The caller's assets should be decreased by the amount of debt repaid.
        assertEq(
            usdc.balanceOf(caller),
            callerBalanceBefore - assetsRepaid,
            "Caller balance should decrease by repaid amount"
        );
    }

    // Test case 5: Revert when repaying the debt with external funds and caller is not authorized
    function test_RevertWhen_RepayingTheDebtWithExternalFundsAndCallerIsNotAuthorized()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsNotAuthorized
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        RepayParams memory params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType(0),
            assets: 0,
            shares: office.balanceOf(account, key.toDebtId()), // Repay all debt shares
            extraData: ""
        });

        vm.expectRevert(abi.encodeWithSelector(IRegistry.Registry__NotAuthorizedCaller.selector, account, caller));
        office.repay(params);
    }

    // Test case 6: When repaying the debt with collateral and caller is owner
    function test_WhenRepayingTheDebtWithCollateralAndCallerIsOwner()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        OfficeStorage.ReserveData memory usdcReserveDataBefore = office.getReserveData(key);
        uint256 debtSharesBefore = office.balanceOf(account, key.toDebtId());
        uint256 callerBalanceBefore = usdc.balanceOf(caller);
        uint256 wethSupplyBefore = office.balanceOf(account, wethKey.toEscrowId());

        office.accrueInterest(key); // Ensure interest is accrued before repayment

        uint256 assetsToRepay =
            debtSharesBefore.toAssetsUp(usdcReserveDataBefore.borrowed, office.totalSupply(usdcKey.toDebtId()));
        uint256 collateralAssets = oracleModule.getQuote(assetsToRepay, address(usdc), address(weth));

        encodeWithdraw(wethKey.toEscrowId(), collateralAssets);
        encodeRepay(key, debtSharesBefore);

        bytes memory returnData =
            office.delegationCall(DelegationCallParams({delegatee: delegatee, callbackData: abi.encode(batchCalls)}));
        bytes[] memory results = abi.decode(returnData, (bytes[]));
        uint256 assetsRepaid = abi.decode(results[1], (uint256));

        // It should burn all debt shares of the account.
        assertEq(office.balanceOf(account, key.toDebtId()), 0, "Debt shares should be burned");

        // It should decrease the borrowed assets amount.
        assertEq(
            office.getReserveData(key).borrowed,
            usdcReserveDataBefore.borrowed - assetsRepaid,
            "Borrowed assets should reduce by repaid amount"
        );

        // It should decrease the WETH escrowed shares amount.
        assertEq(
            office.totalSupply(wethKey.toEscrowId()),
            wethSupplyBefore - collateralAssets,
            "Escrowed assets should decrease by shares redeemed"
        );

        // The caller's assets should not change since they used collateral.
        assertEq(usdc.balanceOf(caller), callerBalanceBefore, "Caller balance should remain unchanged");

        // The account's collateral should be reduced by the amount used for repayment.
        assertEq(
            office.balanceOf(account, wethKey.toEscrowId()),
            accountSuppliedAmountBefore.wethEscrowShareAmount - collateralAssets,
            "Account's WETH collateral shares should decrease"
        );
    }

    // Test case 7: When repaying the debt with collateral and caller is operator
    function test_WhenRepayingTheDebtWithCollateralAndCallerIsOperator()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        OfficeStorage.ReserveData memory usdcReserveDataBefore = office.getReserveData(key);
        uint256 debtSharesBefore = office.balanceOf(account, key.toDebtId());
        uint256 callerBalanceBefore = usdc.balanceOf(caller);
        uint256 wethSupplyBefore = office.balanceOf(account, wethKey.toEscrowId());

        office.accrueInterest(key); // Ensure interest is accrued before repayment

        uint256 assetsToRepay =
            debtSharesBefore.toAssetsUp(usdcReserveDataBefore.borrowed, office.totalSupply(usdcKey.toDebtId()));
        uint256 collateralAssets = oracleModule.getQuote(assetsToRepay, address(usdc), address(weth));

        encodeWithdraw(wethKey.toEscrowId(), collateralAssets);
        encodeRepay(key, debtSharesBefore);

        bytes memory returnData =
            office.delegationCall(DelegationCallParams({delegatee: delegatee, callbackData: abi.encode(batchCalls)}));
        bytes[] memory results = abi.decode(returnData, (bytes[]));
        uint256 assetsRepaid = abi.decode(results[1], (uint256));

        // It should burn all debt shares of the account.
        assertEq(office.balanceOf(account, key.toDebtId()), 0, "Debt shares should be burned");

        // It should decrease the borrowed assets amount.
        assertEq(
            office.getReserveData(key).borrowed,
            usdcReserveDataBefore.borrowed - assetsRepaid,
            "Borrowed assets should reduce by repaid amount"
        );

        // It should decrease the WETH escrowed shares amount.
        assertEq(
            office.totalSupply(wethKey.toEscrowId()),
            wethSupplyBefore - collateralAssets,
            "Escrowed assets should decrease by shares redeemed"
        );

        // The caller's assets should not change since they used collateral.
        assertEq(usdc.balanceOf(caller), callerBalanceBefore, "Caller balance should remain unchanged");

        // The account's collateral should be reduced by the amount used for repayment.
        assertEq(
            office.balanceOf(account, wethKey.toEscrowId()),
            accountSuppliedAmountBefore.wethEscrowShareAmount - collateralAssets,
            "Account's WETH collateral shares should decrease"
        );
    }

    // Test case 8: Revert when repaying the debt with collateral and caller is not authorized
    function test_RevertWhen_RepayingTheDebtWithCollateralAndCallerIsNotAuthorized()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner // We manually set an unauthorized caller after creating a valid position.
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        caller = keeper; // Keeper is not authorized to call repay.
        vm.startPrank(caller);

        OfficeStorage.ReserveData memory usdcReserveDataBefore = office.getReserveData(key);
        uint256 debtSharesBefore = office.balanceOf(account, key.toDebtId());

        office.accrueInterest(key); // Ensure interest is accrued before repayment

        uint256 assetsToRepay =
            debtSharesBefore.toAssetsUp(usdcReserveDataBefore.borrowed, office.totalSupply(usdcKey.toDebtId()));
        uint256 collateralAssets = oracleModule.getQuote(assetsToRepay, address(usdc), address(weth));

        encodeWithdraw(wethKey.toEscrowId(), collateralAssets);
        encodeRepay(key, debtSharesBefore);

        // It should revert with `SimpleDelegatee__CallFailed` because the repay call fails due to insufficient allowance.
        // Which means the caller is not the operator/owner of the account and hence not authorized.
        // We are not using exact revert encoding because the parameters (like allowance amount) may vary.
        vm.expectPartialRevert(SimpleDelegatee.SimpleDelegatee__CallFailed.selector);
        office.delegationCall(DelegationCallParams({delegatee: delegatee, callbackData: abi.encode(batchCalls)}));
    }

    // Test case 9: Revert when repaying the debt with collateral but account will be unhealthy
    function test_RevertWhen_RepayingTheDebtWithCollateralButAccountWillBeUnhealthy()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        // It should revert.
        //     This can happen when the position's collateral is drained more than the debt amount repaid.

        vm.startPrank(caller);

        office.accrueInterest(key); // Ensure interest is accrued before repayment

        // Use all the escrowed WETH as collateral for repayment.
        encodeWithdraw(wethKey.toEscrowId(), office.balanceOf(account, wethKey.toEscrowId()));

        // Repay a fraction of the debt shares
        encodeRepay(key, 1e6);

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, key.getMarketId()));
        office.delegationCall(DelegationCallParams({delegatee: delegatee, callbackData: abi.encode(batchCalls)}));
    }

    // Test case 10: When repaying the debt via collateral - Given collateral is escrow type
    function test_WhenRepayingTheDebtViaCollateral_GivenCollateralIsEscrowType()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        // First, escrow some USDC (same asset as the debt) for the collateral repayment
        office.supply(
            SupplyParams({
                tokenId: usdcKey.toEscrowId(), // Escrow USDC instead of WETH
                account: account,
                assets: 500e6, // 500 USDC escrowed
                extraData: ""
            })
        );

        OfficeStorage.ReserveData memory usdcReserveDataBefore = office.getReserveData(key);
        uint256 debtSharesBefore = office.balanceOf(account, key.toDebtId());
        uint256 usdcEscrowSharesBefore = office.balanceOf(account, usdcKey.toEscrowId());

        RepayParams memory params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType.ESCROW,
            assets: 0,
            shares: debtSharesBefore / 4, // Repay quarter of debt
            extraData: ""
        });

        uint256 assetsRepaid = office.repay(params);

        uint256 debtSharesAfter = office.balanceOf(account, key.toDebtId());
        uint256 borrowedAfter = office.getReserveData(key).borrowed;
        uint256 usdcEscrowSharesAfter = office.balanceOf(account, usdcKey.toEscrowId());

        // It should burn correct amount of debt shares of the account.
        assertEq(debtSharesAfter, debtSharesBefore - debtSharesBefore / 4, "Quarter of debt shares should be burned");

        // It should decrease the borrowed assets amount.
        assertEq(
            borrowedAfter,
            usdcReserveDataBefore.borrowed - assetsRepaid,
            "Borrowed assets should decrease by repaid amount"
        );

        // It should decrease escrow shares of the account.
        // The decrease in escrow shares should correspond to the assets repaid (1:1 for escrow)
        uint256 expectedEscrowSharesAfter = usdcEscrowSharesBefore - assetsRepaid;
        assertEq(
            usdcEscrowSharesAfter,
            expectedEscrowSharesAfter,
            "USDC escrow shares should decrease by exact repaid amount"
        );
    }

    // Test case 11: When repaying the debt via collateral - Given collateral is lent type
    function test_WhenRepayingTheDebtViaCollateral_GivenCollateralIsLentType()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        uint256 debtSharesBefore = office.balanceOf(account, key.toDebtId());
        uint256 debtSharesToRepay = debtSharesBefore / 2; // Repay half the debt

        OfficeStorage.ReserveData memory usdcReserveDataBefore = office.getReserveData(key);
        uint256 usdcLentSharesBefore = office.balanceOf(account, usdcKey.toLentId());
        uint256 suppliedAssetsBefore = office.getReserveData(key).supplied;
        uint256 expectedAssetsRepaid = debtSharesToRepay.toAssetsUp(usdcReserveDataBefore.borrowed, debtSharesBefore); // Expect to repay half the debt in assets
        uint256 expectedLentSharesConsumed =
            expectedAssetsRepaid.toSharesUp(suppliedAssetsBefore, office.totalSupply(usdcKey.toLentId()));

        RepayParams memory params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType.LEND,
            assets: 0,
            shares: debtSharesToRepay, // Repay half of debt
            extraData: ""
        });

        uint256 assetsRepaid = office.repay(params);

        uint256 debtSharesAfter = office.balanceOf(account, key.toDebtId());
        uint256 borrowedAfter = office.getReserveData(key).borrowed;
        uint256 suppliedAfter = office.getReserveData(key).supplied;
        uint256 usdcLentSharesAfter = office.balanceOf(account, usdcKey.toLentId());

        assertEq(assetsRepaid, expectedAssetsRepaid, "Assets repaid should match expected amount");

        // It should burn correct amount of debt shares of the account.
        assertEq(debtSharesAfter, debtSharesBefore - debtSharesToRepay, "Half of debt shares should be burned");

        // It should decrease the borrowed assets amount.
        assertEq(
            borrowedAfter,
            usdcReserveDataBefore.borrowed - expectedAssetsRepaid,
            "Borrowed assets should decrease by repaid amount"
        );

        // It should decrease the supplied assets amount.
        assertEq(
            suppliedAfter,
            suppliedAssetsBefore - expectedAssetsRepaid,
            "Supplied assets should decrease by repaid amount"
        );

        // It should decrease lent shares of the account.
        assertEq(
            usdcLentSharesBefore - usdcLentSharesAfter,
            expectedLentSharesConsumed,
            "Lent shares consumed should match expected amount"
        );
    }

    // Test case 12: When repaying the debt via collateral - Given collateral is invalid type
    function test_Revert_WhenRepayingTheDebtViaCollateral_GivenCollateralIsInvalidType()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        uint256 debtSharesBefore = office.balanceOf(account, key.toDebtId());

        RepayParams memory params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType.DEBT, // Using DEBT type as invalid collateral type
            assets: 0,
            shares: debtSharesBefore / 2, // Repay half of debt
            extraData: ""
        });

        // It should revert.
        //     With `Office__InvalidCollateralType` error.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__InvalidCollateralType.selector, TokenType.DEBT));
        office.repay(params);
    }

    // Test case 13: When repaying the debt using max uint256 shares as input
    function test_WhenRepayingTheDebtUsingMaxUint256SharesAsInput()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        uint256 reserveSuppliedBefore = office.getReserveData(key).supplied;
        uint256 borrowedBefore = office.getReserveData(key).borrowed;
        uint256 callerBalanceBefore = usdc.balanceOf(caller);

        RepayParams memory params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType(0),
            assets: 0,
            shares: type(uint256).max,
            extraData: ""
        });

        uint256 assetsRepaid = office.repay(params);

        // It should repay the entire debt of the account.
        assertEq(
            office.getReserveData(key).borrowed,
            borrowedBefore - assetsRepaid,
            "Borrowed should reduce by repaid amount"
        );
        assertEq(office.getReserveData(key).borrowed, 0, "Debt should be fully repaid");

        // It should burn all debt shares of the account.
        assertEq(office.balanceOf(account, key.toDebtId()), 0, "Debt shares should be fully burned");

        // It should not modify the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, reserveSuppliedBefore, "Supplied assets should remain unchanged");

        // Caller balance should decrease by exactly assetsRepaid.
        assertEq(usdc.balanceOf(caller), callerBalanceBefore - assetsRepaid, "Caller balance mismatch");
    }

    // Test case 14: When repaying the debt using max uint256 assets as input
    function test_WhenRepayingTheDebtUsingMaxUint256AssetsAsInput()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        uint256 reserveSuppliedBefore = office.getReserveData(key).supplied;
        uint256 borrowedBefore = office.getReserveData(key).borrowed;
        uint256 callerBalanceBefore = usdc.balanceOf(caller);

        RepayParams memory params = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType(0),
            assets: type(uint256).max,
            shares: 0,
            extraData: ""
        });

        uint256 assetsRepaid = office.repay(params);

        // It should repay the entire debt of the account.
        assertEq(office.getReserveData(key).borrowed, 0, "Debt should be fully repaid");

        // It should burn all debt shares of the account.
        assertEq(office.balanceOf(account, key.toDebtId()), 0, "Debt shares should be burned");

        // It should decrease the borrowed assets amount.
        assertLt(office.getReserveData(key).borrowed, borrowedBefore, "Borrowed assets should decrease");

        // It should not modify the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, reserveSuppliedBefore, "Supplied assets should remain unchanged");

        // It should only transfer the exact amount needed to repay the debt.
        assertEq(
            usdc.balanceOf(caller),
            callerBalanceBefore - assetsRepaid,
            "Caller balance should decrease by exact repaid amount"
        );
        assertEq(assetsRepaid, borrowedBefore, "Should only transfer borrowed amount, not entire max uint256");
    }

    // Test case 15: When both assets and shares are provided
    function test_Revert_WhenRepayingTheDebt_WhenBothAssetsAndSharesAreProvided()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        RepayParams memory params = RepayParams({
            key: key, account: account, withCollateralType: TokenType(0), assets: 100e6, shares: 1, extraData: ""
        });

        // It should revert.
        //     With `IOffice.Office__AssetsAndSharesNonZero` error.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AssetsAndSharesNonZero.selector, 100e6, 1));
        office.repay(params);
    }

    // Test case 17: When repaying dust amount of debt
    // This test replicates the vulnerability from https://github.com/sherlock-audit/2025-12-dhedge-dytm-dec-18th/issues/47
    // where assetsRepaid can exceed borrowed due to rounding up in toAssetsUp calculation,
    // potentially causing an underflow without saturatingSub protection.
    function test_WhenRepayingDustAmountOfDebt()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        uint256 reserveSuppliedBefore = office.getReserveData(key).supplied;
        uint256 debtSharesBefore = office.balanceOf(account, key.toDebtId());

        // Step 1: Repay the loan such that only 1 debt share remains
        RepayParams memory paramsFirstRepay = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType(0),
            assets: 0,
            shares: debtSharesBefore - 1, // Repay all but 1 share
            extraData: ""
        });

        office.repay(paramsFirstRepay);

        // Verify that exactly 1 debt share remains
        assertEq(office.balanceOf(account, key.toDebtId()), 1, "Exactly 1 debt share should remain");

        uint256 borrowedAfterFirstRepay = office.getReserveData(key).borrowed;

        assertEq(borrowedAfterFirstRepay, 0, "Borrowed amount should be 0 as calculated manually");

        // Step 2: Try repaying the remaining debt share in another transaction
        // This is where the vulnerability manifests: toAssetsUp can round up to exceed borrowed amount
        RepayParams memory paramsDustRepay = RepayParams({
            key: key,
            account: account,
            withCollateralType: TokenType(0),
            assets: 0,
            shares: 1, // Repay the last remaining share
            extraData: ""
        });

        uint256 assetsRepaid = office.repay(paramsDustRepay);

        assertEq(assetsRepaid, 1, "Assets repaid should be 1 due to rounding up of obligation");

        // It should burn all debt shares of the account.
        assertEq(office.balanceOf(account, key.toDebtId()), 0, "All debt shares should be burned");

        // It should keep the borrowed assets amount at 0 after the dust repay.
        assertEq(office.getReserveData(key).borrowed, 0, "Borrowed assets should remain 0 after dust repay");

        // It should not modify the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, reserveSuppliedBefore, "Supplied assets should remain unchanged");
    }

    /////////////////////////////////////////////
    //             Encoding Helpers            //
    /////////////////////////////////////////////

    function encodeWithdraw(uint256 tokenId_, uint256 shares_) internal {
        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId_,
            account: account,
            receiver: address(delegatee), // Delegatee will receive the withdrawn assets
            assets: 0,
            shares: shares_,
            extraData: ""
        });

        batchCalls.push(
            Call({target: address(office), callData: abi.encodeWithSelector(IOffice.withdraw.selector, params)})
        );
    }

    function encodeRepay(ReserveKey key_, uint256 shares_) internal {
        RepayParams memory params = RepayParams({
            key: key_, account: account, withCollateralType: TokenType(0), assets: 0, shares: shares_, extraData: ""
        });

        batchCalls.push(
            Call({target: address(office), callData: abi.encodeWithSelector(IOffice.repay.selector, params)})
        );
    }
}

// Generated using co-pilot: GPT-4o
