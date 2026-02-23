// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../helpers/CommonFunctions.sol";
import "../../shared/CommonScenarios.sol";

contract Office_supply is CommonScenarios {
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;
    using SharesMathLib for uint256;
    using FixedPointMathLib for uint256;

    function test_RevertWhen_MarketDoesNotExist() external {
        market = MarketId.wrap(1);
        key = market.toReserveKey(usdc);

        vm.startPrank(alice);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: key.toLentId(),
            account: alice.toUserAccount(),
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        vm.expectRevert();
        office.supply(supplyParams);
    }

    function test_WhenLendingAssets()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should mint correct amount of lending shares.
        assertEq(scaleDownByOffset(shares), 1000e6, "Scaled down shares should be equal to the supplied amount");
        assertEq(office.balanceOf(caller, tokenId), shares, "Caller should have the correct amount of shares");
        assertEq(
            (office.getAllCollateralIds(caller, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, 1000e6, "Supplied amounts don't match");
    }

    function test_WhenEscrowingAssets()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenEscrowingAsset(usdcKey)
    {
        vm.startPrank(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should mint correct amount of escrow shares.
        assertEq(shares, 1000e6, "Escrow shares should be equal to the supplied amount");
        assertEq(office.balanceOf(caller, tokenId), shares, "Caller should have the correct amount of shares");
        assertEq(
            (office.getAllCollateralIds(caller, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should not increase the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, 0, "Escrowed amount shouldn't be counted as supplied");
    }

    function test_WhenLendingToAnIsolatedAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenLendingAsset(usdcKey)
    {
        caller = alice;
        vm.startPrank(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should mint correct amount of lending shares to the isolated account.
        assertEq(scaleDownByOffset(shares), 1000e6, "Scaled down shares should be equal to the supplied amount");
        assertTrue(account == uint96(1).toIsolatedAccount(), "Isolated account id incorrect");
        assertEq(
            office.balanceOf(account, tokenId), shares, "Isolated account should have the correct amount of shares"
        );
        assertEq(
            (office.getAllCollateralIds(account, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, 1000e6, "Supplied amounts don't match");

        // It should create an isolated account for the caller.
        assertEq(office.ownerOf(account), caller, "Isolated account owner should be the caller");
    }

    function test_WhenLendingOnBehalfOfAnAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsNotAuthorized
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should mint correct amount of lending shares to the account.
        assertEq(scaleDownByOffset(shares), 1000e6, "Scaled down shares should be equal to the supplied amount");
        assertEq(office.balanceOf(account, tokenId), shares, "Account should have the correct amount of shares");
        assertEq(
            (office.getAllCollateralIds(account, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, 1000e6, "Supplied amounts don't match");
    }

    function test_WhenLendingOnBehalfOfAnIsolatedAccountAndTheAccountExists()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should mint correct amount of lending shares to the account.
        assertEq(scaleDownByOffset(shares), 1000e6, "Scaled down shares should be equal to the supplied amount");
        assertEq(office.balanceOf(account, tokenId), shares, "Account should have the correct amount of shares");
        assertEq(
            (office.getAllCollateralIds(account, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, 1000e6, "Supplied amounts don't match");

        // It should not create an isolated account for the caller.
        assertTrue(office.ownerOf(account) != caller, "Isolated account owner should not be the caller");
    }

    function test_WhenLendingOnBehalfOfAnIsolatedAccountAndTheAccountDoesNotExist()
        external
        whenReserveExists
        whenIsolatedAccountDoesNotExist
        whenLendingAsset(usdcKey)
    {
        caller = keeper;
        vm.startPrank(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should mint correct amount of lending shares to the account.
        assertEq(scaleDownByOffset(shares), 1000e6, "Scaled down shares should be equal to the supplied amount");
        assertEq(office.balanceOf(account, tokenId), shares, "Account should have the correct amount of shares");
        assertEq(
            (office.getAllCollateralIds(account, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the supplied assets amount.
        assertEq(office.getReserveData(key).supplied, 1000e6, "Supplied amounts don't match");

        // It should not create an isolated account for the caller.
        // The `ownerOf` function reverts in case the owner of account is address(0).
        vm.expectRevert(abi.encodeWithSelector(IRegistry.Registry__NoAccountOwner.selector, account));
        office.ownerOf(account);
    }

    function test_WhenEscrowingToAnIsolatedAccount()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenEscrowingAsset(usdcKey)
    {
        caller = alice;
        vm.startPrank(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should mint correct amount of escrow shares to the isolated account.
        assertEq(shares, 1000e6, "Escrow shares should be equal to the supplied amount");
        assertTrue(account == uint96(1).toIsolatedAccount(), "Isolated account id incorrect");
        assertEq(
            office.balanceOf(account, tokenId), shares, "Isolated account should have the correct amount of shares"
        );
        assertEq(
            (office.getAllCollateralIds(account, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the escrowed assets amount.
        assertEq(office.totalSupply(tokenId), 1000e6, "Escrowed amounts don't match");

        // It should create an isolated account for the caller.
        assertEq(office.ownerOf(account), caller, "Isolated account owner should be the caller");
    }

    function test_WhenEscrowingOnBehalfOfAnAccount() external whenReserveExists whenEscrowingAsset(usdcKey) {
        account = alice.toUserAccount();
        caller = keeper;
        vm.startPrank(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should mint correct amount of escrow shares to the account.
        assertEq(shares, 1000e6, "Escrow shares should be equal to the supplied amount");
        assertEq(office.balanceOf(account, tokenId), shares, "Account should have the correct amount of shares");
        assertEq(
            (office.getAllCollateralIds(account, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the escrowed assets amount.
        assertEq(office.totalSupply(tokenId), 1000e6, "Escrowed amounts don't match");
    }

    function test_WhenEscrowingOnBehalfOfAnIsolatedAccountAndTheAccountExists()
        external
        whenReserveExists
        givenAccountIsIsolated
        whenCallerIsOperator
        whenEscrowingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // First supply to the isolated account.
        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should mint correct amount of lending shares to the account.
        assertEq(shares, 1000e6, "Escrow shares should be equal to the supplied amount");
        assertEq(office.balanceOf(account, tokenId), shares, "Account should have the correct amount of shares");
        assertEq(
            (office.getAllCollateralIds(account, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the escrowed assets amount.
        assertEq(office.totalSupply(tokenId), 1000e6, "Supplied amounts don't match");

        // It should not create an isolated account for the caller.
        assertTrue(office.ownerOf(account) != caller, "Isolated account owner should not be the caller");
    }

    function test_WhenEscrowingOnBehalfOfAnIsolatedAccountAndTheAccountDoesNotExist()
        external
        whenReserveExists
        whenIsolatedAccountDoesNotExist
        whenEscrowingAsset(usdcKey)
    {
        caller = keeper;
        vm.startPrank(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 USDC
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should mint correct amount of escrow shares to the account.
        assertEq(shares, 1000e6, "Escrow shares should be equal to the supplied amount");
        assertEq(office.balanceOf(account, tokenId), shares, "Account should have the correct amount of shares");
        assertEq(
            (office.getAllCollateralIds(account, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the escrowed assets amount.
        assertEq(office.totalSupply(tokenId), 1000e6, "Escrowed amounts don't match");

        // It should not create an isolated account for the caller.
        // The `ownerOf` function reverts in case the owner of account is address(0).
        vm.expectRevert(abi.encodeWithSelector(IRegistry.Registry__NoAccountOwner.selector, account));
        office.ownerOf(account);
    }

    function test_WhenLendingUsingMaxUint256AssetsAmount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        uint256 callerBalanceBefore = usdc.balanceOf(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: type(uint256).max, // Max uint256 amount
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should lend the entire balance of the caller.
        assertEq(usdc.balanceOf(caller), 0, "Caller should have zero balance after lending entire balance");

        // It should mint correct amount of lending shares.
        assertEq(
            scaleDownByOffset(shares),
            callerBalanceBefore,
            "Scaled down shares should equal the caller's previous balance"
        );
        assertEq(office.balanceOf(caller, tokenId), shares, "Caller should have the correct amount of shares");
        assertEq(
            (office.getAllCollateralIds(caller, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the supplied assets amount.
        assertEq(
            office.getReserveData(key).supplied,
            callerBalanceBefore,
            "Supplied amount should equal caller's previous balance"
        );
    }

    function test_WhenEscrowingUsingMaxUint256AssetsAmount()
        external
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenEscrowingAsset(usdcKey)
    {
        vm.startPrank(caller);

        uint256 callerBalanceBefore = usdc.balanceOf(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: type(uint256).max, // Max uint256 amount
            extraData: bytes("")
        });

        uint256 shares = office.supply(supplyParams);

        // It should escrow the entire balance of the caller.
        assertEq(usdc.balanceOf(caller), 0, "Caller should have zero balance after escrowing entire balance");

        // It should mint correct amount of escrow shares.
        assertEq(shares, callerBalanceBefore, "Escrow shares should equal the caller's previous balance");
        assertEq(office.balanceOf(caller, tokenId), shares, "Caller should have the correct amount of shares");
        assertEq(
            (office.getAllCollateralIds(caller, key.getMarketId()))[0],
            tokenId,
            "Collateral id should be added to the IDs set"
        );

        // It should increase the escrowed assets amount.
        assertEq(
            office.totalSupply(tokenId), callerBalanceBefore, "Escrowed amount should equal caller's previous balance"
        );
    }

    function test_RevertWhen_ReserveDoesntExist()
        external
        whenReserveIsNotSupported
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenLendingAsset(key) // By default, because of `whenReserveIsNotSupported` modifier, the key is that of a dummy
            // asset.
    {
        // It should revert.
        //     Because the asset is not supported.
        vm.startPrank(caller);

        SupplyParams memory supplyParams = SupplyParams({
            tokenId: tokenId,
            account: account,
            assets: 1000e6, // 1000 DUMMY
            extraData: bytes("")
        });

        vm.expectRevert(abi.encodeWithSelector(IOffice.Office__ReserveNotSupported.selector, key));
        office.supply(supplyParams);
    }
}
