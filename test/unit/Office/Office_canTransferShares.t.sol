// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Office_canTransferShares is CommonScenarios {
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;

    modifier whenMarketRestrictsSharesTransfer() {
        // Mock the market config to prevent share transfers.
        vm.mockCall(
            address(marketConfig), abi.encodeWithSelector(IMarketConfig.canTransferShares.selector), abi.encode(false)
        );
        _;
    }

    // Test case 1: Attempt to transfer collateral shares when the market restricts share transfers.
    function test_Revert_WhenMarketRestrictsSharesTransfer_WhenTransferringCollateralShares()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        whenUsingSuppliedPlusEscrowedAssets
        whenMarketRestrictsSharesTransfer
    {
        vm.startPrank(caller);

        uint256 amount = office.balanceOf(account, tokenId);

        vm.expectRevert(
            abi.encodeWithSelector(
                IOffice.Office__TransferNotAllowed.selector, account, bob.toUserAccount(), tokenId, amount
            )
        );
        office.transfer(bob, tokenId, amount);
    }

    // Test case 2: Attempt to transfer debt shares when the market restricts share transfers.
    function test_Revert_WhenMarketRestrictsSharesTransfer_WhenTransferringDebtShares()
        public
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        whenUsingSuppliedPlusEscrowedAssets
        givenSecondAccountIsSetup
        whenMarketRestrictsSharesTransfer
    {
        vm.startPrank(caller);

        tokenId = key.toDebtId();
        uint256 amount = 1;

        vm.expectRevert(
            abi.encodeWithSelector(IOffice.Office__TransferNotAllowed.selector, account2, account, tokenId, amount)
        );
        office.transferFrom({sender: account2, receiver: account, tokenId: tokenId, amount: amount});
    }

    // Test case 3: Attempt to transfer shares when the market allows share transfers.
    function test_WhenMarketAllowsSharesTransfer()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(key)
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        uint256 amount = office.balanceOf(account, tokenId);

        // Transfer to Bob
        office.transfer(bob, tokenId, amount);

        assertEq(office.balanceOf(bob, tokenId), amount, "Bob should receive the shares");
        assertEq(office.balanceOf(account, tokenId), 0, "Alice's shares should be reduced");
    }
}
