// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {AccountId} from "../types/Types.sol";

import {IRegistry} from "./IRegistry.sol";

/// @title IAddressAccountBaseWhitelist
/// @notice Interface for the AddressAccountBaseWhitelist contract.
/// @author Chinmay <chinmay@dhedge.org>
interface IAddressAccountBaseWhitelist {
    /////////////////////////////////////////////
    //                 Events                  //
    /////////////////////////////////////////////

    event AddressAccountBaseWhitelist_AccountWhitelistModified(AccountId indexed account, bool isWhitelisted);
    event AddressAccountBaseWhitelist_AddressWhitelistModified(address indexed accountOwner, bool isWhitelisted);

    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error AddressAccountBaseWhitelist_ZeroAddress();
    error AddressAccountBaseWhitelist_NotWhitelisted(AccountId account, address accountOwner);

    /////////////////////////////////////////////
    //               Functions                 //
    /////////////////////////////////////////////

    /**
     * @notice The registry contract to fetch account owner from.
     * @return registry The registry contract interface.
     */
    function REGISTRY() external view returns (IRegistry registry);

    /**
     * @notice Mapping to track whitelisted accounts.
     * @param account The account id.
     * @return allowed Whether the account is whitelisted.
     */
    function isWhitelistedAccount(AccountId account) external view returns (bool allowed);

    /**
     * @notice Mapping to track whitelisted account owners.
     * @param accountOwner The account owner address.
     * @return allowed Whether the account owner is whitelisted.
     */
    function isWhitelistedAddress(address accountOwner) external view returns (bool allowed);

    /**
     * @notice Verifies if the given account or its owner is whitelisted.
     * @dev Implicitly verifies access for the owner address of the given account.
     * @param account The account to verify access for.
     * @return allowed `true` if either the account or its owner is whitelisted.
     */
    function hasAccess(AccountId account) external view returns (bool allowed);
}
