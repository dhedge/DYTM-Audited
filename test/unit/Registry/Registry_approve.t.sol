// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Registry_approve is CommonScenarios {
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;

    address internal _spender = makeAddr("spender");
    uint256 internal _approvalAmount = 1000e6; // 1000 USDC

    // Test case 1
    function test_WhenCallerIsOwnerForNonIsolatedAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // It should approve the other address to spend tokens.
        bool success = office.approve(_spender, tokenId, _approvalAmount);

        // Verify approval was successful
        assertTrue(success, "Approval should succeed");
        assertEq(office.allowance(caller, _spender, tokenId), _approvalAmount, "Allowance should be set correctly");
    }

    // Test case 2
    function test_WhenCallerIsOwnerForIsolatedAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // It should approve the other address to spend tokens.
        bool success = office.approve(_spender, tokenId, _approvalAmount);

        // Verify approval was successful
        assertTrue(success, "Approval should succeed");
        assertEq(office.allowance(caller, _spender, tokenId), _approvalAmount, "Allowance should be set correctly");
    }

    // Test case 3
    function test_WhenApprovingLendingAndEscrowTokens()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
    {
        vm.startPrank(caller);

        // It should approve the other address to spend tokens for lending and escrow tokens.
        uint256 lendingTokenId = usdcKey.toLentId();
        bool lendingSuccess = office.approve(_spender, lendingTokenId, _approvalAmount);

        uint256 escrowTokenId = usdcKey.toEscrowId();
        bool escrowSuccess = office.approve(_spender, escrowTokenId, _approvalAmount);

        uint256 debtTokenId = usdcKey.toDebtId();
        bool debtSuccess = office.approve(_spender, debtTokenId, _approvalAmount);

        // Verify all approvals were successful
        assertTrue(lendingSuccess, "Lending token approval should succeed");
        assertTrue(escrowSuccess, "Escrow token approval should succeed");
        assertTrue(debtSuccess, "Debt token approval should succeed");

        // Verify all allowances are set correctly
        assertEq(
            office.allowance(caller, _spender, lendingTokenId),
            _approvalAmount,
            "Lending token allowance should be set correctly"
        );
        assertEq(
            office.allowance(caller, _spender, escrowTokenId),
            _approvalAmount,
            "Escrow token allowance should be set correctly"
        );
        assertEq(
            office.allowance(caller, _spender, debtTokenId),
            _approvalAmount,
            "Debt token allowance should be set correctly"
        );
    }

    // Test case 4
    function test_WhenApprovingZeroAmount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // First approve some amount
        office.approve(_spender, tokenId, _approvalAmount);

        // It should allow the approval transaction.
        bool success = office.approve(_spender, tokenId, 0);

        // Verify approval was successful and allowance is zero
        assertTrue(success, "Zero approval should succeed");
        assertEq(office.allowance(caller, _spender, tokenId), 0, "Allowance should be set to zero");
    }

    // Test case 5
    function test_WhenCallerIsOperatorForIsolatedAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        AccountId spenderAccount = _spender.toUserAccount();

        // It should approve the other address to spend tokens.
        bool success = office.approve(account, spenderAccount, tokenId, _approvalAmount);

        // Verify approval was successful
        assertTrue(success, "Approval should succeed");

        // It shouldn't change the allowance amount returned by `allowance` for the owner.
        assertEq(
            office.allowance(office.ownerOf(account), account, spenderAccount, tokenId),
            0,
            "Allowance should remain 0 for account owner"
        );
    }

    // Test case 6
    function test_WhenCallerIsUnauthorizedForIsolatedAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsNotAuthorized
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        AccountId spenderAccount = _spender.toUserAccount();

        // It should approve the other address to spend tokens.
        bool success = office.approve(account, spenderAccount, tokenId, _approvalAmount);

        // Verify approval was successful
        assertTrue(success, "Approval should succeed");

        // It shouldn't change the allowance amount returned by `allowance` for the owner.
        assertEq(
            office.allowance(office.ownerOf(account), account, spenderAccount, tokenId),
            0,
            "Allowance should remain 0 for account owner"
        );
    }

    // Test case 7
    function test_RevertWhenSpenderIsIsolatedAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        AccountId spenderIsolatedAccount = office.createIsolatedAccount(caller);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.Registry__InvalidSpender.selector, spenderIsolatedAccount));
        office.approve(account, spenderIsolatedAccount, tokenId, _approvalAmount);
    }

    // Test case 8
    function test_WhenReserveDoesNotExist()
        external
        whenReserveIsNotSupported
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
    {
        vm.startPrank(caller);

        // It should approve the other address to spend tokens.
        bool success = office.approve(_spender, tokenId, _approvalAmount);

        // Verify approval was successful
        assertTrue(success, "Approval should succeed even for non-existent reserve");
        assertEq(office.allowance(caller, _spender, tokenId), _approvalAmount, "Allowance should be set correctly");
    }
}

// Generated using co-pilot: Claude Sonnet 4.5
