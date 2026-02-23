// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";
import "../../../src/IRM/LinearKinkIRM.sol";

contract LinearKinkIRM_borrowRate is CommonScenarios {
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;
    using FixedPointMathLib for uint256;

    LinearKinkIRM internal linearKinkIRM;
    LinearKinkIRM.IRMParams internal testParams;

    // Test values for calculating expected rates
    uint256 internal constant OPTIMAL_UTILIZATION = 0.8e18; // 80%
    uint256 internal baseRatePerSecond;
    uint256 internal slope1PerSecond;
    uint256 internal slope2PerSecond;

    // Custom modifiers for different utilization scenarios
    modifier whenUtilizationIsAtOptimal() {
        // Set up exactly 80% utilization
        _setupUtilization(OPTIMAL_UTILIZATION); // 80% utilization
        _;
    }

    modifier whenUtilizationIsAboveOptimal() {
        // Set up 90% utilization (above 80% optimal)
        _setupUtilization(0.9e18); // 90% utilization
        _;
    }

    modifier whenUtilizationIsMaxedOut() {
        // Set up 100% utilization
        _setupUtilization(1e18); // 100% utilization
        _;
    }

    modifier whenUtilizationIsUnderOptimal() {
        // Set up 40% utilization (under 80% optimal)
        _setupUtilization(0.4e18); // 40% utilization
        _;
    }

    function setUp() public override {
        super.setUp();

        linearKinkIRM = new LinearKinkIRM(office);

        // Set up realistic test parameters
        baseRatePerSecond = getRatePerSecond(0.02e18); // 2% base rate
        slope1PerSecond = getRatePerSecond(0.05e18); // 5% slope1
        slope2PerSecond = getRatePerSecond(0.5e18); // 50% slope2

        testParams = LinearKinkIRM.IRMParams({
            baseRatePerSecond: baseRatePerSecond,
            slope1PerSecond: slope1PerSecond,
            slope2PerSecond: slope2PerSecond,
            optimalUtilization: OPTIMAL_UTILIZATION
        });
    }

    function test_WhenReserveIsNotSupported() external whenReserveIsNotSupported {
        // It should return 0.
        uint256 borrowRate = linearKinkIRM.borrowRateView(key);
        assertEq(borrowRate, 0, "Borrow rate should be 0 for unsupported reserve");
    }

    function test_WhenReserveIsNotBorrowable()
        external
        whenReserveExists
        whenReserveIsNotBorrowable
        whenCallerIsOfficer
    {
        vm.startPrank(caller);

        // Set up IRM parameters for WETH (non-borrowable)
        linearKinkIRM.setParams(key, testParams);

        // Verify utilization is 0 for non-borrowable asset (WETH)
        uint256 utilization = linearKinkIRM.getUtilization(key);
        assertEq(utilization, 0, "Utilization should be 0 for non-borrowable reserve");

        uint256 borrowRate = linearKinkIRM.borrowRateView(key);

        // With 0% utilization: baseRate + (0 * slope1) / optimalUtilization = baseRate
        uint256 expectedRate = baseRatePerSecond;

        assertEq(borrowRate, expectedRate, "Borrow rate should be base rate when utilization is 0");
    }

    function test_WhenUtilisationIsUnderOptimalUtilisation()
        external
        whenReserveExists
        whenReserveIsBorrowable
        whenLendingAsset(usdcKey)
        whenUtilizationIsUnderOptimal
        whenCallerIsOfficer
    {
        vm.startPrank(caller);

        // Set up IRM parameters
        linearKinkIRM.setParams(key, testParams);

        // It should return borrow rate below the kink.
        uint256 borrowRate = linearKinkIRM.borrowRateView(key);

        // Calculate expected rate: baseRate + (utilization * slope1) / optimalUtilization
        // With 40% utilization: baseRate + (0.4 * slope1) / 0.8 = baseRate + 0.5 * slope1
        uint256 expectedRate = baseRatePerSecond + slope1PerSecond.mulWadDown(0.5e18);

        assertEq(borrowRate, expectedRate, "Borrow rate should be below kink rate");
    }

    function test_WhenUtilisationIsAtOptimalUtilisation()
        external
        whenReserveExists
        whenReserveIsBorrowable
        whenLendingAsset(usdcKey)
        whenUtilizationIsAtOptimal
        whenCallerIsOfficer
    {
        vm.startPrank(caller);

        // Set up IRM parameters
        linearKinkIRM.setParams(key, testParams);

        // It should return borrow rate at the kink.
        uint256 borrowRate = linearKinkIRM.borrowRateView(key);

        // At optimal utilization: baseRate + slope1
        uint256 expectedRate = baseRatePerSecond + slope1PerSecond;

        assertEq(borrowRate, expectedRate, "Borrow rate should be at kink rate");
    }

    function test_WhenUtilisationIsAboveOptimalUtilisation()
        external
        whenReserveExists
        whenReserveIsBorrowable
        whenLendingAsset(usdcKey)
        whenUtilizationIsAboveOptimal
        whenCallerIsOfficer
    {
        vm.startPrank(caller);

        // Set up IRM parameters
        linearKinkIRM.setParams(key, testParams);

        // It should return borrow rate above the kink.
        uint256 borrowRate = linearKinkIRM.borrowRateView(key);

        // Calculate expected rate: baseRate + slope1 + ((utilization - optimal) * slope2) / (1 - optimal)
        // With 90% utilization: baseRate + slope1 + ((0.9 - 0.8) * slope2) / (1 - 0.8)
        // = baseRate + slope1 + (0.1 * slope2) / 0.2 = baseRate + slope1 + 0.5 * slope2
        uint256 expectedRate = baseRatePerSecond + slope1PerSecond + slope2PerSecond.mulWadDown(0.5e18);

        assertEq(borrowRate, expectedRate, "Borrow rate should be above kink rate");
    }

    function test_WhenUtilisationIsMaxedOut()
        external
        whenReserveExists
        whenReserveIsBorrowable
        whenLendingAsset(usdcKey)
        whenUtilizationIsMaxedOut
        whenCallerIsOfficer
    {
        vm.startPrank(caller);

        // Set up IRM parameters
        linearKinkIRM.setParams(key, testParams);

        // It should return max borrow rate.
        uint256 borrowRate = linearKinkIRM.borrowRateView(key);

        // At 100% utilization: baseRate + slope1 + slope2
        uint256 expectedMaxRate = baseRatePerSecond + slope1PerSecond + slope2PerSecond;

        assertEq(borrowRate, expectedMaxRate, "Borrow rate should be at maximum");
    }

    // Helper function to set up specific utilization levels
    function _setupUtilization(uint256 targetUtilization) private {
        uint256 suppliedAmount = 10_000e6; // 10,000 USDC supplied
        uint256 borrowedAmount = suppliedAmount.mulWadDown(targetUtilization);

        // Mock the supplied amount to create liquidity
        mockSupply(key, suppliedAmount);

        // Mock the borrowed amount to achieve target utilization
        mockBorrow(key, borrowedAmount);
    }
}
