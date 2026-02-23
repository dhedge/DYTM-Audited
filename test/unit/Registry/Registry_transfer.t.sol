// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Registry_transfer is CommonScenarios {
    using ReserveKeyLibrary for ReserveKey;
    using TokenHelpers for uint256;
    using AccountIdLibrary for address;

    // Internal variables for test setup
    address internal _receiver = bob; // Default receiver
    uint256 internal _transferAmount; // Will be set based on AccountSuppliedAmount

    // Modifier to set minimum debt amount for testing minimum debt enforcement
    modifier whenMinDebtAmountIsSet() {
        vm.startPrank(admin);
        marketConfig.setMinDebtAmountUSD(1500e18); // Set minimum debt to $1500
        vm.stopPrank();
        _;
    }

    // Test case 1
    function test_WhenTheAccountHasADebtPosition_GivenAccountIsHealthy_ItShouldAllowCollateralTokenTransfer()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
    {
        // Test USDC lending token transfer
        key = usdcKey;
        tokenId = key.toLentId();
        _transferAmount = accountSuppliedAmountBefore.usdcLentAmount / 10; // Transfer a small amount to maintain health

        _testSuccessfulTransfer();

        // Test WETH escrow token transfer
        key = wethKey;
        tokenId = key.toEscrowId();
        _transferAmount = accountSuppliedAmountBefore.wethEscrowedAmount / 10; // Transfer a small amount to maintain health

        _testSuccessfulTransfer();
    }

    // Test case 2
    function test_Revert_WhenTheAccountHasADebtPosition_GivenAccountWillBeUnhealthy_ItShouldRevert()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
    {
        // Test USDC lending token transfer - should revert due to unhealthy account
        key = usdcKey;
        tokenId = key.toLentId();
        _transferAmount = accountSuppliedAmountBefore.usdcLentAmount / 2;

        _testRevertUnhealthyAccount();

        // Test WETH escrow token transfer - should revert due to unhealthy account
        key = wethKey;
        tokenId = key.toEscrowId();
        _transferAmount = accountSuppliedAmountBefore.wethEscrowedAmount / 2;

        _testRevertUnhealthyAccount();
    }

    // Test case 3
    function test_Revert_WhenTheAccountHasADebtPosition_GivenAccountsDebtWillBeBelowMinimumDebtAfterTransfer_ItShouldRevert()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenMinDebtAmountIsSet
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
        givenSecondAccountIsSetup
    {
        // Test debt token transfer - should revert due to debt falling below minimum
        // Transfer a portion of debt tokens that would leave the from account with debt below minimum
        key = usdcKey;
        tokenId = key.toDebtId();

        // Get current debt balance on the account
        uint256 debtBalance = office.balanceOf(account, tokenId);

        // Transfer half the debt, which would leave half (below the $1500 minimum)
        _transferAmount = debtBalance / 2;

        // Supply collateral to account2 so it can receive the debt transfer
        vm.startPrank(bob);
        office.supply(
            SupplyParams({
                account: account2,
                tokenId: wethKey.toEscrowId(),
                assets: 5e18, // Add 5 WETH ($10000) to ensure account2 can accept the debt
                extraData: ""
            })
        );

        vm.startPrank(caller);

        // It should revert with Office__DebtBelowMinimum error
        vm.expectPartialRevert(IOffice.Office__DebtBelowMinimum.selector);
        office.transferFrom(account, account2, tokenId, _transferAmount);
    }

    // Test case 4
    function test_Revert_WhenTheAccountHasADebtPosition_GivenRecipientAccountDebtWillBeBelowMinimumDebtAfterTransfer_ItShouldRevert()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenMinDebtAmountIsSet
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
    {
        // Prepare to transfer a small portion of debt so sender stays above minimum,
        // but recipient would end up below minimum debt after transfer (new recipient account with zero debt).
        key = usdcKey;
        tokenId = key.toDebtId();

        uint256 debtBalance = office.balanceOf(account, tokenId);
        _transferAmount = debtBalance / 10; // ~10% of debt; sender remains >= minimum

        // Create a new isolated recipient account owned by the caller with no prior debt
        vm.startPrank(caller);
        AccountId recipientAccount = office.createIsolatedAccount(caller);

        // Supply collateral to recipient so health is not a factor
        vm.startPrank(bob);
        office.supply(
            SupplyParams({account: recipientAccount, tokenId: wethKey.toEscrowId(), assets: 5e18, extraData: ""})
        );

        vm.startPrank(caller);

        // It should revert.
        //     With error `Office__DebtBelowMinimum`.
        vm.expectPartialRevert(IOffice.Office__DebtBelowMinimum.selector);
        office.transferFrom(account, recipientAccount, tokenId, _transferAmount);
    }

    // Test case 5
    function test_WhenTheAccountHasADebtPosition_GivenAccountsDebtWillBeZeroAfterTransfer_ItShouldAllowDebtTokenTransfer()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenMinDebtAmountIsSet
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenAccountIsHealthy
        givenSecondAccountIsSetup
    {
        // Test debt token transfer - should allow when debt becomes zero
        // Transfer all debt tokens so the from account has zero debt (which is allowed per the minimum debt check)
        key = usdcKey;
        tokenId = key.toDebtId();

        // Before transferring debt to account2, supply more collateral to keep it healthy
        // account2 already has 1000 USDC + 1 WETH ($2000) collateral and $2000 debt (total $3000 collateral)
        // When we transfer $2000 more debt to it, it will have $4000 debt total
        // So we need to add enough collateral to maintain health (requires sufficient collateral at weighted amounts)
        vm.startPrank(bob);
        office.supply(
            SupplyParams({
                account: account2,
                tokenId: wethKey.toEscrowId(),
                assets: 5e18, // Add 5 more WETH ($10000) for a total of 6 WETH ($12000) + 1000 USDC = $13000 collateral
                extraData: ""
            })
        );

        // Get the actual debt balance to transfer all of it
        uint256 debtBalance = office.balanceOf(account, tokenId);
        _transferAmount = debtBalance;

        // Perform the transfer from alice to account2
        vm.startPrank(caller);
        uint256 initialToBalance = office.balanceOf(account2, tokenId);

        office.transferFrom(account, account2, tokenId, _transferAmount);

        // It should allow debt token transfer (debt becomes zero for alice's account)
        assertEq(office.balanceOf(account, tokenId), 0, "From balance incorrect");
        assertEq(office.balanceOf(account2, tokenId), initialToBalance + _transferAmount, "To balance incorrect");
    }

    // Test case 6
    function test_Revert_GivenRecipientAccountIsNotOwnedByCaller_WhenTransferringDebtToken()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
    {
        // Supply collateral to bob's user account to keep it healthy
        vm.startPrank(bob);
        office.supply(
            SupplyParams({account: bob.toUserAccount(), tokenId: key.toLentId(), assets: 100_000e6, extraData: ""})
        );

        uint256 debtTokenId = key.toDebtId();
        uint256 transferAmount = office.balanceOf(account, debtTokenId) / 2;

        // Caller tries to transfer debt to bob's user account (different owner)
        vm.startPrank(caller);

        // It should revert with Registry__DifferentOwnersWhenTransferringDebt
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__DifferentOwnersWhenTransferringDebt.selector,
                caller.toUserAccount(),
                bob.toUserAccount(),
                caller,
                bob,
                debtTokenId
            )
        );
        office.transfer(bob, debtTokenId, transferAmount);
    }

    /////////////////////////////////////////////
    //                 Helpers                 //
    /////////////////////////////////////////////

    function _testSuccessfulTransfer() internal {
        uint256 initialFromBalance = office.balanceOf(account, tokenId);
        uint256 initialToBalance = office.balanceOf(_receiver.toUserAccount(), tokenId);

        vm.startPrank(caller);
        office.transfer(_receiver, tokenId, _transferAmount);

        // It should allow collateral token transfer
        assertEq(office.balanceOf(account, tokenId), initialFromBalance - _transferAmount, "From balance incorrect");
        assertEq(
            office.balanceOf(_receiver.toUserAccount(), tokenId),
            initialToBalance + _transferAmount,
            "To balance incorrect"
        );
    }

    function _testRevertUnhealthyAccount() internal {
        MarketId marketId = key.getMarketId();

        vm.startPrank(caller);

        // It should revert with Office__AccountNotHealthy error
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, marketId));
        office.transfer(_receiver, tokenId, _transferAmount);
    }
}

// Generated using co-pilot: GPT-5
