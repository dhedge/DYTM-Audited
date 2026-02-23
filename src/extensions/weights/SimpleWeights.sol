// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import {IWeights} from "../../interfaces/IWeights.sol";
import {IMarketConfig} from "../../interfaces/IMarketConfig.sol";
import {IOfficeStorage} from "../../interfaces/IOfficeStorage.sol";

import {ReserveKey, AccountId, MarketId} from "../../types/Types.sol";
import {ReserveKeyLibrary} from "../../types/ReserveKey.sol";
import {TokenHelpers} from "../../libraries/TokenHelpers.sol";

import {WAD} from "../../libraries/Constants.sol";

/// @title SimpleWeights
/// @author Chinmay <chinmay@dhedge.org>
/// @notice A simple weights contract that can be used to set weights between different assets.
/// @dev Can be used only by the officer of the market(s) to set weights.
/// @dev Doesn't revert if no weight is set for a particular asset pair. It simply returns 0 in that case.
/// @dev If weights are set too high with no buffer (apart from liquidation bonus percentage), it can lead to debt/bad debt
///      in the system. For example, if `BUFFER` is 0.75% and liquidation bonus percentage is 1.25%, then the maximum
///      weight that can be set is 0.98e18. However, if a Chainlink oracle is being used which updates price if there
///      is a 2% deviation, then an attacker can open a position with max leverage before the price update and then
///      when the price is updated, the position may instantly create debt/bad debt. Set weights with extreme caution
///      and don't blindly assume `BUFFER` is sufficient.
/// @dev While the `setWeight` function takes an `account` parameter, it is only used to fetch
///      liquidation bonus percentages from the market config. The `getWeight` function ignores it.
///      DO NOT USE THIS CONTRACT IF YOU NEED ACCOUNT-SPECIFIC WEIGHTS.
/// @dev > [!WARNING] For same asset pairs (debt == collateral), the weights SHOULD NOT BE set to WAD (1e18).
///      > This is to avoid a user to leverage it to a ridiculously high degree and then creating
///      > bad debt in the system with ease. Unless you trust the borrower(s), do not do this.
contract SimpleWeights is IWeights {
    using TokenHelpers for uint256;
    using FixedPointMathLib for uint256;
    using ReserveKeyLibrary for ReserveKey;

    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error SimpleWeights__ZeroAddress();
    error SimpleWeights__AssetStillSupported(IERC20 asset);
    error SimpleWeights__NotOfficer(MarketId market, address caller);
    error SimpleWeights__InvalidWeight(uint64 weight, uint64 bonusPercentage);

    /////////////////////////////////////////////
    //                 State                   //
    /////////////////////////////////////////////

    /// @notice A buffer between weight and (1 - liquidation bonus percentage).
    /// @dev For example if weight is 0.98e18 and buffer is 0.75% then max liquidation bonus percentage
    ///      can be 0.0125e18 (1.25%).
    /// @dev Buffer should be set according to the deviation thresholds of the price oracles being used on
    ///      the network. For example, most of the oracles of Chainlink on Ethereum update price if there is a 2% deviation.
    ///      On Arbitrum, this deviation is 0.5%. So buffer should be set to a value greater than these deviations to be safe.
    uint64 public immutable BUFFER;

    /// @notice The Office contract address.
    /// @dev Used to fetch market configurations.
    IOfficeStorage public immutable OFFICE_STORAGE;

    /// @notice Mapping of collateral token ID to debt reserve key to raw weight.
    mapping(uint256 collateralTokenId => mapping(ReserveKey debtKey => uint64 weight)) public rawWeights;

    /////////////////////////////////////////////
    //               Functions                 //
    /////////////////////////////////////////////

    constructor(IOfficeStorage officeStorage, uint64 buffer) {
        require(address(officeStorage) != address(0), SimpleWeights__ZeroAddress());

        OFFICE_STORAGE = officeStorage;
        BUFFER = buffer;
    }

    /// @notice - Returns the weight of the collateral asset in relation to the debt asset.
    ///         - If the weight between the two assets doesn't exist, it returns 0.
    ///         - Doesn't differentiate between escrowed and lent collateral.
    ///         - Doesn't consider the `account` parameter.
    /// @param collateralTokenId The token ID of the collateral asset.
    /// @param debtKey The reserve key of the debt asset.
    /// @return weight The weight of the collateral asset in relation to the debt asset.
    function getWeight(
        AccountId,
        /* account */
        uint256 collateralTokenId,
        ReserveKey debtKey
    )
        external
        view
        returns (uint64 weight)
    {
        weight = rawWeights[collateralTokenId][debtKey];
    }

    /////////////////////////////////////////////
    //             Admin Functions             //
    /////////////////////////////////////////////

    /// @notice Sets the weight of a collateral asset in relation to a debt asset.
    /// @dev - Doesn't revert if the weight is already set to the desired value.
    ///      - Isn't symmetric. Must set both directions if needed.
    ///      - Weights must be set for lent collateral and escrowed collateral separately.
    ///      - The sum of weight and liquidation bonus percentage must be less than or equal to (1 - BUFFER).
    ///      - Only the officer of the market can call this function.
    ///      - When disabling a collateral asset, this function would revert if the asset
    ///        is still supported in the market config.
    /// @param account The account ID to pass to the market config while fetching liquidation bonus percentages.
    /// @param collateralTokenId The token ID of the collateral asset in a particular market.
    /// @param debtKey The reserve key of the debt asset.
    /// @param weight The weight of the collateral asset in relation to the debt asset.
    ///               Must be less than or equal to WAD.
    function setWeight(AccountId account, uint256 collateralTokenId, ReserveKey debtKey, uint64 weight) external {
        MarketId market = collateralTokenId.getMarketId();
        IMarketConfig marketConfig = OFFICE_STORAGE.getMarketConfig(market);
        uint64 bonusPercentage = marketConfig.liquidationBonusPercentage({
            account: account, collateralTokenId: collateralTokenId, debtKey: debtKey
        });
        IERC20 collateralAsset = collateralTokenId.getAsset();

        require(msg.sender == OFFICE_STORAGE.getOfficer(market), SimpleWeights__NotOfficer(market, msg.sender));

        // The following requirement is derived as follows (courtesy of xiaoming90):
        // Where w = weight, b = bonusPercentage, c = collateral value, D = current debt.
        //  Current Debt <= Debt Repaid
        //  D <= c/(1+b)
        //  w*c <= c/(1+b)
        //  w <= 1/(1+b)
        //  w(1+b) <= 1
        require(
            uint256(weight).mulWadDown(WAD + bonusPercentage) <= WAD - BUFFER,
            SimpleWeights__InvalidWeight(weight, bonusPercentage)
        );
        require(
            weight != 0 || !marketConfig.isSupportedAsset(collateralAsset),
            SimpleWeights__AssetStillSupported(collateralAsset)
        );

        rawWeights[collateralTokenId][debtKey] = weight;
    }
}
