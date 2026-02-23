// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "../../shared/CommonScenarios.sol";

contract Office_delegationCall is CommonScenarios, IDelegatee {
    using ReserveKeyLibrary for *;
    using MarketIdLibrary for *;
    using AccountIdLibrary for *;
    using TokenHelpers for *;

    event ChecksDeferred(AccountId account, MarketId market);

    // Internal variables for test state
    MarketId internal _otherMarket;
    AccountId internal _otherAccount;
    uint256 internal _testCaseNumber;

    function setUp() public override {
        // Call parent setUp first
        super.setUp();

        // Set up default state for all tests.
        vm.startPrank(admin);
        _otherMarket = createDefaultNoHooksMarket();
        _otherAccount = office.createIsolatedAccount(alice);

        // Set this contract as an operator for the other account.
        vm.startPrank(alice);
        office.setOperator(address(this), _otherAccount, true);

        // Allow this contract to supply on behalf of any account.
        vm.startPrank(address(this));
        deal(address(usdc), address(this), 1_000_000e6); // 1,000,000 USDC
        usdc.approve(address(office), 1_000_000e6);
    }

    // Test case 1: Should defer health checks for account actions in different markets.
    function test_ShouldDeferHealthChecksForAccountActionsInDifferentMarkets()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        whenOngoingDelegationCall
    {
        _testCaseNumber = 1;

        vm.startPrank(caller);

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.delegationCall(DelegationCallParams({delegatee: IDelegatee(address(this)), callbackData: bytes("")}));
    }

    // Test case 2: Should defer health checks for different account actions in the same market.
    function test_ShouldDeferHealthChecksForDifferentAccountActionsInTheSameMarket()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        whenOngoingDelegationCall
    {
        _testCaseNumber = 2;

        vm.startPrank(caller);

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, _otherAccount, market));
        office.delegationCall(DelegationCallParams({delegatee: IDelegatee(address(this)), callbackData: bytes("")}));
    }

    // Test case 3: Should perform health checks after delegation call if any action reduces the health of an account.
    function test_ShouldPerformHealthChecksAfterDelegationCallIfAnyActionReducesTheHealthOfAnAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        whenOngoingDelegationCall
    {
        _testCaseNumber = 3;

        vm.startPrank(caller);

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.delegationCall(DelegationCallParams({delegatee: IDelegatee(address(this)), callbackData: bytes("")}));
    }

    // Test case 4: Should revert if reentering delegation call function.
    function test_Revert_ShouldRevertIfReenteringDelegationCallFunction()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenOngoingDelegationCall
    {
        _testCaseNumber = 4;

        vm.startPrank(caller);

        // This should revert due to reentrancy protection
        office.delegationCall(DelegationCallParams({delegatee: IDelegatee(address(this)), callbackData: bytes("")}));
    }

    // Test case 5: Should revert if any unauthorized address calls a function for an account.
    function test_Revert_ShouldRevertIfAnyUnauthorizedAddressCallsAFunctionForAnAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenOngoingDelegationCall
    {
        _testCaseNumber = 5;

        vm.startPrank(caller);

        office.delegationCall(DelegationCallParams({delegatee: IDelegatee(address(this)), callbackData: bytes("")}));
    }

    // Test case 6: Should revert if the account is not healthy at the end of the delegation call.
    function test_Revert_ShouldRevertIfTheAccountIsNotHealthyAtTheEndOfTheDelegationCall()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        whenOngoingDelegationCall
    {
        _testCaseNumber = 6;

        vm.startPrank(caller);

        // This should revert if the account in context is not healthy after the delegation call.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.delegationCall(DelegationCallParams({delegatee: IDelegatee(address(this)), callbackData: bytes("")}));
    }

    // Test case 7: Should revert if liquidating any account.
    function test_Revert_ShouldRevertIfLiquidatingAnyAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
        whenOngoingDelegationCall
    {
        _testCaseNumber = 7;

        vm.startPrank(caller);

        // This should revert when trying to liquidate during delegation call
        office.delegationCall(DelegationCallParams({delegatee: IDelegatee(address(this)), callbackData: bytes("")}));
    }

    function onDelegationCallback(bytes calldata) external returns (bytes memory returnData) {
        // Test case 1: Should defer health checks for account actions in different markets.
        // Try to borrow from different markets - should defer health checks.
        if (_testCaseNumber == 1) {
            ReserveKey otherMarketUSDCKey = _otherMarket.toReserveKey(usdc);
            uint256 otherMarketLendingId = otherMarketUSDCKey.toLentId();

            office.supply(
                SupplyParams({
                    tokenId: otherMarketLendingId,
                    account: account,
                    assets: 100e6, // 100 USDC
                    extraData: ""
                })
            );

            // Add liquidity to other market to enable borrowing more than supplied amount.
            vm.startPrank(address(this));
            office.supply(
                SupplyParams({
                    tokenId: _otherMarket.toReserveKey(usdc).toLentId(),
                    account: bob.toUserAccount(),
                    assets: 100_000e6, // 100,000 USDC
                    extraData: ""
                })
            );

            vm.startPrank(caller);

            // The health check for the account in the other market will be queued first.
            (bool success,) = address(office)
                .call(
                    abi.encodeCall(
                        office.borrow,
                        BorrowParams({
                            key: otherMarketUSDCKey,
                            account: account,
                            receiver: caller,
                            assets: 50e6, // 50 USDC which is less than supplied amount
                            extraData: ""
                        })
                    )
                );

            assertTrue(success, "Health checks should be deferred for borrow in different market");

            // Borrow from the original market to make the account unhealthy.
            // The health check for this market will be queued second and executed last.
            (success,) = address(office)
                .call(
                    abi.encodeCall(
                        office.borrow,
                        BorrowParams({
                            key: usdcKey,
                            account: account,
                            receiver: caller,
                            assets: 5000e6, // 5,000 USDC which is more than the supplied amount
                            extraData: ""
                        })
                    )
                );

            assertTrue(success, "Health checks should be deferred for borrow in original market");

            // We expect the transaction to revert due to health check failing for the account
            // in the original market. This ensures that health checks were deferred and executed
            // only after the callback completed.
        } else if (_testCaseNumber == 2) {
            // Test case 2: Should defer health checks for different account actions in the same market.
            // Try to transfer collateral from a different account - should defer health checks
            // First supply some tokens to the other account
            uint256 usdcLentId = market.toReserveKey(usdc).toLentId();

            uint256 shares = office.supply(
                SupplyParams({
                    tokenId: usdcLentId,
                    account: _otherAccount,
                    assets: 100e6, // 100 USDC
                    extraData: ""
                })
            );

            // Borrow funds to make the account unhealthy if collateral is transferred out
            (bool success,) = address(office)
                .call(
                    abi.encodeCall(
                        office.borrow,
                        BorrowParams({
                            key: market.toReserveKey(usdc),
                            account: _otherAccount,
                            receiver: caller,
                            assets: 80e6, // 80 USDC
                            extraData: ""
                        })
                    )
                );

            assertTrue(success, "Borrow to make the other account unhealthy should succeed");

            // Transfer from other account - this should defer health checks
            (success,) = address(office)
                .call(
                    abi.encodeWithSignature(
                        "transferFrom(uint256,uint256,uint256,uint256)", _otherAccount, account, usdcLentId, shares
                    )
                );

            assertTrue(success, "Health checks should be deferred for asset transfer");
        } else if (_testCaseNumber == 3) {
            // Test case 3: Should perform health checks after delegation call if any action reduces the health of an account.
            // Perform an action that reduces health - should defer health check and perform it after callback
            uint256 currentShares = office.balanceOf(account, market.toReserveKey(weth).toEscrowId());

            (bool success,) = address(office)
                .call(
                    abi.encodeCall(
                        office.withdraw,
                        WithdrawParams({
                            tokenId: market.toReserveKey(weth).toEscrowId(),
                            account: account,
                            assets: 0,
                            shares: currentShares, // Withdraw all to make account unhealthy
                            receiver: caller,
                            extraData: ""
                        })
                    )
                );

            assertTrue(success, "Withdraw to reduce collateral should succeed");

            // The health check should be deferred and performed after this callback
            assertEq(office.requiresHealthCheck(), true, "Health check should be required after reducing collateral");
        } else if (_testCaseNumber == 4) {
            // Test case 4: Should revert if reentering delegation call function.
            // Try to call delegationCall again - should revert due to reentrancy
            vm.expectRevert(IContext.Context__ContextAlreadySet.selector);

            office.delegationCall(DelegationCallParams({delegatee: IDelegatee(address(this)), callbackData: bytes("")}));
        } else if (_testCaseNumber == 5) {
            // Test case 5: Should revert if any unauthorized address calls a function for an account.
            uint256 usdcLentId = usdcKey.toLentId();
            uint256 shares = office.balanceOf(alice, usdcLentId);

            vm.startPrank(bob);

            vm.expectRevert(abi.encodeWithSelector(IRegistry.Registry__NotAuthorizedCaller.selector, account, bob));

            // Try to redeem shares of Alice.
            office.withdraw(
                WithdrawParams({
                    tokenId: usdcLentId, account: account, assets: 0, shares: shares, receiver: bob, extraData: ""
                })
            );
        } else if (_testCaseNumber == 6) {
            // Test case 6: Should revert if the account is not healthy at the end of the delegation call.
            uint256 usdcLentId = usdcKey.toLentId();
            uint256 shares = office.balanceOf(account, usdcLentId);

            // Redeem all shares to make the account unhealthy.
            office.withdraw(
                WithdrawParams({
                    tokenId: usdcLentId, account: account, assets: 0, shares: shares, receiver: caller, extraData: ""
                })
            );
        } else if (_testCaseNumber == 7) {
            // Test case 7: Should revert if liquidating any account.
            // Try to liquidate an account during delegation call - should revert
            vm.expectRevert(abi.encodeWithSelector(IOffice.Office__CannotLiquidateDuringDelegationCall.selector));

            office.liquidate(
                LiquidationParams({
                    account: account,
                    market: market,
                    collateralParams: new CollateralLiquidationParams[](0),
                    callbackData: "",
                    extraData: ""
                })
            );
        }

        return returnData;
    }
}

// Generated using co-pilot: Claude-3.5-Sonnet
