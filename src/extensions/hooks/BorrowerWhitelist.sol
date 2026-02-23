// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {MarketId} from "../../types/Types.sol";
import {MARKET_ID_ZERO} from "../../libraries/Constants.sol";
import {BorrowParams} from "../../interfaces/ParamStructs.sol";
import {BEFORE_BORROW_FLAG} from "../../libraries/Constants.sol";

import {BaseHook} from "./BaseHook.sol";
import {AddressAccountBaseWhitelist} from "./AddressAccountBaseWhitelist.sol";

import {IRegistry} from "../../interfaces/IRegistry.sol";

/// @title BorrowerWhitelist
/// @notice A simple whitelist contract that can be used to restrict borrowing access to DYTM protocol
///         to a predefined set of whitelisted accounts and owners. The owner of this contract can add or
///         remove accounts from the whitelist. This contract is intended to be used as a hook contract
///         in the DYTM protocol. The following hook is enabled:
///           1. beforeBorrow
///         This means only certain addresses or actions on certain accounts are allowed to borrow.
/// @author Chinmay <chinmay@dhedge.org>
contract BorrowerWhitelist is AddressAccountBaseWhitelist, BaseHook {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error BorrowerWhitelist_ZeroMarketId();

    /////////////////////////////////////////////
    //                 State                   //
    /////////////////////////////////////////////

    /// @notice The market id for which this hook contract is enabled.
    MarketId public immutable MARKET_ID;

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @notice Constructor
    /// @param admin The admin address for the Ownable contract.
    /// @param office The DYTM office address.
    /// @param marketId The market id for which this hook contract is enabled.
    constructor(
        address admin,
        address office,
        MarketId marketId
    )
        AddressAccountBaseWhitelist(IRegistry(office), admin)
        BaseHook(BEFORE_BORROW_FLAG, office)
    {
        require(marketId != MARKET_ID_ZERO, BorrowerWhitelist_ZeroMarketId());

        MARKET_ID = marketId;
    }

    /////////////////////////////////////////////
    //              Hook Functions             //
    /////////////////////////////////////////////

    /// @notice Only allows whitelisted accounts/owners to borrow.
    /// @param params The borrow parameters.
    function beforeBorrow(BorrowParams calldata params) public override onlyAuthorized(params.account) {
        super.beforeBorrow(params);
    }
}
