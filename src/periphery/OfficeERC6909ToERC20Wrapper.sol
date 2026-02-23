// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ReentrancyGuardTransient} from "@openzeppelin-contracts/utils/ReentrancyGuardTransient.sol";

import {MarketId} from "../types/Types.sol";
import {TokenHelpers} from "../libraries/TokenHelpers.sol";

import {WrappedERC6909ERC20} from "./WrappedERC6909ERC20.sol";

import {IRegistry} from "../interfaces/IRegistry.sol";

interface IOfficeStorage {
    function getOfficer(MarketId market) external view returns (address officer);
}

/// @title OfficeERC6909ToERC20Wrapper
/// @notice Wrapper singleton contract for ERC6909 <> ERC20 tokens.
/// @dev Ideally, should be deployed at the same address across all networks.
///      Since we use CREATE2, the deployed wrapped ERC20 token addresses can be the same across networks.
///      provided the ERC6909 token ID is the same, which means the address of the
///      ERC20 asset it represents should also be the same.
/// @author Chinmay <chinmay@dhedge.org>
/// @custom:attribution Adapted from <https://etherscan.io/address/0x000000000020979cc92752fa2708868984a7f746?s=09#code>
contract OfficeERC6909ToERC20Wrapper is ReentrancyGuardTransient {
    using TokenHelpers for uint256;

    /////////////////////////////////////////////
    //                 Events                  //
    /////////////////////////////////////////////

    event OfficeERC6909ToERC20Wrapper__Registered(uint256 indexed id, address indexed erc20);
    event OfficeERC6909ToERC20Wrapper__Wrapped(uint256 indexed id, address indexed erc20, uint256 amount);
    event OfficeERC6909ToERC20Wrapper__Unwrapped(uint256 indexed id, address indexed erc20, uint256 amount);

    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error OfficeERC6909ToERC20Wrapper__Reentrancy();
    error OfficeERC6909ToERC20Wrapper__ZeroAddress();
    error OfficeERC6909ToERC20Wrapper__ERC20AlreadyRegistered(uint256 id);
    error OfficeERC6909ToERC20Wrapper__NotOfficer(MarketId market, address caller);
    error OfficeERC6909ToERC20Wrapper__TransferFailed(address from, address to, uint256 id, uint256 amount);

    /////////////////////////////////////////////
    //                 State                   //
    /////////////////////////////////////////////

    address public immutable OFFICE;

    mapping(uint256 id => address erc20) public getERC20;

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    constructor(address office) {
        require(office != address(0), OfficeERC6909ToERC20Wrapper__ZeroAddress());

        OFFICE = office;
    }

    /// @notice Creates a new wrapped ERC20 token for the given ERC6909 token ID.
    /// @dev Can only be called by the officer of the market to which the token ID belongs.
    /// @param id The ERC6909 token ID to create a wrapped ERC20 token for.
    /// @param name The name of the wrapped ERC20 token.
    /// @param symbol The symbol of the wrapped ERC20 token.
    /// @param decimals The decimals of the wrapped ERC20 token.
    /// @return erc20 The address of the newly created wrapped ERC20 token.
    function register(
        uint256 id,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    )
        external
        returns (address erc20)
    {
        MarketId market = id.getMarketId();

        require(
            msg.sender == IOfficeStorage(OFFICE).getOfficer(market),
            OfficeERC6909ToERC20Wrapper__NotOfficer(market, msg.sender)
        );

        require(getERC20[id] == address(0), OfficeERC6909ToERC20Wrapper__ERC20AlreadyRegistered(id));

        erc20 = address(new WrappedERC6909ERC20{salt: keccak256(abi.encodePacked(id))}(name, symbol, decimals));

        require(erc20 != address(0), OfficeERC6909ToERC20Wrapper__ZeroAddress());

        getERC20[id] = erc20;

        emit OfficeERC6909ToERC20Wrapper__Registered(id, erc20);
    }

    /// @notice Wraps `amount` of ERC6909 tokens of `id` into the corresponding wrapped ERC20 tokens.
    /// @dev The caller must have approved this contract to transfer their ERC6909 tokens of `id`.
    ///      Reverts if there is no wrapped ERC20 token registered for the given `id`.
    /// @param id The ERC6909 token ID to wrap.
    /// @param amount The amount of ERC6909 tokens to wrap.
    function wrap(uint256 id, uint256 amount) public nonReentrant {
        address erc20 = getERC20[id];

        require(
            IRegistry(OFFICE).transferFrom(msg.sender, address(this), id, amount),
            OfficeERC6909ToERC20Wrapper__TransferFailed(msg.sender, address(this), id, amount)
        );

        WrappedERC6909ERC20(erc20).mint(msg.sender, amount);

        emit OfficeERC6909ToERC20Wrapper__Wrapped(id, erc20, amount);
    }

    /// @notice Unwraps `amount` of wrapped ERC20 tokens of `id` into the corresponding ERC6909 tokens.
    /// @dev The caller must have approved this contract to transfer their wrapped ERC20 tokens of `id`.
    ///      Reverts if there is no wrapped ERC20 token registered for the given `id`.
    /// @param id The ERC6909 token ID to unwrap.
    /// @param amount The amount of wrapped ERC20 tokens to unwrap.
    function unwrap(uint256 id, uint256 amount) public nonReentrant {
        address erc20 = getERC20[id];

        WrappedERC6909ERC20(erc20).burn(msg.sender, amount);

        require(
            IRegistry(OFFICE).transfer(msg.sender, id, amount),
            OfficeERC6909ToERC20Wrapper__TransferFailed(address(this), msg.sender, id, amount)
        );

        emit OfficeERC6909ToERC20Wrapper__Unwrapped(id, erc20, amount);
    }
}
