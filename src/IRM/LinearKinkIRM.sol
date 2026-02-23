// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import {Office} from "../Office.sol";
import {OfficeStorage} from "../abstracts/storages/OfficeStorage.sol";

import {IIRM} from "../interfaces/IIRM.sol";

import {ReserveKey} from "../types/Types.sol";
import {ReserveKeyLibrary} from "../types/ReserveKey.sol";

import {WAD} from "../libraries/Constants.sol";

/// @title LinearKinkIRM
/// @notice A simple kink based linear Interest Rate Model (IRM).
/// @dev Can be used for any number of markets as long as the officer address is non-zero.
/// @dev Based on the RareSkills article <https://www.rareskills.io/post/aave-interest-rate-model>.
/// @author Chinmay <chinmay@dhedge.org>
contract LinearKinkIRM is IIRM {
    using FixedPointMathLib for uint256;
    using ReserveKeyLibrary for ReserveKey;

    //////////////////////////////////////////////
    //                 Events                   //
    //////////////////////////////////////////////

    event LinearKinkIRM__ParametersModified(ReserveKey indexed key, IRMParams oldParams, IRMParams newParams);

    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error LinearKinkIRM__NotOfficer(address officer);
    error LinearKinkIRM__InvalidOptimalUtilization(uint256 optimalUtilization);

    /////////////////////////////////////////////
    //                Structs                  //
    /////////////////////////////////////////////

    /// @notice Interest rate parameters for each reserve.
    /// @param baseRatePerSecond Min rate when utilization > 0 (in per second format).
    /// @param slope1PerSecond Rate of increase below optimal utilization (in per second format).
    /// @param slope2PerSecond Rate of increase above optimal utilization (in per second format).
    /// @param optimalUtilization The optimal utilization rate (in WAD format, e.g., 0.8e18 = 80%).
    struct IRMParams {
        uint256 baseRatePerSecond;
        uint256 slope1PerSecond;
        uint256 slope2PerSecond;
        uint256 optimalUtilization;
    }

    /////////////////////////////////////////////
    //              State Variables            //
    /////////////////////////////////////////////

    /// @notice The Office contract which will consume the data from this IRM.
    Office public immutable OFFICE;

    /// @notice Mapping from reserve key to IRM parameters
    mapping(ReserveKey key => IRMParams params) public irmParams;

    ////////////////////////////////////////////////
    //                  Functions                 //
    ////////////////////////////////////////////////

    constructor(Office office_) {
        OFFICE = office_;
    }

    /// @inheritdoc IIRM
    function borrowRate(ReserveKey key) external view returns (uint256 ratePerSecond) {
        return _calculateBorrowRate(key);
    }

    /// @inheritdoc IIRM
    function borrowRateView(ReserveKey key) external view returns (uint256 ratePerSecond) {
        return _calculateBorrowRate(key);
    }

    /// @notice Set the interest rate parameters for a specific reserve.
    /// @param key The reserve key for which the parameters are being set.
    /// @param newParams The new IRM parameters to be set.
    function setParams(ReserveKey key, IRMParams calldata newParams) external {
        IRMParams memory oldParams = irmParams[key];

        require(OFFICE.getOfficer(key.getMarketId()) == msg.sender, LinearKinkIRM__NotOfficer(msg.sender));
        require(
            newParams.optimalUtilization <= WAD, LinearKinkIRM__InvalidOptimalUtilization(newParams.optimalUtilization)
        );

        // Accrue interest before changing parameters.
        // If the asset is not borrow enabled, the reserves `lastUpdateTimestamp` will still
        // be updated to the current block timestamp.
        OFFICE.accrueInterest(key);

        // Update parameters
        irmParams[key] = newParams;

        emit LinearKinkIRM__ParametersModified({key: key, oldParams: oldParams, newParams: newParams});
    }

    /// @notice Calculate the current utilization rate for a reserve.
    /// @param key The reserve key.
    /// @return utilization The utilization rate in WAD format.
    function getUtilization(ReserveKey key) public view returns (uint256 utilization) {
        OfficeStorage.ReserveData memory reserveData = OFFICE.getReserveData(key);

        if (reserveData.supplied == 0) {
            return 0;
        }

        // Calculate utilization: borrowed / supplied
        utilization = reserveData.borrowed.divWadDown(reserveData.supplied);
    }

    ////////////////////////////////////////////////
    //              Internal Functions            //
    ////////////////////////////////////////////////

    /// @notice Calculate the borrow rate based on utilization and IRM parameters.
    /// @dev [!WARNING]: This function doesn't revert if IRM parameters are not set.
    ///                  It will just return 0 instead.
    /// @param key The reserve key.
    /// @return ratePerSecond The borrow rate per second.
    function _calculateBorrowRate(ReserveKey key) internal view returns (uint256 ratePerSecond) {
        IRMParams memory params = irmParams[key];

        // We assume that if optimalUtilization is 0, the IRM is not configured.
        if (params.optimalUtilization == 0) {
            return 0;
        }

        uint256 utilization = getUtilization(key);

        if (utilization <= params.optimalUtilization) {
            // Below optimal utilization: baseRate + (utilization * slope1) / optimalUtilization
            uint256 utilizationRatio = utilization.divWadDown(params.optimalUtilization);

            ratePerSecond = params.baseRatePerSecond + utilizationRatio.mulWadDown(params.slope1PerSecond);
        } else {
            // Above optimal utilization: baseRate + slope1 + ((utilization - optimal) * slope2) / (1 - optimal)
            uint256 excessUtilization = utilization - params.optimalUtilization;
            uint256 excessUtilizationRatio = excessUtilization.divWadDown(WAD - params.optimalUtilization);

            ratePerSecond = params.baseRatePerSecond + params.slope1PerSecond
                + excessUtilizationRatio.mulWadDown(params.slope2PerSecond);
        }
    }
}
