// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Office_borrow is CommonScenarios {
    using ReserveKeyLibrary for *;
    using MarketIdLibrary for *;

    Call[] batchCalls;

    /// @dev Modifier to make WETH borrowable and add liquidity
    modifier givenWethIsBorrowable() {
        vm.startPrank(admin);

        // Make WETH borrowable
        SimpleMarketConfig.AssetConfig[] memory assets = new SimpleMarketConfig.AssetConfig[](1);
        assets[0] = SimpleMarketConfig.AssetConfig({asset: weth, isBorrowable: true});
        marketConfig.addSupportedAssets(assets);

        // Set the borrow rate for WETH
        irm.setRate(wethKey, getRatePerSecond(0.05e18)); // 5% annual interest rate

        // Bob provides liquidity for WETH
        vm.startPrank(bob);
        office.supply(
            SupplyParams({
                tokenId: wethKey.toLentId(),
                account: AccountIdLibrary.toUserAccount(bob),
                assets: 100e18, // 100 WETH
                extraData: ""
            })
        );
        vm.stopPrank();

        _;
    }

    function test_GivenCallerIsTheOwnerOfTheAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Call the borrow function with the necessary parameters.
        BorrowParams memory params = BorrowParams({
            key: usdcKey,
            account: account,
            receiver: caller,
            assets: 100e6, // Borrow 100 USDC
            extraData: ""
        });

        uint256 marketSuppliedAmountBefore = office.getReserveData(usdcKey).supplied;

        // It should allow over-collateralized borrowing.
        office.borrow(params);

        // It should mint the correct amount of debt shares.
        assertEq(
            scaleDownByOffset(office.balanceOf(account, usdcKey.toDebtId())),
            100e6,
            "Debt shares were not minted correctly"
        );

        // It should update the reserve borrowed amount.
        assertEq(office.getReserveData(usdcKey).borrowed, 100e6, "Reserve borrowed amount was not updated correctly");
        assertEq(
            office.getReserveData(usdcKey).supplied, marketSuppliedAmountBefore, "Supplied amount should not change"
        );
    }

    function test_GivenTheCallerIsTheOperatorOfTheOwner()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        givenEnoughLiquidityInTheReserve
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Call the borrow function with the necessary parameters.
        BorrowParams memory params = BorrowParams({
            key: usdcKey,
            account: account,
            receiver: caller,
            assets: 100e6, // Borrow 100 USDC
            extraData: ""
        });

        uint256 marketSuppliedAmountBefore = office.getReserveData(usdcKey).supplied;

        // It should allow over-collateralized borrowing.
        office.borrow(params);

        // It should mint the correct amount of debt shares.
        assertEq(
            scaleDownByOffset(office.balanceOf(account, usdcKey.toDebtId())),
            100e6,
            "Debt shares were not minted correctly"
        );

        // It should update the reserve borrowed amount.
        assertEq(office.getReserveData(usdcKey).borrowed, 100e6, "Reserve borrowed amount was not updated correctly");
        assertEq(
            office.getReserveData(usdcKey).supplied, marketSuppliedAmountBefore, "Supplied amount should not change"
        );
    }

    function test_RevertGiven_TheCallerIsNotAuthorizedForTheAccount()
        external
        whenReserveExists
        whenCallerIsNotAuthorized
        givenEnoughLiquidityInTheReserve
        givenAccountIsNotIsolated
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Call the borrow function with the necessary parameters.
        BorrowParams memory params = BorrowParams({
            key: usdcKey,
            account: account,
            receiver: caller,
            assets: 100e6, // Borrow 100 USDC
            extraData: ""
        });

        vm.expectRevert(abi.encodeWithSelector(IRegistry.Registry__NotAuthorizedCaller.selector, account, caller));
        office.borrow(params);
    }

    function test_RevertGiven_TheCallerIsNotAuthorizedForTheAccountAndAccountIsIsolated()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsNotAuthorized
        givenEnoughLiquidityInTheReserve
        givenAccountIsHealthy
    {
        vm.startPrank(alice);

        office.supply(
            SupplyParams({
                tokenId: usdcKey.toLentId(),
                account: account, // Will be ignored since `isolate` is true.
                assets: 1000e6, // Supply 1000 USDC
                extraData: ""
            })
        );

        // Caller is someone who is not authorized for Alice's account.
        vm.startPrank(caller);

        // Call the borrow function with the necessary parameters.
        BorrowParams memory params = BorrowParams({
            key: usdcKey,
            account: account,
            receiver: caller,
            assets: 100e6, // Borrow 100 USDC
            extraData: ""
        });

        vm.expectRevert(abi.encodeWithSelector(IRegistry.Registry__NotAuthorizedCaller.selector, account, caller));
        office.borrow(params);
    }

    /// @dev This test case is not about liquidation but rather about borrowing an amount which would make the account
    /// unhealthy.
    function test_RevertGiven_TheAccountIsUnhealthy()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Params to borrow entire amount available in the reserve.
        // The amount supplied in `whenUsingSuppliedPlusEscrowedAssets` is 1000 USDC.
        // So borrowing a lot more than that would make the account unhealthy.
        BorrowParams memory params = BorrowParams({
            key: usdcKey,
            account: account,
            receiver: caller,
            assets: office.getReserveData(usdcKey).supplied,
            extraData: ""
        });

        vm.expectRevert(
            abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, usdcKey.getMarketId())
        );
        office.borrow(params);
    }

    function test_RevertGiven_MinDebtAmountUSDIsNotMetAfterBorrowing()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(admin);

        // Set a high minimum debt requirement (e.g., $500 USD).
        marketConfig.setMinDebtAmountUSD(500e18);

        vm.startPrank(caller);

        // Try to borrow an amount that's below the minimum debt requirement.
        // Account has $3000 worth of collateral (1000 USDC + 1 WETH @ $2000).
        // We'll try to borrow only $100 USDC, which is below the $500 minimum.
        BorrowParams memory params = BorrowParams({
            key: usdcKey,
            account: account,
            receiver: caller,
            assets: 100e6, // Borrow 100 USDC = $100 USD (below $500 minimum)
            extraData: ""
        });

        // It should revert.
        //     With `Office__DebtBelowMinimum` error.
        vm.expectPartialRevert(IOffice.Office__DebtBelowMinimum.selector);
        office.borrow(params);
    }

    function test_GivenTheReceiverReturnsSufficientCollateralAndLendsThem()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenTakingAnUndercollateralizedLoan
        givenTheReceiverReturnsSufficientCollateral
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        uint256 marketSuppliedAmountBefore = office.getReserveData(usdcKey).supplied;

        // Encode necessary calls to be executed by the delegatee.
        bytes memory callbackData;
        {
            // Borrow 3000 USDC using the simple delegatee as the receiver.
            encodeBorrow(usdcKey, 3000e6);

            // Lend 1.5 WETH => equivalent to 3000 USDC at 2000 USDC/WETH price using the simple delegatee.
            encodeSupply(wethKey.toLentId(), 1.5e18);

            callbackData = abi.encode(batchCalls);
        }

        // It should allow under-collateralized borrowing.
        office.delegationCall(DelegationCallParams({delegatee: delegatee, callbackData: callbackData}));

        // It should mint the correct amount of debt shares.
        assertEq(
            scaleDownByOffset(office.balanceOf(account, usdcKey.toDebtId())),
            3000e6,
            "Debt shares were not minted correctly"
        );

        // It should update the reserve borrowed amount.
        assertEq(office.getReserveData(usdcKey).borrowed, 3000e6, "Reserve borrowed amount was not updated correctly");

        // It should mint the correct amount of lending shares.
        assertEq(
            scaleDownByOffset(office.balanceOf(account, wethKey.toLentId())),
            1.5e18 + scaleDownByOffset(accountSuppliedAmountBefore.wethLendingShareAmount),
            "WETH lending shares were not minted correctly"
        );

        // It should not update the reserve supplied amount for USDC.
        assertEq(
            office.getReserveData(usdcKey).supplied,
            marketSuppliedAmountBefore,
            "Reserve supplied amount should not change"
        );

        // It should not modify USDC lending shares.
        assertEq(
            office.balanceOf(account, usdcKey.toLentId()),
            accountSuppliedAmountBefore.usdcLendingShareAmount,
            "USDC lending shares should not change"
        );

        // It should update the WETH lent reserve supplied amount.
        assertEq(
            office.getReserveData(wethKey).supplied, 1.5e18, "WETH reserve supplied amount was not updated correctly"
        );
    }

    function test_GivenTheReceiverReturnsSufficientCollateralAndEscrowsThem()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenTakingAnUndercollateralizedLoan
        givenTheReceiverReturnsSufficientCollateral
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        uint256 marketSuppliedAmountUSDCBefore = office.getReserveData(usdcKey).supplied;
        uint256 marketSuppliedAmountWETHBefore = office.getReserveData(wethKey).supplied;

        // Encode necessary calls to be executed by the delegatee.
        bytes memory callbackData;
        {
            // Borrow 3000 USDC using the simple delegatee as the receiver.
            encodeBorrow(usdcKey, 3000e6);

            // Escrow 1.5 WETH => equivalent to 3000 USDC at 2000 USDC/WETH price using the simple delegatee.
            encodeSupply(wethKey.toEscrowId(), 1.5e18);

            callbackData = abi.encode(batchCalls);
        }

        // It should allow under-collateralized borrowing.
        office.delegationCall(DelegationCallParams({delegatee: delegatee, callbackData: callbackData}));

        // It should mint the correct amount of debt shares.
        assertEq(
            scaleDownByOffset(office.balanceOf(account, usdcKey.toDebtId())),
            3000e6,
            "Debt shares were not minted correctly"
        );

        // It should update the reserve borrowed amount.
        assertEq(office.getReserveData(usdcKey).borrowed, 3000e6, "Reserve borrowed amount was not updated correctly");

        // It should mint the correct amount of escrow shares.
        // Should consider previously escrowed amount.
        assertEq(
            office.balanceOf(account, wethKey.toEscrowId()),
            1.5e18 + accountSuppliedAmountBefore.wethEscrowShareAmount,
            "Escrow shares were not minted correctly"
        );

        // It should not mint any lending shares for USDC or WETH.
        assertEq(
            office.balanceOf(account, usdcKey.toLentId()),
            accountSuppliedAmountBefore.usdcLendingShareAmount,
            "USDC lending shares should not change"
        );
        assertEq(
            office.balanceOf(account, wethKey.toLentId()),
            accountSuppliedAmountBefore.wethLendingShareAmount,
            "WETH lending shares should not change"
        );

        // It should not update the reserve supplied amounts.
        assertEq(
            office.getReserveData(usdcKey).supplied,
            marketSuppliedAmountUSDCBefore,
            "USDC reserve supplied amount should not change"
        );
        assertEq(
            office.getReserveData(wethKey).supplied,
            marketSuppliedAmountWETHBefore,
            "WETH reserve supplied amount should not change"
        );
    }

    function test_RevertGiven_TheReceiverDoesNotReturnSufficientCollateral()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenTakingAnUndercollateralizedLoan
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Encode necessary calls to be executed by the delegatee.
        bytes memory callbackData;
        {
            // Borrow 3000 USDC using the simple delegatee as the receiver.
            encodeBorrow(usdcKey, 3000e6);

            // Escrow 0.00001 WETH => equivalent to 20 USDC at 2000 USDC/WETH price using the simple delegatee.
            // This is not enough to cover the 3000 USDC borrowed.
            encodeSupply(wethKey.toEscrowId(), 0.00001e18);

            callbackData = abi.encode(batchCalls);
        }

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.delegationCall(DelegationCallParams({delegatee: delegatee, callbackData: callbackData}));
    }

    function test_RevertGiven_TheReceiverIsAnInvalidLoanReceiver()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenTakingAnUndercollateralizedLoan
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Encode necessary calls to be executed by the delegatee.
        bytes memory callbackData;
        {
            // Borrow 3000 USDC using the simple delegatee as the receiver.
            encodeBorrow(usdcKey, 3000e6);

            // Escrow 1.5 WETH => equivalent to 3000 USDC at 2000 USDC/WETH price using the simple delegatee.
            encodeSupply(wethKey.toEscrowId(), 1.5e18);

            callbackData = abi.encode(batchCalls);
        }

        vm.expectRevert();
        office.delegationCall(
            DelegationCallParams({
                delegatee: IDelegatee(makeAddr("dummy")), // Invalid delegatee address.
                callbackData: callbackData
            })
        );
    }

    function test_RevertGiven_InsufficientLiquidityInTheReserve()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // As such this doesn't matter as the borrow will fail due to insufficient liquidity.
        BorrowParams memory params = BorrowParams({
            key: usdcKey,
            account: account,
            receiver: alice,
            assets: office.getReserveData(usdcKey).supplied + 1,
            extraData: ""
        });

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__InsufficientLiquidity.selector, usdcKey));
        office.borrow(params);
    }

    function test_RevertWhen_ReserveIsNotBorrowable()
        external
        whenReserveExists
        whenReserveIsNotBorrowable
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Call the borrow function with the necessary parameters.
        BorrowParams memory params = BorrowParams({
            key: wethKey,
            account: account,
            receiver: caller,
            assets: 0.1e18, // Borrow 0.1 WETH
            extraData: ""
        });

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AssetNotBorrowable.selector, wethKey));
        office.borrow(params);
    }

    function test_RevertWhen_ReserveDoesNotExist()
        external
        whenReserveIsNotSupported
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Call the borrow function with the necessary parameters.
        BorrowParams memory params = BorrowParams({
            key: key,
            account: account,
            receiver: caller,
            assets: 0.1e18, // Borrow 0.1 DUMMY
            extraData: ""
        });

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AssetNotBorrowable.selector, key));
        office.borrow(params);
    }

    /////////////////////////////////////////////
    //              Encoding Helpers           //
    /////////////////////////////////////////////

    function encodeSupply(uint256 tokenId_, uint256 amount_) internal {
        SupplyParams memory supplyParams =
            SupplyParams({tokenId: tokenId_, account: account, assets: amount_, extraData: ""});

        batchCalls.push(
            Call({target: address(office), callData: abi.encodeWithSelector(IOffice.supply.selector, supplyParams)})
        );
    }

    function encodeBorrow(ReserveKey key_, uint256 assets_) internal {
        BorrowParams memory borrowParams = BorrowParams({
            key: key_,
            account: account,
            receiver: address(delegatee), // Use the delegatee as the receiver.
            assets: assets_,
            extraData: ""
        });

        batchCalls.push(
            Call({target: address(office), callData: abi.encodeWithSelector(IOffice.borrow.selector, borrowParams)})
        );
    }

    /// @dev Test case #13
    function test_RevertWhen_AnotherTokenIsBeingBorrowed()
        external
        whenReserveExists
        givenWethIsBorrowable
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition // By default it has USDC debt.

    {
        vm.startPrank(caller);

        // Account already has debt in USDC (from the modifier).
        // Now trying to borrow WETH which is a different token.
        BorrowParams memory params = BorrowParams({
            key: wethKey,
            account: account,
            receiver: caller,
            assets: 0.1e18, // Borrow 0.1 WETH
            extraData: ""
        });

        // It should revert with Registry__DebtIdMismatch error.
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__DebtIdMismatch.selector, account, wethKey.toDebtId(), usdcKey.toDebtId()
            )
        );
        office.borrow(params);
    }

    /// @dev Test case #14
    function test_WhenTheSameTokenIsBeingBorrowed()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition // By default it has USDC debt.

    {
        vm.startPrank(caller);

        uint256 existingDebtShares = scaleDownByOffset(office.balanceOf(account, usdcKey.toDebtId()));
        uint256 existingBorrowedAmount = office.getReserveData(usdcKey).borrowed;

        // Account already has debt in USDC (from the modifier).
        // Now borrowing more USDC (same token).
        BorrowParams memory params = BorrowParams({
            key: usdcKey,
            account: account,
            receiver: caller,
            assets: 100e6, // Borrow additional 100 USDC
            extraData: ""
        });

        // It should allow borrowing.
        office.borrow(params);

        // It should mint the correct amount of debt shares.
        assertEq(
            scaleDownByOffset(office.balanceOf(account, usdcKey.toDebtId())),
            existingDebtShares + 100e6,
            "Debt shares were not minted correctly"
        );

        // It should update the reserve borrowed amount.
        assertEq(
            office.getReserveData(usdcKey).borrowed,
            existingBorrowedAmount + 100e6,
            "Reserve borrowed amount was not updated correctly"
        );
    }
}

// Generated using co-pilot: Claude Sonnet 4.5
