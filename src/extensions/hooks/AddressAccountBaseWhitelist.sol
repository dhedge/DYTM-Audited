// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {AccountId} from "../../types/Types.sol";

import {IRegistry} from "../../interfaces/IRegistry.sol";
import {IAddressAccountBaseWhitelist} from "../../interfaces/IAddressAccountBaseWhitelist.sol";

/// @title AddressAccountBaseWhitelist
/// @notice Base contract for whitelisting accounts and account owners by address.
/// @author Chinmay <chinmay@dhedge.org>
abstract contract AddressAccountBaseWhitelist is IAddressAccountBaseWhitelist, Ownable {
    /////////////////////////////////////////////
    //                 State                   //
    /////////////////////////////////////////////

    /// @inheritdoc IAddressAccountBaseWhitelist
    IRegistry public immutable override REGISTRY;

    /// @inheritdoc IAddressAccountBaseWhitelist
    mapping(AccountId account => bool allowed) public isWhitelistedAccount;

    /// @inheritdoc IAddressAccountBaseWhitelist
    mapping(address accountOwner => bool allowed) public isWhitelistedAddress;

    /////////////////////////////////////////////
    //               Modifiers                 //
    /////////////////////////////////////////////

    modifier onlyAuthorized(AccountId account) {
        _verifyAccess(account);
        _;
    }

    /////////////////////////////////////////////
    //               Functions                 //
    /////////////////////////////////////////////

    /// @notice Constructor
    /// @param registry_ The registry contract to fetch account owner from.
    /// @param admin_ The admin address which will be set as the owner.
    constructor(IRegistry registry_, address admin_) Ownable(admin_) {
        require(address(registry_) != address(0), AddressAccountBaseWhitelist_ZeroAddress());

        REGISTRY = registry_;
    }

    /// @inheritdoc IAddressAccountBaseWhitelist
    function hasAccess(AccountId account) public view returns (bool allowed) {
        address accountOwner = REGISTRY.ownerOf(account);

        return isWhitelistedAddress[accountOwner] || isWhitelistedAccount[account];
    }

    /////////////////////////////////////////////
    //             Admin Functions             //
    /////////////////////////////////////////////

    /// @notice Adds or removes an account from the whitelist.
    /// @dev Doesn't revert if the account is already in the desired state.
    /// @param account The account to add or remove.
    /// @param allowed `true` to add the account, `false` to remove it.
    function setAccountWhitelist(AccountId account, bool allowed) external onlyOwner {
        // We don't check for zero account as it can never be used by the Office.

        isWhitelistedAccount[account] = allowed;

        emit AddressAccountBaseWhitelist_AccountWhitelistModified(account, allowed);
    }

    /// @notice Adds or removes an account owner from the whitelist.
    /// @dev Doesn't revert if the account owner is already in the desired state.
    /// @param accountOwner The account owner to add or remove.
    /// @param allowed `true` to add the account owner, `false` to remove it.
    function setAddressWhitelist(address accountOwner, bool allowed) external onlyOwner {
        require(accountOwner != address(0), AddressAccountBaseWhitelist_ZeroAddress());

        isWhitelistedAddress[accountOwner] = allowed;

        emit AddressAccountBaseWhitelist_AddressWhitelistModified(accountOwner, allowed);
    }

    /////////////////////////////////////////////
    //            Internal Functions           //
    /////////////////////////////////////////////

    function _verifyAccess(AccountId account) internal view {
        require(hasAccess(account), AddressAccountBaseWhitelist_NotWhitelisted(account, REGISTRY.ownerOf(account)));
    }
}
