// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {AccountId, MarketId} from "../../types/Types.sol";
import {MARKET_ID_ZERO} from "../../libraries/Constants.sol";
import {TokenHelpers} from "../../libraries/TokenHelpers.sol";
import {SupplyParams, BorrowParams, MigrateSupplyParams} from "../../interfaces/ParamStructs.sol";
import {BEFORE_SUPPLY_FLAG, BEFORE_BORROW_FLAG, BEFORE_MIGRATE_SUPPLY_FLAG} from "../../libraries/Constants.sol";

import {BaseHook} from "./BaseHook.sol";
import {AddressAccountBaseWhitelist} from "./AddressAccountBaseWhitelist.sol";

import {IRegistry} from "../../interfaces/IRegistry.sol";

/// @title SimpleAccountWhitelist
/// @notice A simple whitelist contract that can be used to restrict access to DYTM protocol
///         to a predefined set of whitelisted accounts and owners. The owner of this contract can add or
///         remove accounts from the whitelist. This contract is intended to be used as a hook contract
///         in the DYTM protocol. The following hooks are enabled:
///           1. beforeSupply
///           2. beforeBorrow
///           3. beforeMigrateSupply
///         This means only certain addresses or actions on certain accounts are allowed to be performed.
///         We don't explicitly enable/disable other hooks given that the above hooks are sufficient to
///         restrict access to the protocol.
/// @author Chinmay <chinmay@dhedge.org>
contract SimpleAccountWhitelist is AddressAccountBaseWhitelist, BaseHook {
    using TokenHelpers for uint256;

    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error SimpleAccountWhitelist_ZeroMarketId();

    /////////////////////////////////////////////
    //                 State                   //
    /////////////////////////////////////////////

    /// @notice The market id for which this hook contract is enabled.
    MarketId public immutable MARKET_ID;

    /////////////////////////////////////////////
    //               Functions                 //
    /////////////////////////////////////////////

    /// @notice SimpleAccountWhitelist constructor.
    /// @param admin The admin/owner of this contract.
    /// @param office The address of the Office contract.
    /// @param marketId The market id for which this hook contract is enabled.
    constructor(
        address admin,
        address office,
        MarketId marketId
    )
        AddressAccountBaseWhitelist(IRegistry(office), admin)
        BaseHook(BEFORE_SUPPLY_FLAG | BEFORE_BORROW_FLAG | BEFORE_MIGRATE_SUPPLY_FLAG, office)
    {
        require(marketId != MARKET_ID_ZERO, SimpleAccountWhitelist_ZeroMarketId());

        MARKET_ID = marketId;
    }

    /////////////////////////////////////////////
    //              Hook Functions             //
    /////////////////////////////////////////////

    /// @notice Only allows whitelisted accounts/owners to supply.
    /// @param params The supply parameters.
    function beforeSupply(SupplyParams calldata params) public override onlyAuthorized(params.account) {
        super.beforeSupply(params);
    }

    /// @notice Only allows whitelisted accounts/owners to borrow.
    /// @param params The borrow parameters.
    function beforeBorrow(BorrowParams calldata params) public override onlyAuthorized(params.account) {
        super.beforeBorrow(params);
    }

    /// @notice Only allows whitelisted accounts/owners to migrate supply.
    /// @dev Verifies that the account is whitelisted only if the destination market is the hook's designated market.
    /// @param params The migrate supply parameters.
    function beforeMigrateSupply(MigrateSupplyParams calldata params) public override {
        super.beforeMigrateSupply(params);

        // If some account is migrating supply to the hook's designated market, verify the account.
        if (params.toTokenId.getMarketId() == MARKET_ID) {
            _verifyAccess(params.account);
        }
    }
}
