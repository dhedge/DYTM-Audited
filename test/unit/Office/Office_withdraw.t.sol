// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Office_withdraw is CommonScenarios {
    using TokenHelpers for *;
    using ReserveKeyLibrary for *;
    using SharesMathLib for uint256;

    function test_WhenWithdrawingLentAssetsFromAUserAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        IERC20 asset = tokenId.getAsset();
        uint256 underlyingBalanceBefore = asset.balanceOf(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: caller,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        uint256 assets = office.withdraw(params);

        // It should redeem correct amount of shares.
        assertEq(office.balanceOf(account, tokenId), 0, "Shares were not redeemed correctly");

        // It should update the reserve supplied amount.
        assertEq(office.getReserveData(key).supplied, 0, "Reserve supplied amount was not updated correctly");

        // It should give back correct amount of assets.
        assertEq(assets, accountSuppliedAmountBefore.usdcLentAmount, "Assets were not given back correctly");
        assertEq(
            asset.balanceOf(caller),
            underlyingBalanceBefore + accountSuppliedAmountBefore.usdcLentAmount,
            "Receiver balance after withdrawal is incorrect"
        );

        // Total supply should be updated.
        assertEq(office.totalSupply(tokenId), 0, "Total supply was not updated correctly");
    }

    function test_RevertWhen_WithdrawingLentAssetsFromAnAccountAndCallerIsNotAuthorized()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsNotAuthorized
        whenLendingAsset(usdcKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: caller,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.Registry__NotAuthorizedCaller.selector, account, caller));
        office.withdraw(params);
    }

    function test_WhenWithdrawingLentAssetsFromAnIsolatedAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        IERC20 asset = tokenId.getAsset();
        uint256 underlyingBalanceBefore = asset.balanceOf(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: caller,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        uint256 assets = office.withdraw(params);

        // It should redeem correct amount of shares.
        assertEq(office.balanceOf(account, tokenId), 0, "Shares were not redeemed correctly");

        // It should update the reserve supplied amount.
        assertEq(office.getReserveData(key).supplied, 0, "Reserve supplied amount was not updated correctly");

        // It should give back correct amount of assets.
        assertEq(assets, accountSuppliedAmountBefore.usdcLentAmount, "Assets were not given back correctly");
        assertEq(
            asset.balanceOf(caller),
            underlyingBalanceBefore + accountSuppliedAmountBefore.usdcLentAmount,
            "Receiver balance after withdrawal is incorrect"
        );

        // Total supply should be updated.
        assertEq(office.totalSupply(tokenId), 0, "Total supply was not updated correctly");
    }

    function test_WhenWithdrawingLentAssetsToARandomAddress()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        address receiver = makeAddr("receiver");

        vm.startPrank(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: receiver,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        uint256 assets = office.withdraw(params);

        // It should redeem correct amount of shares.
        assertEq(office.balanceOf(account, tokenId), 0, "Shares were not redeemed correctly");

        // It should update the reserve supplied amount.
        assertEq(office.getReserveData(key).supplied, 0, "Reserve supplied amount was not updated correctly");

        // It should give back correct amount of assets.
        assertEq(assets, accountSuppliedAmountBefore.usdcLentAmount, "Assets were not given back correctly");
        assertEq(
            tokenId.getAsset().balanceOf(receiver),
            accountSuppliedAmountBefore.usdcLentAmount,
            "Receiver balance after withdrawal is incorrect"
        );

        // Total supply should be updated.
        assertEq(office.totalSupply(tokenId), 0, "Total supply was not updated correctly");
    }

    function test_WhenWithdrawingEscrowedAssetsFromAUserAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenEscrowingAsset(wethKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        IERC20 asset = tokenId.getAsset();
        uint256 underlyingBalanceBefore = asset.balanceOf(caller);
        uint256 suppliedAmountBefore = office.getReserveData(key).supplied;

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: caller,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        uint256 assets = office.withdraw(params);

        // It should redeem correct amount of shares.
        assertEq(office.balanceOf(account, tokenId), 0, "Shares were not redeemed correctly");

        // It should not update the lending reserve supplied amount.
        assertEq(
            office.getReserveData(key).supplied, suppliedAmountBefore, "Reserve supplied amount should not be updated"
        );

        // It should give back correct amount of assets.
        assertEq(assets, accountSuppliedAmountBefore.wethEscrowedAmount, "Assets were not given back correctly");
        assertEq(
            asset.balanceOf(caller),
            underlyingBalanceBefore + accountSuppliedAmountBefore.wethEscrowedAmount,
            "Receiver balance after withdrawal is incorrect"
        );

        // Total supply should be updated.
        assertEq(office.totalSupply(tokenId), 0, "Total supply was not updated correctly");
    }

    function test_RevertWhen_WithdrawingEscrowedAssetsFromAnAccountAndCallerIsNotAuthorized()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsNotAuthorized
        whenEscrowingAsset(wethKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: caller,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.Registry__NotAuthorizedCaller.selector, account, caller));
        office.withdraw(params);
    }

    function test_WhenWithdrawingEscrowedAssetsFromAnIsolatedAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenEscrowingAsset(wethKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        IERC20 asset = tokenId.getAsset();
        uint256 underlyingBalanceBefore = asset.balanceOf(caller);
        uint256 suppliedAmountBefore = office.getReserveData(key).supplied;

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: caller,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        uint256 assets = office.withdraw(params);

        // It should redeem correct amount of shares.
        assertEq(office.balanceOf(account, tokenId), 0, "Shares were not redeemed correctly");

        // It should not update the lending reserve supplied amount.
        assertEq(
            office.getReserveData(key).supplied, suppliedAmountBefore, "Reserve supplied amount should not be updated"
        );

        // It should give back correct amount of assets.
        assertEq(assets, accountSuppliedAmountBefore.wethEscrowedAmount, "Assets were not given back correctly");
        assertEq(
            asset.balanceOf(caller),
            underlyingBalanceBefore + accountSuppliedAmountBefore.wethEscrowedAmount,
            "Receiver balance after withdrawal is incorrect"
        );

        // Total supply should be updated.
        assertEq(office.totalSupply(tokenId), 0, "Total supply was not updated correctly");
    }

    function test_WhenWithdrawingEscrowedAssetsToARandomAddress()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenEscrowingAsset(wethKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        address receiver = makeAddr("receiver");

        vm.startPrank(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: receiver,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        uint256 assets = office.withdraw(params);

        // It should redeem correct amount of shares.
        assertEq(office.balanceOf(account, tokenId), 0, "Shares were not redeemed correctly");

        // It should update the reserve supplied amount.
        assertEq(office.getReserveData(key).supplied, 0, "Reserve supplied amount was not updated correctly");

        // It should give back correct amount of assets.
        assertEq(assets, accountSuppliedAmountBefore.wethEscrowedAmount, "Assets were not given back correctly");
        assertEq(
            tokenId.getAsset().balanceOf(receiver),
            accountSuppliedAmountBefore.wethEscrowedAmount,
            "Receiver balance after withdrawal is incorrect"
        );

        // Total supply should be updated.
        assertEq(office.totalSupply(tokenId), 0, "Total supply was not updated correctly");
    }

    function test_RevertWhen_WithdrawingLentAssetsFromAnAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
    {
        vm.startPrank(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: caller,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.withdraw(params);
    }

    function test_RevertWhen_WithdrawingEscrowedAssetsFromAnAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenEscrowingAsset(wethKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenAccountIsUnhealthy
    {
        vm.startPrank(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: caller,
            shares: office.balanceOf(account, tokenId),
            extraData: "",
            assets: 0
        });

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.withdraw(params);
    }

    function test_WhenWithdrawingSomeLentAssetsFromAnAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenTheAccountWillBeHealthy
    {
        vm.startPrank(caller);

        IERC20 asset = tokenId.getAsset();
        uint256 underlyingBalanceBefore = asset.balanceOf(caller);
        uint256 totalSupplyBefore = office.totalSupply(tokenId);
        uint256 reserveSuppliedBefore = office.getReserveData(key).supplied;

        // `whenUsingSuppliedPlusEscrowedAssets` modifier supplies $3000 ($1000 in USDC and $2000 in WETH) to the
        // account.
        // `whenTheAccountHasADebtPosition` modifier borrows $2000 in USDC out of max borrowable $2200.
        // So the account still has $200 credit. We need to calculate the shares worth $200 in USDC to withdraw.
        uint256 assetsToWithdraw = 200e6; // $200 in USDC
        uint256 sharesToWithdraw = assetsToWithdraw.toSharesDown(reserveSuppliedBefore, office.totalSupply(tokenId));

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId, account: account, receiver: caller, assets: 0, shares: sharesToWithdraw, extraData: ""
        });

        uint256 assets = office.withdraw(params);

        // It should redeem correct amount of shares.
        assertEq(
            office.balanceOf(account, tokenId),
            accountSuppliedAmountBefore.usdcLendingShareAmount - sharesToWithdraw,
            "Shares were not redeemed correctly"
        );

        // It should update the reserve supplied amount.
        assertEq(
            office.getReserveData(key).supplied,
            reserveSuppliedBefore - assetsToWithdraw,
            "Reserve supplied amount was not updated correctly"
        );

        // It should give back correct amount of assets.
        assertEq(assets, assetsToWithdraw, "Assets were not given back correctly");
        assertEq(
            asset.balanceOf(caller),
            underlyingBalanceBefore + assetsToWithdraw,
            "Receiver balance after withdrawal is incorrect"
        );

        // Total supply should be updated.
        assertEq(
            office.totalSupply(tokenId), totalSupplyBefore - sharesToWithdraw, "Total supply was not updated correctly"
        );
    }

    function test_WhenWithdrawingSomeEscrowedAssetsFromAnAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenEscrowingAsset(wethKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenTheAccountWillBeHealthy
    {
        vm.startPrank(caller);

        IERC20 asset = tokenId.getAsset();
        uint256 underlyingBalanceBefore = asset.balanceOf(caller);
        uint256 totalSupplyBefore = office.totalSupply(tokenId);
        uint256 reserveSuppliedBefore = office.getReserveData(key).supplied;

        // `whenUsingSuppliedPlusEscrowedAssets` modifier supplies $3000 ($1000 in USDC and $2000 in WETH) to the
        // account.
        // `whenTheAccountHasADebtPosition` modifier borrows $2000 in USDC out of max borrowable $2200.
        // So the account still has $334 credit if removing WETH.
        uint256 assetsToWithdraw = oracleModule.getQuote(333e6, address(usdc), address(weth));
        uint256 sharesToWithdraw = assetsToWithdraw;

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId, account: account, receiver: caller, assets: 0, shares: sharesToWithdraw, extraData: ""
        });

        uint256 assets = office.withdraw(params);

        // It should redeem correct amount of shares.
        assertEq(
            office.balanceOf(account, tokenId),
            accountSuppliedAmountBefore.wethEscrowShareAmount - sharesToWithdraw,
            "Shares were not redeemed correctly"
        );

        // It should not update the reserve supplied amount.
        assertEq(
            office.getReserveData(key).supplied, reserveSuppliedBefore, "Reserve supplied amount should not be updated"
        );

        // It should give back correct amount of assets.
        assertEq(assets, assetsToWithdraw, "Assets were not given back correctly");
        assertEq(
            asset.balanceOf(caller),
            underlyingBalanceBefore + assetsToWithdraw,
            "Receiver balance after withdrawal is incorrect"
        );

        // Total supply should be updated.
        assertEq(
            office.totalSupply(tokenId), totalSupplyBefore - sharesToWithdraw, "Total supply was not updated correctly"
        );
    }

    function test_RevertWhen_WithdrawingAllLentAssetsFromAnAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenTheAccountWillBecomeUnhealthy
    {
        vm.startPrank(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: caller,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.withdraw(params);
    }

    function test_RevertWhen_WithdrawingAllEscrowedAssetsFromAnAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenEscrowingAsset(wethKey)
        whenUsingSuppliedPlusEscrowedAssets
        givenEnoughLiquidityInTheReserve
        whenTheAccountHasADebtPosition
        givenTheAccountWillBecomeUnhealthy
    {
        vm.startPrank(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId,
            account: account,
            receiver: caller,
            assets: 0,
            shares: office.balanceOf(account, tokenId),
            extraData: ""
        });

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.withdraw(params);
    }

    // Test case: When withdrawing using max uint256 shares amount - lent assets
    function test_WhenWithdrawingUsingMaxUint256SharesAmount_WhenWithdrawingLentAssetsFromAUserAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        IERC20 asset = tokenId.getAsset();
        uint256 underlyingBalanceBefore = asset.balanceOf(caller);
        uint256 reserveSuppliedBefore = office.getReserveData(key).supplied;
        uint256 totalSupplyBefore = office.totalSupply(tokenId);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId, account: account, receiver: caller, assets: 0, shares: type(uint256).max, extraData: ""
        });

        uint256 assetsWithdrawn = office.withdraw(params);

        // It should update the reserve supplied amount.
        assertEq(
            office.getReserveData(key).supplied,
            reserveSuppliedBefore - accountSuppliedAmountBefore.usdcLentAmount,
            "Reserve supplied amount incorrect"
        );

        // It should give back correct amount of assets.
        assertEq(assetsWithdrawn, accountSuppliedAmountBefore.usdcLentAmount, "Incorrect assets withdrawn");
        assertEq(
            asset.balanceOf(caller),
            underlyingBalanceBefore + accountSuppliedAmountBefore.usdcLentAmount,
            "Caller balance incorrect"
        );

        // It should burn the entire lent shares of the user.
        assertEq(office.balanceOf(account, tokenId), 0, "Lent shares not fully burned");

        // Total supply should update.
        assertEq(
            office.totalSupply(tokenId),
            totalSupplyBefore - accountSuppliedAmountBefore.usdcLendingShareAmount,
            "Total supply not updated"
        );
    }

    // Test case: When withdrawing using max uint256 shares amount - escrowed assets
    function test_WhenWithdrawingUsingMaxUint256SharesAmount_WhenWithdrawingEscrowedAssetsFromAUserAccount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenEscrowingAsset(wethKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        IERC20 asset = tokenId.getAsset();
        uint256 underlyingBalanceBefore = asset.balanceOf(caller);
        uint256 suppliedBefore = office.getReserveData(key).supplied;
        uint256 totalSupplyBefore = office.totalSupply(tokenId);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId, account: account, receiver: caller, assets: 0, shares: type(uint256).max, extraData: ""
        });

        uint256 assetsWithdrawn = office.withdraw(params);

        // It should not update the lending reserve supplied amount.
        assertEq(office.getReserveData(key).supplied, suppliedBefore, "Supplied amount should remain unchanged");

        // It should give back correct amount of assets.
        assertEq(assetsWithdrawn, accountSuppliedAmountBefore.wethEscrowedAmount, "Incorrect escrow assets withdrawn");
        assertEq(
            asset.balanceOf(caller),
            underlyingBalanceBefore + accountSuppliedAmountBefore.wethEscrowedAmount,
            "Caller balance incorrect"
        );

        // It should burn the entire escrow shares of the user.
        assertEq(office.balanceOf(account, tokenId), 0, "Escrow shares not fully burned");

        // Total supply should update.
        assertEq(
            office.totalSupply(tokenId),
            totalSupplyBefore - accountSuppliedAmountBefore.wethEscrowShareAmount,
            "Total supply not updated"
        );
    }

    // Test case: When withdrawing using assets amount - lent assets (partial)
    function test_WhenWithdrawingUsingAssetsAmount_WhenWithdrawingLentAssetsFromAUserAccount_GivenAmountIsLessThanBalance()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        IERC20 asset = tokenId.getAsset();
        uint256 underlyingBalanceBefore = asset.balanceOf(caller);
        uint256 reserveSuppliedBefore = office.getReserveData(key).supplied;
        uint256 totalSupplyBefore = office.totalSupply(tokenId);

        uint256 assetsToWithdraw = accountSuppliedAmountBefore.usdcLentAmount / 2; // less than balance
        uint256 expectedSharesRedeemed = assetsToWithdraw.toSharesUp(reserveSuppliedBefore, totalSupplyBefore);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId, account: account, receiver: caller, assets: assetsToWithdraw, shares: 0, extraData: ""
        });

        uint256 assetsWithdrawn = office.withdraw(params);

        // It should update the reserve supplied amount.
        assertEq(
            office.getReserveData(key).supplied,
            reserveSuppliedBefore - assetsToWithdraw,
            "Reserve supplied not decreased correctly"
        );

        // It should give back correct amount of assets.
        assertEq(assetsWithdrawn, assetsToWithdraw, "Incorrect partial assets withdrawn");
        assertEq(asset.balanceOf(caller), underlyingBalanceBefore + assetsToWithdraw, "Caller balance incorrect");

        // It should burn the correct amount of lent shares.
        assertEq(
            office.balanceOf(account, tokenId),
            accountSuppliedAmountBefore.usdcLendingShareAmount - expectedSharesRedeemed,
            "Incorrect lending shares burned"
        );
    }

    // Test case: When withdrawing using assets amount - lent assets (over-balance revert)
    function test_Revert_WhenWithdrawingUsingAssetsAmount_WhenWithdrawingLentAssetsFromAUserAccount_GivenAmountIsMoreThanBalance()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        uint256 overAssets = accountSuppliedAmountBefore.usdcLentAmount + 1;

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId, account: account, receiver: caller, assets: overAssets, shares: 0, extraData: ""
        });

        // It should revert.
        //     Due to underflow when subtracting the assets withdrawn amount from the total supplied amount.
        vm.expectRevert();
        office.withdraw(params);
    }

    // Test case: When withdrawing using assets amount - escrowed assets (partial)
    function test_WhenWithdrawingUsingAssetsAmount_WhenWithdrawingEscrowedAssetsFromAUserAccount_GivenAmountIsLessThanBalance()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenEscrowingAsset(wethKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        IERC20 asset = tokenId.getAsset();
        uint256 underlyingBalanceBefore = asset.balanceOf(caller);
        uint256 suppliedBefore = office.getReserveData(key).supplied;
        uint256 totalSupplyBefore = office.totalSupply(tokenId);

        uint256 assetsToWithdraw = accountSuppliedAmountBefore.wethEscrowedAmount / 2; // less than balance

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId, account: account, receiver: caller, assets: assetsToWithdraw, shares: 0, extraData: ""
        });

        uint256 assetsWithdrawn = office.withdraw(params);

        // It should not update the lending reserve supplied amount.
        assertEq(office.getReserveData(key).supplied, suppliedBefore, "Supplied amount should remain unchanged");

        // It should give back correct amount of assets.
        assertEq(assetsWithdrawn, assetsToWithdraw, "Incorrect escrow assets withdrawn");
        assertEq(asset.balanceOf(caller), underlyingBalanceBefore + assetsToWithdraw, "Caller balance incorrect");

        // It should burn the correct amount of escrow shares.
        assertEq(
            office.balanceOf(account, tokenId),
            accountSuppliedAmountBefore.wethEscrowShareAmount - assetsToWithdraw,
            "Incorrect escrow shares burned"
        );
        // Total supply should update.
        assertEq(
            office.totalSupply(tokenId), totalSupplyBefore - assetsToWithdraw, "Total supply not updated correctly"
        );
    }

    // Test case: When withdrawing using assets amount - escrowed assets (over-balance revert)
    function test_Revert_WhenWithdrawingUsingAssetsAmount_WhenWithdrawingEscrowedAssetsFromAUserAccount_GivenAmountIsMoreThanBalance()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenEscrowingAsset(wethKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        uint256 overAssets = accountSuppliedAmountBefore.wethEscrowedAmount + 1;

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId, account: account, receiver: caller, assets: overAssets, shares: 0, extraData: ""
        });

        // It should revert.
        //     With `IRegistry.Registry__InsufficientBalance` error.
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientBalance.selector,
                account,
                office.balanceOf(account, tokenId),
                overAssets, // escrow shares 1:1 mapping
                tokenId
            )
        );
        office.withdraw(params);
    }

    // Test case: When both assets and shares are provided (revert)
    function test_Revert_WhenWithdrawing_WhenBothAssetsAndSharesAreProvided()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
        givenAccountIsHealthy
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        WithdrawParams memory params = WithdrawParams({
            tokenId: tokenId, account: account, receiver: caller, assets: 100e6, shares: 1, extraData: ""
        });

        // It should revert.
        //     With `IOffice.Office__AssetsAndSharesNonZero` error.
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AssetsAndSharesNonZero.selector, 100e6, 1));
        office.withdraw(params);
    }
}

// Generated using co-pilot: GPT-4o
