// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Office_accrueInterest is CommonScenarios {
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;
    using SharesMathLib for uint256;
    using FixedPointMathLib for uint256;

    uint256 supplied;
    uint256 borrowed;
    uint256 totalInterestAccrued;

    function setUp() public override {
        super.setUp();

        // Set the supplied and borrowed amounts for the USDC reserve.
        supplied = 10_000e6; // 10,000 USDC
        borrowed = 5000e6; // 5,000 USDC borrowed
        totalInterestAccrued = 0;
    }

    function test_whenReserveIsNotSupported() external whenReserveIsNotSupported {
        // It should return 0.
        //   Because the asset is not borrowable as it's not supported.
        assertEq(office.accrueInterest(key), 0, "Should return 0 interest accrued for non-existing reserve");
    }

    function test_WhenReserveIsNotBorrowEnabled() external whenReserveExists whenReserveIsNotBorrowable {
        // It should return 0.
        //   Because the asset is not borrowable.
        assertEq(office.accrueInterest(key), 0, "Should return 0 interest accrued for non-existing reserve");
    }

    function test_WhenUtilisationAndRateIsFixedAndPerformanceFeeIsNotSet()
        external
        whenReserveExists
        whenReserveIsBorrowable
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(alice);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: alice.toUserAccount(),
            assets: supplied, // 10,000 USDC
            extraData: bytes("")
        });

        office.supply(supplyParams);

        _mockBorrow(key, borrowed); // 50% utilisation.

        skip(SECONDS_IN_YEAR); // Skip 1 year.
        _accrueInterest(key);

        OfficeStorage.ReserveData memory reserveData = office.getReserveData(key);

        assertEq(totalInterestAccrued, 256_354_166, "Incorrect interest accrued");

        // It should verify that interest paid by borrowers matches the interest earned by lenders.
        assertEq(reserveData.borrowed, borrowed, "Borrowed amount should include interest accrued");
        assertEq(reserveData.supplied, supplied, "Supplied amount should include interest accrued");
    }

    function test_WhenUtilisationIsFixedAndPerformanceFeeIsSet()
        external
        whenReserveExists
        whenPerformanceFeeSet
        whenReserveIsBorrowable
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(alice);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: alice.toUserAccount(),
            assets: supplied, // 10,000 USDC
            extraData: bytes("")
        });

        office.supply(supplyParams);

        _mockBorrow(key, borrowed); // 50% utilisation.

        skip(SECONDS_IN_YEAR); // Skip 1 year.
        _accrueInterest(key);

        OfficeStorage.ReserveData memory reserveData = office.getReserveData(key);

        assertEq(totalInterestAccrued, 256_354_166, "Incorrect interest accrued");

        // It should verify that interest paid by borrowers matches the interest earned by lenders + performance fee.
        assertEq(reserveData.borrowed, borrowed, "Borrowed amount should include interest accrued");
        assertEq(reserveData.supplied, supplied, "Supplied amount should include interest accrued");
        assertApproxEqAbs(
            office.balanceOf(feeRecipient, tokenId).toAssetsDown(reserveData.supplied, office.totalSupply(tokenId)),
            51_270_833,
            1,
            "Performance fee shares should be approx worth 20% of interest accrued"
        );
    }

    function test_WhenUtilisationIsVariableAndRateIsFixedAndPerformanceFeeIsNotSet()
        external
        whenReserveExists
        whenReserveIsBorrowable
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(alice);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: alice.toUserAccount(),
            assets: supplied, // 10,000 USDC
            extraData: bytes("")
        });

        office.supply(supplyParams);

        _mockBorrow(key, borrowed); // 50% utilisation.

        skip(SECONDS_IN_YEAR); // Skip 1 year.
        _accrueInterest(key);

        _mockBorrow(key, borrowed + 1000e6); // Increase utilisation to 60%.

        skip(SECONDS_IN_YEAR); // Skip another year.
        _accrueInterest(key);

        OfficeStorage.ReserveData memory reserveData = office.getReserveData(key);

        assertEq(totalInterestAccrued, 577_122_657, "Incorrect total interest accrued");

        // It should verify that interest paid by borrowers matches the interest earned by lenders.
        assertEq(reserveData.borrowed, borrowed, "Borrowed amount should include total interest accrued");
        assertEq(reserveData.supplied, supplied, "Supplied amount should include total interest accrued");
    }

    function test_WhenUtilisationIsVariableAndRateIsFixedAndPerformanceFeeIsSet()
        external
        whenReserveExists
        whenReserveIsBorrowable
        whenPerformanceFeeSet
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(alice);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: alice.toUserAccount(),
            assets: supplied, // 10,000 USDC
            extraData: bytes("")
        });

        office.supply(supplyParams);

        _mockBorrow(key, borrowed); // 50% utilisation.

        skip(SECONDS_IN_YEAR); // Skip 1 year.
        _accrueInterest(key);

        _mockBorrow(key, borrowed + 1000e6); // Increase utilisation to 60%.

        skip(SECONDS_IN_YEAR); // Skip another year.
        _accrueInterest(key);

        OfficeStorage.ReserveData memory reserveData = office.getReserveData(key);

        assertEq(totalInterestAccrued, 577_122_657, "Incorrect total interest accrued");

        // It should verify that interest paid by borrowers matches the interest earned by lenders + performance fee.
        assertEq(reserveData.borrowed, borrowed, "Borrowed amount should include total interest accrued");
        assertEq(reserveData.supplied, supplied, "Supplied amount should include total interest accrued");

        // Note that the fee amount is not strictly 20% of the `totalInterestAccrued` (slightly higher) due to the fact
        // that the fee amount earned in each period is re-supplied to the reserve.
        assertApproxEqRel(
            office.balanceOf(feeRecipient, tokenId).toAssetsDown(reserveData.supplied, office.totalSupply(tokenId)),
            116_707_331,
            1.5e18, // 1.5% relative tolerance
            "Performance fee shares should be approx worth 20% of interest accrued"
        );
    }

    function test_WhenUtilisationIsVariableAndRateIsVariableAndPerformanceFeeIsNotSet()
        external
        whenReserveExists
        whenReserveIsBorrowable
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(alice);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: alice.toUserAccount(),
            assets: supplied, // 10,000 USDC
            extraData: bytes("")
        });

        office.supply(supplyParams);

        _mockBorrow(key, borrowed); // 50% utilisation.

        skip(SECONDS_IN_YEAR); // Skip 1 year.
        _accrueInterest(key);

        // Change the borrow rate to 10% per year.
        vm.startPrank(admin);
        irm.setRate(key, getRatePerSecond(0.1e18)); // 10% annual interest rate

        _mockBorrow(key, borrowed + 1000e6); // Increase utilisation to 60%.

        skip(SECONDS_IN_YEAR); // Skip another year.
        _accrueInterest(key);

        OfficeStorage.ReserveData memory reserveData = office.getReserveData(key);

        assertEq(totalInterestAccrued, 914_314_079, "Incorrect total interest accrued");

        // It should verify that interest paid by borrowers matches the interest earned by lenders.
        assertEq(reserveData.borrowed, borrowed, "Borrowed amount should include total interest accrued");
        assertEq(reserveData.supplied, supplied, "Supplied amount should include total interest accrued");
    }

    function test_WhenUtilisationIsVariableAndRateIsVariableAndPerformanceFeeIsSet()
        external
        whenReserveExists
        whenReserveIsBorrowable
        whenPerformanceFeeSet
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(alice);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: alice.toUserAccount(),
            assets: supplied, // 10,000 USDC
            extraData: bytes("")
        });

        office.supply(supplyParams);

        _mockBorrow(key, borrowed); // 50% utilisation.

        skip(SECONDS_IN_YEAR); // Skip 1 year.
        _accrueInterest(key);

        // Change the borrow rate to 10% per year.
        vm.startPrank(admin);
        irm.setRate(key, getRatePerSecond(0.1e18)); // 10% annual interest rate

        _mockBorrow(key, borrowed + 1000e6); // Increase utilisation to 60%.

        skip(SECONDS_IN_YEAR); // Skip another year.
        _accrueInterest(key);

        OfficeStorage.ReserveData memory reserveData = office.getReserveData(key);

        assertEq(totalInterestAccrued, 914_314_079, "Incorrect total interest accrued");

        // It should verify that interest paid by borrowers matches the interest earned by lenders.
        assertEq(reserveData.borrowed, borrowed, "Borrowed amount should include total interest accrued");
        assertEq(reserveData.supplied, supplied, "Supplied amount should include total interest accrued");

        // Note that the fee amount is not strictly 20% of the `totalInterestAccrued` (slightly higher) due to the fact
        // that
        // the fee amount earned in each period is re-supplied to the reserve.
        assertApproxEqRel(
            office.balanceOf(feeRecipient, tokenId).toAssetsDown(reserveData.supplied, office.totalSupply(tokenId)),
            186_033_198,
            1.5e18, // 1.5% relative tolerance
            "Performance fee shares should be approx worth 20% of interest accrued"
        );
    }

    function _mockBorrow(ReserveKey key_, uint256 amount_) private {
        borrowed = mockBorrow(key_, amount_);
    }

    function _accrueInterest(ReserveKey key_) private returns (uint256 interestAccrued) {
        // Call the `accrueInterest` function and return the interest accrued.
        interestAccrued = office.accrueInterest(key_);
        borrowed += interestAccrued;
        supplied += interestAccrued;
        totalInterestAccrued += interestAccrued;
    }
}
