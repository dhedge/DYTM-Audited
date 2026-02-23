// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.29;

import {EnumerableSet} from "@openzeppelin-contracts/utils/structs/EnumerableSet.sol";

import {MarketId, ReserveKey} from "../../types/Types.sol";
import {ReserveKeyLibrary} from "../../types/ReserveKey.sol";

import {getOfficeStorageStruct} from "../../libraries/StorageAccessors.sol";

import {IMarketConfig} from "../../interfaces/IMarketConfig.sol";
import {IOfficeStorage} from "../../interfaces/IOfficeStorage.sol";

/// @title OfficeStorage
/// @notice Abstract contract that manages the storage for the Office contract.
/// @author Chinmay <chinmay@dhedge.org>
abstract contract OfficeStorage is IOfficeStorage {
    using ReserveKeyLibrary for *;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /////////////////////////////////////////////
    //                 Events                 //
    /////////////////////////////////////////////

    event OfficeStorage__OfficerModified(MarketId indexed market, address newOfficer, address oldOfficer);
    event OfficeStorage__MarketConfigModified(
        MarketId indexed market, IMarketConfig prevMarketConfig, IMarketConfig newMarketConfig
    );

    /////////////////////////////////////////////
    //                  Errors                 //
    /////////////////////////////////////////////

    error OfficeStorage__ZeroAddress();
    error OfficeStorage__NotOfficer(MarketId market, address caller);

    /////////////////////////////////////////////
    //                 Structs                 //
    /////////////////////////////////////////////

    /// @param marketCount The total number of markets created in the Office.
    /// @param officers Mapping of market ID to officer address.
    /// @param reserveData Mapping of reserve key to reserve data.
    /// @param configs Mapping of market ID to market configuration contract.
    /// @custom:storage-location erc7201:DYTM.storage.Office
    struct OfficeStorageStruct {
        uint88 marketCount;
        mapping(MarketId market => address officer) officers;
        mapping(ReserveKey key => ReserveData data) reserveData;
        mapping(MarketId market => IMarketConfig config) configs;
    }

    /////////////////////////////////////////////
    //                Modifiers                //
    /////////////////////////////////////////////

    modifier onlyOfficer(MarketId market) {
        _verifyOfficer(market);
        _;
    }

    /////////////////////////////////////////////
    //                 Setters                 //
    /////////////////////////////////////////////

    /// @notice Sets the market configuration for a given market.
    /// @dev > [!WARNING] Interest should be accrued on all reserves before changing the fee percentage
    ///      > or IRM by setting a new market configuration.
    /// @param market The market ID for which to set the configuration.
    /// @param marketConfig The market configuration to set.
    function setMarketConfig(MarketId market, IMarketConfig marketConfig) external onlyOfficer(market) {
        _setMarketConfig(market, marketConfig);
    }

    /// @notice Changes the officer for a given market.
    /// @dev Note: The officer can be the zero address for immutable markets.
    /// @param market The market ID for which to change the officer.
    /// @param newOfficer The address of the new officer.
    function changeOfficer(MarketId market, address newOfficer) external onlyOfficer(market) {
        _setOfficer(market, newOfficer);
    }

    /////////////////////////////////////////////
    //                 Getters                 //
    /////////////////////////////////////////////

    /// @inheritdoc IOfficeStorage
    function getMarketConfig(MarketId market) public view returns (IMarketConfig marketConfig) {
        return getOfficeStorageStruct().configs[market];
    }

    /// @inheritdoc IOfficeStorage
    function getOfficer(MarketId market) public view returns (address officer) {
        return getOfficeStorageStruct().officers[market];
    }

    /// @inheritdoc IOfficeStorage
    function getReserveData(ReserveKey key) public view returns (ReserveData memory reserveData) {
        return getOfficeStorageStruct().reserveData[key];
    }

    /////////////////////////////////////////////
    //            Internal Functions           //
    /////////////////////////////////////////////

    function _setMarketConfig(MarketId market, IMarketConfig newMarketConfig) internal {
        IMarketConfig prevMarketConfig = getMarketConfig(market);

        require(address(newMarketConfig) != address(0), OfficeStorage__ZeroAddress());

        getOfficeStorageStruct().configs[market] = newMarketConfig;

        emit OfficeStorage__MarketConfigModified(market, prevMarketConfig, newMarketConfig);
    }

    function _setOfficer(MarketId market, address newOfficer) internal {
        address oldOfficer = getOfficer(market);
        getOfficeStorageStruct().officers[market] = newOfficer;

        emit OfficeStorage__OfficerModified(market, newOfficer, oldOfficer);
    }

    function _verifyOfficer(MarketId market) internal view {
        require(msg.sender == getOfficer(market), OfficeStorage__NotOfficer(market, msg.sender));
    }
}
