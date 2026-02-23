// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Office} from "../Office.sol";

import {IIRM} from "../interfaces/IIRM.sol";

import {ReserveKey} from "../types/Types.sol";
import {ReserveKeyLibrary} from "../types/ReserveKey.sol";

/// @title FixedBorrowRateIRM
/// @notice A simple fixed borrow rate Interest Rate Model (IRM).
/// @dev Can be used for any number of markets as long as the officer address is non-zero.
/// @author Chinmay <chinmay@dhedge.org>
contract FixedBorrowRateIRM is IIRM {
    using ReserveKeyLibrary for ReserveKey;

    ////////////////////////////////////////////////
    //                   Events                   //
    ////////////////////////////////////////////////

    event FixedBorrowRateIRM__RateModified(ReserveKey indexed key, uint256 newRate, uint256 oldRate);

    ///////////////////////////////////////////////
    //                   Errors                  //
    ///////////////////////////////////////////////

    error FixedBorrowRateIRM__NotOfficer(address officer);

    ///////////////////////////////////////////////
    //               State Variables             //
    ///////////////////////////////////////////////

    /// @notice The Office contract which will consume the data from this IRM.
    Office public immutable OFFICE;

    /// @inheritdoc IIRM
    mapping(ReserveKey key => uint256 ratePerSecond) public borrowRateView;

    ////////////////////////////////////////////////
    //                  Functions                 //
    ////////////////////////////////////////////////

    constructor(Office office_) {
        OFFICE = office_;
    }

    /// @inheritdoc IIRM
    function borrowRate(ReserveKey key) external view returns (uint256 ratePerSecond) {
        return borrowRateView[key];
    }

    /// @notice Set a new interest rate for a specific reserve.
    /// @param key The reserve key for which the interest rate is being set.
    /// @param newRatePerSecond The new interest rate per second to be set.
    function setRate(ReserveKey key, uint256 newRatePerSecond) external {
        uint256 oldRatePerSecond = borrowRateView[key];

        require(OFFICE.getOfficer(key.getMarketId()) == msg.sender, FixedBorrowRateIRM__NotOfficer(msg.sender));

        // Accrue interest before changing parameters.
        // If the asset is not borrow enabled, this will have no effect.
        OFFICE.accrueInterest(key);

        borrowRateView[key] = newRatePerSecond;

        emit FixedBorrowRateIRM__RateModified({key: key, newRate: newRatePerSecond, oldRate: oldRatePerSecond});
    }
}
