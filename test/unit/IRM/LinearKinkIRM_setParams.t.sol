// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";
import "../../../src/IRM/LinearKinkIRM.sol";

contract LinearKinkIRM_setParams is CommonScenarios {
    using ReserveKeyLibrary for *;

    LinearKinkIRM internal linearKinkIRM;

    // Test parameters for LinearKinkIRM
    LinearKinkIRM.IRMParams internal testParams;

    function setUp() public override {
        super.setUp();

        linearKinkIRM = new LinearKinkIRM(office);

        // Set up test parameters
        testParams = LinearKinkIRM.IRMParams({
            baseRatePerSecond: getRatePerSecond(0.02e18), // 2% base rate
            slope1PerSecond: getRatePerSecond(0.05e18), // 5% slope1
            slope2PerSecond: getRatePerSecond(0.5e18), // 50% slope2
            optimalUtilization: 0.8e18 // 80% optimal utilization
        });
    }

    function test_WhenReserveDoesNotExist() external whenReserveIsNotSupported {
        vm.startPrank(admin);
        linearKinkIRM.setParams(key, testParams);

        // It should set the params correctly.
        (uint256 baseRate, uint256 slope1, uint256 slope2, uint256 optimalUtil) = linearKinkIRM.irmParams(key);
        assertEq(baseRate, testParams.baseRatePerSecond, "Base rate should be set correctly");
        assertEq(slope1, testParams.slope1PerSecond, "Slope1 should be set correctly");
        assertEq(slope2, testParams.slope2PerSecond, "Slope2 should be set correctly");
        assertEq(optimalUtil, testParams.optimalUtilization, "Optimal utilization should be set correctly");
    }

    function test_WhenReserveIsNotBorrowable() external whenReserveExists whenReserveIsNotBorrowable {
        vm.startPrank(admin);
        linearKinkIRM.setParams(key, testParams);

        // It should set the params correctly.
        (uint256 baseRate, uint256 slope1, uint256 slope2, uint256 optimalUtil) = linearKinkIRM.irmParams(key);
        assertEq(baseRate, testParams.baseRatePerSecond, "Base rate should be set correctly");
        assertEq(slope1, testParams.slope1PerSecond, "Slope1 should be set correctly");
        assertEq(slope2, testParams.slope2PerSecond, "Slope2 should be set correctly");
        assertEq(optimalUtil, testParams.optimalUtilization, "Optimal utilization should be set correctly");
    }

    function test_WhenReserveIsBorrowable() external whenReserveExists whenReserveIsBorrowable {
        vm.startPrank(admin);
        linearKinkIRM.setParams(key, testParams);

        // It should set the params correctly.
        (uint256 baseRate, uint256 slope1, uint256 slope2, uint256 optimalUtil) = linearKinkIRM.irmParams(key);
        assertEq(baseRate, testParams.baseRatePerSecond, "Base rate should be set correctly");
        assertEq(slope1, testParams.slope1PerSecond, "Slope1 should be set correctly");
        assertEq(slope2, testParams.slope2PerSecond, "Slope2 should be set correctly");
        assertEq(optimalUtil, testParams.optimalUtilization, "Optimal utilization should be set correctly");
    }
}
