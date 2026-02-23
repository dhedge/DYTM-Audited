// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";
import {IIRM} from "./IIRM.sol";
import {IHooks} from "./IHooks.sol";
import {IWeights} from "./IWeights.sol";
import {AccountId, ReserveKey} from "../types/Types.sol";
import {IOracleModule} from "./IOracleModule.sol";

/**
 * @title IMarketConfig
 * @notice Interface for the market configuration contract.
 * @author Chinmay <chinmay@dhedge.org>
 */
interface IMarketConfig {
    /**
     * @notice The Interest Rate Model (IRM) for the market.
     * @dev MUST NOT be null address.
     * @return irm The IRM contract interface.
     */
    function irm() external view returns (IIRM irm);

    /**
     * @notice The Hooks contract for the market.
     * @dev MAY BE null address if no hooks are used.
     * @return hooks The Hooks contract interface.
     */
    function hooks() external view returns (IHooks hooks);

    /**
     * @notice The Weights contract for the market.
     * @dev MUST NOT be null address.
     * @return weights The Weights contract interface.
     */
    function weights() external view returns (IWeights weights);

    /**
     * @notice The Oracle Module for the market.
     * @dev MUST NOT be null address.
     * @return oracleModule The Oracle Module contract interface.
     */
    function oracleModule() external view returns (IOracleModule oracleModule);

    /**
     * @notice The recipient of the performance fees for the market.
     * @dev MAY BE null address only if `feePercentage` is zero.
     * @return feeRecipient The address of the fee recipient.
     */
    function feeRecipient() external view returns (address feeRecipient);

    /**
     * @notice The percentage of the performance fee for the market.
     * @dev - MAY BE zero.
     *      - MUST BE in the range of 0 to 1e18 (WAD units).
     * @return feePercentage The fee percentage.
     */
    function feePercentage() external view returns (uint64 feePercentage);

    /**
     * @notice The liquidation bonus percentage for liquidators in the market.
     * @dev MUST BE in the range of 0 to 1e18 (WAD units).
     * @param account The account being liquidated.
     * @param collateralTokenId The collateral asset token ID being liquidated.
     * @param debtKey The reserve key of the debt asset being repaid by the liquidator.
     * @return liquidationBonusPercentage The liquidation bonus percentage.
     */
    function liquidationBonusPercentage(
        AccountId account,
        uint256 collateralTokenId,
        ReserveKey debtKey
    )
        external
        view
        returns (uint64 liquidationBonusPercentage);

    /**
     * @notice The minimum debt amount in USD for the market.
     * @dev Helps in prevention of bad debt accumulation due to dust borrow positions.
     * @dev - MUST BE in WAD units (e.g. $1 = 1e18).
     *      - MAY BE zero.
     * @return minDebtAmountUSD The minimum debt amount in USD.
     */
    function minDebtAmountUSD() external view returns (uint128 minDebtAmountUSD);

    /**
     * @notice Checks if the asset is supported.
     * @dev MUST NOT revert if the asset is not supported.
     * @param asset The asset to check.
     * @return isSupported `true` if the asset is supported, `false` otherwise.
     */
    function isSupportedAsset(IERC20 asset) external view returns (bool isSupported);

    /**
     * @notice Checks if the asset is borrowable.
     * @dev MUST NOT revert if the asset is not supported and/or not borrowable.
     * @param asset The asset to check.
     * @return isBorrowable `true` if the asset is borrowable, `false` otherwise.
     */
    function isBorrowableAsset(IERC20 asset) external view returns (bool isBorrowable);

    /**
     * @notice Checks if the transfer of shares between two accounts is allowed.
     *
     * > [!WARNING]
     * > Doesn't prevent minting/redemption of shares even if the account
     * > is explicitly restricted from transferring/receiving shares.
     * > Make sure proper hook checks are in place if needed for such cases.
     *
     * @dev MAY revert.
     * @param from The account from which shares are transferred.
     * @param to The account to which shares are transferred.
     * @param tokenId The tokenId of the shares to be transferred.
     * @param shares The amount of shares to be transferred.
     * @return canTransfer `true` if the transfer is allowed, `false` otherwise.
     */
    function canTransferShares(
        AccountId from,
        AccountId to,
        uint256 tokenId,
        uint256 shares
    )
        external
        view
        returns (bool canTransfer);
}
