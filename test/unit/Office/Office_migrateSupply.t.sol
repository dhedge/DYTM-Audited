// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Office_migrateSupply is CommonScenarios {
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;
    using SharesMathLib for uint256;
    using FixedPointMathLib for uint256;

    MarketId internal marketTwo;
    ReserveKey internal usdcKeyMarketTwo;
    ReserveKey internal wethKeyMarketTwo;

    modifier whenSecondMarketExists() {
        vm.startPrank(admin);

        // Create a second market with no hooks.
        marketTwo = createDefaultNoHooksMarket();

        usdcKeyMarketTwo = marketTwo.toReserveKey(usdc);
        wethKeyMarketTwo = marketTwo.toReserveKey(weth);

        vm.stopPrank();
        _;
    }

    modifier givenNotEnoughLiquidityInTheReserve() {
        // We don't add any liquidity to the reserve, so there won't be enough.
        _;
    }

    modifier whenAccountWantsToMigrateToLendingReserveInMarketTwo() {
        // This modifier indicates the test will migrate to lending reserve in market two.
        // The actual migration parameters will be set in the test function.
        _;
    }

    modifier whenAccountWantsToMigrateToEscrowReserveInMarketTwo() {
        // This modifier indicates the test will migrate to escrow reserve in market two.
        // The actual migration parameters will be set in the test function.
        _;
    }

    // Test case 1: Account with no debt migrates from lending to lending reserve
    function test_WhenAccountHasNoDebtPosition_GivenCollateralInLendingReserveInMarketOne_WhenAccountWantsToMigrateToLendingReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenAccountWantsToMigrateToLendingReserveInMarketTwo
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        uint256 suppliedAmountMarketOneBefore = office.getReserveData(key).supplied;
        uint256 suppliedAmountMarketTwoBefore = office.getReserveData(usdcKeyMarketTwo).supplied;

        // Calculate expected values before migration
        // Source is lending token, so assetsRedeemed = shares.toAssetsDown(reserveData.supplied, totalSupply(tokenId))
        uint256 fromTotalSupply = office.totalSupply(tokenId);
        uint256 expectedAssetsRedeemed = accountSuppliedAmountBefore.usdcLendingShareAmount
            .toAssetsDown(suppliedAmountMarketOneBefore, fromTotalSupply);

        // Destination is lending token, so newSharesMinted = assets.toSharesDown(reserveData.supplied,
        // totalSupply(tokenId))
        uint256 toTotalSupply = office.totalSupply(usdcKeyMarketTwo.toLentId());
        uint256 expectedSharesMinted = expectedAssetsRedeemed.toSharesDown(suppliedAmountMarketTwoBefore, toTotalSupply);

        // Migrate to lending reserve in market two.
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKeyMarketTwo.toLentId(),
            assets: 0,
            shares: accountSuppliedAmountBefore.usdcLendingShareAmount,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should correctly calculate assets redeemed and shares minted.
        assertEq(assetsRedeemed, expectedAssetsRedeemed, "Assets redeemed should match expected value");
        assertEq(newSharesMinted, expectedSharesMinted, "Shares minted should match expected value");

        // It should burn the shares in the old reserve.
        assertEq(office.balanceOf(account, tokenId), 0, "Old shares should be burned");

        // It should mint shares in the new reserve.
        assertEq(office.balanceOf(account, usdcKeyMarketTwo.toLentId()), newSharesMinted, "New shares should be minted");

        // It should reduce the supplied amount in the old reserve.
        assertEq(
            office.getReserveData(key).supplied,
            suppliedAmountMarketOneBefore - assetsRedeemed,
            "Supplied amount in old reserve should be reduced"
        );

        // It should increase the supplied amount in the new reserve.
        assertEq(
            office.getReserveData(usdcKeyMarketTwo).supplied,
            suppliedAmountMarketTwoBefore + assetsRedeemed,
            "Supplied amount in new reserve should be increased"
        );
    }

    // Test case 2: Account with no debt migrates from lending to escrow reserve
    function test_WhenAccountHasNoDebtPosition_GivenCollateralInLendingReserveInMarketOne_WhenAccountWantsToMigrateToEscrowReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenAccountWantsToMigrateToEscrowReserveInMarketTwo
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        uint256 suppliedAmountMarketOneBefore = office.getReserveData(key).supplied;

        // Calculate expected values before migration
        // Source is lending token, so assetsRedeemed = shares.toAssetsDown(reserveData.supplied, totalSupply(tokenId))
        uint256 fromTotalSupply = office.totalSupply(tokenId);
        uint256 expectedAssetsRedeemed = accountSuppliedAmountBefore.usdcLendingShareAmount
            .toAssetsDown(suppliedAmountMarketOneBefore, fromTotalSupply);

        // Destination is escrow token, so newSharesMinted = assets (1:1 ratio)
        uint256 expectedSharesMinted = expectedAssetsRedeemed;

        // Migrate to escrow reserve in market two
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKeyMarketTwo.toEscrowId(),
            assets: 0,
            shares: accountSuppliedAmountBefore.usdcLendingShareAmount,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should correctly calculate assets redeemed and shares minted.
        assertEq(assetsRedeemed, expectedAssetsRedeemed, "Assets redeemed should match expected value");
        assertEq(newSharesMinted, expectedSharesMinted, "Shares minted should match expected value");

        // It should burn the shares in the old reserve.
        assertEq(office.balanceOf(account, tokenId), 0, "Old shares should be burned");

        // It should mint shares in the new reserve.
        assertEq(
            office.balanceOf(account, usdcKeyMarketTwo.toEscrowId()), newSharesMinted, "New shares should be minted"
        );

        // It should reduce the supplied amount in the old reserve.
        assertEq(
            office.getReserveData(key).supplied,
            suppliedAmountMarketOneBefore - assetsRedeemed,
            "Supplied amount in old reserve should be reduced"
        );
    }

    // Test case 3: Account with no debt migrates from escrow to lending reserve
    function test_WhenAccountHasNoDebtPosition_GivenCollateralInEscrowedReserveInMarketOne_WhenAccountWantsToMigrateToLendingReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenAccountWantsToMigrateToLendingReserveInMarketTwo
    {
        // Setup source - WETH escrow in market one
        key = wethKey;
        tokenId = wethKey.toEscrowId();

        vm.startPrank(caller);

        uint256 suppliedAmountMarketTwoBefore = office.getReserveData(wethKeyMarketTwo).supplied;

        // Calculate expected values before migration
        // Source is escrow token, so assetsRedeemed = shares (1:1 ratio)
        uint256 expectedAssetsRedeemed = accountSuppliedAmountBefore.wethEscrowShareAmount;

        // Destination is lending token, so newSharesMinted = assets.toSharesDown(reserveData.supplied,
        // totalSupply(tokenId))
        uint256 toTotalSupply = office.totalSupply(wethKeyMarketTwo.toLentId());
        uint256 expectedSharesMinted = expectedAssetsRedeemed.toSharesDown(suppliedAmountMarketTwoBefore, toTotalSupply);

        // Migrate to lending reserve in market two
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: wethKeyMarketTwo.toLentId(),
            assets: 0,
            shares: accountSuppliedAmountBefore.wethEscrowShareAmount,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should correctly calculate assets redeemed and shares minted.
        assertEq(assetsRedeemed, expectedAssetsRedeemed, "Assets redeemed should match expected value");
        assertEq(newSharesMinted, expectedSharesMinted, "Shares minted should match expected value");

        // It should burn the shares in the old reserve.
        assertEq(office.balanceOf(account, tokenId), 0, "Old shares should be burned");

        // It should mint shares in the new reserve.
        assertEq(office.balanceOf(account, wethKeyMarketTwo.toLentId()), newSharesMinted, "New shares should be minted");

        // It should increase the supplied amount in the new reserve.
        assertEq(
            office.getReserveData(wethKeyMarketTwo).supplied,
            suppliedAmountMarketTwoBefore + assetsRedeemed,
            "Supplied amount in new reserve should be increased"
        );
    }

    // Test case 4: Account with no debt migrates from escrow to escrow reserve
    function test_WhenAccountHasNoDebtPosition_GivenCollateralInEscrowedReserveInMarketOne_WhenAccountWantsToMigrateToEscrowReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenAccountWantsToMigrateToEscrowReserveInMarketTwo
    {
        // Setup source - WETH escrow in market one
        key = wethKey;
        tokenId = wethKey.toEscrowId();

        vm.startPrank(caller);

        // Calculate expected values before migration
        // Source is escrow token, so assetsRedeemed = shares (1:1 ratio)
        uint256 expectedAssetsRedeemed = accountSuppliedAmountBefore.wethEscrowShareAmount;

        // Destination is escrow token, so newSharesMinted = assets (1:1 ratio)
        uint256 expectedSharesMinted = expectedAssetsRedeemed;

        // Migrate to escrow reserve in market two
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: wethKeyMarketTwo.toEscrowId(),
            assets: 0,
            shares: accountSuppliedAmountBefore.wethEscrowShareAmount,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should correctly calculate assets redeemed and shares minted.
        assertEq(assetsRedeemed, expectedAssetsRedeemed, "Assets redeemed should match expected value");
        assertEq(newSharesMinted, expectedSharesMinted, "Shares minted should match expected value");

        // It should burn the shares in the old reserve.
        assertEq(office.balanceOf(account, tokenId), 0, "Old shares should be burned");

        // It should mint shares in the new reserve.
        assertEq(
            office.balanceOf(account, wethKeyMarketTwo.toEscrowId()), newSharesMinted, "New shares should be minted"
        );
    }

    // Test case 5: Account with debt (will be healthy) migrates from lending to lending reserve
    function test_WhenAccountHasDebtPosition_GivenAccountWillBeHealthy_GivenCollateralInLendingReserveInMarketOne_WhenAccountWantsToMigrateToLendingReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenTheAccountWillBeHealthy
        whenAccountWantsToMigrateToLendingReserveInMarketTwo
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        uint256 suppliedAmountMarketOneBefore = office.getReserveData(key).supplied;
        uint256 suppliedAmountMarketTwoBefore = office.getReserveData(usdcKeyMarketTwo).supplied;

        // Calculate safe migration amount - can't migrate all USDC because of debt position.
        // Account has 1000 USDC lent + 1 WETH escrowed (2000 USD) = 3000 USD collateral.
        // Account has 2000 USDC borrowed.
        // Need to maintain healthy collateralization - migrate only 10% of USDC shares.
        uint256 sharesToMigrate = accountSuppliedAmountBefore.usdcLendingShareAmount / 10;

        // Calculate expected values before migration
        // Source is lending token, so assetsRedeemed = shares.toAssetsDown(reserveData.supplied, totalSupply(tokenId))
        uint256 fromTotalSupply = office.totalSupply(tokenId);
        uint256 expectedAssetsRedeemed = sharesToMigrate.toAssetsDown(suppliedAmountMarketOneBefore, fromTotalSupply);

        // Destination is lending token, so newSharesMinted = assets.toSharesDown(reserveData.supplied,
        // totalSupply(tokenId))
        uint256 toTotalSupply = office.totalSupply(usdcKeyMarketTwo.toLentId());
        uint256 expectedSharesMinted = expectedAssetsRedeemed.toSharesDown(suppliedAmountMarketTwoBefore, toTotalSupply);

        // Migrate to lending reserve in market two
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKeyMarketTwo.toLentId(),
            assets: 0,
            shares: sharesToMigrate,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should correctly calculate assets redeemed and shares minted.
        assertEq(assetsRedeemed, expectedAssetsRedeemed, "Assets redeemed should match expected value");
        assertEq(newSharesMinted, expectedSharesMinted, "Shares minted should match expected value");

        // It should burn only the migrated shares in the old reserve, not all shares.
        uint256 remainingShares = accountSuppliedAmountBefore.usdcLendingShareAmount - sharesToMigrate;
        assertEq(office.balanceOf(account, tokenId), remainingShares, "Only migrated shares should be burned");

        // It should mint shares in the new reserve.
        assertEq(office.balanceOf(account, usdcKeyMarketTwo.toLentId()), newSharesMinted, "New shares should be minted");

        // It should reduce the supplied amount in the old reserve.
        assertEq(
            office.getReserveData(key).supplied,
            suppliedAmountMarketOneBefore - assetsRedeemed,
            "Supplied amount in old reserve should be reduced"
        );

        // It should increase the supplied amount in the new reserve.
        assertEq(
            office.getReserveData(usdcKeyMarketTwo).supplied,
            suppliedAmountMarketTwoBefore + assetsRedeemed,
            "Supplied amount in new reserve should be increased"
        );
    }

    // Test case 6: Account with debt (will be healthy) migrates from lending to escrow reserve
    function test_WhenAccountHasDebtPosition_GivenAccountWillBeHealthy_GivenCollateralInLendingReserveInMarketOne_WhenAccountWantsToMigrateToEscrowReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenTheAccountWillBeHealthy
        whenAccountWantsToMigrateToEscrowReserveInMarketTwo
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        uint256 suppliedAmountMarketOneBefore = office.getReserveData(key).supplied;

        // Calculate safe migration amount - can't migrate all USDC because of debt position
        // Account has 1000 USDC lent + 1 WETH escrowed (2000 USD) = 3000 USD collateral
        // Account has 2000 USDC borrowed
        // Need to maintain healthy collateralization - migrate only 10% of USDC shares
        uint256 sharesToMigrate = accountSuppliedAmountBefore.usdcLendingShareAmount / 10;

        // Calculate expected values before migration
        // Source is lending token, so assetsRedeemed = shares.toAssetsDown(reserveData.supplied, totalSupply(tokenId))
        uint256 fromTotalSupply = office.totalSupply(tokenId);
        uint256 expectedAssetsRedeemed = sharesToMigrate.toAssetsDown(suppliedAmountMarketOneBefore, fromTotalSupply);

        // Destination is escrow token, so newSharesMinted = assets (1:1 ratio)
        uint256 expectedSharesMinted = expectedAssetsRedeemed;

        // Migrate to escrow reserve in market two
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKeyMarketTwo.toEscrowId(),
            assets: 0,
            shares: sharesToMigrate,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should correctly calculate assets redeemed and shares minted.
        assertEq(assetsRedeemed, expectedAssetsRedeemed, "Assets redeemed should match expected value");
        assertEq(newSharesMinted, expectedSharesMinted, "Shares minted should match expected value");

        // It should burn only the migrated shares in the old reserve, not all shares.
        uint256 remainingShares = accountSuppliedAmountBefore.usdcLendingShareAmount - sharesToMigrate;
        assertEq(office.balanceOf(account, tokenId), remainingShares, "Only migrated shares should be burned");

        // It should mint shares in the new reserve.
        assertEq(
            office.balanceOf(account, usdcKeyMarketTwo.toEscrowId()), newSharesMinted, "New shares should be minted"
        );

        // It should reduce the supplied amount in the old reserve.
        assertEq(
            office.getReserveData(key).supplied,
            suppliedAmountMarketOneBefore - assetsRedeemed,
            "Supplied amount in old reserve should be reduced"
        );
    }

    // Test case 7: Account with debt (will be healthy) migrates from escrow to lending reserve
    function test_WhenAccountHasDebtPosition_GivenAccountWillBeHealthy_GivenCollateralInEscrowedReserveInMarketOne_WhenAccountWantsToMigrateToLendingReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenTheAccountWillBeHealthy
        whenAccountWantsToMigrateToLendingReserveInMarketTwo
    {
        // Setup source - WETH escrow in market one
        key = wethKey;
        tokenId = wethKey.toEscrowId();

        vm.startPrank(caller);

        uint256 suppliedAmountMarketTwoBefore = office.getReserveData(wethKeyMarketTwo).supplied;

        // Calculate safe migration amount - can migrate only a portion of WETH to maintain health
        // Account has 1000 USDC lent + 1 WETH escrowed (2000 USD) = 3000 USD collateral
        // Account has 2000 USDC borrowed and the max borrow is 2200 (manual calculations).
        // For WETH, we can migrate $200 worth of shares while keeping account healthy.
        // Since escrow shares are priced at 1:1 with the underlying asset, no need to use shares math.
        uint256 sharesToMigrate = oracleModule.getQuote(200e18, USD_ISO_ADDRESS, address(weth));

        // Calculate expected values before migration
        // Source is escrow token, so assetsRedeemed = shares (1:1 ratio)
        uint256 expectedAssetsRedeemed = sharesToMigrate;

        // Destination is lending token, so newSharesMinted = assets.toSharesDown(reserveData.supplied,
        // totalSupply(tokenId))
        uint256 toTotalSupply = office.totalSupply(wethKeyMarketTwo.toLentId());
        uint256 expectedSharesMinted = expectedAssetsRedeemed.toSharesDown(suppliedAmountMarketTwoBefore, toTotalSupply);

        // Migrate to lending reserve in market two
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: wethKeyMarketTwo.toLentId(),
            assets: 0,
            shares: sharesToMigrate,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should correctly calculate assets redeemed and shares minted.
        assertEq(assetsRedeemed, expectedAssetsRedeemed, "Assets redeemed should match expected value");
        assertEq(newSharesMinted, expectedSharesMinted, "Shares minted should match expected value");

        // It should burn only the migrated shares in the old reserve, not all shares.
        uint256 remainingShares = accountSuppliedAmountBefore.wethEscrowShareAmount - sharesToMigrate;
        assertEq(office.balanceOf(account, tokenId), remainingShares, "Only migrated shares should be burned");

        // It should mint shares in the new reserve.
        assertEq(office.balanceOf(account, wethKeyMarketTwo.toLentId()), newSharesMinted, "New shares should be minted");

        // It should increase the supplied amount in the new reserve.
        assertEq(
            office.getReserveData(wethKeyMarketTwo).supplied,
            suppliedAmountMarketTwoBefore + assetsRedeemed,
            "Supplied amount in new reserve should be increased"
        );
    }

    // Test case 8: Account with debt (will be healthy) migrates from escrow to escrow reserve
    function test_WhenAccountHasDebtPosition_GivenAccountWillBeHealthy_GivenCollateralInEscrowedReserveInMarketOne_WhenAccountWantsToMigrateToEscrowReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenTheAccountWillBeHealthy
        whenAccountWantsToMigrateToEscrowReserveInMarketTwo
    {
        // Setup source - WETH escrow in market one
        key = wethKey;
        tokenId = wethKey.toEscrowId();

        vm.startPrank(caller);

        // Calculate safe migration amount - can migrate only a portion of WETH to maintain health
        // Account has 1000 USDC lent + 1 WETH escrowed (2000 USD) = 3000 USD collateral
        // Account has 2000 USDC borrowed and the max borrow is 2200 (manual calculations).
        // For WETH, we can migrate $200 worth of shares while keeping account healthy.
        // Since escrow shares are priced at 1:1 with the underlying asset, no need to use shares math.
        uint256 sharesToMigrate = oracleModule.getQuote(200e18, USD_ISO_ADDRESS, address(weth));

        // Calculate expected values before migration
        // Source is escrow token, so assetsRedeemed = shares (1:1 ratio)
        uint256 expectedAssetsRedeemed = sharesToMigrate;

        // Destination is escrow token, so newSharesMinted = assets (1:1 ratio)
        uint256 expectedSharesMinted = expectedAssetsRedeemed;

        // Migrate to escrow reserve in market two
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: wethKeyMarketTwo.toEscrowId(),
            assets: 0,
            shares: sharesToMigrate,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should correctly calculate assets redeemed and shares minted.
        assertEq(assetsRedeemed, expectedAssetsRedeemed, "Assets redeemed should match expected value");
        assertEq(newSharesMinted, expectedSharesMinted, "Shares minted should match expected value");

        // It should burn only the migrated shares in the old reserve, not all shares.
        uint256 remainingShares = accountSuppliedAmountBefore.wethEscrowShareAmount - sharesToMigrate;
        assertEq(office.balanceOf(account, tokenId), remainingShares, "Only migrated shares should be burned");

        // It should mint shares in the new reserve.
        assertEq(
            office.balanceOf(account, wethKeyMarketTwo.toEscrowId()), newSharesMinted, "New shares should be minted"
        );
    }

    // Test case 9: Revert when account has debt and will become unhealthy
    function test_RevertWhen_AccountHasDebtPosition_GivenAccountWillBecomeUnhealthy()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenTheAccountHasADebtPosition
        givenTheAccountWillBecomeUnhealthy
        whenAccountWantsToMigrateToLendingReserveInMarketTwo
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        // Migrate all USDC lending shares to market two, which will make the account unhealthy
        // This is testing the negative case - migrating all collateral should fail
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKeyMarketTwo.toLentId(),
            assets: 0,
            shares: accountSuppliedAmountBefore.usdcLendingShareAmount, // Trying to migrate 100% - should fail
            fromExtraData: "",
            toExtraData: ""
        });

        // It should revert with Office__AccountNotHealthy error
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AccountNotHealthy.selector, account, key.getMarketId()));
        office.migrateSupply(migrateParams);
    }

    // Test case 10: Revert when not enough liquidity in lending reserve
    function test_RevertGiven_NotEnoughLiquidityInLendingReserveInMarketOne()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenNotEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
        whenAccountWantsToMigrateToLendingReserveInMarketTwo
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        // Mock that someone borrowed all the liquidity
        mockBorrow(key, office.getReserveData(key).supplied);

        // Try to migrate to lending reserve in market two
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKeyMarketTwo.toLentId(),
            assets: 0,
            shares: accountSuppliedAmountBefore.usdcLendingShareAmount,
            fromExtraData: "",
            toExtraData: ""
        });

        // It should revert with Office__InsufficientLiquidity error
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__InsufficientLiquidity.selector, key));
        office.migrateSupply(migrateParams);
    }

    // Test case 11: Revert when asset is not supported in the new market
    function test_Revert_WhenAccountHasNoDebtPosition_WhenTheAssetIsNotSupportedInTheNewMarket()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Setup: Create a second market that doesn't support USDC.
        vm.startPrank(admin);

        // Create a custom market config that only supports the dummy token (not USDC)
        SimpleMarketConfig.ConfigInitParams memory initParams = SimpleMarketConfig.ConfigInitParams({
            feeRecipient: feeRecipient,
            irm: irm,
            weights: weights,
            oracleModule: oracleModule,
            hooks: NO_HOOKS_SET,
            feePercentage: 0,
            minDebtAmountUSD: 0
        });

        SimpleMarketConfig customMarketConfig = new SimpleMarketConfig(admin, office, initParams);

        // Create the market with custom config that doesn't support USDC.
        marketTwo = office.createMarket(admin, customMarketConfig);

        vm.startPrank(caller);

        usdcKeyMarketTwo = marketTwo.toReserveKey(usdc);

        // Try to migrate USDC from market one to market two (which doesn't support USDC).
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: usdcKey.toLentId(), // USDC lending token from market one
            toTokenId: usdcKeyMarketTwo.toLentId(), // USDC lending token in market two (unsupported)
            assets: 0,
            shares: accountSuppliedAmountBefore.usdcLendingShareAmount,
            fromExtraData: "",
            toExtraData: ""
        });

        // It should revert with Office__ReserveNotSupported error
        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__ReserveNotSupported.selector, usdcKeyMarketTwo));
        office.migrateSupply(migrateParams);
    }

    // Test case 12: Account uses max uint256 shares to migrate from lending to lending reserve
    function test_WhenAccountUsesMaxUint256SharesToMigrate_GivenCollateralInLendingReserveInMarketOne_WhenAccountWantsToMigrateToLendingReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        uint256 suppliedAmountMarketOneBefore = office.getReserveData(key).supplied;
        uint256 suppliedAmountMarketTwoBefore = office.getReserveData(usdcKeyMarketTwo).supplied;
        uint256 fromTotalSupply = office.totalSupply(tokenId);
        uint256 debtShares = accountSuppliedAmountBefore.usdcLendingShareAmount; // existing lending shares

        // Expected assets redeemed & shares minted using full balance
        uint256 expectedAssetsRedeemed = debtShares.toAssetsDown(suppliedAmountMarketOneBefore, fromTotalSupply);
        uint256 toTotalSupply = office.totalSupply(usdcKeyMarketTwo.toLentId());
        uint256 expectedSharesMinted = expectedAssetsRedeemed.toSharesDown(suppliedAmountMarketTwoBefore, toTotalSupply);

        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKeyMarketTwo.toLentId(),
            assets: 0,
            shares: type(uint256).max,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should migrate the entire lending balance of the user.
        assertEq(assetsRedeemed, expectedAssetsRedeemed, "Assets redeemed mismatch");

        // It should burn the entire lending shares of the user in the old reserve.
        assertEq(office.balanceOf(account, tokenId), 0, "Old lending shares not fully burned");

        // It should mint the correct amount of lending shares in the new reserve.
        assertEq(newSharesMinted, expectedSharesMinted, "Minted lending shares mismatch");
        assertEq(
            office.balanceOf(account, usdcKeyMarketTwo.toLentId()), expectedSharesMinted, "New lending shares incorrect"
        );

        // It should reduce the supplied amount in the old reserve.
        assertEq(
            office.getReserveData(key).supplied,
            suppliedAmountMarketOneBefore - assetsRedeemed,
            "Old reserve supplied not reduced correctly"
        );

        // It should increase the supplied amount in the new reserve.
        assertEq(
            office.getReserveData(usdcKeyMarketTwo).supplied,
            suppliedAmountMarketTwoBefore + assetsRedeemed,
            "New reserve supplied not increased correctly"
        );
    }

    // Test case 13: Account uses max uint256 shares to migrate from escrow to escrow reserve
    function test_WhenAccountUsesMaxUint256SharesToMigrate_GivenCollateralInEscrowedReserveInMarketOne_WhenAccountWantsToMigrateToEscrowReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Setup source - WETH escrow in market one
        key = wethKey;
        tokenId = wethKey.toEscrowId();

        vm.startPrank(caller);

        uint256 escrowShares = accountSuppliedAmountBefore.wethEscrowShareAmount;

        // Expected assets redeemed (1:1) and destination shares minted (1:1)
        uint256 expectedAssetsRedeemed = escrowShares;
        uint256 expectedSharesMinted = expectedAssetsRedeemed;

        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: wethKeyMarketTwo.toEscrowId(),
            assets: 0,
            shares: type(uint256).max,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should migrate the entire escrow balance of the user.
        assertEq(assetsRedeemed, expectedAssetsRedeemed, "Escrow assets redeemed mismatch");

        // It should burn the entire escrow shares of the user in the old reserve.
        assertEq(office.balanceOf(account, tokenId), 0, "Old escrow shares not fully burned");

        // It should mint the correct amount of escrow shares in the new reserve.
        assertEq(newSharesMinted, expectedSharesMinted, "Minted escrow shares mismatch");
        assertEq(
            office.balanceOf(account, wethKeyMarketTwo.toEscrowId()),
            expectedSharesMinted,
            "New escrow shares incorrect"
        );
    }

    // Test case 14: Account migrates partial assets amount from lending to lending reserve
    function test_WhenAccountMigratesPartialAssetsAmount_GivenCollateralInLendingReserveInMarketOne_WhenAccountWantsToMigrateToLendingReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        uint256 suppliedAmountMarketOneBefore = office.getReserveData(key).supplied;
        uint256 suppliedAmountMarketTwoBefore = office.getReserveData(usdcKeyMarketTwo).supplied;
        uint256 fromTotalSupply = office.totalSupply(tokenId);

        // Derive user's total assets represented by their lending shares
        uint256 userTotalAssets = accountSuppliedAmountBefore.usdcLendingShareAmount
            .toAssetsDown(suppliedAmountMarketOneBefore, fromTotalSupply);

        // Choose a partial assets amount (e.g., 50% of user's assets)
        uint256 assetsToMigrate = userTotalAssets / 2;

        // Expected shares to burn from source lending reserve for assetsToMigrate
        uint256 expectedSharesToBurn = assetsToMigrate.toSharesDown(suppliedAmountMarketOneBefore, fromTotalSupply);

        // Expected shares to mint in destination lending reserve
        uint256 toTotalSupply = office.totalSupply(usdcKeyMarketTwo.toLentId());
        uint256 expectedSharesMinted = assetsToMigrate.toSharesDown(suppliedAmountMarketTwoBefore, toTotalSupply);

        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKeyMarketTwo.toLentId(),
            assets: assetsToMigrate,
            shares: 0,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should redeem exactly the requested assets amount
        assertEq(assetsRedeemed, assetsToMigrate, "Assets redeemed mismatch for partial assets migration");

        // It should burn the expected shares only
        uint256 remainingShares = accountSuppliedAmountBefore.usdcLendingShareAmount - expectedSharesToBurn;
        assertEq(
            office.balanceOf(account, tokenId),
            remainingShares,
            "Incorrect remaining lending shares after partial assets migration"
        );

        // It should mint the expected number of shares in the destination lending reserve
        assertEq(newSharesMinted, expectedSharesMinted, "Minted shares mismatch for partial assets migration");
        assertEq(
            office.balanceOf(account, usdcKeyMarketTwo.toLentId()),
            expectedSharesMinted,
            "New lending shares incorrect for partial assets migration"
        );

        // Supplied amounts adjustments
        assertEq(
            office.getReserveData(key).supplied,
            suppliedAmountMarketOneBefore - assetsRedeemed,
            "Old reserve supplied not reduced correctly for partial assets migration"
        );
        assertEq(
            office.getReserveData(usdcKeyMarketTwo).supplied,
            suppliedAmountMarketTwoBefore + assetsRedeemed,
            "New reserve supplied not increased correctly for partial assets migration"
        );
    }

    // Test case 15: Account migrates partial assets amount from escrow to escrow reserve
    function test_WhenAccountMigratesPartialAssetsAmount_GivenCollateralInEscrowedReserveInMarketOne_WhenAccountWantsToMigrateToEscrowReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Setup source - WETH escrow in market one
        key = wethKey;
        tokenId = wethKey.toEscrowId();

        vm.startPrank(caller);

        uint256 escrowSharesBefore = accountSuppliedAmountBefore.wethEscrowShareAmount;

        // Migrate 50% of the escrowed assets using assets parameter (shares=0)
        uint256 assetsToMigrate = escrowSharesBefore / 2;

        // Expected shares to burn (1:1) and mint (1:1) for escrow -> escrow
        uint256 expectedSharesToBurn = assetsToMigrate;
        uint256 expectedSharesMinted = assetsToMigrate;

        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: wethKeyMarketTwo.toEscrowId(),
            assets: assetsToMigrate,
            shares: 0,
            fromExtraData: "",
            toExtraData: ""
        });

        (uint256 assetsRedeemed, uint256 newSharesMinted) = office.migrateSupply(migrateParams);

        // It should redeem the specified assets amount
        assertEq(assetsRedeemed, assetsToMigrate, "Assets redeemed mismatch for partial escrow migration");

        // It should burn the correct number of escrow shares
        uint256 remainingShares = escrowSharesBefore - expectedSharesToBurn;
        assertEq(
            office.balanceOf(account, tokenId),
            remainingShares,
            "Incorrect remaining escrow shares after partial migration"
        );

        // It should mint the correct number of escrow shares in market two
        assertEq(newSharesMinted, expectedSharesMinted, "Minted escrow shares mismatch for partial migration");
        assertEq(
            office.balanceOf(account, wethKeyMarketTwo.toEscrowId()),
            expectedSharesMinted,
            "New escrow shares incorrect for partial migration"
        );
    }

    // Test case 16: Revert when account migrates over balance assets amount from lending reserve
    function test_Revert_WhenAccountMigratesOverBalanceAssetsAmount_GivenCollateralInLendingReserveInMarketOne_WhenAccountWantsToMigrateToLendingReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        uint256 suppliedAmountMarketOneBefore = office.getReserveData(key).supplied;
        uint256 assetsToMigrate = suppliedAmountMarketOneBefore + 1; // Over balance

        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKeyMarketTwo.toLentId(),
            assets: assetsToMigrate,
            shares: 0,
            fromExtraData: "",
            toExtraData: ""
        });

        // Expectedto revert with a underflow panic error.
        vm.expectRevert();
        office.migrateSupply(migrateParams);
    }

    // Test case 17: Revert when account migrates over balance assets amount from escrow reserve
    function test_Revert_WhenAccountMigratesOverBalanceAssetsAmount_GivenCollateralInEscrowedReserveInMarketOne_WhenAccountWantsToMigrateToEscrowReserveInMarketTwo()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Setup source - WETH escrow in market one
        key = wethKey;
        tokenId = wethKey.toEscrowId();

        vm.startPrank(caller);

        uint256 escrowSharesBefore = accountSuppliedAmountBefore.wethEscrowShareAmount;
        uint256 assetsToMigrate = escrowSharesBefore + 1; // Over balance (1:1)

        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: wethKeyMarketTwo.toEscrowId(),
            assets: assetsToMigrate,
            shares: 0,
            fromExtraData: "",
            toExtraData: ""
        });

        // Expect revert - insufficient balance
        vm.expectRevert(
            abi.encodeWithSelector(
                IRegistry.Registry__InsufficientBalance.selector, account, escrowSharesBefore, assetsToMigrate, tokenId
            )
        );
        office.migrateSupply(migrateParams);
    }

    // Test case 18: Revert when both assets and shares are non-zero
    function test_Revert_WhenAccountMigratesSupplyWithBothAssetsAndSharesNonZero()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        // Provide both assets and shares to trigger revert
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKeyMarketTwo.toLentId(),
            assets: 1,
            shares: 1,
            fromExtraData: "",
            toExtraData: ""
        });

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__AssetsAndSharesNonZero.selector, uint256(1), uint256(1)));
        office.migrateSupply(migrateParams);
    }

    // Test case 19: Revert when assets represented by fromTokenId and toTokenId do not match
    function test_Revert_WhenAssetsRepresentedByFromTokenIdAndToTokenIdDoNotMatch()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        // Try to migrate to WETH lending reserve in market two (different asset)
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: wethKeyMarketTwo.toLentId(),
            assets: 0,
            shares: accountSuppliedAmountBefore.usdcLendingShareAmount,
            fromExtraData: "",
            toExtraData: ""
        });

        // It should revert with Office__MismatchedAssetsInMigration error.
        vm.expectRevert(
            abi.encodeWithSelector(
                IOffice.Office__MismatchedAssetsInMigration.selector, IERC20(address(usdc)), IERC20(address(weth))
            )
        );
        office.migrateSupply(migrateParams);
    }

    // Test case 20: Revert when fromTokenId and toTokenId are in the same market
    function test_Revert_WhenFromTokenIdAndToTokenIdAreInTheSameMarket()
        external
        whenReserveExists
        whenSecondMarketExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        givenEnoughLiquidityInTheReserve
        whenUsingSuppliedPlusEscrowedAssets
    {
        // Setup source - USDC lending in market one
        key = usdcKey;
        tokenId = usdcKey.toLentId();

        vm.startPrank(caller);

        // Try to migrate to USDC lending reserve in the same market (market one)
        MigrateSupplyParams memory migrateParams = MigrateSupplyParams({
            account: account,
            fromTokenId: tokenId,
            toTokenId: usdcKey.toLentId(), // Same market and asset
            assets: 0,
            shares: accountSuppliedAmountBefore.usdcLendingShareAmount,
            fromExtraData: "",
            toExtraData: ""
        });

        // It should revert with Office__SameMarketInMigration error.
        vm.expectRevert(
            abi.encodeWithSelector(IOffice.Office__SameMarketInMigration.selector, tokenId, usdcKey.toLentId())
        );
        office.migrateSupply(migrateParams);
    }

    // Generated using co-pilot: Claude Sonnet 4.5
}
