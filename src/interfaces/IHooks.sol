// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {
    SupplyParams,
    SwitchCollateralParams,
    WithdrawParams,
    BorrowParams,
    RepayParams,
    LiquidationParams,
    MigrateSupplyParams
} from "./ParamStructs.sol";

/**
 * @title IHooks
 * @author Chinmay <chinmay@dhedge.org>
 * @notice Interface for implementing hook callbacks in the DYTM protocol.
 * @dev Hooks allow custom logic to be executed before and after key market operations.
 *      Implementations can choose to implement only the hooks they need.
 */
interface IHooks {
    /**
     * @notice Hook called before a supply operation.
     * @param params The supply parameters.
     */
    function beforeSupply(SupplyParams calldata params) external;

    /**
     * @notice Hook called after a supply operation.
     * @param params The supply parameters.
     */
    function afterSupply(SupplyParams calldata params) external;

    /**
     * @notice Hook called before a collateral switch operation.
     * @param params The switch collateral parameters.
     */
    function beforeSwitchCollateral(SwitchCollateralParams calldata params) external;

    /**
     * @notice Hook called after a collateral switch operation.
     * @param params The switch collateral parameters.
     */
    function afterSwitchCollateral(SwitchCollateralParams calldata params) external;

    /**
     * @notice Hook called before a withdraw operation.
     * @param params The withdraw parameters.
     */
    function beforeWithdraw(WithdrawParams calldata params) external;

    /**
     * @notice Hook called after a withdraw operation.
     * @param params The withdraw parameters.
     */
    function afterWithdraw(WithdrawParams calldata params) external;

    /**
     * @notice Hook called before a borrow operation.
     * @param params The borrow parameters.
     */
    function beforeBorrow(BorrowParams calldata params) external;

    /**
     * @notice Hook called after a borrow operation.
     * @param params The borrow parameters.
     */
    function afterBorrow(BorrowParams calldata params) external;

    /**
     * @notice Hook called before a repay operation.
     * @param params The repay parameters.
     */
    function beforeRepay(RepayParams calldata params) external;

    /**
     * @notice Hook called after a repay operation.
     * @param params The repay parameters.
     */
    function afterRepay(RepayParams calldata params) external;

    /**
     * @notice Hook called before a liquidation operation.
     * @param params The liquidation parameters.
     */
    function beforeLiquidate(LiquidationParams calldata params) external;

    /**
     * @notice Hook called after a liquidation operation.
     * @param params The liquidation parameters.
     */
    function afterLiquidate(LiquidationParams calldata params) external;

    /**
     * @notice Hook called before a supply migration operation.
     * @param params The migrate supply parameters.
     */
    function beforeMigrateSupply(MigrateSupplyParams calldata params) external;

    /**
     * @notice Hook called after a supply migration operation.
     * @param params The migrate supply parameters.
     */
    function afterMigrateSupply(MigrateSupplyParams calldata params) external;
}
