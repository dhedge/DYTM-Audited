// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract FixedBorrowIRM_setRate is CommonScenarios {
    using ReserveKeyLibrary for *;

    uint256 ratePerSecond = getRatePerSecond(0.05e18); // 5% annual interest rate

    function test_whenReserveIsNotSupported() external whenReserveIsNotSupported {
        vm.startPrank(admin);
        irm.setRate(key, ratePerSecond);

        // It should set the rate correctly.
        assertEq(irm.borrowRateView(key), ratePerSecond, "Rate should be set correctly");
    }

    function test_WhenReserveIsNotBorrowable() external whenReserveExists whenReserveIsNotBorrowable {
        // It should set the rate correctly.

        vm.startPrank(admin);
        irm.setRate(key, ratePerSecond);

        // It should set the rate correctly.
        assertEq(irm.borrowRateView(key), ratePerSecond, "Rate should be set correctly");
    }

    function test_WhenReserveIsBorrowable() external whenReserveExists whenReserveIsBorrowable {
        vm.startPrank(admin);
        irm.setRate(key, ratePerSecond);

        // It should set the rate correctly.
        assertEq(irm.borrowRateView(key), ratePerSecond, "Rate should be set correctly");
    }
}
