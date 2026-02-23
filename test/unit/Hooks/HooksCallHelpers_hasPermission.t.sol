// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract HooksCallHelpers_hasPermission is CommonScenarios {
    using HooksCallHelpers for IHooks;

    // Test case 1
    function test_GivenSupplyHooksEnabled_ItShouldReturnTrue() external pure {
        IHooks hooksWithSupplyEnabled =
            IHooks(address(uint160(address(NO_HOOKS_SET)) | Constants.BEFORE_SUPPLY_FLAG | Constants.AFTER_SUPPLY_FLAG));

        // It should return true
        assertTrue(hooksWithSupplyEnabled.hasPermission(Constants.BEFORE_SUPPLY_FLAG));
        assertTrue(hooksWithSupplyEnabled.hasPermission(Constants.AFTER_SUPPLY_FLAG));
    }

    // Test case 2
    function test_GivenSupplyHooksAreNotEnabled_ItShouldReturnFalse() external pure {
        IHooks hooksWithoutSupply = IHooks(
            address(uint160(address(ALL_HOOKS_SET)) ^ (Constants.BEFORE_SUPPLY_FLAG | Constants.AFTER_SUPPLY_FLAG))
        );

        // It should return false
        assertFalse(hooksWithoutSupply.hasPermission(Constants.BEFORE_SUPPLY_FLAG));
        assertFalse(hooksWithoutSupply.hasPermission(Constants.AFTER_SUPPLY_FLAG));
    }

    // Test case 3
    function test_GivenSwitchCollateralHooksEnabled_ItShouldReturnTrue() external pure {
        IHooks hooksWithSwitchCollateralEnabled = IHooks(
            address(
                uint160(address(NO_HOOKS_SET)) | Constants.BEFORE_SWITCH_COLLATERAL_FLAG
                    | Constants.AFTER_SWITCH_COLLATERAL_FLAG
            )
        );

        // It should return true
        assertTrue(hooksWithSwitchCollateralEnabled.hasPermission(Constants.BEFORE_SWITCH_COLLATERAL_FLAG));
        assertTrue(hooksWithSwitchCollateralEnabled.hasPermission(Constants.AFTER_SWITCH_COLLATERAL_FLAG));
    }

    // Test case 4
    function test_GivenSwitchCollateralHooksAreNotEnabled_ItShouldReturnFalse() external pure {
        IHooks hooksWithoutSwitchCollateral = IHooks(
            address(
                uint160(address(ALL_HOOKS_SET))
                    ^ (Constants.BEFORE_SWITCH_COLLATERAL_FLAG | Constants.AFTER_SWITCH_COLLATERAL_FLAG)
            )
        );

        // It should return false
        assertFalse(hooksWithoutSwitchCollateral.hasPermission(Constants.BEFORE_SWITCH_COLLATERAL_FLAG));
        assertFalse(hooksWithoutSwitchCollateral.hasPermission(Constants.AFTER_SWITCH_COLLATERAL_FLAG));
    }

    // Test case 5
    function test_GivenWithdrawCollateralHooksEnabled_ItShouldReturnTrue() external pure {
        IHooks hooksWithWithdrawEnabled = IHooks(
            address(uint160(address(NO_HOOKS_SET)) | Constants.BEFORE_WITHDRAW_FLAG | Constants.AFTER_WITHDRAW_FLAG)
        );

        // It should return true
        assertTrue(hooksWithWithdrawEnabled.hasPermission(Constants.BEFORE_WITHDRAW_FLAG));
        assertTrue(hooksWithWithdrawEnabled.hasPermission(Constants.AFTER_WITHDRAW_FLAG));
    }

    // Test case 6
    function test_GivenWithdrawCollateralHooksAreNotEnabled_ItShouldReturnFalse() external pure {
        IHooks hooksWithoutWithdraw = IHooks(
            address(uint160(address(ALL_HOOKS_SET)) ^ (Constants.BEFORE_WITHDRAW_FLAG | Constants.AFTER_WITHDRAW_FLAG))
        );

        // It should return false
        assertFalse(hooksWithoutWithdraw.hasPermission(Constants.BEFORE_WITHDRAW_FLAG));
        assertFalse(hooksWithoutWithdraw.hasPermission(Constants.AFTER_WITHDRAW_FLAG));
    }

    // Test case 7
    function test_GivenBorrowHooksEnabled_ItShouldReturnTrue() external pure {
        IHooks hooksWithBorrowEnabled =
            IHooks(address(uint160(address(NO_HOOKS_SET)) | Constants.BEFORE_BORROW_FLAG | Constants.AFTER_BORROW_FLAG));

        // It should return true
        assertTrue(hooksWithBorrowEnabled.hasPermission(Constants.BEFORE_BORROW_FLAG));
        assertTrue(hooksWithBorrowEnabled.hasPermission(Constants.AFTER_BORROW_FLAG));
    }

    // Test case 8
    function test_GivenBorrowHooksAreNotEnabled_ItShouldReturnFalse() external pure {
        IHooks hooksWithoutBorrow = IHooks(
            address(uint160(address(ALL_HOOKS_SET)) ^ (Constants.BEFORE_BORROW_FLAG | Constants.AFTER_BORROW_FLAG))
        );

        // It should return false
        assertFalse(hooksWithoutBorrow.hasPermission(Constants.BEFORE_BORROW_FLAG));
        assertFalse(hooksWithoutBorrow.hasPermission(Constants.AFTER_BORROW_FLAG));
    }

    // Test case 9
    function test_GivenRepayHooksEnabled_ItShouldReturnTrue() external pure {
        IHooks hooksWithRepayEnabled =
            IHooks(address(uint160(address(NO_HOOKS_SET)) | Constants.BEFORE_REPAY_FLAG | Constants.AFTER_REPAY_FLAG));

        // It should return true
        assertTrue(hooksWithRepayEnabled.hasPermission(Constants.BEFORE_REPAY_FLAG));
        assertTrue(hooksWithRepayEnabled.hasPermission(Constants.AFTER_REPAY_FLAG));
    }

    // Test case 10
    function test_GivenRepayHooksAreNotEnabled_ItShouldReturnFalse() external pure {
        IHooks hooksWithoutRepay = IHooks(
            address(uint160(address(ALL_HOOKS_SET)) ^ (Constants.BEFORE_REPAY_FLAG | Constants.AFTER_REPAY_FLAG))
        );

        // It should return false
        assertFalse(hooksWithoutRepay.hasPermission(Constants.BEFORE_REPAY_FLAG));
        assertFalse(hooksWithoutRepay.hasPermission(Constants.AFTER_REPAY_FLAG));
    }

    // Test case 11
    function test_GivenLiquidateHooksEnabled_ItShouldReturnTrue() external pure {
        IHooks hooksWithLiquidateEnabled = IHooks(
            address(uint160(address(NO_HOOKS_SET)) | Constants.BEFORE_LIQUIDATE_FLAG | Constants.AFTER_LIQUIDATE_FLAG)
        );

        // It should return true
        assertTrue(hooksWithLiquidateEnabled.hasPermission(Constants.BEFORE_LIQUIDATE_FLAG));
        assertTrue(hooksWithLiquidateEnabled.hasPermission(Constants.AFTER_LIQUIDATE_FLAG));
    }

    // Test case 12
    function test_GivenLiquidateHooksAreNotEnabled_ItShouldReturnFalse() external pure {
        IHooks hooksWithoutLiquidate = IHooks(
            address(
                uint160(address(ALL_HOOKS_SET)) ^ (Constants.BEFORE_LIQUIDATE_FLAG | Constants.AFTER_LIQUIDATE_FLAG)
            )
        );

        // It should return false
        assertFalse(hooksWithoutLiquidate.hasPermission(Constants.BEFORE_LIQUIDATE_FLAG));
        assertFalse(hooksWithoutLiquidate.hasPermission(Constants.AFTER_LIQUIDATE_FLAG));
    }

    // Test case 13
    function test_GivenMigrateSupplyHooksEnabled_ItShouldReturnTrue() external pure {
        IHooks hooksWithMigrateSupplyEnabled = IHooks(
            address(
                uint160(address(NO_HOOKS_SET)) | Constants.BEFORE_MIGRATE_SUPPLY_FLAG
                    | Constants.AFTER_MIGRATE_SUPPLY_FLAG
            )
        );

        // It should return true
        assertTrue(hooksWithMigrateSupplyEnabled.hasPermission(Constants.BEFORE_MIGRATE_SUPPLY_FLAG));
        assertTrue(hooksWithMigrateSupplyEnabled.hasPermission(Constants.AFTER_MIGRATE_SUPPLY_FLAG));
    }

    // Test case 14
    function test_GivenMigrateSupplyHooksAreNotEnabled_ItShouldReturnFalse() external pure {
        IHooks hooksWithoutMigrateSupply = IHooks(
            address(
                uint160(address(ALL_HOOKS_SET))
                    ^ (Constants.BEFORE_MIGRATE_SUPPLY_FLAG | Constants.AFTER_MIGRATE_SUPPLY_FLAG)
            )
        );

        // It should return false
        assertFalse(hooksWithoutMigrateSupply.hasPermission(Constants.BEFORE_MIGRATE_SUPPLY_FLAG));
        assertFalse(hooksWithoutMigrateSupply.hasPermission(Constants.AFTER_MIGRATE_SUPPLY_FLAG));
    }
}

// Generated using co-pilot: Claude Sonnet 4
