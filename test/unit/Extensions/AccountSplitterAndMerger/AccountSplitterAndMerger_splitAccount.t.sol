// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../../shared/CommonScenarios.sol";
import {AccountSplitterAndMerger} from "../../../../src/extensions/delegatees/AccountSplitterAndMerger.sol";

contract AccountSplitterAndMerger_splitAccount is CommonScenarios {
    using ReserveKeyLibrary for *;
    using MarketIdLibrary for *;
    using AccountIdLibrary for *;

    uint64 internal constant _VALID_FRACTION = uint64(0.5e18); // 50%
    uint64 internal constant _INVALID_FRACTION = uint64(1.5e18); // 150%
    AccountSplitterAndMerger internal _extension;

    function setUp() public override {
        super.setUp();

        // Deploy the AccountSplitterAndMerger extension.
        vm.startPrank(admin);

        _extension = new AccountSplitterAndMerger(address(office));
    }

    // Test case 1: Given account is healthy + Given valid fraction
    function test_GivenAccountIsHealthy_GivenValidFraction()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
    {
        vm.startPrank(caller);

        // Store original debt shares balance.
        uint256 originalDebtShares = office.balanceOf(account, usdcKey.toDebtId());

        AccountSplitterAndMerger.SplitAccountParams memory params = AccountSplitterAndMerger.SplitAccountParams({
            fraction: _VALID_FRACTION, sourceAccount: account, market: market
        });

        bytes memory callbackData = abi.encode(
            AccountSplitterAndMerger.CallbackData({
                operation: AccountSplitterAndMerger.Operation.SPLIT_ACCOUNT, data: abi.encode(params)
            })
        );

        // The extension can only be used via a delegation call.
        DelegationCallParams memory delegationCallParams =
            DelegationCallParams({delegatee: IDelegatee(address(_extension)), callbackData: callbackData});

        // It should check account is healthy before splitting.
        // This is implicit in the function call - if account was unhealthy, it would revert.
        bytes memory returnData = office.delegationCall(delegationCallParams);

        AccountId newAccount = abi.decode(returnData, (AccountId));

        // It should create a new account with half the collateral shares.
        uint256 expectedUsdcCollateral = accountSuppliedAmountBefore.usdcLendingShareAmount / 2;
        uint256 expectedWethCollateral = accountSuppliedAmountBefore.wethEscrowShareAmount / 2;
        assertEq(
            office.balanceOf(newAccount, usdcKey.toLentId()),
            expectedUsdcCollateral,
            "New account should have half the USDC collateral shares"
        );
        assertEq(
            office.balanceOf(newAccount, wethKey.toEscrowId()),
            expectedWethCollateral,
            "New account should have half the WETH collateral shares"
        );

        // It should seed the new account with half the debt shares.
        uint256 expectedDebtShares = originalDebtShares / 2;
        assertEq(
            office.balanceOf(newAccount, usdcKey.toDebtId()),
            expectedDebtShares,
            "New account should have half the debt shares"
        );

        // It should give the new account to the caller.
        assertEq(office.ownerOf(newAccount), caller, "New account should be owned by the caller");
    }

    // Test case 2: Given account is healthy + Given invalid fraction
    function test_RevertGivenAccountIsHealthy_GivenInvalidFraction()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
    {
        vm.startPrank(caller);

        AccountSplitterAndMerger.SplitAccountParams memory params = AccountSplitterAndMerger.SplitAccountParams({
            fraction: _INVALID_FRACTION, sourceAccount: account, market: market
        });

        bytes memory callbackData = abi.encode(
            AccountSplitterAndMerger.CallbackData({
                operation: AccountSplitterAndMerger.Operation.SPLIT_ACCOUNT, data: abi.encode(params)
            })
        );

        // The extension can only be used via a delegation call.
        DelegationCallParams memory delegationCallParams =
            DelegationCallParams({delegatee: IDelegatee(address(_extension)), callbackData: callbackData});

        // It should revert with AccountSplitterAndMerger__InvalidFraction.
        vm.expectRevert(
            abi.encodeWithSelector(
                AccountSplitterAndMerger.AccountSplitterAndMerger_InvalidFraction.selector, _INVALID_FRACTION
            )
        );
        office.delegationCall(delegationCallParams);
    }

    // Test case 3: Given account is unhealthy
    function test_RevertGivenAccountIsUnhealthy()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
    {
        vm.startPrank(caller);

        AccountSplitterAndMerger.SplitAccountParams memory params = AccountSplitterAndMerger.SplitAccountParams({
            fraction: _VALID_FRACTION, sourceAccount: account, market: market
        });

        bytes memory callbackData = abi.encode(
            AccountSplitterAndMerger.CallbackData({
                operation: AccountSplitterAndMerger.Operation.SPLIT_ACCOUNT, data: abi.encode(params)
            })
        );

        // The extension can only be used via a delegation call.
        DelegationCallParams memory delegationCallParams =
            DelegationCallParams({delegatee: IDelegatee(address(_extension)), callbackData: callbackData});

        // It should revert with Office__AccountNotHealthy.
        // The account parameter in the error is the source account as it's queued first for health check.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.delegationCall(delegationCallParams);
    }

    // Test case 4: When caller is unauthorized
    function test_RevertWhenCallerIsUnauthorized()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
        whenCallerIsNotAuthorized // Required to be after `whenCallerIsOwner` so that the debt position can be created.

    {
        vm.startPrank(caller);

        AccountSplitterAndMerger.SplitAccountParams memory params = AccountSplitterAndMerger.SplitAccountParams({
            fraction: _VALID_FRACTION, sourceAccount: account, market: market
        });

        bytes memory callbackData = abi.encode(
            AccountSplitterAndMerger.CallbackData({
                operation: AccountSplitterAndMerger.Operation.SPLIT_ACCOUNT, data: abi.encode(params)
            })
        );

        // The extension can only be used via a delegation call.
        DelegationCallParams memory delegationCallParams =
            DelegationCallParams({delegatee: IDelegatee(address(_extension)), callbackData: callbackData});

        // It should revert with `Registry__InsufficientAllowance`.
        // We are not using exact revert encoding because the parameters (like allowance amount) may vary.
        vm.expectPartialRevert(IRegistry.Registry__InsufficientAllowance.selector);
        office.delegationCall(delegationCallParams);
    }

    // Test case 5: When the callback function is called directly (not via the Office)
    function test_RevertWhenCallbackFunctionCalledDirectly() external {
        vm.startPrank(caller);

        // It should revert with AccountSplitterAndMerger__OnlyOffice when the callback function is called directly.
        vm.expectRevert(
            abi.encodeWithSelector(AccountSplitterAndMerger.AccountSplitterAndMerger_OnlyOffice.selector, caller)
        );
        _extension.onDelegationCallback(bytes(""));
    }
}

// Generated using co-pilot: Claude Sonnet 4
