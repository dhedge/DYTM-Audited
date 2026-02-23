// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {MarketId, ReserveKey, AccountId} from "../types/Types.sol";
import {TokenType} from "../libraries/TokenHelpers.sol";
import {IDelegatee} from "./IDelegatee.sol";

/**
 * @title ParamStructs
 * @author Chinmay <chinmay@dhedge.org>
 * @notice Parameter structures used across the DYTM protocol interfaces.
 * @dev These structs define the parameters for various market operations including
 *      supply, borrow, repay, liquidation, and other core functionality.
 */

/**
 * @notice Parameters for delegation calls.
 * @param delegatee The delegatee that will be called to perform batch operations.
 * @param callbackData Additional data that can be used by the delegatee to perform the operations.
 */
struct DelegationCallParams {
    IDelegatee delegatee;
    bytes callbackData;
}

/**
 * @notice Parameters for supply operations.
 * @param account The account which should receive the lending/escrow receipt tokens.
 * @param tokenId The tokenId of the receipt token token shares to mint.
 *                A user has a choice to supply the assets to either the lending market or to escrow.
 * @param assets The amount of the asset as encoded in the tokenId to supply.
 *               Use `type(uint256).max` to supply all the balance.
 * @param extraData Extra data that can be used by the hooks.
 */
struct SupplyParams {
    AccountId account;
    uint256 tokenId;
    uint256 assets;
    bytes extraData;
}

/**
 * @notice Parameters for switching collateral between escrow and lending market.
 * @dev Exactly one of `assets` or `shares` must be zero.
 * @param account The account whose collateral will be switched to escrow or lending market.
 * @param tokenId The collateral tokenId to switch.
 *                - If an escrow tokenId is provided, the shares will be switched to the lending market.
 *                - If a lending market tokenId is provided, the shares will be switched to escrow.
 * @param assets The amount of the asset (as encoded in the tokenId) to switch.
 * @param shares The amount of shares to switch.
 *               Use `type(uint256).max` to switch all shares.
 */
struct SwitchCollateralParams {
    AccountId account;
    uint256 tokenId;
    uint256 assets;
    uint256 shares;
}

/**
 * @notice Parameters for withdraw operations.
 * @dev Exactly one of `assets` or `shares` must be zero.
 * @param account The account from which the assets should be withdrawn.
 * @param tokenId The tokenId of the receipt token shares to withdraw.
 *                A user has a choice to withdraw the assets from either the lending market or from escrow.
 * @param receiver The address that will receive the withdrawn assets.
 * @param assets The amount of the asset (as encoded in the tokenId) to withdraw.
 * @param shares The amount of shares to redeem.
 *               Use `type(uint256).max` to redeem all the shares.
 * @param extraData Extra data that can be used by the hooks.
 */
struct WithdrawParams {
    AccountId account;
    uint256 tokenId;
    address receiver;
    uint256 assets;
    uint256 shares;
    bytes extraData;
}

/**
 * @notice Parameters for borrow operations.
 * @param account The account whose debt will be increased.
 * @param key The reserve key for the asset.
 * @param receiver The address that will be given the borrowed asset.
 * @param assets The amount to be borrowed.
 * @param extraData Extra data that can be used by the hooks.
 */
struct BorrowParams {
    AccountId account;
    ReserveKey key;
    address receiver;
    uint256 assets;
    bytes extraData;
}

/**
 * @notice Parameters for repay operations.
 * @dev Exactly one of `assets` or `shares` must be zero.
 * @param account The account whose debt will be repaid.
 * @param key The reserve key for the asset.
 * @param withCollateralType The TokenType of the collateral to be used for repaying the debt.
 *                           Can be used to repay using the supplied collateral (same as debt asset).
 *                           Only TokenType.ESCROW and TokenType.LEND are supported.
 *                           Use TokenType.NONE to indicate repayment is not done via collateral.
 * @param assets The amount of the asset to repay.
 *               Use `type(uint256).max` to repay debt using entire repayer balance.
 *               If repayer balance is greater than debt obligation, only the required amount will be pulled.
 * @param shares The amount of debt shares to repay.
 *               Use `type(uint256).max` to repay all the debt shares.
 * @param extraData Extra data that can be used by the hooks.
 */
struct RepayParams {
    AccountId account;
    ReserveKey key;
    TokenType withCollateralType;
    uint256 assets;
    uint256 shares;
    bytes extraData;
}

/**
 * @notice Parameters for collateral liquidation within a liquidation operation.
 * @dev At least one of `assets` or `shares` must be non-zero.
 * @param tokenId The collateral tokenId to withdraw from the account for liquidations.
 * @param assets The amount of the asset (as encoded in the tokenId) to liquidate.
 * @param shares The amount of shares to liquidate.
 *               Use `type(uint256).max` to liquidate all the shares.
 * @param inKind If true AND the reserve doesn't have enough liquidity of the underlying asset,
 *               the collateral shares will be transferred to the liquidator. Only applicable for
 *               TokenType.LEND type collateral. Note that this will be ignored if the reserve
 *               has enough liquidity to cover the liquidation.
 */
struct CollateralLiquidationParams {
    uint256 tokenId;
    uint256 assets;
    uint256 shares;
    bool inKind;
}

/**
 * @notice Parameters for liquidation operations.
 * @param account The account that has a debt in a market.
 * @param market The market identifier that the `account` has a debt in.
 * @param collateralParams The collateral tokenId shares and corresponding amounts to be liquidated.
 * @param callbackData Additional data that can be used by the liquidator to perform the liquidation.
 *                     The `liquidator` must implement the `ILiquidator` interface.
 * @param extraData Extra data that can be used by the hooks.
 */
struct LiquidationParams {
    AccountId account;
    MarketId market;
    CollateralLiquidationParams[] collateralParams;
    bytes callbackData;
    bytes extraData;
}

/**
 * @notice Parameters for supply migration operations between markets.
 * @dev Exactly one of `assets` or `shares` must be zero.
 * @param account The account whose assets will be migrated.
 * @param fromTokenId The tokenId that one wants to redeem/withdraw.
 * @param toTokenId The tokenId that one wants to get in exchange for the `fromTokenId`.
 * @param assets The amount of the asset (as encoded in the `fromTokenId`) to redeem and migrate.
 * @param shares The amount of shares to redeem and migrate.
 *               Use `type(uint256).max` to redeem and migrate all the shares.
 * @param fromExtraData Extra data that can be used by the hooks of the market of the `fromTokenId`.
 * @param toExtraData Extra data that can be used by the hooks of the market of the `toTokenId`.
 */
struct MigrateSupplyParams {
    AccountId account;
    uint256 fromTokenId;
    uint256 toTokenId;
    uint256 assets;
    uint256 shares;
    bytes fromExtraData;
    bytes toExtraData;
}
