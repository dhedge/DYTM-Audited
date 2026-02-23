// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AccountId} from "../../types/Types.sol";

import {SimpleMarketConfig} from "./SimpleMarketConfig.sol";

import {IOffice} from "../../interfaces/IOffice.sol";
import {IAddressAccountBaseWhitelist} from "../../interfaces/IAddressAccountBaseWhitelist.sol";

/// @title WhitelistedTransfersMarketConfig
/// @notice Market config contract that restricts share transfers to whitelisted accounts only.
/// @dev Requires the `hooks` contract to implement `IAddressAccountBaseWhitelist` but
///      does not enforce this given that the `hooks` contract is configurable.
/// @author Chinmay <chinmay@dhedge.org>
contract WhitelistedTransfersMarketConfig is SimpleMarketConfig {
    constructor(
        address initialOwner,
        IOffice office,
        ConfigInitParams memory params
    )
        SimpleMarketConfig(initialOwner, office, params)
    {}

    /// @notice Overrides the default share transfer permission logic to include whitelist checks.
    /// @dev Only verifies whether the receiver account is whitelisted.
    /// @param to The account to which shares are being transferred.
    /// @return canTransfer `true` if the transfer is allowed, `false` otherwise.
    function canTransferShares(
        AccountId,
        AccountId to,
        uint256,
        uint256
    )
        external
        view
        override
        returns (bool canTransfer)
    {
        return IAddressAccountBaseWhitelist(address(hooks)).hasAccess(to);
    }
}
