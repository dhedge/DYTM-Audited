// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract HooksCallHelpers_callHook is CommonScenarios {
    using HooksCallHelpers for IHooks;
    using MarketIdLibrary for MarketId;
    using ReserveKeyLibrary for *;
    using SharesMathLib for uint256;
    using AccountIdLibrary for *;

    IHooks private _testHooks;

    modifier givenAllHooksSet() {
        _testHooks = ALL_HOOKS_SET;
        _;
    }

    modifier givenNoHooksSet() {
        _testHooks = NO_HOOKS_SET;
        _;
    }

    modifier whenMarketExists() override {
        vm.startPrank(admin);

        market = (address(_testHooks) == address(ALL_HOOKS_SET))
            ? createDefaultAllHooksMarket()
            : createDefaultNoHooksMarket();
        _;
    }

    modifier whenReserveExists() override {
        vm.startPrank(admin);

        usdcKey = market.toReserveKey(usdc);
        wethKey = market.toReserveKey(weth);

        // By default we will use USDC as the reserve key.
        // This can be overriden using `whenEscrowingAsset` or `whenLendingAsset` modifiers.
        key = usdcKey;

        // Set the borrow rate for the reserve.
        irm.setRate(key, getRatePerSecond(0.05e18)); // 5% annual interest rate
        _;
    }

    // Test case 1
    function test_GivenAllHooksSet_WhenAssetsAreSupplied()
        external
        givenAllHooksSet
        whenMarketExists
        whenReserveExists
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(alice);

        // Expect the before hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeSupply.selector));
        // Expect the after hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.afterSupply.selector));

        // It should trigger before and after hooks
        office.supply(SupplyParams({tokenId: tokenId, account: alice.toUserAccount(), assets: 1000e6, extraData: ""}));
    }

    // Test case 2
    function test_GivenAllHooksSet_WhenCollateralIsSwitched()
        external
        givenAllHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // Expect the before hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeSwitchCollateral.selector));
        // Expect the after hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.afterSwitchCollateral.selector));

        // It should trigger before and after hooks
        office.switchCollateral(
            SwitchCollateralParams({
                account: account,
                tokenId: tokenId,
                assets: 0,
                shares: office.balanceOf(account, tokenId) / 2
            })
        );
    }

    // Test case 3
    function test_GivenAllHooksSet_WhenCollateralIsWithdrawn()
        external
        givenAllHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // Expect the before hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeWithdraw.selector));
        // Expect the after hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.afterWithdraw.selector));

        // It should trigger before and after hooks
        office.withdraw(
            WithdrawParams({
                tokenId: tokenId,
                account: account,
                receiver: caller,
                assets: 0,
                shares: office.balanceOf(account, tokenId) / 2,
                extraData: ""
            })
        );
    }

    // Test case 4
    function test_GivenAllHooksSet_WhenAssetsAreBorrowed()
        external
        givenAllHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Expect the before hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeBorrow.selector));
        // Expect the after hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.afterBorrow.selector));

        // It should trigger before and after hooks
        office.borrow(BorrowParams({key: usdcKey, account: account, receiver: caller, assets: 500e6, extraData: ""}));
    }

    // Test case 5
    function test_GivenAllHooksSet_WhenDebtIsRepaid()
        external
        givenAllHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        uint256 debtShares = office.balanceOf(account, usdcKey.toDebtId());

        // Expect the before hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeRepay.selector));
        // Expect the after hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.afterRepay.selector));

        // It should trigger before and after hooks
        office.repay(
            RepayParams({
                key: usdcKey,
                account: account,
                withCollateralType: TokenType(0),
                assets: 0,
                shares: debtShares / 2,
                extraData: ""
            })
        );
    }

    // Test case 6
    function test_GivenAllHooksSet_WhenCollateralIsLiquidated()
        external
        givenAllHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
    {
        vm.startPrank(liquidator);

        uint256 totalDebtAssets = office.balanceOf(account, usdcKey.toDebtId()).toAssetsUp(
            office.getReserveData(usdcKey).borrowed, office.totalSupply(usdcKey.toDebtId())
        );

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        // Expect the before hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeLiquidate.selector));
        // Expect the after hook to be called
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.afterLiquidate.selector));

        // It should trigger before and after hooks
        office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );
    }

    // Test case 7
    function test_GivenAllHooksSet_WhenSupplyIsMigrated()
        external
        givenAllHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(admin);

        // Create second market with all hooks set
        MarketId secondMarket = createDefaultAllHooksMarket();

        vm.startPrank(caller);

        // Expect the before hook to be called (twice - once for each market)
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeMigrateSupply.selector), 2);
        // Expect the after hook to be called (twice - once for each market)
        vm.expectCall(address(ALL_HOOKS_SET), abi.encodeWithSelector(IHooks.afterMigrateSupply.selector), 2);

        uint256 fromTokenId = usdcKey.toLentId();
        uint256 toTokenId = secondMarket.toReserveKey(usdc).toLentId();

        // It should trigger before and after hooks
        office.migrateSupply(
            MigrateSupplyParams({
                account: account,
                fromTokenId: fromTokenId,
                toTokenId: toTokenId,
                assets: 0,
                shares: office.balanceOf(account, fromTokenId) / 2,
                fromExtraData: "",
                toExtraData: ""
            })
        );
    }

    // Test case 8
    function test_GivenNoHooksSet_WhenAssetsAreSupplied_ItShouldNotTriggerAnyHooks()
        external
        givenNoHooksSet
        whenMarketExists
        whenReserveExists
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(alice);

        // Expect NO calls to be made to the hooks
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeSupply.selector), 0);
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.afterSupply.selector), 0);

        // It should not trigger any hooks
        office.supply(SupplyParams({tokenId: tokenId, account: alice.toUserAccount(), assets: 1000e6, extraData: ""}));
    }

    // Test case 9
    function test_GivenNoHooksSet_WhenCollateralIsSwitched_ItShouldNotTriggerAnyHooks()
        external
        givenNoHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // Expect NO calls to be made to the hooks
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeSwitchCollateral.selector), 0);
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.afterSwitchCollateral.selector), 0);

        // It should not trigger any hooks
        office.switchCollateral(
            SwitchCollateralParams({
                account: account,
                tokenId: tokenId,
                assets: 0,
                shares: office.balanceOf(account, tokenId) / 2
            })
        );
    }

    // Test case 10
    function test_GivenNoHooksSet_WhenCollateralIsWithdrawn_ItShouldNotTriggerAnyHooks()
        external
        givenNoHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // Expect NO calls to be made to the hooks
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeWithdraw.selector), 0);
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.afterWithdraw.selector), 0);

        // It should not trigger any hooks
        office.withdraw(
            WithdrawParams({
                tokenId: tokenId,
                account: account,
                receiver: caller,
                assets: 0,
                shares: office.balanceOf(account, tokenId) / 2,
                extraData: ""
            })
        );
    }

    // Test case 11
    function test_GivenNoHooksSet_WhenAssetsAreBorrowed_ItShouldNotTriggerAnyHooks()
        external
        givenNoHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Expect NO calls to be made to the hooks
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeBorrow.selector), 0);
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.afterBorrow.selector), 0);

        // It should not trigger any hooks
        office.borrow(BorrowParams({key: usdcKey, account: account, receiver: caller, assets: 500e6, extraData: ""}));
    }

    // Test case 12
    function test_GivenNoHooksSet_WhenDebtIsRepaid_ItShouldNotTriggerAnyHooks()
        external
        givenNoHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        vm.startPrank(caller);

        // Expect NO calls to be made to the hooks
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeRepay.selector), 0);
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.afterRepay.selector), 0);

        uint256 debtShares = office.balanceOf(account, usdcKey.toDebtId());

        // It should not trigger any hooks
        office.repay(
            RepayParams({
                key: usdcKey,
                account: account,
                withCollateralType: TokenType(0),
                assets: 0,
                shares: debtShares / 2,
                extraData: ""
            })
        );
    }

    // Test case 13
    function test_GivenNoHooksSet_WhenCollateralIsLiquidated_ItShouldNotTriggerAnyHooks()
        external
        givenNoHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
    {
        vm.startPrank(liquidator);

        // Expect NO calls to be made to the hooks
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeLiquidate.selector), 0);
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.afterLiquidate.selector), 0);

        uint256 totalDebtAssets = office.balanceOf(account, usdcKey.toDebtId()).toAssetsUp(
            office.getReserveData(usdcKey).borrowed, office.totalSupply(usdcKey.toDebtId())
        );

        CollateralLiquidationParams[] memory collateralToLiquidate =
            getLiquidationCollaterals(account, market, totalDebtAssets);

        // It should not trigger any hooks
        office.liquidate(
            LiquidationParams({
                market: market,
                account: account,
                collateralParams: collateralToLiquidate,
                callbackData: "",
                extraData: ""
            })
        );
    }

    // Test case 14
    function test_GivenNoHooksSet_WhenSupplyIsMigrated_ItShouldNotTriggerAnyHooks()
        external
        givenNoHooksSet
        whenMarketExists
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(admin);

        // Create second market with no hooks set
        MarketId secondMarket = createDefaultNoHooksMarket();

        vm.startPrank(caller);

        // Expect NO calls to be made to the hooks
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.beforeMigrateSupply.selector), 0);
        vm.expectCall(address(NO_HOOKS_SET), abi.encodeWithSelector(IHooks.afterMigrateSupply.selector), 0);

        uint256 fromTokenId = usdcKey.toLentId();
        uint256 toTokenId = secondMarket.toReserveKey(usdc).toLentId();

        // It should not trigger any hooks
        office.migrateSupply(
            MigrateSupplyParams({
                account: account,
                fromTokenId: fromTokenId,
                toTokenId: toTokenId,
                assets: 0,
                shares: office.balanceOf(account, fromTokenId) / 2,
                fromExtraData: "",
                toExtraData: ""
            })
        );
    }
}

// Generated using co-pilot: Claude Sonnet 4
