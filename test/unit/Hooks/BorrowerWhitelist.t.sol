// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract BorrowerWhitelistTest is CommonScenarios {
    using MarketIdLibrary for MarketId;
    using ReserveKeyLibrary for *;
    using AccountIdLibrary for *;
    using stdStorage for StdStorage;

    /////////////////////////////////////////////
    //                 State                   //
    /////////////////////////////////////////////

    uint160 internal constant CORRECT_HOOK_FLAGS = uint160(BEFORE_BORROW_FLAG);
    address internal constant CORRECT_HOOK_ADDRESS = 0x8421542496f5FAd0D6761DB419E14512B4554010;

    BorrowerWhitelist internal _whitelistHook;
    MarketId internal _otherMarket;

    ////////////////////////////////////////////
    //               Modifiers                //
    ////////////////////////////////////////////

    modifier givenCorrectHookAddress() {
        // Mine for the correct hook address using the test contract as deployer
        // The market ID will be assigned when we create the market with the hook
        // setUp() creates market 1 (_otherMarket), whenMarketWithWhitelistHookExists creates market 2 (market)
        MarketId nextMarketId = MarketId.wrap(2);

        deployCodeTo("BorrowerWhitelist.sol", abi.encode(admin, address(office), nextMarketId), CORRECT_HOOK_ADDRESS);
        _whitelistHook = BorrowerWhitelist(CORRECT_HOOK_ADDRESS);
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
    function test_WhenSupplyingToMarket_GivenAccountIsNotWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsNotWhitelisted
        givenAccountOwnerIsNotWhitelisted
    {
        vm.startPrank(alice);

        // It should allow the supply action.
        office.supply(SupplyParams({tokenId: usdcKey.toLentId(), account: account, assets: 1000e6, extraData: ""}));

        // It should have the correct balance.
        assertTrue(office.balanceOf(account, usdcKey.toLentId()) > 0, "Account should have balance");
    }

    // Test case 2
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

        // It should allow the borrow action.
        office.borrow(BorrowParams({key: usdcKey, account: account, receiver: alice, assets: 1000e6, extraData: ""}));

        // It should have borrowed successfully.
        assertTrue(usdc.balanceOf(alice) == aliceUSDCBefore + 1000e6, "Alice should have received USDC");
    }

    // Test case 3
    function test_Revert_WhenBorrowingFromMarket_GivenAccountIsNotWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsNotWhitelisted
        givenAccountOwnerIsNotWhitelisted
        givenEnoughLiquidityInTheReserveForWhitelistMarket
    {
        vm.startPrank(alice);

        // First supply collateral
        office.supply(SupplyParams({tokenId: wethKey.toEscrowId(), account: account, assets: 1e18, extraData: ""}));

        // It should revert.
        // With `BorrowerWhitelist_NotWhitelisted` error.
        vm.expectPartialRevert(HooksCallHelpers.HookCallHelpers__HookCallFailed.selector);
        office.borrow(BorrowParams({key: usdcKey, account: account, receiver: alice, assets: 1000e6, extraData: ""}));
    }

    // Test case 4
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

        // It should allow the borrow action.
        office.borrow(BorrowParams({key: usdcKey, account: account, receiver: alice, assets: 1000e6, extraData: ""}));

        // It should have borrowed successfully.
        assertTrue(usdc.balanceOf(alice) == aliceUSDCBefore + 1000e6, "Alice should have received USDC");
    }

    // Test case 5
    function test_Revert_WhenBorrowingFromMarket_GivenAccountOwnerIsNotWhitelisted()
        public
        givenCorrectHookAddress
        whenMarketWithWhitelistHookExists
        givenAccountIsIsolated
        givenAccountIsNotWhitelisted
        givenAccountOwnerIsNotWhitelisted
        givenEnoughLiquidityInTheReserveForWhitelistMarket
    {
        vm.startPrank(alice);

        // First supply collateral
        office.supply(SupplyParams({tokenId: wethKey.toEscrowId(), account: account, assets: 1e18, extraData: ""}));

        // It should revert.
        // With `BorrowerWhitelist_NotWhitelisted` error.
        vm.expectPartialRevert(HooksCallHelpers.HookCallHelpers__HookCallFailed.selector);
        office.borrow(BorrowParams({key: usdcKey, account: account, receiver: alice, assets: 1000e6, extraData: ""}));
    }

    // Test case 6
    function test_WhenMigratingSupplyToMarket_GivenDestinationMarketIsHooksDesignatedMarket_GivenAccountIsNotWhitelisted()
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

        // It should allow the migrate supply action.
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

        // It should have migrated successfully.
        assertTrue(office.balanceOf(account, usdcKey.toLentId()) > 0, "Account should have balance in whitelist market");
    }
}

// Generated using co-pilot: Claude Sonnet 4.5
