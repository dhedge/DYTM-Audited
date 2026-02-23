// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Office_donateToReserve is CommonScenarios {
    using TokenHelpers for *;
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;
    using SharesMathLib for uint256;
    using FixedPointMathLib for uint256;

    uint256 internal _donationAmount;

    modifier givenReserveIsEmpty() {
        // Reserve is empty by default, no need to do anything
        _;
    }

    modifier givenDonationAmount() {
        _donationAmount = 500e6; // 500 USDC
        _;
    }

    function test_WhenReserveExists_GivenReserveIsNotEmpty()
        external
        whenReserveExists
        whenCallerIsOfficer
        givenEnoughLiquidityInTheReserve
        givenDonationAmount
    {
        vm.startPrank(caller);

        OfficeStorage.ReserveData memory reserveDataBefore = office.getReserveData(key);
        uint256 callerBalanceBefore = usdc.balanceOf(caller);

        // Calculate share price before donation.
        uint256 totalSharesBefore = office.totalSupply(key.toLentId());
        uint256 expectedSharePriceAfter =
            WAD.toAssetsDown(reserveDataBefore.supplied + _donationAmount, totalSharesBefore);

        office.donateToReserve(key, _donationAmount);

        OfficeStorage.ReserveData memory reserveDataAfter = office.getReserveData(key);
        uint256 callerBalanceAfter = usdc.balanceOf(caller);

        // It should increase the supplied amount of the reserve.
        assertEq(
            reserveDataAfter.supplied,
            reserveDataBefore.supplied + _donationAmount,
            "Supplied amount should increase by donation amount"
        );

        // It should decrease the caller's balance by the donation amount.
        assertEq(
            callerBalanceAfter,
            callerBalanceBefore - _donationAmount,
            "Caller balance should decrease by donation amount"
        );

        // It should increase the share price of the reserve.
        assertEq(
            WAD.toAssetsDown(reserveDataAfter.supplied, totalSharesBefore),
            expectedSharePriceAfter,
            "Share price should increase by donation amount"
        );
    }

    function test_RevertWhen_ReserveExists_GivenReserveIsEmpty()
        external
        whenReserveExists
        whenCallerIsOfficer
        givenReserveIsEmpty
        givenDonationAmount
    {
        // It should revert.
        //     With `Office__ReserveIsEmpty`.

        vm.startPrank(caller);

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__ReserveIsEmpty.selector, key));
        office.donateToReserve(key, _donationAmount);

        vm.stopPrank();
    }

    function test_WhenReserveIsNotSupported_GivenReserveIsNotEmpty()
        external
        whenReserveExists
        givenEnoughLiquidityInTheReserve
        whenCallerIsOfficer
        givenDonationAmount
    {
        vm.startPrank(caller);

        // Remove the asset represented by the key as the supported asset in the market config.
        IERC20 asset = key.getAsset();
        address[] memory removeAssets = new address[](1);
        removeAssets[0] = address(asset);
        marketConfig.removeSupportedAssets(removeAssets);

        OfficeStorage.ReserveData memory reserveDataBefore = office.getReserveData(key);
        uint256 callerBalanceBefore = asset.balanceOf(caller);

        office.donateToReserve(key, _donationAmount);

        OfficeStorage.ReserveData memory reserveDataAfter = office.getReserveData(key);
        uint256 callerBalanceAfter = asset.balanceOf(caller);

        // It should increase the supplied amount of the reserve.
        assertEq(
            reserveDataAfter.supplied,
            reserveDataBefore.supplied + _donationAmount,
            "Supplied amount should increase by donation amount"
        );

        // It should decrease the caller's balance by the donation amount.
        assertEq(
            callerBalanceAfter,
            callerBalanceBefore - _donationAmount,
            "Caller balance should decrease by donation amount"
        );
    }

    function test_RevertWhen_ReserveIsNotSupported_GivenReserveIsEmpty()
        external
        whenReserveIsNotSupported
        whenCallerIsOfficer
        givenReserveIsEmpty
        givenDonationAmount
    {
        // It should revert.
        //     With `Office__ReserveIsEmpty`.

        vm.startPrank(caller);

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__ReserveIsEmpty.selector, key));
        office.donateToReserve(key, _donationAmount);

        vm.stopPrank();
    }

    function test_RevertWhen_ReserveIsNotSupported_GivenCallerIsNotAuthorized()
        external
        whenReserveIsNotSupported
        whenCallerIsNotAuthorized
        givenDonationAmount
    {
        // It should revert.
        //     With `OfficeStorage__NotOfficer`.

        vm.startPrank(caller);

        vm.expectRevert(
            abi.encodeWithSelector(OfficeStorage.OfficeStorage__NotOfficer.selector, key.getMarketId(), caller)
        );
        office.donateToReserve(key, _donationAmount);

        vm.stopPrank();
    }

    function test_WhenReserveExists_GivenReserveIsBorrowable_WhenTheAccountHasADebtPosition_GivenAccountHasBadDebt_GivenAccountIsLiquidated(
    )
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountHasBadDebt
    {
        vm.startPrank(caller);

        uint256 totalDebtAssets = office.balanceOf(account, key.toDebtId()).toAssetsUp(
            office.getReserveData(key).borrowed, office.totalSupply(key.toDebtId())
        );
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

        // Donation amount equals to the bad debt accrued.
        _donationAmount = totalDebtAssets - assetsRepaid;

        // Now test donation functionality
        vm.startPrank(admin);

        // Record state before donation
        OfficeStorage.ReserveData memory reserveDataBefore = office.getReserveData(key);

        // Calculate share value before donation (assets per share)
        uint256 shareValueBefore = WAD.toAssetsDown(reserveDataBefore.supplied, office.totalSupply(key.toLentId()));

        // Donate a significant amount relative to the reserve
        office.donateToReserve(key, _donationAmount);

        // Record state after donation
        OfficeStorage.ReserveData memory reserveDataAfter = office.getReserveData(key);

        // Calculate share value after donation
        uint256 shareValueAfter = WAD.toAssetsDown(reserveDataAfter.supplied, office.totalSupply(key.toLentId()));

        // It should increase the supplied amount of the reserve
        assertEq(
            reserveDataAfter.supplied,
            reserveDataBefore.supplied + _donationAmount,
            "Supplied amount should increase by donation amount"
        );

        assertGe(shareValueAfter, shareValueBefore, "Share value should be the same or increase after donation");
    }
}
