// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../helpers/CommonFunctions.sol";

struct AccountSuppliedAmount {
    uint256 usdcLentAmount;
    uint256 wethLentAmount;
    uint256 usdcEscrowedAmount;
    uint256 wethEscrowedAmount;
    uint256 usdcLendingShareAmount;
    uint256 wethLendingShareAmount;
    uint256 usdcEscrowShareAmount;
    uint256 wethEscrowShareAmount;
}

/// @dev When using the modifiers, note that the order of modifiers matters in the
///      derived contracts.
abstract contract CommonScenarios is CommonFunctions {
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;
    using FixedPointMathLib for uint256;

    MarketId internal market;
    ReserveKey internal key;
    AccountId internal account;
    AccountId internal account2;
    address internal caller;
    address internal loanReceiver;
    uint256 tokenId;

    ReserveKey internal wethKey;
    ReserveKey internal usdcKey;

    AccountSuppliedAmount internal accountSuppliedAmountBefore;

    modifier whenMarketExists() virtual {
        _;
    }

    modifier whenReserveExists() virtual {
        vm.startPrank(admin);

        // Create a default market with no hooks.
        market = createDefaultNoHooksMarket();

        usdcKey = market.toReserveKey(usdc);
        wethKey = market.toReserveKey(weth);

        // By default we will use USDC as the reserve key.
        // This can be overriden using `whenEscrowingAsset` or `whenLendingAsset` modifiers.
        key = usdcKey;

        // Set the borrow rate for the reserve.
        irm.setRate(key, getRatePerSecond(0.05e18)); // 5% annual interest rate

        vm.stopPrank();
        _;
    }

    modifier whenReserveIsNotSupported() {
        vm.startPrank(admin);

        // Create a default market with no hooks.
        market = createDefaultNoHooksMarket();

        MockERC20 dummyToken = new MockERC20();
        dummyToken.initialize("Dummy token", "DUMMY", 6);

        key = market.toReserveKey(dummyToken);

        vm.stopPrank();
        _;
    }

    modifier whenReserveIsBorrowable() {
        // USDC reserve is borrow enabled in the default market.
        // Nothing to do here, just a placeholder for clarity.
        _;
    }

    modifier whenReserveIsNotBorrowable() {
        // WETH reserve is not borrow enabled in the default market.
        key = market.toReserveKey(weth);
        _;
    }

    modifier whenPerformanceFeeSet() {
        vm.startPrank(admin);

        // Set performance fee to 20%
        marketConfig.setPerformanceFee(0.2e18);

        vm.stopPrank();
        _;
    }

    modifier whenCallerIsOwner() {
        caller = office.ownerOf(account);
        _;
    }

    /// @dev It's assumed that `keeper` is not the given any special permissions for the account.
    modifier whenCallerIsNotAuthorized() {
        caller = keeper;
        _;
    }

    modifier whenCallerIsOperator() {
        caller = operator;

        vm.startPrank(office.ownerOf(account));

        // Set the operator for the account.
        office.setOperator(operator, account, true);

        vm.stopPrank();
        _;
    }

    modifier whenCallerIsOfficer() {
        caller = admin; // admin is the officer from createDefaultNoHooksMarket
        _;
    }

    // To be used when an isolated account is expected
    // and it also exists.
    modifier whenIsolatedAccountExists() {
        _;
    }

    // To be used when an isolated account is expected
    // but does not exist yet.
    modifier whenIsolatedAccountDoesNotExist() {
        account = uint96(69).toIsolatedAccount();
        _;
    }

    modifier whenLendingAsset(ReserveKey key_) {
        key = key_;
        tokenId = key_.toLentId();
        _;
    }

    modifier whenEscrowingAsset(ReserveKey key_) {
        key = key_;
        tokenId = key_.toEscrowId();
        _;
    }

    modifier givenEnoughLiquidityInTheReserve() {
        vm.startPrank(bob);

        // Bob lends 1_000_000 USDC to the market.
        office.supply(
            SupplyParams({
                tokenId: market.toReserveKey(usdc).toLentId(),
                account: bob.toUserAccount(),
                assets: 100_000e6, // 100_000 USDC
                extraData: ""
            })
        );

        vm.stopPrank();
        _;
    }

    // To be used when you don't want to use an isolated account
    // for the test scenario.
    modifier givenAccountIsNotIsolated() {
        // The account is not isolated, so it is a user account.
        account = alice.toUserAccount();
        _;
    }

    // To be used when you want to use an isolated account
    // for the test scenario.
    modifier givenAccountIsIsolated() {
        // Create an isolated account for Alice.
        account = office.createIsolatedAccount(alice);
        _;
    }

    // Note, `whenCallerIsOwner` and `whenCallerIsNotAuthorized` need to be used before this modifier.
    modifier whenUsingSuppliedPlusEscrowedAssets() {
        // We will supply and escrow assets in the account.

        vm.startPrank(caller);

        // Lend 1000 USDC to the market.
        office.supply(
            SupplyParams({
                tokenId: market.toReserveKey(usdc).toLentId(),
                account: account,
                assets: 1000e6, // 1000 USDC
                extraData: ""
            })
        );

        // Escrow 1 WETH in the account.
        office.supply(
            SupplyParams({
                tokenId: market.toReserveKey(weth).toEscrowId(),
                account: account,
                assets: 1e18, // 1 WETH
                extraData: ""
            })
        );

        accountSuppliedAmountBefore.usdcLentAmount += 1000e6; // 1000 USDC lent
        accountSuppliedAmountBefore.wethEscrowedAmount += 1e18; // 1 WETH escrowed

        // Refresh the account share amounts.
        _refreshAccountShareAmounts();

        vm.stopPrank();

        _;
    }

    /// @dev Should be used only after `whenUsingSuppliedPlusEscrowedAssets` modifier.
    ///      - Can only be used for over-collateralized loans.
    ///      - Can only be used for USDC if it's borrowable.
    modifier whenTheAccountHasADebtPosition() {
        vm.startPrank(caller);

        office.borrow(
            BorrowParams({
                key: usdcKey,
                account: account,
                receiver: caller,
                assets: 2000e6, // 2000 USDC (equivalent to the WETH escrowed value)
                extraData: ""
            })
        );

        vm.stopPrank();

        _;
    }

    modifier givenAccountIsHealthy() {
        _;
    }

    modifier givenAccountIsUnhealthy() {
        oracleModule.setPrice(address(weth), 1200e8); // $1200/WETH
        _;
    }

    modifier givenAccountHasBadDebt() {
        oracleModule.setPrice(address(weth), 100e8); // $100/WETH
        _;
    }

    modifier givenTheAccountWillBeHealthy() {
        _;
    }

    modifier givenTheAccountWillBecomeUnhealthy() {
        _;
    }

    modifier whenTakingAnUndercollateralizedLoan() {
        _;
    }

    modifier givenTheReceiverReturnsSufficientCollateral() {
        _;
    }

    modifier whenOngoingDelegationCall() {
        _;
    }

    // To be used when you want collateral to consist mostly of the debt asset (USDC)
    // This modifier should be used instead of `whenUsingSuppliedPlusEscrowedAssets`
    modifier givenAccountHasCollateralMostlyInDebtAsset() {
        // We will supply assets with most collateral being in the debt asset (USDC)
        // The account health will be controlled by subsequent modifiers that adjust WETH price

        vm.startPrank(caller);

        // Lend 4000 USDC to the market - this makes USDC the dominant collateral
        office.supply(
            SupplyParams({
                tokenId: usdcKey.toLentId(),
                account: account,
                assets: 1600e6, // 1600 USDC
                extraData: ""
            })
        );

        // Escrow 1 WETH in the account.
        office.supply(
            SupplyParams({
                tokenId: wethKey.toEscrowId(),
                account: account,
                assets: 0.5e18, // 0.5 WETH => $1000
                extraData: ""
            })
        );

        accountSuppliedAmountBefore.usdcLentAmount += 1600e6; // 1600 USDC lent
        accountSuppliedAmountBefore.wethEscrowedAmount += 0.5e18; // 0.5 WETH escrowed

        // Refresh the account share amounts.
        _refreshAccountShareAmounts();

        vm.stopPrank();

        _;
    }

    /// @dev The caller should be set to desired address before using this modifier.
    modifier givenSecondAccountIsSetup() {
        vm.startPrank(caller);

        // Create a source account to merge from
        account2 = office.createIsolatedAccount(caller);

        // Supply assets to the source account
        SupplyParams memory supplyParamsUsdc =
            SupplyParams({tokenId: usdcKey.toLentId(), account: account2, assets: 1000e6, extraData: ""});
        office.supply(supplyParamsUsdc);

        SupplyParams memory supplyParamsWeth =
            SupplyParams({tokenId: wethKey.toEscrowId(), account: account2, assets: 1e18, extraData: ""});
        office.supply(supplyParamsWeth);

        // Borrow some assets on the source account
        BorrowParams memory borrowParams =
            BorrowParams({key: usdcKey, account: account2, receiver: caller, assets: 2000e6, extraData: ""});
        office.borrow(borrowParams);

        vm.stopPrank();
        _;
    }

    function _refreshAccountShareAmounts() private {
        accountSuppliedAmountBefore.usdcLendingShareAmount = office.balanceOf(account, usdcKey.toLentId());
        accountSuppliedAmountBefore.wethLendingShareAmount = office.balanceOf(account, wethKey.toLentId());
        accountSuppliedAmountBefore.usdcEscrowShareAmount = office.balanceOf(account, usdcKey.toEscrowId());
        accountSuppliedAmountBefore.wethEscrowShareAmount = office.balanceOf(account, wethKey.toEscrowId());
    }
}
