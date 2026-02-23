// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Office_switchCollateral is CommonScenarios {
    using SharesMathLib for uint256;
    using ReserveKeyLibrary for *;

    modifier whenSwitchingCollateralFromLendingToEscrow() {
        _;
    }

    modifier givenSwitchingToHigherWeightCollateral() {
        // Mock weights to make escrow have lower weight than lending
        // This simulates switching from lower to higher weight collateral
        key = wethKey;
        tokenId = key.toEscrowId();
        uint256 lendingTokenId = key.toLentId();

        IWeights weightsContract = marketConfig.weights();

        // Mock escrow weight to be 0.5 (50%)
        vm.mockCall(
            address(weightsContract),
            abi.encodeWithSelector(IWeights.getWeight.selector, account, tokenId, usdcKey),
            abi.encode(uint64(0.5e18))
        );

        // Mock lending weight to be 0.6 (60%) - higher than escrow
        vm.mockCall(
            address(weightsContract),
            abi.encodeWithSelector(IWeights.getWeight.selector, account, lendingTokenId, usdcKey),
            abi.encode(uint64(0.6e18))
        );

        _;

        vm.clearMockedCalls();
    }

    modifier givenSwitchingToLowerWeightCollateral() {
        // Mock weights to make escrow have higher weight than lending
        // This simulates switching from higher to lower weight collateral
        key = wethKey;
        tokenId = key.toEscrowId();
        uint256 lendingTokenId = key.toLentId();

        IWeights weightsContract = marketConfig.weights();

        // Mock escrow weight to be 0.6 (60%)
        vm.mockCall(
            address(weightsContract),
            abi.encodeWithSelector(IWeights.getWeight.selector, account, tokenId, usdcKey),
            abi.encode(uint64(0.6e18))
        );

        // Mock lending weight to be 0.3 (30%) - lower than escrow
        vm.mockCall(
            address(weightsContract),
            abi.encodeWithSelector(IWeights.getWeight.selector, account, lendingTokenId, usdcKey),
            abi.encode(uint64(0.3e18))
        );

        _;

        vm.clearMockedCalls();
    }

    function test_WhenTheUserSwitchesCollateralFromEscrowToLending()
        external
        whenReserveExists
        whenEscrowingAsset(wethKey) // Sets tokenId to WETH escrow tokenId.
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        uint256 expectedWethLendingShareAmount = accountSuppliedAmountBefore.wethEscrowedAmount
            .toSharesDown(office.getReserveData(key).supplied, office.totalSupply(key.toLentId()));

        // It should switch an escrow collateral to lending collateral
        office.switchCollateral(
            SwitchCollateralParams({
                account: account, tokenId: tokenId, assets: 0, shares: accountSuppliedAmountBefore.wethEscrowShareAmount
            })
        );

        // It should increase the supplied amount
        assertEq(
            office.getReserveData(key).supplied,
            accountSuppliedAmountBefore.wethLentAmount + accountSuppliedAmountBefore.wethEscrowedAmount,
            "Supplied amount should be increased"
        );

        // It should burn the escrow shares
        assertEq(office.balanceOf(account, tokenId), 0, "All escrow shares should be burned");

        // It should mint the lending shares
        assertEq(
            office.balanceOf(account, key.toLentId()),
            expectedWethLendingShareAmount + accountSuppliedAmountBefore.wethLendingShareAmount,
            "Lending shares should be minted"
        );
    }

    function test_GivenEnoughLiquidityToSwitch()
        external
        whenReserveExists
        whenLendingAsset(usdcKey) // Sets tokenId to USDC lending tokenId.
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenSwitchingCollateralFromLendingToEscrow
    {
        vm.startPrank(caller);

        uint256 expectedUsdcEscrowShareAmount = accountSuppliedAmountBefore.usdcLendingShareAmount
            .toAssetsDown(office.getReserveData(key).supplied, office.totalSupply(tokenId));

        uint256 usdcSuppliedAmountBefore = office.getReserveData(key).supplied;

        // It should switch a lending collateral to escrow collateral
        office.switchCollateral(
            SwitchCollateralParams({
                account: account,
                tokenId: tokenId,
                assets: 0,
                shares: accountSuppliedAmountBefore.usdcLendingShareAmount
            })
        );

        // It should decrease the supplied amount
        assertEq(
            office.getReserveData(key).supplied,
            usdcSuppliedAmountBefore - accountSuppliedAmountBefore.usdcLentAmount,
            "Supplied amount should be decreased"
        );

        // It should burn the lending shares
        assertEq(office.balanceOf(account, tokenId), 0, "All lending shares should be burned");

        // It should mint the escrow shares
        assertEq(
            office.balanceOf(account, key.toEscrowId()),
            expectedUsdcEscrowShareAmount + accountSuppliedAmountBefore.usdcEscrowShareAmount,
            "Escrow shares should be minted"
        );
    }

    function test_RevertGiven_NotEnoughLiquidityToSwitch()
        external
        whenReserveExists
        whenLendingAsset(usdcKey) // Sets tokenId to USDC lending tokenId.
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenSwitchingCollateralFromLendingToEscrow
    {
        // It should revert.
        //     With `Office__InsufficientLiquidity` error.

        vm.startPrank(caller);

        // Mock the borrow to make sure there is not any liquidity to switch.
        mockBorrow(key, office.getReserveData(key).supplied);

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__InsufficientLiquidity.selector, key, 0));
        office.switchCollateral(
            SwitchCollateralParams({
                account: account,
                tokenId: tokenId,
                assets: 0,
                shares: accountSuppliedAmountBefore.usdcLendingShareAmount
            })
        );
    }

    // Test case 4: When the account has a debt position - switching to collateral with higher weight
    function test_WhenTheAccountHasADebtPosition_GivenSwitchingToCollateralWithHigherWeight_ItShouldAllowTheUserToSwitchCollateral()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenSwitchingToHigherWeightCollateral
    {
        // It should allow the user to switch collateral
        // Switching from escrow (weight 0.5) to lending (weight 0.6) increases the weighted collateral

        vm.startPrank(caller);

        uint256 expectedWethLendingShareAmount = accountSuppliedAmountBefore.wethEscrowedAmount
            .toSharesDown(office.getReserveData(key).supplied, office.totalSupply(key.toLentId()));

        // It should switch an escrow collateral to lending collateral
        office.switchCollateral(
            SwitchCollateralParams({
                account: account, tokenId: tokenId, assets: 0, shares: accountSuppliedAmountBefore.wethEscrowShareAmount
            })
        );

        // It should increase the supplied amount
        assertEq(
            office.getReserveData(key).supplied,
            accountSuppliedAmountBefore.wethLentAmount + accountSuppliedAmountBefore.wethEscrowedAmount,
            "Supplied amount should be increased"
        );

        // It should burn the escrow shares
        assertEq(office.balanceOf(account, tokenId), 0, "All escrow shares should be burned");

        // It should mint the lending shares
        assertEq(
            office.balanceOf(account, key.toLentId()),
            expectedWethLendingShareAmount + accountSuppliedAmountBefore.wethLendingShareAmount,
            "Lending shares should be minted"
        );
    }

    // Test case 5: When the account has a debt position - switching to lower weight and account becomes unhealthy
    function test_RevertWhenTheAccountHasADebtPosition_GivenSwitchingToCollateralWithLowerWeight_WhenTheAccountWillBecomeUnhealthy()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenSwitchingToLowerWeightCollateral
    {
        // It should revert.
        //     With `Office__AccountNotHealthy` error.

        // With default WETH price of $2000:
        // Current collateral: 1 WETH escrowed at weight 0.6 + 1000 USDC lent at weight 1.0
        // Current debt: 2000 USDC
        // Before switch (escrow weight 0.6): (1 * 2000 * 0.6) + 1000 = 1200 + 1000 = 2200 >= 2000 (healthy)
        // After switch (lending weight 0.3): (1 * 2000 * 0.3) + 1000 = 600 + 1000 = 1600 < 2000 (unhealthy)

        vm.startPrank(caller);

        // Switching WETH from escrow to lending will reduce weight and make account unhealthy
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, market));
        office.switchCollateral(
            SwitchCollateralParams({
                account: account, tokenId: tokenId, assets: 0, shares: accountSuppliedAmountBefore.wethEscrowShareAmount
            })
        );
    }

    // Test case 6: When the account has a debt position - switching to lower weight but account remains healthy
    function test_WhenTheAccountHasADebtPosition_GivenSwitchingToCollateralWithLowerWeight_WhenTheAccountWillRemainHealthy()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenSwitchingToLowerWeightCollateral
    {
        // It should allow the user to switch collateral
        // Using the modifier with escrow weight 0.6 and lending weight 0.3
        // Need to add more collateral to keep the account healthy after the switch

        vm.startPrank(caller);

        // Add more WETH to escrow to ensure account remains healthy after switch
        // With 1 WETH escrowed at weight 0.6: (1 * 2000 * 0.6) = $1200
        // After switch at weight 0.3: (1 * 2000 * 0.3) = $600 (not enough)
        // Need 2 WETH: (2 * 2000 * 0.3) = $1200, total = $1200 + $1000 USDC = $2200 >= $2000 (healthy)
        office.supply(
            SupplyParams({
                tokenId: tokenId,
                account: account,
                assets: 1e18, // Add 1 more WETH
                extraData: ""
            })
        );

        uint256 totalEscrowShares = accountSuppliedAmountBefore.wethEscrowShareAmount + 1e18;
        uint256 lendingTokenId = key.toLentId();

        uint256 expectedWethLendingShareAmount = (accountSuppliedAmountBefore.wethEscrowedAmount + 1e18)
        .toSharesDown(office.getReserveData(key).supplied, office.totalSupply(lendingTokenId));

        // It should switch all escrow collateral to lending collateral
        office.switchCollateral(
            SwitchCollateralParams({account: account, tokenId: tokenId, assets: 0, shares: totalEscrowShares})
        );

        // It should increase the supplied amount
        assertEq(
            office.getReserveData(key).supplied,
            accountSuppliedAmountBefore.wethLentAmount + accountSuppliedAmountBefore.wethEscrowedAmount + 1e18,
            "Supplied amount should be increased"
        );

        // It should burn all escrow shares
        assertEq(office.balanceOf(account, tokenId), 0, "All escrow shares should be burned");

        // It should mint the lending shares
        assertEq(
            office.balanceOf(account, lendingTokenId),
            expectedWethLendingShareAmount + accountSuppliedAmountBefore.wethLendingShareAmount,
            "Lending shares should be minted"
        );
    }

    // Test case 7: Given not enough shares
    function test_RevertGiven_NotEnoughShares()
        external
        whenReserveExists
        whenLendingAsset(usdcKey) // Sets tokenId to USDC lending tokenId.
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenSwitchingCollateralFromLendingToEscrow
    {
        // It should revert.
        //     With `Office__InsufficientBalance` error.

        vm.startPrank(caller);

        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientBalance.selector,
                account,
                accountSuppliedAmountBefore.usdcLendingShareAmount,
                accountSuppliedAmountBefore.usdcLendingShareAmount + 1,
                tokenId
            )
        );
        office.switchCollateral(
            SwitchCollateralParams({
                account: account,
                tokenId: tokenId,
                assets: 0,
                shares: accountSuppliedAmountBefore.usdcLendingShareAmount + 1
            })
        );

        key = wethKey;
        tokenId = key.toEscrowId();

        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientBalance.selector,
                account,
                accountSuppliedAmountBefore.wethEscrowShareAmount,
                accountSuppliedAmountBefore.wethEscrowShareAmount + 1,
                tokenId
            )
        );
        office.switchCollateral(
            SwitchCollateralParams({
                account: account,
                tokenId: tokenId,
                assets: 0,
                shares: accountSuppliedAmountBefore.wethEscrowShareAmount + 1
            })
        );
    }

    // Test case 8: When the user provides max uint256 shares to switch - escrow -> lending
    function test_WhenUserProvidesMaxUint256Shares_WhenSwitchingEscrowToLending_ItShouldSwitchEntireEscrowBalance()
        external
        whenReserveExists
        whenEscrowingAsset(wethKey) // tokenId => WETH escrow
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        // Pre-state
        uint256 escrowSharesBefore = office.balanceOf(account, tokenId);
        uint256 suppliedBefore = office.getReserveData(key).supplied; // WETH supplied (lent) before
        uint256 lendingTokenId = key.toLentId();
        uint256 lendingTotalSupplyBefore = office.totalSupply(lendingTokenId);

        // Expected lending shares minted for all escrowed assets
        uint256 expectedLendingShares = accountSuppliedAmountBefore.wethEscrowedAmount
            .toSharesDown(office.getReserveData(key).supplied, lendingTotalSupplyBefore);

        // It should switch the entire escrow balance of the user.
        office.switchCollateral(
            SwitchCollateralParams({account: account, tokenId: tokenId, assets: 0, shares: type(uint256).max})
        );

        // It should increase the supplied amount.
        assertEq(
            office.getReserveData(key).supplied,
            suppliedBefore + accountSuppliedAmountBefore.wethEscrowedAmount,
            "Supplied amount not increased by full escrow amount"
        );

        // It should burn the entire escrow shares of the user.
        assertEq(office.balanceOf(account, tokenId), 0, "Escrow shares should be fully burned");

        // It should mint the correct amount of lending shares.
        assertEq(
            office.balanceOf(account, lendingTokenId),
            accountSuppliedAmountBefore.wethLendingShareAmount + expectedLendingShares,
            "Incorrect lending shares minted"
        );
        assertEq(escrowSharesBefore, accountSuppliedAmountBefore.wethEscrowShareAmount, "Pre-state mismatch");
    }

    // Test case 9: When the user provides max uint256 shares to switch - lending -> escrow
    function test_WhenUserProvidesMaxUint256Shares_GivenEnoughLiquidity_WhenSwitchingLendingToEscrow_ItShouldSwitchEntireLendingBalance()
        external
        whenReserveExists
        whenLendingAsset(usdcKey) // tokenId => USDC lending
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenSwitchingCollateralFromLendingToEscrow
    {
        vm.startPrank(caller);

        // Pre-state
        uint256 lendingSharesBefore = office.balanceOf(account, tokenId);
        uint256 suppliedBefore = office.getReserveData(key).supplied; // USDC supplied before
        uint256 escrowTokenId = key.toEscrowId();

        // Expected escrow shares (1:1 with assets withdrawn). Compute underlying assets for all lending shares.
        uint256 expectedAssets = accountSuppliedAmountBefore.usdcLendingShareAmount
        .toAssetsDown(suppliedBefore, office.totalSupply(tokenId));

        // It should switch the entire lending balance of the user.
        office.switchCollateral(
            SwitchCollateralParams({account: account, tokenId: tokenId, assets: 0, shares: type(uint256).max})
        );

        // It should decrease the supplied amount.
        assertEq(
            office.getReserveData(key).supplied,
            suppliedBefore - accountSuppliedAmountBefore.usdcLentAmount,
            "Supplied amount not decreased by full lent amount"
        );

        // It should burn the entire lending shares of the user.
        assertEq(office.balanceOf(account, tokenId), 0, "Lending shares should be fully burned");

        // It should mint the correct amount of escrow shares.
        assertEq(
            office.balanceOf(account, escrowTokenId),
            accountSuppliedAmountBefore.usdcEscrowShareAmount + expectedAssets,
            "Incorrect escrow shares minted"
        );
        assertEq(lendingSharesBefore, accountSuppliedAmountBefore.usdcLendingShareAmount, "Pre-state mismatch");
    }

    // Test case 10: When the user provides assets amount less than balance - escrow -> lending
    function test_WhenUserProvidesAssetsAmount_LessThanBalance_WhenSwitchingEscrowToLending_ItShouldSwitchSpecifiedAmount()
        external
        whenReserveExists
        whenEscrowingAsset(wethKey)
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        uint256 partialAssets = accountSuppliedAmountBefore.wethEscrowedAmount / 2; // strictly less than balance
        uint256 suppliedBefore = office.getReserveData(key).supplied;
        uint256 lendingTokenId = key.toLentId();
        uint256 lendingTotalSupplyBefore = office.totalSupply(lendingTokenId);

        uint256 expectedLendingShares =
            partialAssets.toSharesDown(office.getReserveData(key).supplied, lendingTotalSupplyBefore);

        // It should switch the specified amount of escrow to lending.
        office.switchCollateral(
            SwitchCollateralParams({account: account, tokenId: tokenId, assets: partialAssets, shares: 0})
        );

        // It should increase the supplied amount.
        assertEq(
            office.getReserveData(key).supplied,
            suppliedBefore + partialAssets,
            "Supplied amount not increased by partial amount"
        );

        // It should burn the correct amount of escrow shares.
        assertEq(
            office.balanceOf(account, tokenId),
            accountSuppliedAmountBefore.wethEscrowShareAmount - partialAssets,
            "Incorrect escrow shares burned"
        );

        // It should mint the correct amount of lending shares.
        assertEq(
            office.balanceOf(account, lendingTokenId),
            accountSuppliedAmountBefore.wethLendingShareAmount + expectedLendingShares,
            "Incorrect lending shares minted"
        );
    }

    // Test case 11: When the user provides assets amount less than balance - lending -> escrow (with liquidity)
    function test_WhenUserProvidesAssetsAmount_LessThanBalance_GivenEnoughLiquidity_WhenSwitchingLendingToEscrow_ItShouldSwitchSpecifiedAmount()
        external
        whenReserveExists
        whenLendingAsset(usdcKey)
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenSwitchingCollateralFromLendingToEscrow
    {
        vm.startPrank(caller);

        uint256 partialAssets = accountSuppliedAmountBefore.usdcLentAmount / 2; // strictly less than balance
        uint256 suppliedBefore = office.getReserveData(key).supplied;
        uint256 escrowTokenId = key.toEscrowId();

        // Convert underlying assets to shares that will be burned
        uint256 sharesToBurn = partialAssets.toSharesUp(suppliedBefore, office.totalSupply(tokenId));

        // It should switch the specified amount of lending to escrow.
        office.switchCollateral(
            SwitchCollateralParams({account: account, tokenId: tokenId, assets: partialAssets, shares: 0})
        );

        // It should decrease the supplied amount.
        assertEq(
            office.getReserveData(key).supplied,
            suppliedBefore - partialAssets,
            "Supplied amount not decreased by partial amount"
        );

        // It should burn the correct amount of lending shares.
        assertEq(
            office.balanceOf(account, tokenId),
            accountSuppliedAmountBefore.usdcLendingShareAmount - sharesToBurn,
            "Incorrect lending shares burned"
        );

        // It should mint the correct amount of escrow shares.
        assertEq(
            office.balanceOf(account, escrowTokenId),
            accountSuppliedAmountBefore.usdcEscrowShareAmount + partialAssets,
            "Incorrect escrow shares minted"
        );
    }

    // Test case 12: When the user provides assets amount more than balance - escrow -> lending (revert)
    function test_Revert_WhenUserProvidesAssetsAmount_MoreThanBalance_WhenSwitchingEscrowToLending()
        external
        whenReserveExists
        whenEscrowingAsset(wethKey)
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        vm.startPrank(caller);

        uint256 overAssets = accountSuppliedAmountBefore.wethEscrowedAmount + 1;

        // It should revert.
        //     With `Registry__InsufficientBalance` error.
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientBalance.selector,
                account,
                accountSuppliedAmountBefore.wethEscrowShareAmount,
                overAssets, // requested assets exceed shares (1:1)
                tokenId
            )
        );
        office.switchCollateral(
            SwitchCollateralParams({account: account, tokenId: tokenId, assets: overAssets, shares: 0})
        );
    }

    // Test case 13: When the user provides assets amount more than balance - lending -> escrow (revert)
    function test_Revert_WhenUserProvidesAssetsAmount_MoreThanBalance_GivenEnoughLiquidity_WhenSwitchingLendingToEscrow()
        external
        whenReserveExists
        whenLendingAsset(usdcKey)
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenSwitchingCollateralFromLendingToEscrow
    {
        vm.startPrank(caller);

        uint256 overAssets = accountSuppliedAmountBefore.usdcLentAmount + 1;
        uint256 suppliedBefore = office.getReserveData(key).supplied;
        uint256 totalSupplyBefore = office.totalSupply(tokenId);

        // Determine corresponding shares (rounded up) that would be needed for overAssets.
        uint256 neededShares = overAssets.toSharesUp(suppliedBefore, totalSupplyBefore);

        // It should revert.
        //     With `Registry__InsufficientBalance` error.
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientBalance.selector,
                account,
                office.balanceOf(account, tokenId),
                neededShares,
                tokenId
            )
        );
        office.switchCollateral(
            SwitchCollateralParams({account: account, tokenId: tokenId, assets: overAssets, shares: 0})
        );
    }
}

// Generated using co-pilot: GPT-4o
