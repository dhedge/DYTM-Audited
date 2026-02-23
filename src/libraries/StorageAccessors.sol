// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {OfficeStorage} from "../abstracts/storages/OfficeStorage.sol";
import {Registry} from "../abstracts/Registry.sol";

import {ReserveKey} from "../types/Types.sol";

import {OFFICE_STORAGE_LOCATION, ACCOUNTS_STORAGE_LOCATION} from "../libraries/Constants.sol";

// solhint-disable private-vars-leading-underscore

/// @dev Function to get the storage pointer for the office storage struct.
/// @return $ The storage pointer for the office storage struct.
function getOfficeStorageStruct() pure returns (OfficeStorage.OfficeStorageStruct storage $) {
    bytes32 slot = OFFICE_STORAGE_LOCATION;

    assembly {
        $.slot := slot
    }
}

/// @dev Function to get the storage pointer for the accounts storage struct.
/// @return $ The storage pointer for the accounts storage struct.
function getRegistryStorageStruct() pure returns (Registry.RegistryStorageStruct storage $) {
    bytes32 slot = ACCOUNTS_STORAGE_LOCATION;

    assembly {
        $.slot := slot
    }
}

/// @dev Function to get the storage pointer for the reserve data.
/// @param key The reserve key for the asset.
/// @return reserveData The storage pointer for the reserve data.
function getReserveDataStorage(ReserveKey key) view returns (OfficeStorage.ReserveData storage reserveData) {
    return getOfficeStorageStruct().reserveData[key];
}
