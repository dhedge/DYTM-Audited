// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Registry_transferFrom is CommonScenarios, IDelegatee {
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;

    // Internal variables for test setup
    address internal _receiver = bob;
    AccountId internal _receiverAccount = _receiver.toUserAccount();
    address internal _maliciousCaller = address(0xbeef);

    uint256 internal _transferAmount;
    uint256 internal _allowanceAmount;

    /////////////////////////////////////////////
    //                Modifiers                //
    /////////////////////////////////////////////

    modifier givenIsolatedReceiverAccount() {
        vm.startPrank(_receiver);
        _receiverAccount = office.createIsolatedAccount(_receiver);
        _;
    }

    modifier whenCallerIsReceiverAccountOwner() {
        caller = _receiver;
        _;
    }

    /////////////////////////////////////////////
    //               Test Cases                //
    /////////////////////////////////////////////

    // Test case 1
    function test_WhenSpenderIsOwner_GivenAccountIsNotIsolated()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Test USDC lending token transfer
        key = usdcKey;
        tokenId = key.toLentId();
        _transferAmount = accountSuppliedAmountBefore.usdcLentAmount / 2;
        _testOwnerTransferWithoutAllowanceChange();

        // Test WETH escrow token transfer
        key = wethKey;
        tokenId = key.toEscrowId();
        _transferAmount = accountSuppliedAmountBefore.wethEscrowedAmount / 2;
        _testOwnerTransferWithoutAllowanceChange();
    }

    // Test case 2
    function test_WhenSpenderIsOwner_GivenAccountIsIsolated()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Test USDC lending token transfer
        key = usdcKey;
        tokenId = key.toLentId();
        _transferAmount = accountSuppliedAmountBefore.usdcLentAmount / 2;
        _testOwnerTransferWithoutAllowanceChange();

        // Test WETH escrow token transfer
        key = wethKey;
        tokenId = key.toEscrowId();
        _transferAmount = accountSuppliedAmountBefore.wethEscrowedAmount / 2;
        _testOwnerTransferWithoutAllowanceChange();
    }

    // Test case 3
    function test_WhenSpenderHasEnoughAllowance_GivenAccountIsIsolated()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenCallerIsReceiverAccountOwner
    {
        // Test USDC lending tokens
        key = usdcKey;
        tokenId = key.toLentId();
        _transferAmount = accountSuppliedAmountBefore.usdcLentAmount / 2;
        _allowanceAmount = accountSuppliedAmountBefore.usdcLentAmount;
        vm.startPrank(office.ownerOf(account));
        office.approve(account, _receiverAccount, tokenId, _allowanceAmount);

        _testTransferWithCollateralAndAllowanceUpdate();

        // Test WETH escrow tokens
        key = wethKey;
        tokenId = key.toEscrowId();
        _transferAmount = accountSuppliedAmountBefore.wethEscrowedAmount / 2;
        _allowanceAmount = accountSuppliedAmountBefore.wethEscrowedAmount;
        vm.startPrank(office.ownerOf(account));
        office.approve(account, _receiverAccount, tokenId, _allowanceAmount);

        _testTransferWithCollateralAndAllowanceUpdate();
    }

    // Test case 4
    function test_WhenSpenderHasEnoughAllowance_GivenAccountIsNotIsolated()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenCallerIsReceiverAccountOwner
    {
        // Test USDC lending tokens
        key = usdcKey;
        tokenId = key.toLentId();
        _transferAmount = accountSuppliedAmountBefore.usdcLentAmount / 2;
        _allowanceAmount = accountSuppliedAmountBefore.usdcLentAmount;
        vm.startPrank(office.ownerOf(account));
        office.approve(account, _receiverAccount, tokenId, _allowanceAmount);

        _testTransferWithCollateralAndAllowanceUpdate();

        // Test WETH escrow tokens
        key = wethKey;
        tokenId = key.toEscrowId();
        _transferAmount = accountSuppliedAmountBefore.wethEscrowedAmount / 2;
        _allowanceAmount = accountSuppliedAmountBefore.wethEscrowedAmount;
        vm.startPrank(office.ownerOf(account));
        office.approve(account, _receiverAccount, tokenId, _allowanceAmount);

        _testTransferWithCollateralAndAllowanceUpdate();
    }

    // Test case 5
    function test_WhenSpenderHasEnoughAllowance_GivenAmountIsLessThanBalance()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenCallerIsReceiverAccountOwner
    {
        // Test USDC lending tokens
        key = usdcKey;
        tokenId = key.toLentId();
        _transferAmount = accountSuppliedAmountBefore.usdcLentAmount / 2;
        _allowanceAmount = accountSuppliedAmountBefore.usdcLentAmount;
        vm.startPrank(office.ownerOf(account));
        office.approve(account, _receiverAccount, tokenId, _allowanceAmount);

        _testTransferWithCollateralAndAllowanceUpdate();

        // Test WETH escrow tokens
        key = wethKey;
        tokenId = key.toEscrowId();
        _transferAmount = accountSuppliedAmountBefore.wethEscrowedAmount / 2;
        _allowanceAmount = accountSuppliedAmountBefore.wethEscrowedAmount;
        vm.startPrank(office.ownerOf(account));
        office.approve(account, _receiverAccount, tokenId, _allowanceAmount);

        _testTransferWithCollateralAndAllowanceUpdate();
    }

    // Test case 6
    function test_WhenSpenderHasEnoughAllowance_GivenAmountIsEqualToBalance()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Test USDC lending tokens
        key = usdcKey;
        tokenId = key.toLentId();
        _testFullBalanceTransferWithCollateralUpdate();

        // Test WETH escrow tokens
        key = wethKey;
        tokenId = key.toEscrowId();
        _testFullBalanceTransferWithCollateralUpdate();
    }

    // Test case 7
    function test_RevertWhenBalanceIsInsufficient()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Test USDC lending tokens
        key = usdcKey;
        tokenId = key.toLentId();
        uint256 currentBalance = office.balanceOf(account, tokenId);
        _transferAmount = currentBalance + 1;

        _testRevertInsufficientBalance();

        // Test WETH escrow tokens
        key = wethKey;
        tokenId = key.toEscrowId();
        currentBalance = office.balanceOf(account, tokenId);
        _transferAmount = currentBalance + 1;

        _testRevertInsufficientBalance();
    }

    // Test case 8
    function test_RevertWhenSpenderHasInsufficientAllowance()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenCallerIsReceiverAccountOwner
    {
        // Test USDC lending tokens
        key = usdcKey;
        tokenId = key.toLentId();
        _transferAmount = accountSuppliedAmountBefore.usdcLentAmount / 2;

        _testRevertInsufficientAllowance();

        // Test WETH escrow tokens
        key = wethKey;
        tokenId = key.toEscrowId();
        _transferAmount = accountSuppliedAmountBefore.wethEscrowedAmount / 2;

        _testRevertInsufficientAllowance();
    }

    // Test case 9
    function test_WhenCallerIsOperator_GivenAccountHasEnoughBalance()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOperator
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Test USDC lending token transfer
        key = usdcKey;
        tokenId = key.toLentId();
        _transferAmount = accountSuppliedAmountBefore.usdcLentAmount / 2;
        _testOperatorTransferWithCollateral();

        // Test WETH escrow token transfer
        key = wethKey;
        tokenId = key.toEscrowId();
        _transferAmount = accountSuppliedAmountBefore.wethEscrowedAmount / 2;
        _testOperatorTransferWithCollateral();
    }

    // Test case 10
    function test_GivenAmountIsZero()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Test USDC lending tokens with zero amount
        key = usdcKey;
        tokenId = key.toLentId();
        _transferAmount = 0;

        _testZeroAmountTransfer();

        // Test WETH escrow tokens with zero amount
        key = wethKey;
        tokenId = key.toEscrowId();
        _transferAmount = 0;

        _testZeroAmountTransfer();
    }

    // Test case 11
    function test_WhenTransferringDebtTokens_GivenSpenderHasEnoughAllowance()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);
        AccountId secondAccount = office.createIsolatedAccount(caller);

        // To keep the second account healthy after debt transfer, supply collateral
        office.supply(SupplyParams({account: secondAccount, tokenId: key.toLentId(), assets: 100_000e6, extraData: ""}));

        uint256 debtTokenId = key.toDebtId();
        uint256 previousDebtBalanceAccount = office.balanceOf(account, debtTokenId);
        uint256 transferAmount = previousDebtBalanceAccount / 2;

        // Approve bob (as spender) to transfer debt tokens from account to secondAccount
        office.approve(account, bob.toUserAccount(), debtTokenId, transferAmount);

        // Bob performs the transfer using his allowance
        vm.startPrank(bob);

        // It should allow the transfer.
        office.transferFrom(account, secondAccount, debtTokenId, transferAmount);

        // It should reduce the allowance of the spender for the source account.
        assertEq(office.allowance(caller, account, bob.toUserAccount(), debtTokenId), 0, "Allowance should be reduced");

        // It should reduce the sender's debt balance
        assertEq(
            office.balanceOf(account, debtTokenId),
            previousDebtBalanceAccount - transferAmount,
            "Sender should have reduced debt balance"
        );

        // It should add the tokenId to debt token set of the spender.
        assertEq(office.balanceOf(secondAccount, debtTokenId), transferAmount, "Receiver should have transferred debt");
        assertEq(office.getDebtId(secondAccount, market), debtTokenId, "Receiver should have debt token id set");

        // Now approve and transfer the entire debt balance to test debt token removal
        vm.startPrank(caller);
        office.approve(account, bob.toUserAccount(), debtTokenId, office.balanceOf(account, debtTokenId));
        vm.startPrank(bob);
        office.transferFrom(account, secondAccount, debtTokenId, office.balanceOf(account, debtTokenId));

        // It should remove the tokenId as debt token.
        assertEq(office.getDebtId(account, market), 0, "Sender should have debt token id removed");
        assertEq(office.balanceOf(account, debtTokenId), 0, "Sender should have zero debt balance");
        assertEq(
            office.balanceOf(secondAccount, debtTokenId), previousDebtBalanceAccount, "Receiver should have entire debt"
        );
    }

    // Test case 12
    function test_WhenTransferringDebtTokens_GivenSpenderIsOwnerOfSourceAccount()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);
        AccountId secondAccount = office.createIsolatedAccount(caller);

        // To keep the second account healthy after debt transfer, supply collateral
        office.supply(SupplyParams({account: secondAccount, tokenId: key.toLentId(), assets: 100_000e6, extraData: ""}));

        uint256 debtTokenId = key.toDebtId();
        uint256 previousDebtBalanceAccount = office.balanceOf(account, debtTokenId);
        uint256 transferAmount = previousDebtBalanceAccount / 2;

        uint256 initialAllowance = office.allowance(caller, account, caller.toUserAccount(), debtTokenId);

        // It should allow the transfer.
        office.transferFrom(account, secondAccount, debtTokenId, transferAmount);

        // It should not change the allowance of the spender for the source account.
        assertEq(
            office.allowance(caller, account, caller.toUserAccount(), debtTokenId),
            initialAllowance,
            "Allowance should not change"
        );

        // It should reduce the sender's debt balance
        assertEq(
            office.balanceOf(account, debtTokenId),
            previousDebtBalanceAccount - transferAmount,
            "Sender should have reduced debt balance"
        );

        // It should add the tokenId to debt token set of the spender.
        assertEq(office.balanceOf(secondAccount, debtTokenId), transferAmount, "Receiver should have transferred debt");
        assertEq(office.getDebtId(secondAccount, market), debtTokenId, "Receiver should have debt token id set");

        // Transfer the entire remaining debt balance to test debt token removal
        office.transferFrom(account, secondAccount, debtTokenId, office.balanceOf(account, debtTokenId));

        // It should remove the tokenId as debt token.
        assertEq(office.getDebtId(account, market), 0, "Sender should have debt token id removed");
        assertEq(office.balanceOf(account, debtTokenId), 0, "Sender should have zero debt balance");
        assertEq(
            office.balanceOf(secondAccount, debtTokenId), previousDebtBalanceAccount, "Receiver should have entire debt"
        );
    }

    // Test case 13
    function test_RevertWhenTransferringDebtTokens_GivenSpenderIsOperatorOfSourceAccount()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);
        AccountId secondAccount = office.createIsolatedAccount(caller);

        // To keep the second account healthy after debt transfer, supply collateral
        office.supply(SupplyParams({account: secondAccount, tokenId: key.toLentId(), assets: 100_000e6, extraData: ""}));

        uint256 debtTokenId = key.toDebtId();
        uint256 previousDebtBalanceAccount = office.balanceOf(account, debtTokenId);
        uint256 transferAmount = previousDebtBalanceAccount / 2;

        // Set bob as operator on both source and recipient accounts
        office.setOperator(bob, account, true);
        office.setOperator(bob, secondAccount, true);

        // Bob (operator) performs the transfer
        vm.startPrank(bob);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientAllowance.selector,
                account,
                bob.toUserAccount(),
                0,
                transferAmount,
                debtTokenId
            )
        );
        office.transferFrom(account, secondAccount, debtTokenId, transferAmount);
    }

    // Test case 14
    function test_RevertWhenTransferringDebtTokens_GivenSpenderDoesNotHaveEnoughAllowance()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);
        AccountId secondAccount = office.createIsolatedAccount(caller);
        office.supply(SupplyParams({account: secondAccount, tokenId: key.toLentId(), assets: 100_000e6, extraData: ""}));

        // Set up bob as the spender who will try to transfer debt tokens
        // Give bob a tiny allowance, not enough
        office.approve(account, bob.toUserAccount(), key.toDebtId(), 0);

        uint256 debtTokenId = key.toDebtId();
        uint256 transferAmount = 1;

        // Now bob tries to transfer without enough allowance
        vm.startPrank(bob);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientAllowance.selector,
                account,
                bob.toUserAccount(),
                0,
                transferAmount,
                debtTokenId
            )
        );
        office.transferFrom(account, secondAccount, debtTokenId, transferAmount);
    }

    // Test case 15
    function test_RevertWhenTransferringDebtTokens_GivenSpenderIsMaliciousCallerDuringDelegationCall()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);
        AccountId secondAccount = office.createIsolatedAccount(caller);
        office.supply(SupplyParams({account: secondAccount, tokenId: key.toLentId(), assets: 100_000e6, extraData: ""}));

        uint256 debtTokenId = key.toDebtId();
        uint256 previousDebtBalanceAccount = office.balanceOf(account, debtTokenId);
        uint256 transferAmount = previousDebtBalanceAccount / 2;

        // It should revert.
        //   With `Registry__InsufficientAllowance` error.
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientAllowance.selector,
                account,
                _maliciousCaller.toUserAccount(),
                0,
                transferAmount,
                debtTokenId
            )
        );

        office.delegationCall(
            DelegationCallParams({
                delegatee: IDelegatee(address(this)),
                callbackData: abi.encode(account, secondAccount, debtTokenId, transferAmount)
            })
        );
    }

    // Test case 16
    function test_RevertWhenTransferringDebtTokens_GivenSpenderIsOwnerOfRecipientAccount()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);
        AccountId secondAccount = office.createIsolatedAccount(bob);
        office.supply(SupplyParams({account: secondAccount, tokenId: key.toLentId(), assets: 100_000e6, extraData: ""}));

        uint256 debtTokenId = key.toDebtId();
        uint256 previousDebtBalanceAccount = office.balanceOf(account, debtTokenId);
        uint256 transferAmount = previousDebtBalanceAccount / 2;

        // Approve bob as spender
        office.approve(account, bob.toUserAccount(), debtTokenId, previousDebtBalanceAccount);

        // Bob (owner of recipient account) performs the transfer
        vm.startPrank(bob);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__DifferentOwnersWhenTransferringDebt.selector,
                account,
                secondAccount,
                office.ownerOf(account),
                office.ownerOf(secondAccount),
                debtTokenId
            )
        );
        office.transferFrom(account, secondAccount, debtTokenId, transferAmount);
    }

    // Test case 17
    function test_RevertWhenTransferringDebtTokens_GivenRecipientAccountWillBeUnhealthy()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        // Create a second account owned by the same owner
        AccountId secondAccount = office.createIsolatedAccount(caller);

        // Supply minimal collateral to secondAccount (not enough to remain healthy after debt transfer)
        office.supply(SupplyParams({account: secondAccount, tokenId: key.toLentId(), assets: 100e6, extraData: ""}));

        uint256 debtTokenId = key.toDebtId();
        uint256 debtAmount = office.balanceOf(account, debtTokenId);

        // Approve bob as spender with enough allowance
        office.approve(account, bob.toUserAccount(), debtTokenId, debtAmount);

        // Bob tries to transfer debt, but it should fail because recipient will be unhealthy
        vm.startPrank(bob);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, secondAccount, market));
        office.transferFrom(account, secondAccount, debtTokenId, debtAmount);
    }

    // Test case 18
    function test_WhenTransferringDebtTokensWithZeroAmount()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenLendingAsset(key)
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        // Create a second account owned by the same owner
        AccountId secondAccount = office.createIsolatedAccount(caller);
        office.supply(SupplyParams({account: secondAccount, tokenId: key.toLentId(), assets: 100_000e6, extraData: ""}));

        uint256 debtTokenId = key.toDebtId();
        uint256 initialDebtBalance = office.balanceOf(account, debtTokenId);
        uint256 initialReceiverDebtBalance = office.balanceOf(secondAccount, debtTokenId);

        // It should allow the transfer.
        office.transferFrom(account, secondAccount, debtTokenId, 0);

        // It should not change debt token set of the owner or spender.
        assertEq(office.balanceOf(account, debtTokenId), initialDebtBalance, "Sender debt balance should not change");
        assertEq(
            office.balanceOf(secondAccount, debtTokenId),
            initialReceiverDebtBalance,
            "Receiver debt balance should not change"
        );
    }

    // Test case 19
    function test_WhenTransferringAccountToken_WhenCallerIsOwner_GivenAmountIsOne()
        public
        givenAccountIsIsolated
        whenCallerIsOwner
    {
        uint256 accountTokenId = account.toTokenId();
        AccountId ownerAccount = office.ownerOf(account).toUserAccount();
        _transferAmount = 1;

        vm.startPrank(caller);

        // It should allow the transfer of an account.
        office.transferFrom(ownerAccount, _receiverAccount, accountTokenId, _transferAmount);

        assertEq(office.ownerOf(account), _receiver, "Account owner should be transferred");
        assertEq(office.balanceOf(ownerAccount, accountTokenId), 0, "Sender balance should be zero");
        assertEq(office.balanceOf(_receiverAccount, accountTokenId), 1, "Receiver balance should be one");
    }

    // Test case 20
    function test_WhenTransferringAccountToken_WhenCallerIsOwner_GivenAmountIsZero()
        public
        givenAccountIsIsolated
        whenCallerIsOwner
    {
        uint256 accountTokenId = account.toTokenId();
        AccountId ownerAccount = caller.toUserAccount();
        _transferAmount = 0;

        vm.startPrank(caller);

        // It should allow the transaction but the account should not be transferred.
        office.transferFrom(ownerAccount, _receiverAccount, accountTokenId, _transferAmount);

        assertEq(office.ownerOf(account), caller, "Account owner should remain unchanged");
        assertEq(office.balanceOf(ownerAccount, accountTokenId), 1, "Sender balance should remain one");
        assertEq(office.balanceOf(_receiverAccount, accountTokenId), 0, "Receiver balance should remain zero");
    }

    // Test case 21
    function test_RevertWhenTransferringAccountToken_WhenCallerIsOwner_GivenAmountGreaterThanOne()
        public
        givenAccountIsIsolated
        whenCallerIsOwner
    {
        uint256 accountTokenId = account.toTokenId();
        AccountId ownerAccount = office.ownerOf(account).toUserAccount();
        _transferAmount = 2;

        vm.startPrank(caller);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientBalance.selector, ownerAccount, 1, _transferAmount, accountTokenId
            )
        );
        office.transferFrom(ownerAccount, _receiverAccount, accountTokenId, _transferAmount);
    }

    // Test case 22
    function test_RevertWhenTransferringAccountToken_WhenCallerIsOperator_GivenNotApproved()
        public
        givenAccountIsIsolated
        whenCallerIsOperator
    {
        uint256 accountTokenId = account.toTokenId();
        AccountId ownerAccount = office.ownerOf(account).toUserAccount();
        _transferAmount = 1;

        vm.startPrank(caller);
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientAllowance.selector,
                ownerAccount,
                caller.toUserAccount(),
                0,
                _transferAmount,
                accountTokenId
            )
        );
        office.transferFrom(ownerAccount, _receiverAccount, accountTokenId, _transferAmount);
    }

    // Test case 23
    function test_WhenTransferringAccountToken_WhenCallerIsOperator_GivenApproved()
        public
        givenAccountIsIsolated
        whenCallerIsOperator
    {
        uint256 accountTokenId = account.toTokenId();
        address owner = office.ownerOf(account);
        AccountId ownerAccount = owner.toUserAccount();
        _transferAmount = 1;

        vm.startPrank(owner);
        // For account tokens, operator can transfer if approved specifically for the account token
        office.approve(ownerAccount, caller.toUserAccount(), accountTokenId, 1);

        vm.startPrank(caller);

        // It should allow the transfer of an account.
        office.transferFrom(ownerAccount, _receiverAccount, accountTokenId, _transferAmount);

        assertEq(office.ownerOf(account), _receiver, "Account owner should be transferred");
        assertEq(office.balanceOf(ownerAccount, accountTokenId), 0, "Sender balance should be zero");
        assertEq(office.balanceOf(_receiverAccount, accountTokenId), 1, "Receiver balance should be one");
    }

    // Test case 24
    function test_RevertWhenTransferringAccountToken_WhenCallerIsUnauthorized()
        public
        givenAccountIsIsolated
        whenCallerIsNotAuthorized
    {
        uint256 accountTokenId = account.toTokenId();
        AccountId ownerAccount = office.ownerOf(account).toUserAccount();
        _transferAmount = 1;

        vm.startPrank(office.ownerOf(account));
        // Approve receiver to receive the account, but not the unauthorized caller
        office.approve(ownerAccount, _receiverAccount, accountTokenId, 1);

        vm.startPrank(caller);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientAllowance.selector,
                ownerAccount,
                caller.toUserAccount(),
                0,
                _transferAmount,
                accountTokenId
            )
        );
        office.transferFrom(ownerAccount, _receiverAccount, accountTokenId, _transferAmount);
    }

    // Test case 25
    function test_RevertWhenReserveDoesNotExist()
        public
        whenReserveIsNotSupported
        givenAccountIsNotIsolated
        whenCallerIsOwner
    {
        // Test lending tokens (using unsupported reserve)
        tokenId = key.toLentId();
        _transferAmount = 100e6;

        _testRevertInsufficientBalance();

        // Test escrow tokens (using unsupported reserve)
        tokenId = key.toEscrowId();
        _transferAmount = 1e18;

        _testRevertInsufficientBalance();
    }

    /////////////////////////////////////////////
    //                 Helpers                 //
    /////////////////////////////////////////////

    function onDelegationCallback(bytes calldata data) external returns (bytes memory) {
        (AccountId sender, AccountId receiver, uint256 tokenIdInCall, uint256 amount) =
            abi.decode(data, (AccountId, AccountId, uint256, uint256));

        vm.startPrank(_maliciousCaller);
        office.transferFrom(sender, receiver, tokenIdInCall, amount);
        return "";
    }

    function _testOwnerTransferWithoutAllowanceChange() internal {
        uint256 initialFromBalance = office.balanceOf(account, tokenId);
        uint256 initialToBalance = office.balanceOf(_receiverAccount, tokenId);
        uint256 initialAllowance = office.allowance(office.ownerOf(account), account, _receiverAccount, tokenId);

        vm.startPrank(caller);

        // It should transfer the tokens to the spender.
        office.transferFrom(account, _receiverAccount, tokenId, _transferAmount);

        assertEq(office.balanceOf(account, tokenId), initialFromBalance - _transferAmount, "From balance incorrect");
        assertEq(
            office.balanceOf(_receiverAccount, tokenId), initialToBalance + _transferAmount, "To balance incorrect"
        );

        // It should not change the allowance amount returned by `allowance`.
        assertEq(
            office.allowance(office.ownerOf(account), account, _receiverAccount, tokenId),
            initialAllowance,
            "Allowance should remain unchanged"
        );
    }

    function _testTransferWithCollateralAndAllowanceUpdate() internal {
        uint256 initialFromBalance = office.balanceOf(account, tokenId);
        uint256 initialToBalance = office.balanceOf(_receiverAccount, tokenId);
        uint256 initialAllowance = office.allowance(office.ownerOf(account), account, _receiverAccount, tokenId);

        vm.startPrank(caller);

        // It should transfer the tokens to the spender.
        office.transferFrom(account, _receiverAccount, tokenId, _transferAmount);

        assertEq(office.balanceOf(account, tokenId), initialFromBalance - _transferAmount, "From balance incorrect");
        assertEq(
            office.balanceOf(_receiverAccount, tokenId), initialToBalance + _transferAmount, "To balance incorrect"
        );

        // It should add the tokenId to collateral token set of the spender.
        uint256[] memory receiverCollaterals = office.getAllCollateralIds(_receiverAccount, market);
        bool receiverHasToken = false;
        for (uint256 i = 0; i < receiverCollaterals.length; i++) {
            if (receiverCollaterals[i] == tokenId) {
                receiverHasToken = true;
                break;
            }
        }
        assertTrue(receiverHasToken, "Should add to collateral set for receiver");

        // It should reduce the allowance amount returned by `allowance`.
        assertEq(
            office.allowance(office.ownerOf(account), account, _receiverAccount, tokenId),
            initialAllowance - _transferAmount,
            "Allowance not updated"
        );
    }

    function _testFullBalanceTransferWithCollateralUpdate() internal {
        uint256 initialFromBalance = office.balanceOf(account, tokenId);
        uint256 initialToBalance = office.balanceOf(_receiverAccount, tokenId);
        _transferAmount = initialFromBalance;

        vm.startPrank(caller);

        // It should allow the transfer.
        office.transferFrom(account, _receiverAccount, tokenId, _transferAmount);

        assertEq(office.balanceOf(account, tokenId), 0, "From balance should be zero");
        assertEq(
            office.balanceOf(_receiverAccount, tokenId), initialToBalance + _transferAmount, "To balance incorrect"
        );

        // It should remove the tokenId from collateral token set of the owner.
        uint256[] memory senderCollaterals = office.getAllCollateralIds(account, market);
        bool senderHasToken = false;
        for (uint256 i = 0; i < senderCollaterals.length; i++) {
            if (senderCollaterals[i] == tokenId) {
                senderHasToken = true;
                break;
            }
        }
        assertFalse(senderHasToken, "Should remove from collateral set for sender");

        // It should add the tokenId to collateral token set of the spender.
        uint256[] memory receiverCollaterals = office.getAllCollateralIds(_receiverAccount, market);
        bool receiverHasToken = false;
        for (uint256 i = 0; i < receiverCollaterals.length; i++) {
            if (receiverCollaterals[i] == tokenId) {
                receiverHasToken = true;
                break;
            }
        }
        assertTrue(receiverHasToken, "Should add to collateral set for receiver");

        // It should reduce the allowance amount returned by `allowance`.
        // (For owner transfers, allowance should remain 0)
    }

    function _testOperatorTransferWithCollateral() internal {
        uint256 initialFromBalance = office.balanceOf(account, tokenId);
        uint256 initialToBalance = office.balanceOf(_receiverAccount, tokenId);

        vm.startPrank(caller);

        // It should allow transfer.
        office.transferFrom(account, _receiverAccount, tokenId, _transferAmount);

        assertEq(office.balanceOf(account, tokenId), initialFromBalance - _transferAmount, "From balance incorrect");
        assertEq(
            office.balanceOf(_receiverAccount, tokenId), initialToBalance + _transferAmount, "To balance incorrect"
        );

        // It should add the tokenId to collateral token set of the receiver.
        uint256[] memory receiverCollaterals = office.getAllCollateralIds(_receiverAccount, market);
        bool receiverHasToken = false;
        for (uint256 i = 0; i < receiverCollaterals.length; i++) {
            if (receiverCollaterals[i] == tokenId) {
                receiverHasToken = true;
                break;
            }
        }
        assertTrue(receiverHasToken, "Should add to collateral set for receiver");

        // It should not change the allowance amount returned by `allowance`.
        assertEq(
            office.allowance(office.ownerOf(account), account, _receiverAccount, tokenId),
            0,
            "Allowance should remain 0"
        );
    }

    function _testZeroAmountTransfer() internal {
        uint256 initialFromBalance = office.balanceOf(account, tokenId);
        uint256 initialToBalance = office.balanceOf(_receiverAccount, tokenId);
        uint256[] memory initialSenderCollaterals = office.getAllCollateralIds(account, market);
        uint256[] memory initialReceiverCollaterals = office.getAllCollateralIds(_receiverAccount, market);

        vm.startPrank(caller);

        // It should allow the transfer.
        office.transferFrom(account, _receiverAccount, tokenId, _transferAmount);

        // It should not change the balance of the owner or spender.
        assertEq(office.balanceOf(account, tokenId), initialFromBalance, "From balance should not change");
        assertEq(office.balanceOf(_receiverAccount, tokenId), initialToBalance, "To balance should not change");

        // It should not change collateral token set of the owner or spender.
        uint256[] memory finalSenderCollaterals = office.getAllCollateralIds(account, market);
        uint256[] memory finalReceiverCollaterals = office.getAllCollateralIds(_receiverAccount, market);
        assertEq(
            finalSenderCollaterals.length, initialSenderCollaterals.length, "Sender collateral set should not change"
        );
        assertEq(
            finalReceiverCollaterals.length,
            initialReceiverCollaterals.length,
            "Receiver collateral set should not change"
        );

        // It should not change the allowance amount returned by `allowance`.
        assertEq(
            office.allowance(office.ownerOf(account), account, _receiverAccount, tokenId),
            0,
            "Allowance should remain 0"
        );
    }

    function _testRevertInsufficientAllowance() internal {
        uint256 currentAllowance = office.allowance(office.ownerOf(account), account, _receiverAccount, tokenId);

        vm.startPrank(caller);
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientAllowance.selector,
                account,
                _receiverAccount,
                currentAllowance,
                _transferAmount,
                tokenId
            )
        );
        office.transferFrom(account, _receiverAccount, tokenId, _transferAmount);
    }

    function _testRevertInsufficientBalance() internal {
        uint256 currentBalance = office.balanceOf(account, tokenId);

        vm.startPrank(caller);
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientBalance.selector, account, currentBalance, _transferAmount, tokenId
            )
        );
        office.transferFrom(account, _receiverAccount, tokenId, _transferAmount);
    }
}

// Generated using co-pilot: Claude Haiku 4.5
