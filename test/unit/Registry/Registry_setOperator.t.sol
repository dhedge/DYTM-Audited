// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Registry_setOperator is CommonScenarios {
    using AccountIdLibrary for *;

    address internal _spender = makeAddr("spender");
    address internal _newOwner = makeAddr("newOwner");

    // Test case 1
    function test_WhenCallerIsOwner_GivenSpenderIsNotZeroAddress_ItShouldSetTheOperatorForTheAccount()
        external
        givenAccountIsNotIsolated
        whenCallerIsOwner
    {
        vm.startPrank(caller);

        // It should set the operator for the account
        bool success = office.setOperator(_spender, account, true);

        // Verify operation was successful
        assertTrue(success, "setOperator should succeed");
        assertTrue(office.isOperator(account, _spender), "Spender should be set as operator");
    }

    // Test case 2
    function test_Revert_WhenCallerIsOwner_GivenSpenderIsZeroAddress()
        external
        givenAccountIsNotIsolated
        whenCallerIsOwner
    {
        vm.startPrank(caller);

        // It should revert with Registry__ZeroAddress error
        vm.expectRevert(IRegistry.Registry__ZeroAddress.selector);
        office.setOperator(address(0), account, true);
    }

    // Test case 3
    function test_GivenAccountIsIsolated_GivenSpenderIsNotZeroAddress_ItShouldSetTheOperatorForTheAccount()
        external
        givenAccountIsIsolated
        whenCallerIsOwner
    {
        vm.startPrank(caller);

        // It should set the operator for the account
        bool success = office.setOperator(_spender, account, true);

        // Verify operation was successful
        assertTrue(success, "setOperator should succeed");
        assertTrue(office.isOperator(account, _spender), "Spender should be set as operator");
    }

    // Test case 4
    function test_Revert_GivenAccountIsIsolated_GivenSpenderIsZeroAddress()
        external
        givenAccountIsIsolated
        whenCallerIsOwner
    {
        vm.startPrank(caller);

        // It should revert with Registry__ZeroAddress error
        vm.expectRevert(IRegistry.Registry__ZeroAddress.selector);
        office.setOperator(address(0), account, true);
    }

    // Test case 5
    function test_WhenAccountIsTransferredToANewOwner_ItShouldDenyPermissionsToPreviouslySetOperator()
        external
        givenAccountIsIsolated
        whenCallerIsOwner
    {
        vm.startPrank(caller);

        // Set operator first
        office.setOperator(_spender, account, true);
        assertTrue(office.isOperator(account, _spender), "Operator should be set initially");

        // Transfer account to new owner
        office.transferFrom(caller, _newOwner, AccountId.unwrap(account), 1);

        // It should deny permissions to the previously set operator
        assertFalse(office.isOperator(account, _spender), "Previously set operator should be denied permissions");
    }

    // Test case 6
    function test_WhenAccountIsTransferredBackToPreviousOwner_ItShouldRestorePermissionsToPreviouslySetOperator()
        external
        givenAccountIsIsolated
        whenCallerIsOwner
    {
        address originalOwner = caller;

        vm.startPrank(caller);

        // Set operator first
        office.setOperator(_spender, account, true);
        assertTrue(office.isOperator(account, _spender), "Operator should be set initially");

        // Transfer account to new owner
        office.transferFrom(caller, _newOwner, AccountId.unwrap(account), 1);
        assertFalse(office.isOperator(account, _spender), "Operator should be denied after transfer");

        vm.startPrank(_newOwner);

        // Transfer account back to previous owner
        office.transferFrom(_newOwner, originalOwner, AccountId.unwrap(account), 1);

        // It should restore permissions to the previously set operator
        assertTrue(office.isOperator(account, _spender), "Previously set operator should have permissions restored");
    }

    // Test case 7
    function test_WhenUnsettingOperator_GivenAccountIsNotIsolated_ItShouldUnsetTheOperatorForTheAccount()
        external
        givenAccountIsNotIsolated
        whenCallerIsOwner
    {
        vm.startPrank(caller);

        // First set the operator
        office.setOperator(_spender, account, true);
        assertTrue(office.isOperator(account, _spender), "Operator should be set initially");

        // It should unset the operator for the account
        bool success = office.setOperator(_spender, account, false);

        // Verify operation was successful
        assertTrue(success, "setOperator should succeed");
        assertFalse(office.isOperator(account, _spender), "Operator should be unset");
    }

    // Test case 8
    function test_WhenUnsettingOperator_GivenAccountIsIsolated_ItShouldUnsetTheOperatorForTheAccount()
        external
        givenAccountIsIsolated
        whenCallerIsOwner
    {
        vm.startPrank(caller);

        // First set the operator
        office.setOperator(_spender, account, true);
        assertTrue(office.isOperator(account, _spender), "Operator should be set initially");

        // It should unset the operator for the account
        bool success = office.setOperator(_spender, account, false);

        // Verify operation was successful
        assertTrue(success, "setOperator should succeed");
        assertFalse(office.isOperator(account, _spender), "Operator should be unset");
    }

    // Test case 9
    function test_WhenCallerIsNotOwner_GivenAccountIsNotIsolated_GivenSpenderIsNotZeroAddress_ItShouldSetTheOperatorForTheAccount()
        external
        givenAccountIsNotIsolated
        whenCallerIsNotAuthorized
    {
        vm.startPrank(caller);

        // It should set the operator for the account
        bool success = office.setOperator(_spender, account, true);

        // Verify operation was successful
        assertTrue(success, "setOperator should succeed");
        assertTrue(office.isOperator(caller, account, _spender), "Spender should be set as operator");

        // The `isOperator(account,operator)` should still return false for non-owners.
        assertFalse(office.isOperator(account, _spender), "Should return false for non-owners");
    }

    // Test case 10
    function test_WhenCallerIsNotOwner_GivenAccountIsIsolated_GivenSpenderIsNotZeroAddress_ItShouldSetTheOperatorForTheAccount()
        external
        givenAccountIsIsolated
        whenCallerIsNotAuthorized
    {
        vm.startPrank(caller);

        // It should set the operator for the account
        bool success = office.setOperator(_spender, account, true);

        // Verify operation was successful
        assertTrue(success, "setOperator should succeed");
        assertTrue(office.isOperator(caller, account, _spender), "Spender should be set as operator");

        // The `isOperator(account,operator)` should still return false for non-owners.
        assertFalse(office.isOperator(account, _spender), "Should return false for non-owners");
    }
}

// Generated using co-pilot: Claude Haiku 4.5
