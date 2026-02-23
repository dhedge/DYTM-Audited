// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";

import {
    DelegationCallParams,
    SupplyParams,
    SwitchCollateralParams,
    BorrowParams,
    WithdrawParams,
    RepayParams,
    LiquidationParams,
    MigrateSupplyParams
} from "./ParamStructs.sol";

import {MarketId, AccountId, ReserveKey} from "../types/Types.sol";
import {TokenType} from "../libraries/TokenHelpers.sol";

import {IContext} from "./IContext.sol";
import {IRegistry} from "./IRegistry.sol";
import {IMarketConfig} from "./IMarketConfig.sol";
import {IOfficeStorage} from "./IOfficeStorage.sol";

/**
 * @title IOffice
 * @author Chinmay <chinmay@dhedge.org>
 * @notice Main Office contract interface.
 * @dev Note that certain functions have the `extraData` parameter which is not used by the Office contract
 *      directly but are passed to the hooks contract if:
 *          - it is not address(0)
 *          - if the hooks contract has subscribed to the hooks.
 */
interface IOffice is IOfficeStorage, IRegistry, IContext {
    /////////////////////////////////////////////
    //                  Events                 //
    /////////////////////////////////////////////

    event Office__AssetDonated(ReserveKey indexed key, uint256 assets);
    event Office__PerformanceFeeMinted(ReserveKey indexed key, uint256 shares);
    event Office__AssetBorrowed(AccountId indexed account, ReserveKey indexed key, uint256 assets);
    event Office__AssetFlashloaned(address indexed receiver, IERC20 indexed token, uint256 assets);
    event Office__AssetSupplied(AccountId indexed account, uint256 indexed tokenId, uint256 shares, uint256 assets);
    event Office__MarketCreated(address indexed officer, IMarketConfig indexed marketConfig, MarketId indexed market);
    event Office__CollateralSwitched(
        AccountId indexed account, uint256 indexed fromTokenId, uint256 oldShares, uint256 newShares, uint256 assets
    );
    event Office__AssetWithdrawn(
        AccountId indexed account, address indexed receiver, uint256 indexed tokenId, uint256 shares, uint256 assets
    );
    event Office__DebtRepaid(
        AccountId indexed account, address indexed repayer, ReserveKey indexed key, uint256 shares, uint256 assets
    );
    event Office__SupplyMigrated(
        AccountId indexed account,
        uint256 indexed fromTokenId,
        uint256 indexed toTokenId,
        uint256 oldSharesRedeemed,
        uint256 assetsRedeemed,
        uint256 newSharesMinted
    );
    event Office__AccountLiquidated(
        AccountId indexed account,
        address indexed liquidator,
        MarketId indexed market,
        uint256 repaidShares,
        uint256 repaidAssets,
        uint256 unpaidShares,
        uint256 unpaidAssets
    );

    /////////////////////////////////////////////
    //                  Errors                 //
    /////////////////////////////////////////////

    error Office__NoAssetsRepaid();
    error Office__ReserveIsEmpty(ReserveKey key);
    error Office__IncorrectTokenId(uint256 tokenId);
    error Office__AssetNotBorrowable(ReserveKey key);
    error Office__ReserveNotSupported(ReserveKey key);
    error Office__InvalidHooksContract(address hooks);
    error Office__AccountNotCreated(AccountId account);
    error Office__CannotLiquidateDuringDelegationCall();
    error Office__InKindWithdrawalsOnlyForLiquidation();
    error Office__InvalidFraction(uint64 givenFraction);
    error Office__InsufficientLiquidity(ReserveKey key);
    error Office__InvalidCollateralType(TokenType withCollateralType);
    error Office__AccountNotHealthy(AccountId account, MarketId market);
    error Office__AssetsAndSharesNonZero(uint256 assets, uint256 shares);
    error Office__AccountStillHealthy(AccountId account, MarketId market);
    error Office__MismatchedAssetsInMigration(IERC20 fromAsset, IERC20 toAsset);
    error Office__SameMarketInMigration(uint256 fromTokenId, uint256 toTokenId);
    error Office__ZeroAssetsOrSharesWithdrawn(AccountId account, ReserveKey key);
    error Office__DebtBelowMinimum(uint256 debtValueUSD, uint256 minDebtValueUSD);
    error Office__TransferNotAllowed(AccountId from, AccountId to, uint256 tokenId, uint256 shares);

    //////////////////////////////////////////////
    //               Main Functions             //
    //////////////////////////////////////////////

    /**
     * @notice Function to create a new market.
     *
     * Call will revert if the market already exists or the params are invalid.
     *
     * @param officer The address of the officer of the new market.
     * @param marketConfig The market configuration contract for the new market.
     * @return marketId The Id of the newly created market.
     */
    function createMarket(address officer, IMarketConfig marketConfig) external returns (MarketId marketId);

    /**
     * @notice Function to perform multiple calls on behalf of an account.
     *
     *  The delegatee must implement the `IDelegatee` interface and must be able to handle the `onDelegationCallback`
     *  function.
     *
     * > [!WARNING]
     * >  - This function temporarily grants the delegatee operator access to all the callers' authorized accounts.
     * >  - Health checks for the accounts involved in the delegation call are performed only after the call if necessary.
     * >    This allows users to create temporary undercollateralized positions within the delegation context.
     * >    This behavior introduces a read-only reentrancy vector, where an attacker could exploit external integrations or hooks
     * >    that rely on real-time collateral status. By having temporary undercollateralized positions, the attacker may
     * >    trigger unintended behaviors in those systems, potentially leading to fund loss or incorrect state transitions.
     * >    If real-time collateral status is critical for your use case, consider calling `isHealthyAccount` to check an account's
     * >    health within your integration.
     *
     * @param params The parameters for the delegation call in the form of a `DelegationCallParams` struct.
     * @return returnData The return data from the delegatee's `onDelegationCallback` function.
     */
    function delegationCall(DelegationCallParams calldata params) external returns (bytes memory returnData);

    /**
     * @notice Function to deposit loan asset into a market.
     *
     * - Anyone can supply tokens for an account even if the account is not yet created
     * - One can lend a supported asset even if the the asset is not borrowable. If it is enabled for borrowing,
     *   interest will start accruing automatically. However, this collateral may not be considered for borrowing
     *   until the appropriate weights are set by the officer.
     *
     * > [!WARNING]
     *   If supplying for a non-existent account which the caller assumes will be theirs in the next transaction, make sure you consider front-running risk as
     *   you may end up supplying tokens for an account that belongs to someone else.
     *
     * @param params The parameters for supplying tokens in the form of a `SupplyParams` struct.
     * @return shares The amount of shares minted for the supplied amount.
     */
    function supply(SupplyParams calldata params) external returns (uint256 shares);

    /**
     * @notice Function to switch a collateral from escrow to lending market or vice versa.
     *
     * - Although the same can be achieved by withdrawing and then supplying the asset
     *   using `delegationCall`, this function is more gas efficient and easier to use as it doesn't transfer assets.
     * - Will revert if the account is unhealthy after switching collateral.
     *
     * @param params The parameters for switching collateral in the form of a `SwitchCollateralParams` struct.
     * @return assets The amount of assets switched from escrow to lending market or vice versa.
     * @return shares The new amount of shares minted for the `assets`.
     */
    function switchCollateral(SwitchCollateralParams calldata params) external returns (uint256 assets, uint256 shares);

    /**
     * @notice Function to withdraw an asset from a market.
     *
     * - Allows only authorized callers of the account to withdraw assets.
     * - Will revert if the account is unhealthy after withdrawal.
     *
     * @param params The parameters for withdrawing tokens in the form of a `WithdrawParams` struct.
     * @return assets The amount of assets withdrawn from the market.
     */
    function withdraw(WithdrawParams calldata params) external returns (uint256 assets);

    /**
     * @notice Function to borrow an asset from a market and then escrow some asset(s) in the account.
     *
     * - Allows users to take out an undercollateralized loan before escrowing/lending asset(s) to
     *   meet the required health check condition via `delegationCall`.
     * - Operators of an account can invoke this function.
     * - Will revert if:
     *      - The account is unhealthy after borrowing.
     *      - The asset address provided is not borrowable in the market.
     *      - The account already has a debt in an asset and is trying to borrow a different asset.
     *
     * @param params The parameters for borrowing in the form of `BorrowParams` struct
     * @return debtShares The amount of debt shares created for the borrowed amount.
     */
    function borrow(BorrowParams calldata params) external returns (uint256 debtShares);

    /**
     * @notice Function to repay a debt position in a market.
     *
     * - Allows authorized callers of the account to repay the debt.
     * - Will revert if the account is unhealthy after withdrawal.
     * - Allows repayment using collateral shares of the same asset as the debt asset.
     *
     * @param params The parameters for repaying tokens in the form of a `RepayParams` struct.
     * @return assetsRepaid The amount of assets worth of debt repaid in the market.
     */
    function repay(RepayParams calldata params) external returns (uint256 assetsRepaid);

    /**
     * @notice Function to liquidate an unhealthy account in a market.
     *
     * - Allows anyone to liquidate an unhealthy account.
     * - The liquidator must calculate the collateral shares to liquidate for partial or full liquidation.
     * - The liquidator must approve enough debt asset amount to the Office for repayment.
     * - In case the collateral shares being liquidated are those of a lent asset and if the reserve
     *   doesn't have enough liquidity of the underlying asset, the liquidator can choose to receive
     *   the collateral shares instead of the underlying asset. They will only receive shares instead of assets
     *   if the reserve cannot cover the liquidation in assets.
     *
     * > [!WARNING]
     * > - Regardless of bad debt accrual, the liquidator will always receive a bonus.
     * > - To change this behaviour, the officer can change the bonus percentage to 0 using the before liquidation hook.
     *     However, this will make the job of liquidators harder as they need to calculate the exact amount of
     *     shares/assets to liquidate after the bonus percentage modification.
     *
     * @param params The parameters for liquidation in the form of a `LiquidationParams` struct.
     * @return assetsRepaid The amount of assets worth of debt repaid in the market after accounting for the bonus.
     */
    function liquidate(LiquidationParams calldata params) external returns (uint256 assetsRepaid);

    /**
     * @notice Function to migrate supply from one market to another.
     *
     * - The asset being migrated must be the same and accepted in the new market.
     *
     * @param params The parameters for migrating supply in the form of a `MigrateSupplyParams` struct.
     * @return assetsRedeemed The amount of assets redeemed from the old market.
     * @return newSharesMinted The amount of new shares minted in the new market.
     */
    function migrateSupply(MigrateSupplyParams calldata params)
        external
        returns (uint256 assetsRedeemed, uint256 newSharesMinted);

    /**
     * @notice Function to donate to a lending reserve of a market.
     *
     * - This function increases the `supplied` amount of the reserve.
     * - Can only be called by the officer of the market.
     * - Doesn't check if the asset of the reserve is borrowable or not.
     * - Once donated, the assets can't be clawed back.
     * - Can't donate if reserve `supplied` amount is 0.
     * - It's possible to donate to a reserve whose `supplied` amount is not 0 but is currently
     *   not supported.
     *
     * @param key The reserve key for which the donation is being made.
     * @param amount The amount of the token to be donated to the reserve.
     */
    function donateToReserve(ReserveKey key, uint256 amount) external;

    /**
     * @notice Function to perform a flashloan.
     *
     * - The receiver must implement the `IFlashloanReceiver` interface and must
     *   be able to handle the `onFlashloanCallback` function.
     * - The receiver must also approve the Office contract to transfer the borrowed amount back.
     *
     * @param token The token to be borrowed in the flashloan.
     * @param amount The amount of the token to be borrowed in the flashloan.
     * @param callbackData Additional data that can be used by the receiver.
     */
    function flashloan(IERC20 token, uint256 amount, bytes calldata callbackData) external;

    /**
     * @notice Function to accrue interest for a reserve.
     *
     * - Updates reserves `lastUpdateTimestamp` to the current block timestamp.
     * - If the asset is not borrow enabled (or recently disabled) and if utilization is non-zero,
     *   the interest will accrue.
     *
     * @param key The reserve key for which the reserves are being updated.
     * @return interest The amount of interest accrued for the borrowers of the reserve since the last update.
     */
    function accrueInterest(ReserveKey key) external returns (uint256 interest);

    /**
     * @notice Checks if the `account` is healthy for a debt position in a `market`.
     *
     * - If the `account` has no debt position in the market, it's considered healthy even if
     *   the account has no collateral in the market.
     * - If the weighted collaterals' value in USD is less than (necessary conditions):
     *      - the debt value in USD for the market
     *      - the minimum margin amount in USD for the market
     *   then the account is considered unhealthy.
     *
     * @dev This is a non-view function because it needs to accrue interest on all reserves
     *      the account is part of before performing the health check. Use static call related
     *      functions in libraries such as Viem or ethers.js to perform a view-like call.
     * @param account The account ID to check.
     * @param market The market ID to check.
     * @return isHealthy True if the account is healthy, false otherwise.
     */
    function isHealthyAccount(AccountId account, MarketId market) external returns (bool isHealthy);
}
