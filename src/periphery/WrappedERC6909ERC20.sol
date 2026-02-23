// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ERC20} from "@openzeppelin-contracts/token/ERC20/ERC20.sol";

/// @title WrappedERC6909ERC20
/// @notice ERC20 token contract used as the underlying for wrapped ERC6909 tokens.
/// @author Chinmay <chinmay@dhedge.org>
/// @custom:attribution Adapted from <https://etherscan.io/address/0x000000000020979cc92752fa2708868984a7f746?s=09#code>
contract WrappedERC6909ERC20 is ERC20 {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error WrappedERC6909ERC20__Unauthorized();

    /////////////////////////////////////////////
    //                 State                   //
    /////////////////////////////////////////////

    /// @notice Wrapper singleton contract.
    address public immutable SOURCE = msg.sender;

    uint8 internal immutable _DECIMALS;

    /////////////////////////////////////////////
    //                Modifiers                //
    /////////////////////////////////////////////

    modifier onlySource() {
        require(msg.sender == SOURCE, WrappedERC6909ERC20__Unauthorized());
        _;
    }

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    constructor(string memory name_, string memory symbol_, uint8 decimals_) payable ERC20(name_, symbol_) {
        _DECIMALS = decimals_;
    }

    /// @notice Mints `amount` tokens to `to`.
    /// @dev Can only be called by the SOURCE contract.
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlySource {
        _mint(to, amount);
    }

    /// @notice Burns `amount` tokens from `from`.
    /// @dev Can only be called by the SOURCE contract.
    /// @param from The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    function burn(address from, uint256 amount) external onlySource {
        _burn(from, amount);
    }

    /// @notice Returns the number of decimals as set at deployment.
    /// @return decimals_ The number of decimals.
    function decimals() public view override returns (uint8 decimals_) {
        return _DECIMALS;
    }
}
