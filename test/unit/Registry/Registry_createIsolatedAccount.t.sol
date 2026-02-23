// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "../../shared/CommonScenarios.sol";

contract RegistryCreateIsolatedAccountTest is CommonScenarios {
    // Modifier to simulate condition where account is the first account
    modifier givenAccountIsFirst() {
        // This test will create the first account
        _;
    }

    // Test case 1
    function test_WhenCallerIsOwner_GivenAddressIsOwnerAddress_GivenAccountIsTheFirstAccount()
        public
        givenAccountIsFirst
    {
        vm.startPrank(admin);

        AccountId isolatedAccount = office.createIsolatedAccount(admin);

        // It should create an isolated account.
        assertTrue(AccountId.unwrap(isolatedAccount) != 0, "Isolated account should be created");

        // It should mint the account token to the admin address.
        assertEq(office.ownerOf(isolatedAccount), admin, "Account token should be minted to admin");
    }

    // Test case 2
    function test_WhenCallerIsOwner_GivenAddressIsOwnerAddress_GivenAccountIsNotTheFirstAccount() public {
        // Create a first account to ensure this is not the first account
        vm.startPrank(admin);
        AccountId firstAccount = office.createIsolatedAccount(admin);
        AccountId secondAccount = office.createIsolatedAccount(admin);

        // It should create the first account.
        assertTrue(AccountId.unwrap(firstAccount) != 0, "First account should be created");

        // It should create an isolated account.
        assertTrue(AccountId.unwrap(secondAccount) > AccountId.unwrap(firstAccount), "Second account should be created");

        // It should mint the account token to the admin address.
        assertEq(office.ownerOf(secondAccount), admin, "Account token should be minted to admin");
    }

    // Test case 3
    function test_Revert_WhenCallerIsOwner_GivenAddressIsZeroAddress() public {
        vm.startPrank(admin);

        // It should revert with Registry__ZeroAddress error.
        vm.expectRevert("Registry__ZeroAddress()");
        office.createIsolatedAccount(address(0));
    }

    // Test case 4
    function test_WhenCallerIsNotOwner_GivenAddressIsNotZeroAddress() public {
        vm.startPrank(alice);

        address owner = bob;

        AccountId isolatedAccount = office.createIsolatedAccount(owner);

        // It should create an isolated account.
        assertTrue(AccountId.unwrap(isolatedAccount) != 0, "Isolated account should be created");

        // It should mint the account token to the given address.
        assertEq(office.ownerOf(isolatedAccount), owner, "Account token should be minted to given address");
    }
}

// Generated using co-pilot: Claude 4 Sonnet
