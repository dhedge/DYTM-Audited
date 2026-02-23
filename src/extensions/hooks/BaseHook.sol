// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IHooks} from "../../interfaces/IHooks.sol";

import {ALL_HOOK_MASK} from "../../libraries/Constants.sol";

import {
    SupplyParams,
    SwitchCollateralParams,
    WithdrawParams,
    BorrowParams,
    RepayParams,
    LiquidationParams,
    MigrateSupplyParams
} from "../../interfaces/ParamStructs.sol";

// solhint-disable no-empty-blocks
/// @title BaseHook
/// @notice Base contract for implementing hooks that can be called by the Office contract.
/// @dev All hook functions revert if called by any address other than the authorized Office contract.
/// @author Chinmay <chinmay@dhedge.org>
abstract contract BaseHook is IHooks {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error BaseHook_OnlyOffice();
    error BaseHook_ZeroAddress();
    error BaseHook_IncorrectHooks(uint160 required, uint160 enabled);

    /////////////////////////////////////////////
    //                 State                   //
    /////////////////////////////////////////////

    /// @notice The authorized Office contract address.
    address public immutable OFFICE;

    /////////////////////////////////////////////
    //               Modifiers                //
    ////////////////////////////////////////////

    modifier onlyOffice() {
        _onlyOffice();
        _;
    }

    /////////////////////////////////////////////
    //               Functions                 //
    /////////////////////////////////////////////

    /// @notice Constructor
    /// @param flags The required hook flags.
    /// @param office The address of the Office contract.
    constructor(uint160 flags, address office) {
        require(office != address(0), BaseHook_ZeroAddress());

        uint160 currentFlags = uint160(address(this)) & ALL_HOOK_MASK;

        // Check that the address of this contract has the required hooks enabled.
        require(currentFlags == flags, BaseHook_IncorrectHooks(flags, currentFlags));

        OFFICE = office;
    }

    /// @inheritdoc IHooks
    function beforeSupply(
        SupplyParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function afterSupply(
        SupplyParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function beforeSwitchCollateral(
        SwitchCollateralParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function afterSwitchCollateral(
        SwitchCollateralParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function beforeWithdraw(
        WithdrawParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function afterWithdraw(
        WithdrawParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function beforeBorrow(
        BorrowParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function afterBorrow(
        BorrowParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function beforeRepay(
        RepayParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function afterRepay(
        RepayParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function beforeLiquidate(
        LiquidationParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function afterLiquidate(
        LiquidationParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function beforeMigrateSupply(
        MigrateSupplyParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /// @inheritdoc IHooks
    function afterMigrateSupply(
        MigrateSupplyParams calldata /* params */
    )
        public
        virtual
        onlyOffice
    {}

    /////////////////////////////////////////////
    //                Internal                 //
    /////////////////////////////////////////////

    /// @notice Internal function to check if the caller is the authorized Office contract
    function _onlyOffice() internal view {
        require(msg.sender == OFFICE, BaseHook_OnlyOffice());
    }
}
