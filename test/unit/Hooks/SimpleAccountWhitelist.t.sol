// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";
import {HookMiner} from "../../../script/utils/HookMiner.sol";

contract SimpleAccountWhitelistTest is CommonScenarios {
    using MarketIdLibrary for MarketId;
    using ReserveKeyLibrary for *;
    using AccountIdLibrary for *;
    using stdStorage for StdStorage;

    /////////////////////////////////////////////
    //                 State                   //
    /////////////////////////////////////////////

    uint160 internal constant CORRECT_HOOK_FLAGS =
        uint160(BEFORE_SUPPLY_FLAG | BEFORE_BORROW_FLAG | BEFORE_MIGRATE_SUPPLY_FLAG);
    address internal constant CORRECT_HOOK_ADDRESS = 0x68820A239424DBC921d51edCBF332B41Ca1c1011;
    address internal constant WRONG_HOOK_ADDRESS = 0x00000000000000000000000000000000DeAd0000;

    SimpleAccountWhitelist internal _whitelistHook;
    MarketId internal _otherMarket;

    ////////////////////////////////////////////
    //               Modifiers                //
    ////////////////////////////////////////////

    modifier givenCorrectHookAddress() {
        // Mine for the correct hook address using the test contract as deployer
        // The market ID will be assigned when we create the market with the hook
        // setUp() creates market 1 (_otherMarket), whenMarketWithWhitelistHookExists creates market 2 (market)
        MarketId nextMarketId = MarketId.wrap(2);

        deployCodeTo(
            "SimpleAccountWhitelist.sol", abi.encode(admin, address(office), nextMarketId), CORRECT_HOOK_ADDRESS
        );
        _whitelistHook = SimpleAccountWhitelist(CORRECT_HOOK_ADDRESS);
        _;
    }

    modifier givenWrongHookAddress() {
        // Deploy the hook at an address with wrong flags
        MarketId nextMarketId = MarketId.wrap(2);

        deployCodeTo("SimpleAccountWhitelist.sol", abi.encode(admin, address(office), nextMarketId), WRONG_HOOK_ADDRESS);
        _whitelistHook = SimpleAccountWhitelist(WRONG_HOOK_ADDRESS);
        _;
    }

    modifier whenMarketWithWhitelistHookExists() {
        vm.startPrank(admin);

        // Create market with whitelist hook
        market = _createDefaultMarket(IHooks(address(_whitelistHook)));

        usdcKey = market.toReserveKey(usdc);
        wethKey = market.toReserveKey(weth);
        key = usdcKey;

        irm.setRate(key, getRatePerSecond(0.05e18));

        vm.stopPrank();
        _;
    }

    modifier whenOtherMarketExists() {
        // _otherMarket is already created in setUp
        _;
    }

    modifier givenAccountIsWhitelisted() {
        vm.startPrank(admin);
        _whitelistHook.setAccountWhitelist(account, true);
        vm.stopPrank();
        _;
    }

    modifier givenAccountIsNotWhitelisted() {
        // Account is not whitelisted by default
        _;
    }

    modifier givenAccountOwnerIsWhitelisted() {
        vm.startPrank(admin);
        address owner = office.ownerOf(account);
        _whitelistHook.setAddressWhitelist(owner, true);
        vm.stopPrank();
        _;
    }

    modifier givenAccountOwnerIsNotWhitelisted() {
        // Owner is not whitelisted by default
        _;
    }

    modifier givenEnoughLiquidityInTheReserveForWhitelistMarket() {
        vm.startPrank(admin);
        // Whitelist bob first so he can supply liquidity
        _whitelistHook.setAddressWhitelist(bob, true);

        // Set weights for the assets in the market
        weights.setWeight(usdcKey, wethKey, 0.6e18);

        vm.startPrank(bob);

        // Bob lends 100_000 USDC to the market.
        office.supply(
            SupplyParams({
                tokenId: usdcKey.toLentId(),
                account: bob.toUserAccount(),
                assets: 100_000e6, // 100_000 USDC
                extraData: ""
            })
        );

        vm.stopPrank();
        _;
    }

    function setUp() public override {
        super.setUp();

        vm.startPrank(admin);

        // Create a market for migration tests
        _otherMarket = createDefaultNoHooksMarket();
    }

    // Test case 1
    function test_Revert_WhenHookAddressHasWrongFlags() public {
        vm.startPrank(admin);

        // Try to deploy at an address with wrong flags
        // We need to predict what flags would be wrong at a particular address
        MarketId nextMarketId = MarketId.wrap(2);
        bytes memory creationCode = type(SimpleAccountWhitelist).creationCode;
        bytes memory constructorArgs = abi.encode(admin, address(office), nextMarketId);

        // Find a salt that produces wrong flags (any flags != CORRECT_HOOK_FLAGS)
        uint160 wrongFlags = 0; // No flags set
        (, bytes32 wrongSalt) = HookMiner.find(admin, wrongFlags, creationCode, constructorArgs);

        // It should revert with `BaseHook_IncorrectHooks` error
        // We just check that it reverts
        vm.expectPartialRevert(BaseHook.BaseHook_IncorrectHooks.selector);
        new SimpleAccountWhitelist{salt: wrongSalt}(admin, address(office), nextMarketId);
    }

    // Test case 2
    function test_WhenHookAddressHasCorrectFlags() public givenCorrectHookAddress {
        // It should deploy the hook at the correct address.
        assertTrue(address(_whitelistHook) == CORRECT_HOOK_ADDRESS, "Hook should be deployed at correct address");

        // It should correctly set the MARKET_ID (should be 2: setUp creates market 1, modifier creates market 2).
        assertEq(MarketId.unwrap(_whitelistHook.MARKET_ID()), 2, "Market ID should be 2");

        // It should set the correct owner.
        assertEq(_whitelistHook.owner(), admin, "Owner should be admin");

        // It should set the correct Office address.
        assertEq(_whitelistHook.OFFICE(), address(office), "Office address should be set correctly");
    }

    // Test case 3
    function test_WhenWhitelistingAccount_GivenCallerIsOwner()
        public
        givenCorrectHookAddress
        givenAccountIsIsolated
        givenAccountIsWhitelisted
    {
        // The `givenAccountIsWhitelisted` modifier whitelists the account.
        assertTrue(_whitelistHook.isWhitelistedAccount(account), "Account should be whitelisted");
    }

    // Test case 4
    function test_Revert_WhenWhitelistingAccount_GivenCallerIsNotOwner()
        public
        givenCorrectHookAddress
        givenAccountIsIsolated
    {
        vm.startPrank(alice);

        // It should revert with `OwnableUnauthorizedAccount` error
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        _whitelistHook.setAccountWhitelist(account, true);
    }

    // Test case 5
    function test_WhenRemovingAccountFromWhitelist_GivenCallerIsOwner()
        public
        givenCorrectHookAddress
        givenAccountIsIsolated
        givenAccountIsWhitelisted
    {
        vm.startPrank(admin);

        // It should remove the account from whitelist
        _whitelistHook.setAccountWhitelist(account, false);

        assertFalse(_whitelistHook.isWhitelistedAccount(account), "Account should not be whitelisted");
    }

    // Test case 6
    function test_Revert_WhenRemovingAccountFromWhitelist_GivenCallerIsNotOwner()
        public
        givenCorrectHookAddress
        givenAccountIsIsolated
        givenAccountIsWhitelisted
    {
        vm.startPrank(alice);

        // It should revert with `OwnableUnauthorizedAccount` error
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        _whitelistHook.setAccountWhitelist(account, false);
    }

    // Test case 7
    function test_WhenWhitelistingAddress_GivenCallerIsOwner() public givenCorrectHookAddress {
        vm.startPrank(admin);

        // It should whitelist the address
        _whitelistHook.setAddressWhitelist(alice, true);

        assertTrue(_whitelistHook.isWhitelistedAddress(alice), "Address should be whitelisted");
    }

    // Test case 8
    function test_Revert_WhenWhitelistingAddress_GivenCallerIsNotOwner() public givenCorrectHookAddress {
        vm.startPrank(alice);

        // It should revert with `OwnableUnauthorizedAccount` error
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        _whitelistHook.setAddressWhitelist(bob, true);
    }

    // Test case 9
    function test_WhenRemovingAddressFromWhitelist_GivenCallerIsOwner() public givenCorrectHookAddress {
        vm.startPrank(admin);
        _whitelistHook.setAddressWhitelist(alice, true);

        // It should remove the address from whitelist
        _whitelistHook.setAddressWhitelist(alice, false);

        assertFalse(_whitelistHook.isWhitelistedAddress(alice), "Address should not be whitelisted");
    }

    // Test case 10
    function test_Revert_WhenRemovingAddressFromWhitelist_GivenCallerIsNotOwner() public givenCorrectHookAddress {
        vm.startPrank(admin);
        _whitelistHook.setAddressWhitelist(alice, true);

        vm.startPrank(bob);

        // It should revert with `OwnableUnauthorizedAccount` error
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob));
        _whitelistHook.setAddressWhitelist(alice, false);
    }

    // Test case 11
    function test_WhenSupplyingToMarket_GivenAccountIsWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsWhitelisted
    {
        vm.startPrank(alice);

        // It should allow the supply action
        office.supply(SupplyParams({tokenId: usdcKey.toLentId(), account: account, assets: 1000e6, extraData: ""}));

        // It should have the correct balance
        assertTrue(office.balanceOf(account, usdcKey.toLentId()) > 0, "Account should have balance");
    }

    // Test case 12
    function test_Revert_WhenSupplyingToMarket_GivenAccountIsNotWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsNotWhitelisted
        givenAccountOwnerIsNotWhitelisted
    {
        vm.startPrank(alice);

        // It should revert with `SimpleAccountWhitelist_NotWhitelisted` error (wrapped in HookCallHelpers__HookCallFailed).
        vm.expectPartialRevert(HooksCallHelpers.HookCallHelpers__HookCallFailed.selector);
        office.supply(SupplyParams({tokenId: usdcKey.toLentId(), account: account, assets: 1000e6, extraData: ""}));
    }

    // Test case 13
    function test_WhenSupplyingToMarket_GivenAccountOwnerIsWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountOwnerIsWhitelisted
    {
        vm.startPrank(alice);

        // It should allow the supply action
        office.supply(SupplyParams({tokenId: usdcKey.toLentId(), account: account, assets: 1000e6, extraData: ""}));

        // It should have the correct balance
        assertTrue(office.balanceOf(account, usdcKey.toLentId()) > 0, "Account should have balance");
    }

    // Test case 14
    function test_Revert_WhenSupplyingToMarket_GivenAccountOwnerIsNotWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsNotWhitelisted
        givenAccountOwnerIsNotWhitelisted
    {
        vm.startPrank(alice);

        // It should revert with `SimpleAccountWhitelist_NotWhitelisted` error (wrapped in HookCallHelpers__HookCallFailed).
        vm.expectPartialRevert(HooksCallHelpers.HookCallHelpers__HookCallFailed.selector);
        office.supply(SupplyParams({tokenId: usdcKey.toLentId(), account: account, assets: 1000e6, extraData: ""}));
    }

    // Test case 15
    function test_WhenBorrowingFromMarket_GivenAccountIsWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsWhitelisted
        givenEnoughLiquidityInTheReserveForWhitelistMarket
    {
        vm.startPrank(alice);

        uint256 aliceUSDCBefore = usdc.balanceOf(alice);

        // First supply collateral
        office.supply(SupplyParams({tokenId: wethKey.toEscrowId(), account: account, assets: 1e18, extraData: ""}));

        // It should allow the borrow action
        office.borrow(BorrowParams({key: usdcKey, account: account, receiver: alice, assets: 1000e6, extraData: ""}));

        // It should have borrowed successfully
        assertTrue(usdc.balanceOf(alice) == aliceUSDCBefore + 1000e6, "Alice should have received USDC");
    }

    // Test case 16
    // There are at least 2 ways to test the functionality of the borrow hook. This test uses the method where a whitelisted account may have supplied
    // collateral and then transfers it to a non-whitelisted account before attempting to borrow.
    function test_Revert_WhenBorrowingFromMarket_GivenAccountIsNotWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsNotWhitelisted
        givenAccountOwnerIsNotWhitelisted
        givenEnoughLiquidityInTheReserveForWhitelistMarket
    {
        // Whitelist carol, supply collateral, then transfer to alice's account
        vm.startPrank(admin);
        _whitelistHook.setAddressWhitelist(carol, true);

        vm.startPrank(carol);
        AccountId carolAccount = carol.toUserAccount();
        office.supply(SupplyParams({tokenId: wethKey.toEscrowId(), account: carolAccount, assets: 1e18, extraData: ""}));
        office.transferFrom(carol, alice, wethKey.toEscrowId(), 1e18);

        vm.startPrank(alice);

        // It should revert with `SimpleAccountWhitelist_NotWhitelisted` error (wrapped in HookCallHelpers__HookCallFailed)
        vm.expectPartialRevert(HooksCallHelpers.HookCallHelpers__HookCallFailed.selector);
        office.borrow(BorrowParams({key: usdcKey, account: account, receiver: alice, assets: 1000e6, extraData: ""}));
    }

    // Test case 17
    function test_WhenBorrowingFromMarket_GivenAccountOwnerIsWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountOwnerIsWhitelisted
        givenEnoughLiquidityInTheReserveForWhitelistMarket
    {
        vm.startPrank(alice);

        uint256 aliceUSDCBefore = usdc.balanceOf(alice);

        // First supply collateral
        office.supply(SupplyParams({tokenId: wethKey.toEscrowId(), account: account, assets: 1e18, extraData: ""}));

        // It should allow the borrow action
        office.borrow(BorrowParams({key: usdcKey, account: account, receiver: alice, assets: 1000e6, extraData: ""}));

        // It should have borrowed successfully
        assertTrue(usdc.balanceOf(alice) == aliceUSDCBefore + 1000e6, "Alice should have received USDC");
    }

    // Test case 18
    // There are at least 2 ways to test the functionality of the borrow hook. This test uses the method where a whitelisted account may have supplied
    // collateral and then transfers it to a non-whitelisted account before attempting to borrow.
    function test_Revert_WhenBorrowingFromMarket_GivenAccountOwnerIsNotWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsNotWhitelisted
        givenAccountOwnerIsNotWhitelisted
        givenEnoughLiquidityInTheReserveForWhitelistMarket
    {
        // Whitelist carol, supply collateral, then transfer to alice's account
        vm.startPrank(admin);
        _whitelistHook.setAddressWhitelist(carol, true);

        vm.startPrank(carol);
        AccountId carolAccount = carol.toUserAccount();
        office.supply(SupplyParams({tokenId: wethKey.toEscrowId(), account: carolAccount, assets: 1e18, extraData: ""}));
        office.transferFrom(carol, alice, wethKey.toEscrowId(), 1e18);

        vm.startPrank(alice);

        // It should revert with `SimpleAccountWhitelist_NotWhitelisted` error (wrapped in HookCallHelpers__HookCallFailed)
        vm.expectPartialRevert(HooksCallHelpers.HookCallHelpers__HookCallFailed.selector);
        office.borrow(BorrowParams({key: usdcKey, account: account, receiver: alice, assets: 1000e6, extraData: ""}));
    }

    // Test case 19
    function test_WhenMigratingSupplyToMarket_GivenDestinationIsHooksMarket_GivenAccountIsWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        whenOtherMarketExists
        givenAccountIsIsolated
        givenAccountIsWhitelisted
    {
        // Supply to the other market first (non-whitelisted market)
        vm.startPrank(alice);
        office.supply(
            SupplyParams({
                tokenId: _otherMarket.toReserveKey(usdc).toLentId(), account: account, assets: 1000e6, extraData: ""
            })
        );

        // It should allow the migrate supply action
        office.migrateSupply(
            MigrateSupplyParams({
                account: account,
                fromTokenId: _otherMarket.toReserveKey(usdc).toLentId(),
                toTokenId: usdcKey.toLentId(),
                assets: 500e6,
                shares: 0,
                fromExtraData: "",
                toExtraData: ""
            })
        );

        // It should have migrated successfully
        assertTrue(office.balanceOf(account, usdcKey.toLentId()) > 0, "Account should have balance in whitelist market");
    }

    // Test case 20
    function test_Revert_WhenMigratingSupplyToMarket_GivenDestinationIsHooksMarket_GivenAccountIsNotWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        whenOtherMarketExists
        givenAccountIsIsolated
        givenAccountIsNotWhitelisted
        givenAccountOwnerIsNotWhitelisted
    {
        // Supply to the other market first (non-whitelisted market)
        vm.startPrank(alice);
        office.supply(
            SupplyParams({
                tokenId: _otherMarket.toReserveKey(usdc).toLentId(), account: account, assets: 1000e6, extraData: ""
            })
        );

        // It should revert with `SimpleAccountWhitelist_NotWhitelisted` error (wrapped in HookCallHelpers__HookCallFailed)
        vm.expectPartialRevert(HooksCallHelpers.HookCallHelpers__HookCallFailed.selector);
        office.migrateSupply(
            MigrateSupplyParams({
                account: account,
                fromTokenId: _otherMarket.toReserveKey(usdc).toLentId(),
                toTokenId: usdcKey.toLentId(),
                assets: 500e6,
                shares: 0,
                fromExtraData: "",
                toExtraData: ""
            })
        );
    }

    // Test case 21
    function test_WhenMigratingSupplyToMarket_GivenDestinationIsHooksMarket_GivenAccountOwnerIsWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        whenOtherMarketExists
        givenAccountIsIsolated
        givenAccountOwnerIsWhitelisted
    {
        // Supply to the other market first (non-whitelisted market)
        vm.startPrank(alice);
        office.supply(
            SupplyParams({
                tokenId: _otherMarket.toReserveKey(usdc).toLentId(), account: account, assets: 1000e6, extraData: ""
            })
        );

        // It should allow the migrate supply action
        office.migrateSupply(
            MigrateSupplyParams({
                account: account,
                fromTokenId: _otherMarket.toReserveKey(usdc).toLentId(),
                toTokenId: usdcKey.toLentId(),
                assets: 500e6,
                shares: 0,
                fromExtraData: "",
                toExtraData: ""
            })
        );

        // It should have migrated successfully
        assertTrue(office.balanceOf(account, usdcKey.toLentId()) > 0, "Account should have balance in whitelist market");
    }

    // Test case 22
    function test_Revert_WhenMigratingSupplyToMarket_GivenDestinationIsHooksMarket_GivenAccountOwnerIsNotWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        whenOtherMarketExists
        givenAccountIsIsolated
        givenAccountIsNotWhitelisted
        givenAccountOwnerIsNotWhitelisted
    {
        // Supply to the other market first (non-whitelisted market)
        vm.startPrank(alice);
        office.supply(
            SupplyParams({
                tokenId: _otherMarket.toReserveKey(usdc).toLentId(), account: account, assets: 1000e6, extraData: ""
            })
        );

        // It should revert with `SimpleAccountWhitelist_NotWhitelisted` error (wrapped in HookCallHelpers__HookCallFailed)
        vm.expectPartialRevert(HooksCallHelpers.HookCallHelpers__HookCallFailed.selector);
        office.migrateSupply(
            MigrateSupplyParams({
                account: account,
                fromTokenId: _otherMarket.toReserveKey(usdc).toLentId(),
                toTokenId: usdcKey.toLentId(),
                assets: 500e6,
                shares: 0,
                fromExtraData: "",
                toExtraData: ""
            })
        );
    }

    // Test case 23
    function test_WhenMigratingSupplyToMarket_GivenDestinationIsNotHooksMarket()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        whenOtherMarketExists
        givenAccountIsIsolated
        givenAccountIsNotWhitelisted
        givenAccountOwnerIsNotWhitelisted
    {
        // Whitelist temporarily to supply to whitelist market
        vm.startPrank(admin);
        _whitelistHook.setAccountWhitelist(account, true);

        // Supply to the whitelist market first
        vm.startPrank(alice);
        office.supply(SupplyParams({tokenId: usdcKey.toLentId(), account: account, assets: 1000e6, extraData: ""}));

        // Remove whitelist
        vm.startPrank(admin);
        _whitelistHook.setAccountWhitelist(account, false);

        vm.startPrank(alice);

        // It should allow the migrate supply action
        office.migrateSupply(
            MigrateSupplyParams({
                account: account,
                fromTokenId: usdcKey.toLentId(),
                toTokenId: _otherMarket.toReserveKey(usdc).toLentId(),
                assets: 500e6,
                shares: 0,
                fromExtraData: "",
                toExtraData: ""
            })
        );

        // It should have migrated successfully
        assertTrue(
            office.balanceOf(account, _otherMarket.toReserveKey(usdc).toLentId()) > 0,
            "Account should have balance in other market"
        );
    }

    // Test case 24
    function test_Revert_WhenHookIsNotCalledByOffice_GivenItIsSupplyHook()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsWhitelisted
    {
        vm.startPrank(alice);

        // It should revert.
        // With `BaseHook_OnlyOffice` error.
        vm.expectRevert(BaseHook.BaseHook_OnlyOffice.selector);
        _whitelistHook.beforeSupply(
            SupplyParams({tokenId: usdcKey.toLentId(), account: account, assets: 1000e6, extraData: ""})
        );
    }

    // Test case 25
    function test_Revert_WhenHookIsNotCalledByOffice_GivenItIsBorrowHook()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsWhitelisted
    {
        vm.startPrank(alice);

        // It should revert.
        // With `BaseHook_OnlyOffice` error.
        vm.expectRevert(BaseHook.BaseHook_OnlyOffice.selector);
        _whitelistHook.beforeBorrow(
            BorrowParams({key: usdcKey, account: account, receiver: alice, assets: 1000e6, extraData: ""})
        );
    }

    // Test case 26
    function test_Revert_WhenHookIsNotCalledByOffice_GivenItIsMigrateSupplyHook()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsWhitelisted
    {
        vm.startPrank(alice);

        // It should revert.
        // With `BaseHook_OnlyOffice` error.
        vm.expectRevert(BaseHook.BaseHook_OnlyOffice.selector);
        _whitelistHook.beforeMigrateSupply(
            MigrateSupplyParams({
                account: account,
                fromTokenId: _otherMarket.toReserveKey(usdc).toLentId(),
                toTokenId: usdcKey.toLentId(),
                assets: 500e6,
                shares: 0,
                fromExtraData: "",
                toExtraData: ""
            })
        );
    }
}

// Generated using co-pilot: Claude Sonnet 4.5
