// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../../shared/CommonScenarios.sol";
import {AccountSplitterAndMerger} from "../../../../src/extensions/delegatees/AccountSplitterAndMerger.sol";

contract AccountSplitterAndMerger_mergeAccounts is CommonScenarios {
    using ReserveKeyLibrary for *;
    using MarketIdLibrary for *;
    using AccountIdLibrary for *;
    using FixedPointMathLib for uint256;

    uint64 internal constant _VALID_FRACTION = uint64(0.5e18); // 50%
    uint64 internal constant _FULL_FRACTION = uint64(1e18); // 100%
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
        givenSecondAccountIsSetup
    {
        vm.startPrank(caller);

        // Store original balances - reuse accountSuppliedAmountBefore for recipient account
        uint256 originalRecipientUsdcCollateral = accountSuppliedAmountBefore.usdcLendingShareAmount;
        uint256 originalRecipientWethCollateral = accountSuppliedAmountBefore.wethEscrowShareAmount;
        uint256 originalRecipientDebt = office.balanceOf(account, usdcKey.toDebtId());

        uint256 originalSourceUsdcCollateral = office.balanceOf(account2, usdcKey.toLentId());
        uint256 originalSourceWethCollateral = office.balanceOf(account2, wethKey.toEscrowId());
        uint256 originalSourceDebt = office.balanceOf(account2, usdcKey.toDebtId());

        AccountSplitterAndMerger.MergeAccountsParams memory params = AccountSplitterAndMerger.MergeAccountsParams({
            fraction: _VALID_FRACTION, sourceAccount: account2, recipientAccount: account, market: market
        });

        bytes memory callbackData = abi.encode(
            AccountSplitterAndMerger.CallbackData({
                operation: AccountSplitterAndMerger.Operation.MERGE_ACCOUNTS, data: abi.encode(params)
            })
        );

        // The extension can only be used via a delegation call.
        DelegationCallParams memory delegationCallParams =
            DelegationCallParams({delegatee: IDelegatee(address(_extension)), callbackData: callbackData});

        office.delegationCall(delegationCallParams);

        // It should transfer correct fraction of collateral shares from source to recipient.
        uint256 expectedUsdcTransfer = originalSourceUsdcCollateral.mulWadDown(_VALID_FRACTION);
        uint256 expectedWethTransfer = originalSourceWethCollateral.mulWadDown(_VALID_FRACTION);
        assertEq(
            office.balanceOf(account, usdcKey.toLentId()),
            originalRecipientUsdcCollateral + expectedUsdcTransfer,
            "Recipient should receive correct fraction of USDC collateral"
        );
        assertEq(
            office.balanceOf(account, wethKey.toEscrowId()),
            originalRecipientWethCollateral + expectedWethTransfer,
            "Recipient should receive correct fraction of WETH collateral"
        );

        // It should transfer correct fraction of debt shares from source to recipient.
        uint256 expectedDebtTransfer = originalSourceDebt.mulWadDown(_VALID_FRACTION);
        assertEq(
            office.balanceOf(account, usdcKey.toDebtId()),
            originalRecipientDebt + expectedDebtTransfer,
            "Recipient should receive correct fraction of debt shares"
        );
    }

    // Test case 2: Given account is healthy + Given fraction is 1e18
    function test_GivenAccountIsHealthy_GivenFractionIs1e18()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
        givenSecondAccountIsSetup
    {
        vm.startPrank(caller);

        // Store original balances - reuse accountSuppliedAmountBefore for recipient account
        uint256 originalRecipientUsdcCollateral = accountSuppliedAmountBefore.usdcLendingShareAmount;
        uint256 originalRecipientWethCollateral = accountSuppliedAmountBefore.wethEscrowShareAmount;
        uint256 originalRecipientDebt = office.balanceOf(account, usdcKey.toDebtId());

        uint256 originalSourceUsdcCollateral = office.balanceOf(account2, usdcKey.toLentId());
        uint256 originalSourceWethCollateral = office.balanceOf(account2, wethKey.toEscrowId());
        uint256 originalSourceDebt = office.balanceOf(account2, usdcKey.toDebtId());

        AccountSplitterAndMerger.MergeAccountsParams memory params = AccountSplitterAndMerger.MergeAccountsParams({
            fraction: _FULL_FRACTION, sourceAccount: account2, recipientAccount: account, market: market
        });

        bytes memory callbackData = abi.encode(
            AccountSplitterAndMerger.CallbackData({
                operation: AccountSplitterAndMerger.Operation.MERGE_ACCOUNTS, data: abi.encode(params)
            })
        );

        // The extension can only be used via a delegation call.
        DelegationCallParams memory delegationCallParams =
            DelegationCallParams({delegatee: IDelegatee(address(_extension)), callbackData: callbackData});

        office.delegationCall(delegationCallParams);

        // It should transfer all collateral shares from source to recipient.
        assertEq(
            office.balanceOf(account, usdcKey.toLentId()),
            originalRecipientUsdcCollateral + originalSourceUsdcCollateral,
            "Recipient should receive all USDC collateral from source"
        );
        assertEq(
            office.balanceOf(account, wethKey.toEscrowId()),
            originalRecipientWethCollateral + originalSourceWethCollateral,
            "Recipient should receive all WETH collateral from source"
        );

        // It should transfer all debt shares from source to recipient.
        assertEq(
            office.balanceOf(account, usdcKey.toDebtId()),
            originalRecipientDebt + originalSourceDebt,
            "Recipient should receive all debt shares from source"
        );

        // Source account should have zero balances after full merge
        assertEq(
            office.balanceOf(account2, usdcKey.toLentId()), 0, "Source account should have no USDC collateral left"
        );
        assertEq(
            office.balanceOf(account2, wethKey.toEscrowId()), 0, "Source account should have no WETH collateral left"
        );
        assertEq(office.balanceOf(account2, usdcKey.toDebtId()), 0, "Source account should have no debt left");
    }

    // Test case 3: Given account is healthy + Given invalid fraction
    function test_RevertGivenAccountIsHealthy_GivenInvalidFraction()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
        givenSecondAccountIsSetup
    {
        vm.startPrank(caller);

        AccountSplitterAndMerger.MergeAccountsParams memory params = AccountSplitterAndMerger.MergeAccountsParams({
            fraction: _INVALID_FRACTION, sourceAccount: account2, recipientAccount: account, market: market
        });

        bytes memory callbackData = abi.encode(
            AccountSplitterAndMerger.CallbackData({
                operation: AccountSplitterAndMerger.Operation.MERGE_ACCOUNTS, data: abi.encode(params)
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

    // Test case 4: Given account is unhealthy
    function test_RevertGivenAccountIsUnhealthy()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        givenSecondAccountIsSetup // Setting up second account before reducing the WETH price in `givenAccountIsUnhealthy`
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy // This means the source account needs to be `account` instead of `account2`

    {
        vm.startPrank(caller);

        AccountSplitterAndMerger.MergeAccountsParams memory params = AccountSplitterAndMerger.MergeAccountsParams({
            fraction: _VALID_FRACTION, sourceAccount: account, recipientAccount: account2, market: market
        });

        bytes memory callbackData = abi.encode(
            AccountSplitterAndMerger.CallbackData({
                operation: AccountSplitterAndMerger.Operation.MERGE_ACCOUNTS, data: abi.encode(params)
            })
        );

        // The extension can only be used via a delegation call.
        DelegationCallParams memory delegationCallParams =
            DelegationCallParams({delegatee: IDelegatee(address(_extension)), callbackData: callbackData});

        // It should revert with Office__AccountNotHealthy for the source account.
        // The source account becomes unhealthy due to the reduced WETH price,
        // and the merge operation cannot proceed from an unhealthy source.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.delegationCall(delegationCallParams);
    }

    // Test case 5: When caller of source account is unauthorized
    function test_RevertWhenCallerIsUnauthorized()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
        givenSecondAccountIsSetup
    {
        vm.startPrank(bob);

        AccountSplitterAndMerger.MergeAccountsParams memory params = AccountSplitterAndMerger.MergeAccountsParams({
            fraction: _VALID_FRACTION, sourceAccount: account2, recipientAccount: account, market: market
        });

        bytes memory callbackData = abi.encode(
            AccountSplitterAndMerger.CallbackData({
                operation: AccountSplitterAndMerger.Operation.MERGE_ACCOUNTS, data: abi.encode(params)
            })
        );

        // The extension can only be used via a delegation call.
        DelegationCallParams memory delegationCallParams =
            DelegationCallParams({delegatee: IDelegatee(address(_extension)), callbackData: callbackData});

        // It should revert with Registry__InsufficientAllowance because the caller is not authorized to act on behalf of the source account.
        // We are not using exact revert encoding because the parameters (like allowance amount) may vary.
        vm.expectPartialRevert(IRegistry.Registry__InsufficientAllowance.selector);
        office.delegationCall(delegationCallParams);
    }
}

// Generated using co-pilot: Claude Sonnet 3.5
