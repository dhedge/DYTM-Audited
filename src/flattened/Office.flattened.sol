// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.29 >=0.8.0 ^0.8.20 ^0.8.29;

// dependencies/@openzeppelin-contracts-5.3.0/utils/Comparators.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/Comparators.sol)

/**
 * @dev Provides a set of functions to compare values.
 *
 * _Available since v5.1._
 */
library Comparators {
    function lt(uint256 a, uint256 b) internal pure returns (bool) {
        return a < b;
    }

    function gt(uint256 a, uint256 b) internal pure returns (bool) {
        return a > b;
    }
}

// dependencies/solmate-6.8.0/src/utils/FixedPointMathLib.sol

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// src/interfaces/IDelegatee.sol

/**
 * @title IDelegatee
 * @author Chinmay <chinmay@dhedge.org>
 * @notice Interface for the delegatee contract to handle delegation calls.
 * @dev Be extremely cautious when creating a delegatee contract regarding security implications
 *      in case a delegatee is ever authorized as an operator. It's best to check for access control
 *      within the delegatee contract itself in case operating on an account. There can be cases where
 *      someone can invoke an action on behalf of an account via a delegatee contract which is set as an
 *      operator for that account.
 */
interface IDelegatee {
    /**
     * @notice Callback function to be called by the Office contract for a delegation call.
     * @param callbackData The data to be passed to the callback function of the delegatee.
     * @return returnData An array of return data from the delegatee's calls.
     */
    function onDelegationCallback(bytes calldata callbackData) external returns (bytes memory returnData);
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// dependencies/@openzeppelin-contracts-5.3.0/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// src/interfaces/IFlashloanReceiver.sol

/**
 * @title IFlashloanReceiver
 * @author Chinmay <chinmay@dhedge.org>
 * @notice Interface for the flashloan receiver contract to handle flashloan callbacks.
 */
interface IFlashloanReceiver {
    /**
     * @notice Callback function to be implemented by the flashloan receiver contract.
     * @param assets The amount of assets to be returned to clear the flashloan debt.
     *               Not to be confused with the amount borrowed or transferred to the receiver.
     * @param callbackData Additional data that can be used by the receiver to perform operations.
     */
    function onFlashloanCallback(uint256 assets, bytes calldata callbackData) external;
}

// src/interfaces/ILiquidator.sol

interface ILiquidator {
    /**
     * @notice Function which is called during liquidation of an account for repayment.
     * @param debtAssetAmount The amount of the debt asset that needs to be approved to the Office contract.
     * @param callbackData Additional data that can be used by the liquidator to perform the liquidation.
     */
    function onLiquidationCallback(uint256 debtAssetAmount, bytes calldata callbackData) external;
}

// src/interfaces/IOracleModule.sol

/**
 * @title IOracleModule
 * @dev Adapted from Euler's `IPriceOracle` interface
 * <https://github.com/euler-xyz/euler-price-oracle/blob/ffc3cb82615fc7d003a7f431175bd1eaf0bf41c5/src/interfaces/IPriceOracle.sol>
 *      - DYTM aims to use oracles as used by Euler.
 *      - For getting prices in USD, as required by the Euler oracles (ERC7726), ISO 4217 code is used.
 *        For USD, it is 840 so we use `address(840)` as the address for USD.
 */
interface IOracleModule {
    /**
     * @notice One-sided price: How much quote token you would get for inAmount of base token, assuming no price spread.
     * @dev If `quote` is USD, the `outAmount` is in WAD.
     * @param inAmount The amount of `base` to convert.
     * @param base The token that is being priced.
     * @param quote The token that is the unit of account.
     * @return outAmount The amount of `quote` that is equivalent to `inAmount` of `base`.
     */
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount);
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/Panic.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/Panic.sol)

/**
 * @dev Helper library for emitting standardized panic codes.
 *
 * ```solidity
 * contract Example {
 *      using Panic for uint256;
 *
 *      // Use any of the declared internal constants
 *      function foo() { Panic.GENERIC.panic(); }
 *
 *      // Alternatively
 *      function foo() { Panic.panic(Panic.GENERIC); }
 * }
 * ```
 *
 * Follows the list from https://github.com/ethereum/solidity/blob/v0.8.24/libsolutil/ErrorCodes.h[libsolutil].
 *
 * _Available since v5.1._
 */
// slither-disable-next-line unused-state
library Panic {
    /// @dev generic / unspecified error
    uint256 internal constant GENERIC = 0x00;
    /// @dev used by the assert() builtin
    uint256 internal constant ASSERT = 0x01;
    /// @dev arithmetic underflow or overflow
    uint256 internal constant UNDER_OVERFLOW = 0x11;
    /// @dev division or modulo by zero
    uint256 internal constant DIVISION_BY_ZERO = 0x12;
    /// @dev enum conversion error
    uint256 internal constant ENUM_CONVERSION_ERROR = 0x21;
    /// @dev invalid encoding in storage
    uint256 internal constant STORAGE_ENCODING_ERROR = 0x22;
    /// @dev empty array pop
    uint256 internal constant EMPTY_ARRAY_POP = 0x31;
    /// @dev array out of bounds access
    uint256 internal constant ARRAY_OUT_OF_BOUNDS = 0x32;
    /// @dev resource error (too large allocation or too large array)
    uint256 internal constant RESOURCE_ERROR = 0x41;
    /// @dev calling invalid internal function
    uint256 internal constant INVALID_INTERNAL_FUNCTION = 0x51;

    /// @dev Reverts with a panic code. Recommended to use with
    /// the internal constants with predefined codes.
    function panic(uint256 code) internal pure {
        assembly ("memory-safe") {
            mstore(0x00, 0x4e487b71)
            mstore(0x20, code)
            revert(0x1c, 0x24)
        }
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/math/SafeCast.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

/**
 * @dev Wrappers over Solidity's uintXX/intXX/bool casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }

    /**
     * @dev Cast a boolean (false or true) to a uint256 (0 or 1) with no jump.
     */
    function toUint(bool b) internal pure returns (uint256 u) {
        assembly ("memory-safe") {
            u := iszero(iszero(b))
        }
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/SlotDerivation.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/SlotDerivation.sol)
// This file was procedurally generated from scripts/generate/templates/SlotDerivation.js.

/**
 * @dev Library for computing storage (and transient storage) locations from namespaces and deriving slots
 * corresponding to standard patterns. The derivation method for array and mapping matches the storage layout used by
 * the solidity language / compiler.
 *
 * See https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays[Solidity docs for mappings and dynamic arrays.].
 *
 * Example usage:
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using StorageSlot for bytes32;
 *     using SlotDerivation for bytes32;
 *
 *     // Declare a namespace
 *     string private constant _NAMESPACE = "<namespace>"; // eg. OpenZeppelin.Slot
 *
 *     function setValueInNamespace(uint256 key, address newValue) internal {
 *         _NAMESPACE.erc7201Slot().deriveMapping(key).getAddressSlot().value = newValue;
 *     }
 *
 *     function getValueInNamespace(uint256 key) internal view returns (address) {
 *         return _NAMESPACE.erc7201Slot().deriveMapping(key).getAddressSlot().value;
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {StorageSlot}.
 *
 * NOTE: This library provides a way to manipulate storage locations in a non-standard way. Tooling for checking
 * upgrade safety will ignore the slots accessed through this library.
 *
 * _Available since v5.1._
 */
library SlotDerivation {
    /**
     * @dev Derive an ERC-7201 slot from a string (namespace).
     */
    function erc7201Slot(string memory namespace) internal pure returns (bytes32 slot) {
        assembly ("memory-safe") {
            mstore(0x00, sub(keccak256(add(namespace, 0x20), mload(namespace)), 1))
            slot := and(keccak256(0x00, 0x20), not(0xff))
        }
    }

    /**
     * @dev Add an offset to a slot to get the n-th element of a structure or an array.
     */
    function offset(bytes32 slot, uint256 pos) internal pure returns (bytes32 result) {
        unchecked {
            return bytes32(uint256(slot) + pos);
        }
    }

    /**
     * @dev Derive the location of the first element in an array from the slot where the length is stored.
     */
    function deriveArray(bytes32 slot) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            mstore(0x00, slot)
            result := keccak256(0x00, 0x20)
        }
    }

    /**
     * @dev Derive the location of a mapping element from the key.
     */
    function deriveMapping(bytes32 slot, address key) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            mstore(0x00, and(key, shr(96, not(0))))
            mstore(0x20, slot)
            result := keccak256(0x00, 0x40)
        }
    }

    /**
     * @dev Derive the location of a mapping element from the key.
     */
    function deriveMapping(bytes32 slot, bool key) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            mstore(0x00, iszero(iszero(key)))
            mstore(0x20, slot)
            result := keccak256(0x00, 0x40)
        }
    }

    /**
     * @dev Derive the location of a mapping element from the key.
     */
    function deriveMapping(bytes32 slot, bytes32 key) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            mstore(0x00, key)
            mstore(0x20, slot)
            result := keccak256(0x00, 0x40)
        }
    }

    /**
     * @dev Derive the location of a mapping element from the key.
     */
    function deriveMapping(bytes32 slot, uint256 key) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            mstore(0x00, key)
            mstore(0x20, slot)
            result := keccak256(0x00, 0x40)
        }
    }

    /**
     * @dev Derive the location of a mapping element from the key.
     */
    function deriveMapping(bytes32 slot, int256 key) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            mstore(0x00, key)
            mstore(0x20, slot)
            result := keccak256(0x00, 0x40)
        }
    }

    /**
     * @dev Derive the location of a mapping element from the key.
     */
    function deriveMapping(bytes32 slot, string memory key) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            let length := mload(key)
            let begin := add(key, 0x20)
            let end := add(begin, length)
            let cache := mload(end)
            mstore(end, slot)
            result := keccak256(begin, add(length, 0x20))
            mstore(end, cache)
        }
    }

    /**
     * @dev Derive the location of a mapping element from the key.
     */
    function deriveMapping(bytes32 slot, bytes memory key) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            let length := mload(key)
            let begin := add(key, 0x20)
            let end := add(begin, length)
            let cache := mload(end)
            mstore(end, slot)
            result := keccak256(begin, add(length, 0x20))
            mstore(end, cache)
        }
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/StorageSlot.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC-1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {SlotDerivation}.
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct Int256Slot {
        int256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Int256Slot` with member `value` located at `slot`.
     */
    function getInt256Slot(bytes32 slot) internal pure returns (Int256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns a `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
}

// src/interfaces/IContext.sol

interface IContext {
    /////////////////////////////////////////////
    //                 Events                  //
    /////////////////////////////////////////////

    event Context__DelegationCallCompleted(address indexed caller, IDelegatee indexed delegatee);

    /////////////////////////////////////////////
    //                  Errors                 //
    /////////////////////////////////////////////

    error Context__ContextAlreadySet();

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /**
     * @notice The original caller of the delegation call (if ongoing).
     */
    function callerContext() external view returns (address caller);

    /**
     * @notice The delegatee address for the delegation call (if ongoing).
     * @dev This is not to be confused with the `msg.sender` of the delegation call
     *      which is the `callerContext`.
     */
    function delegateeContext() external view returns (IDelegatee delegatee);

    /**
     * @notice Indicates if an account health check is required after the delegation call.
     */
    function requiresHealthCheck() external view returns (bool healthCheck);

    /**
     * @notice Checks if the ongoing call is a delegation call.
     * @dev Only checks if the delegatee context is set (not address(0)).
     */
    function isOngoingDelegationCall() external view returns (bool callStatus);
}

// dependencies/@openzeppelin-contracts-5.3.0/interfaces/IERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

// dependencies/@openzeppelin-contracts-5.3.0/interfaces/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

// src/libraries/SharesMathLib.sol

/// @title SharesMathLib
/// @notice Shares management library.
/// @dev Mostly adapted from Morpho's SharesMathLib:
/// https://github.com/morpho-org/morpho-blue/blob/d89ca53ff6cbbacf8717a8ce819ee58f49bcc592/src/libraries/SharesMathLib.sol
/// @dev This implementation mitigates share price manipulations, using OpenZeppelin's method of virtual shares:
/// https://docs.openzeppelin.com/contracts/4.x/erc4626#inflation-attack.
/// @author Morpho Labs
/// @author Chinmay <chinmay@dhedge.org>
library SharesMathLib {
    using FixedPointMathLib for uint256;

    /// @dev The number of virtual shares has been chosen low enough to prevent overflows, and high enough to ensure
    ///      high precision computations.
    ///      - Virtual shares can never be redeemed for the assets they are entitled to, but it is assumed the share price
    ///        stays low enough not to inflate these assets to a significant value.
    ///      Warning: The assets to which virtual borrow shares are entitled behave like unrealizable bad debt.
    uint256 internal constant VIRTUAL_SHARES = 1e6;

    /// @dev A number of virtual assets of 1 enforces a conversion rate between shares and assets when a market is
    ///      empty.
    uint256 internal constant VIRTUAL_ASSETS = 1;

    /// @dev Calculates the value of `assets` quoted in shares, rounding down.
    function toSharesDown(
        uint256 assets,
        uint256 totalAssets,
        uint256 totalShares
    )
        internal
        pure
        returns (uint256 shares)
    {
        return assets.mulDivDown(totalShares + VIRTUAL_SHARES, totalAssets + VIRTUAL_ASSETS);
    }

    /// @dev Calculates the value of `shares` quoted in assets, rounding down.
    function toAssetsDown(
        uint256 shares,
        uint256 totalAssets,
        uint256 totalShares
    )
        internal
        pure
        returns (uint256 assets)
    {
        return shares.mulDivDown(totalAssets + VIRTUAL_ASSETS, totalShares + VIRTUAL_SHARES);
    }

    /// @dev Calculates the value of `assets` quoted in shares, rounding up.
    function toSharesUp(
        uint256 assets,
        uint256 totalAssets,
        uint256 totalShares
    )
        internal
        pure
        returns (uint256 shares)
    {
        return assets.mulDivUp(totalShares + VIRTUAL_SHARES, totalAssets + VIRTUAL_ASSETS);
    }

    /// @dev Calculates the value of `shares` quoted in assets, rounding up.
    function toAssetsUp(
        uint256 shares,
        uint256 totalAssets,
        uint256 totalShares
    )
        internal
        pure
        returns (uint256 assets)
    {
        return shares.mulDivUp(totalAssets + VIRTUAL_ASSETS, totalShares + VIRTUAL_SHARES);
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/interfaces/draft-IERC6909.sol

// OpenZeppelin Contracts (last updated v5.3.0) (interfaces/draft-IERC6909.sol)

/**
 * @dev Required interface of an ERC-6909 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-6909[ERC].
 */
interface IERC6909 is IERC165 {
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set for a token of type `id`.
     * The new allowance is `amount`.
     */
    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);

    /**
     * @dev Emitted when `owner` grants or revokes operator status for a `spender`.
     */
    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    /**
     * @dev Emitted when `amount` tokens of type `id` are moved from `sender` to `receiver` initiated by `caller`.
     */
    event Transfer(
        address caller,
        address indexed sender,
        address indexed receiver,
        uint256 indexed id,
        uint256 amount
    );

    /**
     * @dev Returns the amount of tokens of type `id` owned by `owner`.
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens of type `id` that `spender` is allowed to spend on behalf of `owner`.
     *
     * NOTE: Does not include operator allowances.
     */
    function allowance(address owner, address spender, uint256 id) external view returns (uint256);

    /**
     * @dev Returns true if `spender` is set as an operator for `owner`.
     */
    function isOperator(address owner, address spender) external view returns (bool);

    /**
     * @dev Sets an approval to `spender` for `amount` of tokens of type `id` from the caller's tokens. An `amount` of
     * `type(uint256).max` signifies an unlimited approval.
     *
     * Must return true.
     */
    function approve(address spender, uint256 id, uint256 amount) external returns (bool);

    /**
     * @dev Grants or revokes unlimited transfer permission of any token id to `spender` for the caller's tokens.
     *
     * Must return true.
     */
    function setOperator(address spender, bool approved) external returns (bool);

    /**
     * @dev Transfers `amount` of token type `id` from the caller's account to `receiver`.
     *
     * Must return true.
     */
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);

    /**
     * @dev Transfers `amount` of token type `id` from `sender` to `receiver`.
     *
     * Must return true.
     */
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool);
}

/**
 * @dev Optional extension of {IERC6909} that adds metadata functions.
 */
interface IERC6909Metadata is IERC6909 {
    /**
     * @dev Returns the name of the token of type `id`.
     */
    function name(uint256 id) external view returns (string memory);

    /**
     * @dev Returns the ticker symbol of the token of type `id`.
     */
    function symbol(uint256 id) external view returns (string memory);

    /**
     * @dev Returns the number of decimals for the token of type `id`.
     */
    function decimals(uint256 id) external view returns (uint8);
}

/**
 * @dev Optional extension of {IERC6909} that adds content URI functions.
 */
interface IERC6909ContentURI is IERC6909 {
    /**
     * @dev Returns URI for the contract.
     */
    function contractURI() external view returns (string memory);

    /**
     * @dev Returns the URI for the token of type `id`.
     */
    function tokenURI(uint256 id) external view returns (string memory);
}

/**
 * @dev Optional extension of {IERC6909} that adds a token supply function.
 */
interface IERC6909TokenSupply is IERC6909 {
    /**
     * @dev Returns the total supply of the token of type `id`.
     */
    function totalSupply(uint256 id) external view returns (uint256);
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/math/Math.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Return the 512-bit addition of two uint256.
     *
     * The result is stored in two 256 variables such that sum = high * 2²⁵⁶ + low.
     */
    function add512(uint256 a, uint256 b) internal pure returns (uint256 high, uint256 low) {
        assembly ("memory-safe") {
            low := add(a, b)
            high := lt(low, a)
        }
    }

    /**
     * @dev Return the 512-bit multiplication of two uint256.
     *
     * The result is stored in two 256 variables such that product = high * 2²⁵⁶ + low.
     */
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 high, uint256 low) {
        // 512-bit multiply [high low] = x * y. Compute the product mod 2²⁵⁶ and mod 2²⁵⁶ - 1, then use
        // the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = high * 2²⁵⁶ + low.
        assembly ("memory-safe") {
            let mm := mulmod(a, b, not(0))
            low := mul(a, b)
            high := sub(sub(mm, low), lt(mm, low))
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, with a success flag (no overflow).
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        unchecked {
            uint256 c = a + b;
            success = c >= a;
            result = c * SafeCast.toUint(success);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with a success flag (no overflow).
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        unchecked {
            uint256 c = a - b;
            success = c <= a;
            result = c * SafeCast.toUint(success);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with a success flag (no overflow).
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        unchecked {
            uint256 c = a * b;
            assembly ("memory-safe") {
                // Only true when the multiplication doesn't overflow
                // (c / a == b) || (a == 0)
                success := or(eq(div(c, a), b), iszero(a))
            }
            // equivalent to: success ? c : 0
            result = c * SafeCast.toUint(success);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a success flag (no division by zero).
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        unchecked {
            success = b > 0;
            assembly ("memory-safe") {
                // The `DIV` opcode returns zero when the denominator is 0.
                result := div(a, b)
            }
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a success flag (no division by zero).
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool success, uint256 result) {
        unchecked {
            success = b > 0;
            assembly ("memory-safe") {
                // The `MOD` opcode returns zero when the denominator is 0.
                result := mod(a, b)
            }
        }
    }

    /**
     * @dev Unsigned saturating addition, bounds to `2²⁵⁶ - 1` instead of overflowing.
     */
    function saturatingAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        (bool success, uint256 result) = tryAdd(a, b);
        return ternary(success, result, type(uint256).max);
    }

    /**
     * @dev Unsigned saturating subtraction, bounds to zero instead of overflowing.
     */
    function saturatingSub(uint256 a, uint256 b) internal pure returns (uint256) {
        (, uint256 result) = trySub(a, b);
        return result;
    }

    /**
     * @dev Unsigned saturating multiplication, bounds to `2²⁵⁶ - 1` instead of overflowing.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        (bool success, uint256 result) = tryMul(a, b);
        return ternary(success, result, type(uint256).max);
    }

    /**
     * @dev Branchless ternary evaluation for `a ? b : c`. Gas costs are constant.
     *
     * IMPORTANT: This function may reduce bytecode size and consume less gas when used standalone.
     * However, the compiler may optimize Solidity ternary operations (i.e. `a ? b : c`) to only compute
     * one branch when needed, making this function more expensive.
     */
    function ternary(bool condition, uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // branchless ternary works because:
            // b ^ (a ^ b) == a
            // b ^ 0 == b
            return b ^ ((a ^ b) * SafeCast.toUint(condition));
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return ternary(a > b, a, b);
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return ternary(a < b, a, b);
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            Panic.panic(Panic.DIVISION_BY_ZERO);
        }

        // The following calculation ensures accurate ceiling division without overflow.
        // Since a is non-zero, (a - 1) / b will not overflow.
        // The largest possible result occurs when (a - 1) / b is type(uint256).max,
        // but the largest value we can obtain is type(uint256).max - 1, which happens
        // when a = type(uint256).max and b = 1.
        unchecked {
            return SafeCast.toUint(a > 0) * ((a - 1) / b + 1);
        }
    }

    /**
     * @dev Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     *
     * Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            (uint256 high, uint256 low) = mul512(x, y);

            // Handle non-overflow cases, 256 by 256 division.
            if (high == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return low / denominator;
            }

            // Make sure the result is less than 2²⁵⁶. Also prevents denominator == 0.
            if (denominator <= high) {
                Panic.panic(ternary(denominator == 0, Panic.DIVISION_BY_ZERO, Panic.UNDER_OVERFLOW));
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [high low].
            uint256 remainder;
            assembly ("memory-safe") {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                high := sub(high, gt(remainder, low))
                low := sub(low, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly ("memory-safe") {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [high low] by twos.
                low := div(low, twos)

                // Flip twos such that it is 2²⁵⁶ / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from high into low.
            low |= high * twos;

            // Invert denominator mod 2²⁵⁶. Now that denominator is an odd number, it has an inverse modulo 2²⁵⁶ such
            // that denominator * inv ≡ 1 mod 2²⁵⁶. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv ≡ 1 mod 2⁴.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2⁸
            inverse *= 2 - denominator * inverse; // inverse mod 2¹⁶
            inverse *= 2 - denominator * inverse; // inverse mod 2³²
            inverse *= 2 - denominator * inverse; // inverse mod 2⁶⁴
            inverse *= 2 - denominator * inverse; // inverse mod 2¹²⁸
            inverse *= 2 - denominator * inverse; // inverse mod 2²⁵⁶

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2²⁵⁶. Since the preconditions guarantee that the outcome is
            // less than 2²⁵⁶, this is the final result. We don't need to compute the high bits of the result and high
            // is no longer required.
            result = low * inverse;
            return result;
        }
    }

    /**
     * @dev Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        return mulDiv(x, y, denominator) + SafeCast.toUint(unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0);
    }

    /**
     * @dev Calculates floor(x * y >> n) with full precision. Throws if result overflows a uint256.
     */
    function mulShr(uint256 x, uint256 y, uint8 n) internal pure returns (uint256 result) {
        unchecked {
            (uint256 high, uint256 low) = mul512(x, y);
            if (high >= 1 << n) {
                Panic.panic(Panic.UNDER_OVERFLOW);
            }
            return (high << (256 - n)) | (low >> n);
        }
    }

    /**
     * @dev Calculates x * y >> n with full precision, following the selected rounding direction.
     */
    function mulShr(uint256 x, uint256 y, uint8 n, Rounding rounding) internal pure returns (uint256) {
        return mulShr(x, y, n) + SafeCast.toUint(unsignedRoundsUp(rounding) && mulmod(x, y, 1 << n) > 0);
    }

    /**
     * @dev Calculate the modular multiplicative inverse of a number in Z/nZ.
     *
     * If n is a prime, then Z/nZ is a field. In that case all elements are inversible, except 0.
     * If n is not a prime, then Z/nZ is not a field, and some elements might not be inversible.
     *
     * If the input value is not inversible, 0 is returned.
     *
     * NOTE: If you know for sure that n is (big) a prime, it may be cheaper to use Fermat's little theorem and get the
     * inverse using `Math.modExp(a, n - 2, n)`. See {invModPrime}.
     */
    function invMod(uint256 a, uint256 n) internal pure returns (uint256) {
        unchecked {
            if (n == 0) return 0;

            // The inverse modulo is calculated using the Extended Euclidean Algorithm (iterative version)
            // Used to compute integers x and y such that: ax + ny = gcd(a, n).
            // When the gcd is 1, then the inverse of a modulo n exists and it's x.
            // ax + ny = 1
            // ax = 1 + (-y)n
            // ax ≡ 1 (mod n) # x is the inverse of a modulo n

            // If the remainder is 0 the gcd is n right away.
            uint256 remainder = a % n;
            uint256 gcd = n;

            // Therefore the initial coefficients are:
            // ax + ny = gcd(a, n) = n
            // 0a + 1n = n
            int256 x = 0;
            int256 y = 1;

            while (remainder != 0) {
                uint256 quotient = gcd / remainder;

                (gcd, remainder) = (
                    // The old remainder is the next gcd to try.
                    remainder,
                    // Compute the next remainder.
                    // Can't overflow given that (a % gcd) * (gcd // (a % gcd)) <= gcd
                    // where gcd is at most n (capped to type(uint256).max)
                    gcd - remainder * quotient
                );

                (x, y) = (
                    // Increment the coefficient of a.
                    y,
                    // Decrement the coefficient of n.
                    // Can overflow, but the result is casted to uint256 so that the
                    // next value of y is "wrapped around" to a value between 0 and n - 1.
                    x - y * int256(quotient)
                );
            }

            if (gcd != 1) return 0; // No inverse exists.
            return ternary(x < 0, n - uint256(-x), uint256(x)); // Wrap the result if it's negative.
        }
    }

    /**
     * @dev Variant of {invMod}. More efficient, but only works if `p` is known to be a prime greater than `2`.
     *
     * From https://en.wikipedia.org/wiki/Fermat%27s_little_theorem[Fermat's little theorem], we know that if p is
     * prime, then `a**(p-1) ≡ 1 mod p`. As a consequence, we have `a * a**(p-2) ≡ 1 mod p`, which means that
     * `a**(p-2)` is the modular multiplicative inverse of a in Fp.
     *
     * NOTE: this function does NOT check that `p` is a prime greater than `2`.
     */
    function invModPrime(uint256 a, uint256 p) internal view returns (uint256) {
        unchecked {
            return Math.modExp(a, p - 2, p);
        }
    }

    /**
     * @dev Returns the modular exponentiation of the specified base, exponent and modulus (b ** e % m)
     *
     * Requirements:
     * - modulus can't be zero
     * - underlying staticcall to precompile must succeed
     *
     * IMPORTANT: The result is only valid if the underlying call succeeds. When using this function, make
     * sure the chain you're using it on supports the precompiled contract for modular exponentiation
     * at address 0x05 as specified in https://eips.ethereum.org/EIPS/eip-198[EIP-198]. Otherwise,
     * the underlying function will succeed given the lack of a revert, but the result may be incorrectly
     * interpreted as 0.
     */
    function modExp(uint256 b, uint256 e, uint256 m) internal view returns (uint256) {
        (bool success, uint256 result) = tryModExp(b, e, m);
        if (!success) {
            Panic.panic(Panic.DIVISION_BY_ZERO);
        }
        return result;
    }

    /**
     * @dev Returns the modular exponentiation of the specified base, exponent and modulus (b ** e % m).
     * It includes a success flag indicating if the operation succeeded. Operation will be marked as failed if trying
     * to operate modulo 0 or if the underlying precompile reverted.
     *
     * IMPORTANT: The result is only valid if the success flag is true. When using this function, make sure the chain
     * you're using it on supports the precompiled contract for modular exponentiation at address 0x05 as specified in
     * https://eips.ethereum.org/EIPS/eip-198[EIP-198]. Otherwise, the underlying function will succeed given the lack
     * of a revert, but the result may be incorrectly interpreted as 0.
     */
    function tryModExp(uint256 b, uint256 e, uint256 m) internal view returns (bool success, uint256 result) {
        if (m == 0) return (false, 0);
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            // | Offset    | Content    | Content (Hex)                                                      |
            // |-----------|------------|--------------------------------------------------------------------|
            // | 0x00:0x1f | size of b  | 0x0000000000000000000000000000000000000000000000000000000000000020 |
            // | 0x20:0x3f | size of e  | 0x0000000000000000000000000000000000000000000000000000000000000020 |
            // | 0x40:0x5f | size of m  | 0x0000000000000000000000000000000000000000000000000000000000000020 |
            // | 0x60:0x7f | value of b | 0x<.............................................................b> |
            // | 0x80:0x9f | value of e | 0x<.............................................................e> |
            // | 0xa0:0xbf | value of m | 0x<.............................................................m> |
            mstore(ptr, 0x20)
            mstore(add(ptr, 0x20), 0x20)
            mstore(add(ptr, 0x40), 0x20)
            mstore(add(ptr, 0x60), b)
            mstore(add(ptr, 0x80), e)
            mstore(add(ptr, 0xa0), m)

            // Given the result < m, it's guaranteed to fit in 32 bytes,
            // so we can use the memory scratch space located at offset 0.
            success := staticcall(gas(), 0x05, ptr, 0xc0, 0x00, 0x20)
            result := mload(0x00)
        }
    }

    /**
     * @dev Variant of {modExp} that supports inputs of arbitrary length.
     */
    function modExp(bytes memory b, bytes memory e, bytes memory m) internal view returns (bytes memory) {
        (bool success, bytes memory result) = tryModExp(b, e, m);
        if (!success) {
            Panic.panic(Panic.DIVISION_BY_ZERO);
        }
        return result;
    }

    /**
     * @dev Variant of {tryModExp} that supports inputs of arbitrary length.
     */
    function tryModExp(
        bytes memory b,
        bytes memory e,
        bytes memory m
    ) internal view returns (bool success, bytes memory result) {
        if (_zeroBytes(m)) return (false, new bytes(0));

        uint256 mLen = m.length;

        // Encode call args in result and move the free memory pointer
        result = abi.encodePacked(b.length, e.length, mLen, b, e, m);

        assembly ("memory-safe") {
            let dataPtr := add(result, 0x20)
            // Write result on top of args to avoid allocating extra memory.
            success := staticcall(gas(), 0x05, dataPtr, mload(result), dataPtr, mLen)
            // Overwrite the length.
            // result.length > returndatasize() is guaranteed because returndatasize() == m.length
            mstore(result, mLen)
            // Set the memory pointer after the returned data.
            mstore(0x40, add(dataPtr, mLen))
        }
    }

    /**
     * @dev Returns whether the provided byte array is zero.
     */
    function _zeroBytes(bytes memory byteArray) private pure returns (bool) {
        for (uint256 i = 0; i < byteArray.length; ++i) {
            if (byteArray[i] != 0) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * This method is based on Newton's method for computing square roots; the algorithm is restricted to only
     * using integer operations.
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        unchecked {
            // Take care of easy edge cases when a == 0 or a == 1
            if (a <= 1) {
                return a;
            }

            // In this function, we use Newton's method to get a root of `f(x) := x² - a`. It involves building a
            // sequence x_n that converges toward sqrt(a). For each iteration x_n, we also define the error between
            // the current value as `ε_n = | x_n - sqrt(a) |`.
            //
            // For our first estimation, we consider `e` the smallest power of 2 which is bigger than the square root
            // of the target. (i.e. `2**(e-1) ≤ sqrt(a) < 2**e`). We know that `e ≤ 128` because `(2¹²⁸)² = 2²⁵⁶` is
            // bigger than any uint256.
            //
            // By noticing that
            // `2**(e-1) ≤ sqrt(a) < 2**e → (2**(e-1))² ≤ a < (2**e)² → 2**(2*e-2) ≤ a < 2**(2*e)`
            // we can deduce that `e - 1` is `log2(a) / 2`. We can thus compute `x_n = 2**(e-1)` using a method similar
            // to the msb function.
            uint256 aa = a;
            uint256 xn = 1;

            if (aa >= (1 << 128)) {
                aa >>= 128;
                xn <<= 64;
            }
            if (aa >= (1 << 64)) {
                aa >>= 64;
                xn <<= 32;
            }
            if (aa >= (1 << 32)) {
                aa >>= 32;
                xn <<= 16;
            }
            if (aa >= (1 << 16)) {
                aa >>= 16;
                xn <<= 8;
            }
            if (aa >= (1 << 8)) {
                aa >>= 8;
                xn <<= 4;
            }
            if (aa >= (1 << 4)) {
                aa >>= 4;
                xn <<= 2;
            }
            if (aa >= (1 << 2)) {
                xn <<= 1;
            }

            // We now have x_n such that `x_n = 2**(e-1) ≤ sqrt(a) < 2**e = 2 * x_n`. This implies ε_n ≤ 2**(e-1).
            //
            // We can refine our estimation by noticing that the middle of that interval minimizes the error.
            // If we move x_n to equal 2**(e-1) + 2**(e-2), then we reduce the error to ε_n ≤ 2**(e-2).
            // This is going to be our x_0 (and ε_0)
            xn = (3 * xn) >> 1; // ε_0 := | x_0 - sqrt(a) | ≤ 2**(e-2)

            // From here, Newton's method give us:
            // x_{n+1} = (x_n + a / x_n) / 2
            //
            // One should note that:
            // x_{n+1}² - a = ((x_n + a / x_n) / 2)² - a
            //              = ((x_n² + a) / (2 * x_n))² - a
            //              = (x_n⁴ + 2 * a * x_n² + a²) / (4 * x_n²) - a
            //              = (x_n⁴ + 2 * a * x_n² + a² - 4 * a * x_n²) / (4 * x_n²)
            //              = (x_n⁴ - 2 * a * x_n² + a²) / (4 * x_n²)
            //              = (x_n² - a)² / (2 * x_n)²
            //              = ((x_n² - a) / (2 * x_n))²
            //              ≥ 0
            // Which proves that for all n ≥ 1, sqrt(a) ≤ x_n
            //
            // This gives us the proof of quadratic convergence of the sequence:
            // ε_{n+1} = | x_{n+1} - sqrt(a) |
            //         = | (x_n + a / x_n) / 2 - sqrt(a) |
            //         = | (x_n² + a - 2*x_n*sqrt(a)) / (2 * x_n) |
            //         = | (x_n - sqrt(a))² / (2 * x_n) |
            //         = | ε_n² / (2 * x_n) |
            //         = ε_n² / | (2 * x_n) |
            //
            // For the first iteration, we have a special case where x_0 is known:
            // ε_1 = ε_0² / | (2 * x_0) |
            //     ≤ (2**(e-2))² / (2 * (2**(e-1) + 2**(e-2)))
            //     ≤ 2**(2*e-4) / (3 * 2**(e-1))
            //     ≤ 2**(e-3) / 3
            //     ≤ 2**(e-3-log2(3))
            //     ≤ 2**(e-4.5)
            //
            // For the following iterations, we use the fact that, 2**(e-1) ≤ sqrt(a) ≤ x_n:
            // ε_{n+1} = ε_n² / | (2 * x_n) |
            //         ≤ (2**(e-k))² / (2 * 2**(e-1))
            //         ≤ 2**(2*e-2*k) / 2**e
            //         ≤ 2**(e-2*k)
            xn = (xn + a / xn) >> 1; // ε_1 := | x_1 - sqrt(a) | ≤ 2**(e-4.5)  -- special case, see above
            xn = (xn + a / xn) >> 1; // ε_2 := | x_2 - sqrt(a) | ≤ 2**(e-9)    -- general case with k = 4.5
            xn = (xn + a / xn) >> 1; // ε_3 := | x_3 - sqrt(a) | ≤ 2**(e-18)   -- general case with k = 9
            xn = (xn + a / xn) >> 1; // ε_4 := | x_4 - sqrt(a) | ≤ 2**(e-36)   -- general case with k = 18
            xn = (xn + a / xn) >> 1; // ε_5 := | x_5 - sqrt(a) | ≤ 2**(e-72)   -- general case with k = 36
            xn = (xn + a / xn) >> 1; // ε_6 := | x_6 - sqrt(a) | ≤ 2**(e-144)  -- general case with k = 72

            // Because e ≤ 128 (as discussed during the first estimation phase), we know have reached a precision
            // ε_6 ≤ 2**(e-144) < 1. Given we're operating on integers, then we can ensure that xn is now either
            // sqrt(a) or sqrt(a) + 1.
            return xn - SafeCast.toUint(xn > a / xn);
        }
    }

    /**
     * @dev Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + SafeCast.toUint(unsignedRoundsUp(rounding) && result * result < a);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 x) internal pure returns (uint256 r) {
        // If value has upper 128 bits set, log2 result is at least 128
        r = SafeCast.toUint(x > 0xffffffffffffffffffffffffffffffff) << 7;
        // If upper 64 bits of 128-bit half set, add 64 to result
        r |= SafeCast.toUint((x >> r) > 0xffffffffffffffff) << 6;
        // If upper 32 bits of 64-bit half set, add 32 to result
        r |= SafeCast.toUint((x >> r) > 0xffffffff) << 5;
        // If upper 16 bits of 32-bit half set, add 16 to result
        r |= SafeCast.toUint((x >> r) > 0xffff) << 4;
        // If upper 8 bits of 16-bit half set, add 8 to result
        r |= SafeCast.toUint((x >> r) > 0xff) << 3;
        // If upper 4 bits of 8-bit half set, add 4 to result
        r |= SafeCast.toUint((x >> r) > 0xf) << 2;

        // Shifts value right by the current result and use it as an index into this lookup table:
        //
        // | x (4 bits) |  index  | table[index] = MSB position |
        // |------------|---------|-----------------------------|
        // |    0000    |    0    |        table[0] = 0         |
        // |    0001    |    1    |        table[1] = 0         |
        // |    0010    |    2    |        table[2] = 1         |
        // |    0011    |    3    |        table[3] = 1         |
        // |    0100    |    4    |        table[4] = 2         |
        // |    0101    |    5    |        table[5] = 2         |
        // |    0110    |    6    |        table[6] = 2         |
        // |    0111    |    7    |        table[7] = 2         |
        // |    1000    |    8    |        table[8] = 3         |
        // |    1001    |    9    |        table[9] = 3         |
        // |    1010    |   10    |        table[10] = 3        |
        // |    1011    |   11    |        table[11] = 3        |
        // |    1100    |   12    |        table[12] = 3        |
        // |    1101    |   13    |        table[13] = 3        |
        // |    1110    |   14    |        table[14] = 3        |
        // |    1111    |   15    |        table[15] = 3        |
        //
        // The lookup table is represented as a 32-byte value with the MSB positions for 0-15 in the last 16 bytes.
        assembly ("memory-safe") {
            r := or(r, byte(shr(r, x), 0x0000010102020202030303030303030300000000000000000000000000000000))
        }
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + SafeCast.toUint(unsignedRoundsUp(rounding) && 1 << result < value);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + SafeCast.toUint(unsignedRoundsUp(rounding) && 10 ** result < value);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 x) internal pure returns (uint256 r) {
        // If value has upper 128 bits set, log2 result is at least 128
        r = SafeCast.toUint(x > 0xffffffffffffffffffffffffffffffff) << 7;
        // If upper 64 bits of 128-bit half set, add 64 to result
        r |= SafeCast.toUint((x >> r) > 0xffffffffffffffff) << 6;
        // If upper 32 bits of 64-bit half set, add 32 to result
        r |= SafeCast.toUint((x >> r) > 0xffffffff) << 5;
        // If upper 16 bits of 32-bit half set, add 16 to result
        r |= SafeCast.toUint((x >> r) > 0xffff) << 4;
        // Add 1 if upper 8 bits of 16-bit half set, and divide accumulated result by 8
        return (r >> 3) | SafeCast.toUint((x >> r) > 0xff);
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + SafeCast.toUint(unsignedRoundsUp(rounding) && 1 << (result << 3) < value);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/interfaces/IERC1363.sol

// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/IERC1363.sol)

/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// dependencies/@openzeppelin-contracts-5.3.0/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturnBool} that reverts if call fails to meet the requirements.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silently catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return success && (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/Arrays.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/Arrays.sol)
// This file was procedurally generated from scripts/generate/templates/Arrays.js.

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using SlotDerivation for bytes32;
    using StorageSlot for bytes32;

    /**
     * @dev Sort an array of uint256 (in memory) following the provided comparator function.
     *
     * This function does the sorting "in place", meaning that it overrides the input. The object is returned for
     * convenience, but that returned value can be discarded safely if the caller has a memory pointer to the array.
     *
     * NOTE: this function's cost is `O(n · log(n))` in average and `O(n²)` in the worst case, with n the length of the
     * array. Using it in view functions that are executed through `eth_call` is safe, but one should be very careful
     * when executing this as part of a transaction. If the array being sorted is too large, the sort operation may
     * consume more gas than is available in a block, leading to potential DoS.
     *
     * IMPORTANT: Consider memory side-effects when using custom comparator functions that access memory in an unsafe way.
     */
    function sort(
        uint256[] memory array,
        function(uint256, uint256) pure returns (bool) comp
    ) internal pure returns (uint256[] memory) {
        _quickSort(_begin(array), _end(array), comp);
        return array;
    }

    /**
     * @dev Variant of {sort} that sorts an array of uint256 in increasing order.
     */
    function sort(uint256[] memory array) internal pure returns (uint256[] memory) {
        sort(array, Comparators.lt);
        return array;
    }

    /**
     * @dev Sort an array of address (in memory) following the provided comparator function.
     *
     * This function does the sorting "in place", meaning that it overrides the input. The object is returned for
     * convenience, but that returned value can be discarded safely if the caller has a memory pointer to the array.
     *
     * NOTE: this function's cost is `O(n · log(n))` in average and `O(n²)` in the worst case, with n the length of the
     * array. Using it in view functions that are executed through `eth_call` is safe, but one should be very careful
     * when executing this as part of a transaction. If the array being sorted is too large, the sort operation may
     * consume more gas than is available in a block, leading to potential DoS.
     *
     * IMPORTANT: Consider memory side-effects when using custom comparator functions that access memory in an unsafe way.
     */
    function sort(
        address[] memory array,
        function(address, address) pure returns (bool) comp
    ) internal pure returns (address[] memory) {
        sort(_castToUint256Array(array), _castToUint256Comp(comp));
        return array;
    }

    /**
     * @dev Variant of {sort} that sorts an array of address in increasing order.
     */
    function sort(address[] memory array) internal pure returns (address[] memory) {
        sort(_castToUint256Array(array), Comparators.lt);
        return array;
    }

    /**
     * @dev Sort an array of bytes32 (in memory) following the provided comparator function.
     *
     * This function does the sorting "in place", meaning that it overrides the input. The object is returned for
     * convenience, but that returned value can be discarded safely if the caller has a memory pointer to the array.
     *
     * NOTE: this function's cost is `O(n · log(n))` in average and `O(n²)` in the worst case, with n the length of the
     * array. Using it in view functions that are executed through `eth_call` is safe, but one should be very careful
     * when executing this as part of a transaction. If the array being sorted is too large, the sort operation may
     * consume more gas than is available in a block, leading to potential DoS.
     *
     * IMPORTANT: Consider memory side-effects when using custom comparator functions that access memory in an unsafe way.
     */
    function sort(
        bytes32[] memory array,
        function(bytes32, bytes32) pure returns (bool) comp
    ) internal pure returns (bytes32[] memory) {
        sort(_castToUint256Array(array), _castToUint256Comp(comp));
        return array;
    }

    /**
     * @dev Variant of {sort} that sorts an array of bytes32 in increasing order.
     */
    function sort(bytes32[] memory array) internal pure returns (bytes32[] memory) {
        sort(_castToUint256Array(array), Comparators.lt);
        return array;
    }

    /**
     * @dev Performs a quick sort of a segment of memory. The segment sorted starts at `begin` (inclusive), and stops
     * at end (exclusive). Sorting follows the `comp` comparator.
     *
     * Invariant: `begin <= end`. This is the case when initially called by {sort} and is preserved in subcalls.
     *
     * IMPORTANT: Memory locations between `begin` and `end` are not validated/zeroed. This function should
     * be used only if the limits are within a memory array.
     */
    function _quickSort(uint256 begin, uint256 end, function(uint256, uint256) pure returns (bool) comp) private pure {
        unchecked {
            if (end - begin < 0x40) return;

            // Use first element as pivot
            uint256 pivot = _mload(begin);
            // Position where the pivot should be at the end of the loop
            uint256 pos = begin;

            for (uint256 it = begin + 0x20; it < end; it += 0x20) {
                if (comp(_mload(it), pivot)) {
                    // If the value stored at the iterator's position comes before the pivot, we increment the
                    // position of the pivot and move the value there.
                    pos += 0x20;
                    _swap(pos, it);
                }
            }

            _swap(begin, pos); // Swap pivot into place
            _quickSort(begin, pos, comp); // Sort the left side of the pivot
            _quickSort(pos + 0x20, end, comp); // Sort the right side of the pivot
        }
    }

    /**
     * @dev Pointer to the memory location of the first element of `array`.
     */
    function _begin(uint256[] memory array) private pure returns (uint256 ptr) {
        assembly ("memory-safe") {
            ptr := add(array, 0x20)
        }
    }

    /**
     * @dev Pointer to the memory location of the first memory word (32bytes) after `array`. This is the memory word
     * that comes just after the last element of the array.
     */
    function _end(uint256[] memory array) private pure returns (uint256 ptr) {
        unchecked {
            return _begin(array) + array.length * 0x20;
        }
    }

    /**
     * @dev Load memory word (as a uint256) at location `ptr`.
     */
    function _mload(uint256 ptr) private pure returns (uint256 value) {
        assembly {
            value := mload(ptr)
        }
    }

    /**
     * @dev Swaps the elements memory location `ptr1` and `ptr2`.
     */
    function _swap(uint256 ptr1, uint256 ptr2) private pure {
        assembly {
            let value1 := mload(ptr1)
            let value2 := mload(ptr2)
            mstore(ptr1, value2)
            mstore(ptr2, value1)
        }
    }

    /// @dev Helper: low level cast address memory array to uint256 memory array
    function _castToUint256Array(address[] memory input) private pure returns (uint256[] memory output) {
        assembly {
            output := input
        }
    }

    /// @dev Helper: low level cast bytes32 memory array to uint256 memory array
    function _castToUint256Array(bytes32[] memory input) private pure returns (uint256[] memory output) {
        assembly {
            output := input
        }
    }

    /// @dev Helper: low level cast address comp function to uint256 comp function
    function _castToUint256Comp(
        function(address, address) pure returns (bool) input
    ) private pure returns (function(uint256, uint256) pure returns (bool) output) {
        assembly {
            output := input
        }
    }

    /// @dev Helper: low level cast bytes32 comp function to uint256 comp function
    function _castToUint256Comp(
        function(bytes32, bytes32) pure returns (bool) input
    ) private pure returns (function(uint256, uint256) pure returns (bool) output) {
        assembly {
            output := input
        }
    }

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * NOTE: The `array` is expected to be sorted in ascending order, and to
     * contain no repeated elements.
     *
     * IMPORTANT: Deprecated. This implementation behaves as {lowerBound} but lacks
     * support for repeated elements in the array. The {lowerBound} function should
     * be used instead.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        if (high == 0) {
            return 0;
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds towards zero (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Searches an `array` sorted in ascending order and returns the first
     * index that contains a value greater or equal than `element`. If no such index
     * exists (i.e. all values in the array are strictly less than `element`), the array
     * length is returned. Time complexity O(log n).
     *
     * See C++'s https://en.cppreference.com/w/cpp/algorithm/lower_bound[lower_bound].
     */
    function lowerBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        if (high == 0) {
            return 0;
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds towards zero (it does integer division with truncation).
            if (unsafeAccess(array, mid).value < element) {
                // this cannot overflow because mid < high
                unchecked {
                    low = mid + 1;
                }
            } else {
                high = mid;
            }
        }

        return low;
    }

    /**
     * @dev Searches an `array` sorted in ascending order and returns the first
     * index that contains a value strictly greater than `element`. If no such index
     * exists (i.e. all values in the array are strictly less than `element`), the array
     * length is returned. Time complexity O(log n).
     *
     * See C++'s https://en.cppreference.com/w/cpp/algorithm/upper_bound[upper_bound].
     */
    function upperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        if (high == 0) {
            return 0;
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds towards zero (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                // this cannot overflow because mid < high
                unchecked {
                    low = mid + 1;
                }
            }
        }

        return low;
    }

    /**
     * @dev Same as {lowerBound}, but with an array in memory.
     */
    function lowerBoundMemory(uint256[] memory array, uint256 element) internal pure returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        if (high == 0) {
            return 0;
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds towards zero (it does integer division with truncation).
            if (unsafeMemoryAccess(array, mid) < element) {
                // this cannot overflow because mid < high
                unchecked {
                    low = mid + 1;
                }
            } else {
                high = mid;
            }
        }

        return low;
    }

    /**
     * @dev Same as {upperBound}, but with an array in memory.
     */
    function upperBoundMemory(uint256[] memory array, uint256 element) internal pure returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        if (high == 0) {
            return 0;
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds towards zero (it does integer division with truncation).
            if (unsafeMemoryAccess(array, mid) > element) {
                high = mid;
            } else {
                // this cannot overflow because mid < high
                unchecked {
                    low = mid + 1;
                }
            }
        }

        return low;
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        assembly ("memory-safe") {
            slot := arr.slot
        }
        return slot.deriveArray().offset(pos).getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        assembly ("memory-safe") {
            slot := arr.slot
        }
        return slot.deriveArray().offset(pos).getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        assembly ("memory-safe") {
            slot := arr.slot
        }
        return slot.deriveArray().offset(pos).getUint256Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeMemoryAccess(address[] memory arr, uint256 pos) internal pure returns (address res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeMemoryAccess(bytes32[] memory arr, uint256 pos) internal pure returns (bytes32 res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeMemoryAccess(uint256[] memory arr, uint256 pos) internal pure returns (uint256 res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /**
     * @dev Helper to set the length of a dynamic array. Directly writing to `.length` is forbidden.
     *
     * WARNING: this does not clear elements if length is reduced, of initialize elements if length is increased.
     */
    function unsafeSetLength(address[] storage array, uint256 len) internal {
        assembly ("memory-safe") {
            sstore(array.slot, len)
        }
    }

    /**
     * @dev Helper to set the length of a dynamic array. Directly writing to `.length` is forbidden.
     *
     * WARNING: this does not clear elements if length is reduced, of initialize elements if length is increased.
     */
    function unsafeSetLength(bytes32[] storage array, uint256 len) internal {
        assembly ("memory-safe") {
            sstore(array.slot, len)
        }
    }

    /**
     * @dev Helper to set the length of a dynamic array. Directly writing to `.length` is forbidden.
     *
     * WARNING: this does not clear elements if length is reduced, of initialize elements if length is increased.
     */
    function unsafeSetLength(uint256[] storage array, uint256 len) internal {
        assembly ("memory-safe") {
            sstore(array.slot, len)
        }
    }
}

// src/types/AccountId.sol

/* solhint-disable private-vars-leading-underscore */
function eq_0(AccountId a, AccountId b) pure returns (bool isEqual) {
    return AccountId.unwrap(a) == AccountId.unwrap(b);
}

function notEq_0(AccountId a, AccountId b) pure returns (bool isNotEqual) {
    return AccountId.unwrap(a) != AccountId.unwrap(b);
}
/* solhint-enable private-vars-leading-underscore */

/// @title AccountIdLibrary
/// @notice Library for AccountId conversions related functions.
/// @author Chinmay <chinmay@dhedge.org>
library AccountIdLibrary {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error AccountIdLibrary__ZeroAddress();
    error AccountIdLibrary__ZeroAccountNumber();
    error AccountIdLibrary__InvalidRawAccountId(uint256 rawAccount);
    error AccountIdLibrary__InvalidUserAccountId(AccountId account);
    error AccountIdLibrary__InvalidIsolatedAccountId(AccountId account);

    /////////////////////////////////////////////
    //                 Enums                   //
    /////////////////////////////////////////////
    enum AccountType {
        INVALID_ACCOUNT, // 0
        USER_ACCOUNT, // 1
        ISOLATED_ACCOUNT // 2

    }

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @notice Converts a user address to an account ID.
    /// @param user The user address to be converted.
    /// @return account The account ID corresponding to the user address.
    function toUserAccount(address user) internal pure returns (AccountId account) {
        require(user != address(0), AccountIdLibrary__ZeroAddress());

        uint256 userNumber = uint256(uint160(user));
        return AccountId.wrap(userNumber);
    }

    /// @notice Converts an account ID to a token ID.
    /// @dev The token ID is the same as the account ID.
    ///      Note: A user account can't be tokenized, so this function is only valid for isolated accounts.
    /// @param account The account ID to be converted.
    /// @return tokenId The token ID corresponding to the account ID.
    function toTokenId(AccountId account) internal pure returns (uint256 tokenId) {
        require(
            account != ACCOUNT_ID_ZERO && !isUserAccount(account),
            AccountIdLibrary__InvalidIsolatedAccountId(account)
        );

        // The token ID is the same as the account ID.
        return AccountId.unwrap(account);
    }

    /// @notice Converts an account count to an isolated account ID.
    /// @dev An isolated account is one where the least significant 160 bits are zero
    ///      and the top 96 bits are set to the count.
    ///      - Reverts if the count is zero.
    /// @param count The account count to be converted.
    /// @return account The isolated account ID corresponding to the count.
    function toIsolatedAccount(uint96 count) internal pure returns (AccountId account) {
        if (count == 0) {
            revert AccountIdLibrary__ZeroAccountNumber();
        }

        // Set the most significant 96 bits to the count and the least significant 160 bits to zero.
        uint256 accountNumber = (uint256(count) << 160);
        return AccountId.wrap(accountNumber);
    }

    /// @notice Validates and converts an account ID to a user address.
    /// @dev - Reverts if the account ID is not a user account.
    ///      - Revert if the account ID is a null account (i.e., zero address).
    /// @param account The account ID to be converted.
    function toUserAddress(AccountId account) internal pure returns (address user) {
        // Validate that the account is a user account.
        require(isUserAccount(account), AccountIdLibrary__InvalidUserAccountId(account));

        return address(uint160(AccountId.unwrap(account)));
    }

    /// @notice Function to check if an account is a user account.
    ///         Will revert if the `account` is not a valid account type.
    /// @dev A user account is one where the least significant 160 bits are non-zero and
    ///      the top 96 bits are zero.
    /// @param account The account ID to be checked.
    /// @return isUser True if the account is a user account, false otherwise.
    function isUserAccount(AccountId account) internal pure returns (bool isUser) {
        return getAccountType(AccountId.unwrap(account)) == AccountType.USER_ACCOUNT;
    }

    /// @notice Function to check if an account is an isolated account.
    ///         Will revert if the `account` is not a valid account type.
    /// @dev An isolated account is one where the least significant 160 bits are zero
    ///      and the top 96 bits are non-zero.
    /// @param account The account ID to be checked.
    /// @return isIsolated True if the account is an isolated account, false otherwise.
    function isIsolatedAccount(AccountId account) internal pure returns (bool isIsolated) {
        return getAccountType(AccountId.unwrap(account)) == AccountType.ISOLATED_ACCOUNT;
    }

    /// @notice Determines the type of account based on its raw uint256 representation.
    /// @dev Reverts if the raw account ID does not conform to either type.
    /// @param rawAccount The raw uint256 representation of the account ID.
    /// @return accountType The type of the account (USER_ACCOUNT or ISOLATED_ACCOUNT).
    function getAccountType(uint256 rawAccount) internal pure returns (AccountType accountType) {
        uint160 addressField = uint160(rawAccount);
        uint96 accountCount = uint96(rawAccount >> 160);

        if (addressField == 0 && accountCount != 0) {
            return AccountType.ISOLATED_ACCOUNT; // Isolated account
        } else if (addressField != 0 && accountCount == 0) {
            return AccountType.USER_ACCOUNT; // User account
        } else {
            revert AccountIdLibrary__InvalidRawAccountId(rawAccount);
        }
    }
}

// src/libraries/Constants.sol

/* Hook permissions flags. */
uint160 constant BEFORE_SUPPLY_FLAG = 1 << 0;
uint160 constant AFTER_SUPPLY_FLAG = 1 << 1;
uint160 constant BEFORE_SWITCH_COLLATERAL_FLAG = 1 << 2;
uint160 constant AFTER_SWITCH_COLLATERAL_FLAG = 1 << 3;
uint160 constant BEFORE_BORROW_FLAG = 1 << 4;
uint160 constant AFTER_BORROW_FLAG = 1 << 5;
uint160 constant BEFORE_WITHDRAW_FLAG = 1 << 6;
uint160 constant AFTER_WITHDRAW_FLAG = 1 << 7;
uint160 constant BEFORE_REPAY_FLAG = 1 << 8;
uint160 constant AFTER_REPAY_FLAG = 1 << 9;
uint160 constant BEFORE_LIQUIDATE_FLAG = 1 << 10;
uint160 constant AFTER_LIQUIDATE_FLAG = 1 << 11;
uint160 constant BEFORE_MIGRATE_SUPPLY_FLAG = 1 << 12;
uint160 constant AFTER_MIGRATE_SUPPLY_FLAG = 1 << 13;
uint160 constant ALL_HOOK_MASK = uint160((1 << 14) - 1);

/* ERC7201 storage namespaces. */

// keccak256(abi.encode(uint256(keccak256("DYTM.storage.Office")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant OFFICE_STORAGE_LOCATION = 0x71d51ffbf9e21449409619cca98ecabe4a4a4497c444c0c069176d2b254ae700;

// keccak256(abi.encode(uint256(keccak256("DYTM.storage.Accounts")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ACCOUNTS_STORAGE_LOCATION = 0x5e1358d18e2f22d9f7b5b2ce571845b90812696899eaa9f0525b422dc97c1400;

/* Transient Hash Table Storage Constants */
uint8 constant MAX_TRANSIENT_QUEUE_LENGTH = 10; // Max length of the transient array storage.
uint256 constant TRANSIENT_QUEUE_STORAGE_BASE_SLOT = 100;

/* Miscellaneous constants. */
ReserveKey constant RESERVE_KEY_ZERO = ReserveKey.wrap(0);
AccountId constant ACCOUNT_ID_ZERO = AccountId.wrap(0);
MarketId constant MARKET_ID_ZERO = MarketId.wrap(0);
address constant USD_ISO_ADDRESS = address(840); // As required by IOracleModule interface.
uint256 constant WAD = 1e18; // Fixed-point representation with 18 decimals.

// dependencies/@openzeppelin-contracts-5.3.0/utils/structs/EnumerableSet.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 * - Set can be cleared (all elements removed) in O(n).
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes all the values from a set. O(n).
     *
     * WARNING: Developers should keep in mind that this function has an unbounded cost and using it may render the
     * function uncallable if the set grows to the point where clearing it consumes too much gas to fit in a block.
     */
    function _clear(Set storage set) private {
        uint256 len = _length(set);
        for (uint256 i = 0; i < len; ++i) {
            delete set._positions[set._values[i]];
        }
        Arrays.unsafeSetLength(set._values, 0);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Removes all the values from a set. O(n).
     *
     * WARNING: Developers should keep in mind that this function has an unbounded cost and using it may render the
     * function uncallable if the set grows to the point where clearing it consumes too much gas to fit in a block.
     */
    function clear(Bytes32Set storage set) internal {
        _clear(set._inner);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        assembly ("memory-safe") {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes all the values from a set. O(n).
     *
     * WARNING: Developers should keep in mind that this function has an unbounded cost and using it may render the
     * function uncallable if the set grows to the point where clearing it consumes too much gas to fit in a block.
     */
    function clear(AddressSet storage set) internal {
        _clear(set._inner);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly ("memory-safe") {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Removes all the values from a set. O(n).
     *
     * WARNING: Developers should keep in mind that this function has an unbounded cost and using it may render the
     * function uncallable if the set grows to the point where clearing it consumes too much gas to fit in a block.
     */
    function clear(UintSet storage set) internal {
        _clear(set._inner);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly ("memory-safe") {
            result := store
        }

        return result;
    }
}

// src/types/MarketId.sol

/* solhint-disable private-vars-leading-underscore */
function eq_1(MarketId a, MarketId b) pure returns (bool isEqual) {
    return MarketId.unwrap(a) == MarketId.unwrap(b);
}

function notEq_1(MarketId a, MarketId b) pure returns (bool isNotEqual) {
    return MarketId.unwrap(a) != MarketId.unwrap(b);
}

/* solhint-enable private-vars-leading-underscore */

/// @title MarketIdLibrary
/// @dev Library for MarketId conversions related functions.
/// @author Chinmay <chinmay@dhedge.org>
library MarketIdLibrary {
    error MarketIdLibrary__ZeroMarketId();

    /// @dev MarketId is a simple wrapper around uint256.
    /// @dev A market can't be created with `count` = 0.
    function toMarketId(uint88 count) internal pure returns (MarketId market) {
        require(count != 0, MarketIdLibrary__ZeroMarketId());

        return MarketId.wrap(count);
    }
}

// src/types/ReserveKey.sol

/* solhint-disable private-vars-leading-underscore */
function eq_2(ReserveKey a, ReserveKey b) pure returns (bool isEqual) {
    return ReserveKey.unwrap(a) == ReserveKey.unwrap(b);
}

function notEq_2(ReserveKey a, ReserveKey b) pure returns (bool isNotEqual) {
    return ReserveKey.unwrap(a) != ReserveKey.unwrap(b);
}
/* solhint-enable private-vars-leading-underscore */

/// @title ReserveKeyLibrary
/// @dev Library for ReserveKey conversions related functions.
/// @author Chinmay <chinmay@dhedge.org>
library ReserveKeyLibrary {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error ReserveKeyLibrary__ZeroMarketId();
    error ReserveKeyLibrary__InvalidReserveKey(ReserveKey key);

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @dev ReserveKey for a particular principal asset in a market.
    function toReserveKey(MarketId marketId, IERC20 asset) internal pure returns (ReserveKey key) {
        uint88 unwrappedMarketId = MarketId.unwrap(marketId);

        require(unwrappedMarketId != 0, ReserveKeyLibrary__ZeroMarketId());

        uint248 marketIdPart = uint248(unwrappedMarketId) << 160;
        uint248 assetPart = uint160(address(asset));

        return ReserveKey.wrap(marketIdPart | assetPart);
    }

    /// @dev Function to convert a ReserveKey to an escrow reserve id.
    function toEscrowId(ReserveKey key) internal pure returns (uint256 escrowReserveId) {
        return uint256(uint256(TokenType.ESCROW) << 248) | uint256(ReserveKey.unwrap(key));
    }

    /// @dev Function to convert a ReserveKey to a share reserve id.
    function toLentId(ReserveKey key) internal pure returns (uint256 shareReserveId) {
        return uint256(uint256(TokenType.LEND) << 248) | uint256(ReserveKey.unwrap(key));
    }

    /// @dev Function to convert a ReserveKey to a debt reserve id.
    function toDebtId(ReserveKey key) internal pure returns (uint256 debtReserveId) {
        return uint256(uint256(TokenType.DEBT) << 248) | uint256(ReserveKey.unwrap(key));
    }

    /// @dev Function to get the ERC20 asset address from a ReserveKey.
    /// @dev Since the last 160 bits of the ReserveKey are reserved for the asset address,
    ///      we can cast the unwrapped key to a uint160.
    function getAsset(ReserveKey key) internal pure returns (IERC20 asset) {
        return IERC20(address(uint160(ReserveKey.unwrap(key))));
    }

    /// @dev Function to get the MarketId from a ReserveKey.
    /// @dev The MarketId is stored in the bits [247:160] of the ReserveKey.
    /// @dev We can extract it by right shifting the unwrapped key by 160 bits and casting it to a uint88.
    function getMarketId(ReserveKey key) internal pure returns (MarketId marketId) {
        uint88 marketIdPart = uint88(ReserveKey.unwrap(key) >> 160);

        return MarketId.wrap(marketIdPart);
    }

    function validateReserveKey(ReserveKey key) internal pure {
        require(
            key != RESERVE_KEY_ZERO && uint88(ReserveKey.unwrap(key) >> 160) != 0,
            ReserveKeyLibrary__InvalidReserveKey(key)
        );
    }
}

// src/libraries/TokenHelpers.sol

enum TokenType {
    INVALID, // 0
    ESCROW, // 1
    LEND, // 2
    DEBT, // 3
    ISOLATED_ACCOUNT // 4

}

library TokenHelpers {
    /// @dev Function to get the token type from a tokenId.
    /// @dev If the least significant 160 bits of the tokenId are zero and the top 96 bits are non-zero, it's an
    ///      isolated account token.
    ///      If the least significant 160 bits are non-zero and the top 96 bits are zero, it's a user account token.
    ///      Otherwise, the token type is stored in the most significant byte of the tokenId.
    /// @dev WARNING: This function assumes that the tokenId is a valid token ID.
    /// @param tokenId The token ID to convert.
    /// @return tokenType The type of the token, represented as a uint8.
    function getTokenType(uint256 tokenId) internal pure returns (TokenType tokenType) {
        uint160 lsb160 = uint160(tokenId);
        uint96 msb96 = uint96(tokenId >> 160);

        if (lsb160 == 0 && msb96 != 0) {
            return TokenType.ISOLATED_ACCOUNT;
        } else if (lsb160 != 0 && msb96 == 0) {
            return TokenType.INVALID; // User accounts are not tokenized.
        } else {
            return TokenType(msb96 >> 88);
        }
    }

    /// @dev Function to get the MarketId from a tokenId.
    /// @dev The MarketId is stored in the bits [247:160] of the tokenId.
    /// @dev We can extract it by right shifting the tokenId by 160 bits and casting it to a uint88.
    function getMarketId(uint256 tokenId) internal pure returns (MarketId marketId) {
        return MarketId.wrap(uint88(tokenId >> 160));
    }

    /// @dev Function to get the asset address from a tokenId.
    /// @dev The asset address is the last 160 bits of the token ID.
    /// @param tokenId The token ID to convert.
    /// @return asset The IERC20 asset corresponding to the tokenId.
    function getAsset(uint256 tokenId) internal pure returns (IERC20 asset) {
        return IERC20(address(uint160(tokenId)));
    }

    /// @dev Function to get the ReserveKey from a tokenId.
    /// @dev The ReserveKey is the last 248 bits of the tokenId consisting of the MarketId and the asset address.
    /// @dev We can extract it by casting the tokenId to a uint248 and then wrapping it in a ReserveKey.
    /// @param tokenId The token ID to convert.
    /// @return key The ReserveKey corresponding to the tokenId.
    function getReserveKey(uint256 tokenId) internal pure returns (ReserveKey key) {
        return ReserveKey.wrap(uint248(tokenId));
    }

    /// @dev Function to check if a tokenId is a collateral token.
    /// @dev A token is considered collateral if it is either an escrow token or a share token.
    /// @param tokenId The token ID to check.
    /// @return result True if the tokenId is a collateral token, false otherwise.
    function isCollateral(uint256 tokenId) internal pure returns (bool result) {
        TokenType tokenType = getTokenType(tokenId);

        return (tokenType == TokenType.ESCROW || tokenType == TokenType.LEND);
    }

    /// @dev Function to check if a tokenId is a debt token.
    /// @param tokenId The token ID to check.
    /// @return result True if the tokenId is a debt token, false otherwise.
    function isDebt(uint256 tokenId) internal pure returns (bool result) {
        TokenType tokenType = getTokenType(tokenId);

        return (tokenType == TokenType.DEBT);
    }
}

// src/types/Types.sol

// A market id can be any natural number.
type MarketId is uint88;

// An account id is a unique identifier for an account NFT.
// AccountId bit layout:
// +-------------------------------+--------------------------------------+
// |         96 bits               |             160 bits                 |
// |       account count           |           address field              |
// +-------------------------------+--------------------------------------+
// - Every Ethereum public key has an account represented by its address.
//   This is called the "user account".
// - If the least significant 160 bits are zero and the most significant 96 bits are non-zero,
//   it is an "isolated account".
type AccountId is uint256;

// Comprises of the market id and the asset address.
// ReserveKey bit layout:
//      +------------------------+--------------------------------------+
//      |      88 bits           |            160 bits                  |
//      |     market id          |         asset address                |
//      +------------------------+--------------------------------------+
type ReserveKey is uint248;

using {eq_1 as ==, notEq_1 as !=} for MarketId global;
using {eq_0 as ==, notEq_0 as !=} for AccountId global;
using {eq_2 as ==, notEq_2 as !=} for ReserveKey global;

// src/interfaces/IIRM.sol

/**
 * @title IIRM
 * @notice Interest Rate Model interface for a market in the DYTM protocol.
 * @author Chinmay <chinmay@dhedge.org>
 * @dev Follows similar interface as a Morpho market's IRM.
 */
interface IIRM {
    /**
     * @notice Returns the updated borrow rate for a given reserve key.
     * @dev Assumes that the implementation is non-view to allow for any state changes in the implementation.
     * @param key The reserve key for which the borrow rate is requested.
     * @return ratePerSecond The borrow rate per second for the given reserve key.
     */
    function borrowRate(ReserveKey key) external returns (uint256 ratePerSecond);

    /**
     * @notice Returns the borrow rate for a given reserve key.
     * @param key The reserve key for which the borrow rate is requested.
     * @return ratePerSecond The borrow rate per second for the given reserve key.
     */
    function borrowRateView(ReserveKey key) external view returns (uint256 ratePerSecond);
}

// src/interfaces/IWeights.sol

interface IWeights {
    /**
     * @notice Returns the weight of the collateral asset in relation to the debt asset.
     * @dev The weight should be a value between 0 and 1, where 1 means the collateral asset is fully equivalent to the
     * debt asset.
     *      - If the weight between the two assets doesn't exist, it may revert or return 0.
     *      - May return a value less than 1 even if the collateral asset is fully equivalent to the debt asset.
     * @param account The account ID for more context.
     * @param collateralTokenId The token ID of the collateral asset to differentiate between escrowed and lent
     * collateral.
     * @param debtAsset The reserve key of the debt asset.
     * @return weight The weight of the collateral asset in relation to the debt asset.
     */
    function getWeight(
        AccountId account,
        uint256 collateralTokenId,
        ReserveKey debtAsset
    )
        external
        view
        returns (uint64 weight);
}

// src/abstracts/storages/TransientEnumerableHashTableStorage.sol

/// @title TransientEnumerableHashTableStorage
/// @notice Abstract contract which stores the account Id and market Id of the account for which
///         health check is required into a queue with duplication checks using a hash table approach.
/// @dev The hash table isn't cleared after use and we rely on the fact that the transient storage
///      is automatically cleared after the transaction ends.
/// @author Chinmay <chinmay@dhedge.org>
abstract contract TransientEnumerableHashTableStorage {
    using AccountIdLibrary for *;
    using MarketIdLibrary for uint88;

    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error TransientEnumerableHashTableStorage__QueueFull();
    error TransientEnumerableHashTableStorage__IndexOutOfBounds();

    /////////////////////////////////////////////
    //                 Storage                 //
    /////////////////////////////////////////////

    uint8 private transient __length;

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @dev Inserts the `account` and the `market` in the transient queue if there is space and not already inserted.
    ///      This function will revert if the queue is full.
    /// @param account The account ID to be stored.
    /// @param market The market ID to be stored.
    function _insert(AccountId account, MarketId market) internal {
        require(__length < MAX_TRANSIENT_QUEUE_LENGTH, TransientEnumerableHashTableStorage__QueueFull());

        uint256 encodedValue = __encodeAccountMarket(account, market);

        // Check if the combo already exists using our hash table.
        if (__isDuplicate(encodedValue)) {
            return; // Skip if already queued.
        }

        uint256 baseSlot = TRANSIENT_QUEUE_STORAGE_BASE_SLOT;
        uint8 queueIndex = __length;
        assembly ("memory-safe") {
            tstore(add(baseSlot, queueIndex), encodedValue)
        }

        __addToHashTable(encodedValue);

        ++__length;
    }

    /// @dev Gets the account Id and market Id at the `index` from the transient queue.
    /// @param index The index of the element to be retrieved.
    /// @return account The account Id at the given index.
    /// @return market The market Id at the given index.
    function _get(uint8 index) internal view returns (AccountId account, MarketId market) {
        require(index < __length, TransientEnumerableHashTableStorage__IndexOutOfBounds());

        uint256 baseSlot = TRANSIENT_QUEUE_STORAGE_BASE_SLOT;
        uint256 encodedValue;

        assembly ("memory-safe") {
            encodedValue := tload(add(baseSlot, index))
        }

        (account, market) = __decodeAccountMarket(encodedValue);
    }

    /// @dev Gets the current length of the transient queue.
    /// @return length The current length of the transient queue.
    function _getLength() internal view returns (uint8 length) {
        return __length;
    }

    /// @dev Marks the encoded value as inserted.
    /// @dev Given that `__encodeAccountMarket` is a bijective function and the least value of
    ///      this function is `2^168 + 2`, One could safely assume that there will never be collisions.
    /// @param encodedValue The pre-encoded account and market combination.
    function __addToHashTable(uint256 encodedValue) private {
        assembly ("memory-safe") {
            tstore(encodedValue, 1)
        }
    }

    /// @dev Checks if account and market combination is already in the queue using a hash table approach.
    ///      The check loads the value at the slot `encodedValue` and checks if it is 1 indicating duplication.
    /// @param encodedValue The account and market id combination encoded value.
    /// @return isDuplicate True if the combination is a duplicate.
    function __isDuplicate(uint256 encodedValue) private view returns (bool isDuplicate) {
        assembly ("memory-safe") {
            // If the slot contains 1, it is a duplicate. Otherwise, it will be 0 (default).
            isDuplicate := tload(encodedValue)
        }
    }

    /// @dev We encode the account Id and the market Id into a single uint256 and store it in the table.
    ///      This is possible because the market Id is at most 88 bits and the account Id is at most 160 bits
    ///      even though the underlying account Id type is 256 bits, only the upper 96 bits are useful for isolated accounts
    ///      and only the lower 160 bits are useful for user accounts. In short, this is a bijective function.
    /// @param account The account ID to encode.
    /// @param market The market ID to encode.
    /// @return encoded The encoded value containing both IDs.
    function __encodeAccountMarket(AccountId account, MarketId market) private pure returns (uint256 encoded) {
        uint256 rawAccount = AccountId.unwrap(account);
        uint88 rawMarket = MarketId.unwrap(market);

        bool isIsolatedAccount = account.isIsolatedAccount();

        if (isIsolatedAccount) {
            // Although the actual isolated account ID is in the upper 96 bits,
            // we only need to shift right by 159 as the LSB is always 0 for isolated accounts.
            // The lower 160 bits of an isolated account ID are always 0.
            uint256 rawIsolatedAccount = uint256(rawAccount >> 159);

            // Isolated account: upper 88 bits = market, next 96 bits = account, LSB = 1
            encoded = (uint256(rawMarket) << 168) | rawIsolatedAccount | 1;
        } else {
            // Although we could have casted the rawAccount to uint160 directly,
            // we do it this way to set the LSB to 0.
            uint256 rawUserAccount = rawAccount << 1;

            // User account: upper 88 bits = market, next 160 bits = account, LSB = 0
            encoded = (uint256(rawMarket) << 168) | rawUserAccount;
        }
    }

    /// @dev Decodes the encoded value back to account and market IDs.
    /// @param encoded The encoded value to decode.
    /// @return account The decoded account ID.
    /// @return market The decoded market ID.
    function __decodeAccountMarket(uint256 encoded) private pure returns (AccountId account, MarketId market) {
        // Extract market ID from upper 88 bits
        uint88 rawMarket = uint88(encoded >> 168);
        market = rawMarket.toMarketId();

        // Check the LSB to determine account type
        bool isIsolatedAccount = (encoded & 1) == 1;

        if (isIsolatedAccount) {
            // Extract 96 bits for isolated account (bits 1-96).
            uint96 rawIsolatedAccount = uint96(encoded >> 1);

            account = rawIsolatedAccount.toIsolatedAccount();
        } else {
            // Extract 160 bits for user account (bits 1-160)
            address rawUserAccount = address(uint160(encoded >> 1));

            account = rawUserAccount.toUserAccount();
        }
    }
}

// src/interfaces/ParamStructs.sol

/// @param delegatee The delegatee that will be called to perform batch operations.
/// @param callbackData Additional data that can be used by the delegatee to perform the operations.
struct DelegationCallParams {
    IDelegatee delegatee;
    bytes callbackData;
}

/// @param tokenId The tokenId of the receipt token token shares to mint.
///                A user has a choice to supply the assets to either the lending market or to escrow.
/// @param account The account which should receive the lending/escrow receipt tokens.
/// @param assets The amount of the asset as encoded in the tokenId to supply.
///               The last 160 bits of the tokenId are reserved for the asset address which is what will be supplied.
/// @param extraData Extra data that can be used by the hooks.
struct SupplyParams {
    AccountId account;
    uint256 tokenId;
    uint256 assets;
    bytes extraData;
}

/// @param account The account whose collateral will be switched to escrow or lending market.
/// @param tokenId The collateral tokenId to switch.
///                - If an escrow tokenId is provided, the shares will be switched to the lending market.
///                - If a lending market tokenId is provided, the shares will be switched to escrow.
/// @param shares The amount of shares to switch.
struct SwitchCollateralParams {
    AccountId account;
    uint256 tokenId;
    uint256 shares;
}

/// @param tokenId The tokenId of the receipt token shares to withdraw.
///                A user has a choice to withdraw the assets from either the lending market or from escrow.
/// @param account The account from which the assets should be withdrawn.
/// @param receiver The address that will receive the withdrawn assets.
/// @param shares The amount of shares to redeem.
/// @param extraData Extra data that can be used by the hooks.
struct WithdrawParams {
    AccountId account;
    uint256 tokenId;
    address receiver;
    uint256 shares;
    bytes extraData;
}

/// @param key The reserve key for the asset.
/// @param account The account whose debt will be increased.
/// @param receiver The address that will be given the borrowed asset.
/// @param assets The amount to be borrowed.
/// @param extraData Extra data that can be used by the hooks.
struct BorrowParams {
    AccountId account;
    ReserveKey key;
    address receiver;
    uint256 assets;
    bytes extraData;
}

/// @param key The reserve key for the asset.
/// @param account The account whose debt will be repaid.
/// @param repayer The address that will repay the debt.
/// @param shares The amount of debt shares to repay.
/// @param extraData Extra data that can be used by the hooks.
struct RepayParams {
    AccountId account;
    ReserveKey key;
    uint256 shares;
    bytes extraData;
}

/// @param tokenId The collateral tokenId to withdraw from the account for liquidations.
/// @param shares The amount of shares to redeem.
struct CollateralLiquidationParams {
    uint256 tokenId;
    uint256 shares;
}

/// @param account The account that has a debt in a market.
/// @param market The market identifier that the `account` has a debt in.
/// @param collateralShares The collateral tokenId shares and corresponding amounts to be liquidated.
/// @param callbackData Additional data that can be used by the liquidator to perform the liquidation.
///                     The `liquidator` must implement the `ILiquidator` interface.
/// @param extraData Extra data that can be used by the hooks.
struct LiquidationParams {
    AccountId account;
    MarketId market;
    CollateralLiquidationParams[] collateralShares;
    bytes callbackData;
    bytes extraData;
}

/// @param account The account whose assets will be migrated.
/// @param fromTokenId The tokenId that one wants to redeem/withdraw.
/// @param toTokenId The tokenId that one wants to get in exchange for the `fromTokenId`.
/// @param shares The amount of shares to redeem and migrate.
/// @param fromExtraData Extra data that can be used by the hooks of the market of the `fromTokenId`.
/// @param toExtraData Extra data that can be used by the hooks of the market of the `toTokenId`.
struct MigrateSupplyParams {
    AccountId account;
    uint256 fromTokenId;
    uint256 toTokenId;
    uint256 shares;
    bytes fromExtraData;
    bytes toExtraData;
}

// src/abstracts/storages/Context.sol

/// @title Context
/// @dev Transient storage variables have completely independent address space from storage,
///      so that the order of transient state variables does not affect the layout of storage state variables and
///      vice-versa.
/// @author Chinmay <chinmay@dhedge.org>
abstract contract Context is IContext {
    /////////////////////////////////////////////
    //                 Storage                 //
    /////////////////////////////////////////////

    /// @inheritdoc IContext
    address public transient callerContext;

    /// @inheritdoc IContext
    IDelegatee public transient delegateeContext;

    /// @inheritdoc IContext
    bool public transient requiresHealthCheck;

    /////////////////////////////////////////////
    //                Modifiers                //
    /////////////////////////////////////////////

    /// @dev Can be used to enable delegation calls.
    modifier useContext(IDelegatee delegatee) {
        _setContext(delegatee);
        _;
        _deleteContext();

        emit Context__DelegationCallCompleted(msg.sender, delegatee);
    }

    ///////////////////////////////////////////////
    //                 Functions                 //
    ///////////////////////////////////////////////

    /// @inheritdoc IContext
    function isOngoingDelegationCall() public view returns (bool callStatus) {
        return address(delegateeContext) != address(0);
    }

    /// @dev Sets the context of the delegation call.
    ///      - Sets the caller, delegatee, account, and market context for the delegation call.
    ///      - Should be called at the beginning of a delegation call.
    ///      - Once set, the context cannot be changed until deleted so the function utilising `useContext` modifier
    ///        is effectively non-reentrant.
    function _setContext(IDelegatee delegatee) private {
        if (isOngoingDelegationCall()) {
            revert Context__ContextAlreadySet();
        }

        callerContext = msg.sender;
        delegateeContext = delegatee;
    }

    /// @dev Deletes the context of the delegation call.
    ///      Should be called at the end of a delegation call.
    function _deleteContext() private {
        delete callerContext;
        delete delegateeContext;
        delete requiresHealthCheck;
    }
}

// src/interfaces/IHooks.sol

interface IHooks {
    function beforeSupply(SupplyParams calldata params) external;

    function afterSupply(SupplyParams calldata params) external;

    function beforeSwitchCollateral(SwitchCollateralParams calldata params) external;

    function afterSwitchCollateral(SwitchCollateralParams calldata params) external;

    function beforeWithdraw(WithdrawParams calldata params) external;

    function afterWithdraw(WithdrawParams calldata params) external;

    function beforeBorrow(BorrowParams calldata params) external;

    function afterBorrow(BorrowParams calldata params) external;

    function beforeRepay(RepayParams calldata params) external;

    function afterRepay(RepayParams calldata params) external;

    function beforeLiquidate(LiquidationParams calldata params) external;

    function afterLiquidate(LiquidationParams calldata params) external;

    function beforeMigrateSupply(MigrateSupplyParams calldata params) external;

    function afterMigrateSupply(MigrateSupplyParams calldata params) external;
}

// src/libraries/HooksCallHelpers.sol

/// @title HooksCallHelpers
/// @dev A library to dispatch calls to hook functions in the Hooks contract.
///      Inspired by Uniswap v4's hooks.
/// @author Chinmay <chinmay@dhedge.org>
// solhint-disable avoid-low-level-calls
library HooksCallHelpers {
    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////
    error HookCallHelpers__HookCallFailed(bytes4 selector, bytes errorData);

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @dev Calls a hook function on the provided hooks contract if the flag is set.
    /// @param hooks The hooks contract to call.
    /// @param hookSelector The selector of the hook function to call.
    /// @param flag The flag to check for permission.
    function callHook(IHooks hooks, bytes4 hookSelector, uint160 flag) internal {
        if (hasPermission(hooks, flag)) {
            (bool success, bytes memory result) = address(hooks).call(abi.encodePacked(hookSelector, msg.data[4:]));

            require(success, HookCallHelpers__HookCallFailed(hookSelector, result));
        }
    }

    /// @dev Checks if the hooks contract has permission to call a specific hook function based on the flag.
    /// @param hooks The hooks contract to check.
    /// @param flag The flag to check for permission.
    /// @return permitted True if the hooks contract has permission, false otherwise.
    function hasPermission(IHooks hooks, uint160 flag) internal pure returns (bool permitted) {
        return uint160(address(hooks)) & flag != 0;
    }
}

// src/interfaces/IMarketConfig.sol

interface IMarketConfig {
    /**
     * @notice The Interest Rate Model (IRM) for the market.
     * @dev MUST NOT be null address.
     * @return irm The IRM contract interface.
     */
    function irm() external view returns (IIRM irm);

    /**
     * @notice The Hooks contract for the market.
     * @dev MAY BE null address if no hooks are used.
     * @return hooks The Hooks contract interface.
     */
    function hooks() external view returns (IHooks hooks);

    /**
     * @notice The Weights contract for the market.
     * @dev MUST NOT be null address.
     * @return weights The Weights contract interface.
     */
    function weights() external view returns (IWeights weights);

    /**
     * @notice The Oracle Module for the market.
     * @dev MUST NOT be null address.
     * @return oracleModule The Oracle Module contract interface.
     */
    function oracleModule() external view returns (IOracleModule oracleModule);

    /**
     * @notice The recipient of the performance fees for the market.
     * @dev MAY BE null address only if `feePercentage` is zero.
     * @return feeRecipient The address of the fee recipient.
     */
    function feeRecipient() external view returns (address feeRecipient);

    /**
     * @notice The percentage of the performance fee for the market.
     * @dev - MAY BE zero.
     *      - MUST BE in the range of 0 to 1e18 (WAD units).
     * @return feePercentage The fee percentage.
     */
    function feePercentage() external view returns (uint64 feePercentage);

    /**
     * @notice The liquidation bonus percentage for liquidators in the market.
     * @dev MUST BE in the range of 0 to 1e18 (WAD units).
     * @return liquidationBonusPercentage The liquidation bonus percentage.
     */
    function liquidationBonusPercentage() external view returns (uint64 liquidationBonusPercentage);

    /**
     * @notice The minimum margin amount in USD for the market.
     * @dev - MUST BE in WAD units (e.g. $1 = 1e18).
     *      - MAY BE zero.
     * @return minMarginAmountUSD The minimum margin amount in USD.
     */
    function minMarginAmountUSD() external view returns (uint128 minMarginAmountUSD);

    /**
     * @notice Checks if the asset is supported.
     * @dev MUST NOT revert if the asset is not supported.
     * @param asset The asset to check.
     * @return isSupported `true` if the asset is supported, `false` otherwise.
     */
    function isSupportedAsset(IERC20 asset) external view returns (bool isSupported);

    /**
     * @notice Checks if the asset is borrowable.
     * @dev MUST NOT revert if the asset is not supported and/or not borrowable.
     * @param asset The asset to check.
     * @return isBorrowable `true` if the asset is borrowable, `false` otherwise.
     */
    function isBorrowableAsset(IERC20 asset) external view returns (bool isBorrowable);
}

// src/interfaces/IOffice.sol

/**
 * @title IOffice
 * @author Chinmay <chinmay@dhedge.org>
 * @notice Main Office contract interface.
 * @dev Note that certain functions have the `extraData` parameter which is not used by the Office contract
 *      directly but are passed to the hooks contract if:
 *          - it is not address(0)
 *          - if the hooks contract has subscribed to the hooks.
 */
interface IOffice {
    /////////////////////////////////////////////
    //                  Events                 //
    /////////////////////////////////////////////

    event Office__AssetDonated(ReserveKey indexed key, uint256 assets);
    event Office__PerformanceFeeMinted(ReserveKey indexed key, uint256 shares);
    event Office__AssetBorrowed(AccountId indexed account, ReserveKey indexed key, uint256 assets);
    event Office__AssetFlashloaned(address indexed receiver, IERC20 indexed token, uint256 assets);
    event Office__AssetSupplied(AccountId indexed account, uint256 indexed tokenId, uint256 shares, uint256 assets);
    event Office__MarketCreated(address indexed officer, IMarketConfig indexed marketConfig, MarketId indexed market);
    event Office__CollateralSwitched(
        AccountId indexed account, uint256 indexed fromTokenId, uint256 oldShares, uint256 newShares, uint256 assets
    );
    event Office__AssetWithdrawn(
        AccountId indexed account, address indexed receiver, uint256 indexed tokenId, uint256 shares, uint256 assets
    );
    event Office__DebtRepaid(
        AccountId indexed account, address indexed repayer, ReserveKey indexed key, uint256 shares, uint256 assets
    );
    event Office__AccountSplit(
        AccountId indexed originalAccount,
        AccountId indexed newAccount,
        MarketId indexed market,
        address receiver,
        uint256 fraction
    );
    event Office__SupplyMigrated(
        AccountId indexed account,
        uint256 indexed fromTokenId,
        uint256 indexed toTokenId,
        uint256 assetsRedeemed,
        uint256 newSharesMinted
    );
    event Office__AccountLiquidated(
        AccountId indexed account,
        address indexed liquidator,
        MarketId indexed market,
        uint256 repaidShares,
        uint256 repaidAssets,
        uint256 unpaidShares,
        uint256 unpaidAssets
    );

    /////////////////////////////////////////////
    //                  Errors                 //
    /////////////////////////////////////////////

    error Office__ReserveIsEmpty(ReserveKey key);
    error Office__IncorrectTokenId(uint256 tokenId);
    error Office__AssetNotBorrowable(ReserveKey key);
    error Office__ReserveNotSupported(ReserveKey key);
    error Office__InvalidHooksContract(address hooks);
    error Office__AccountNotCreated(AccountId account);
    error Office__InsufficientLiquidity(ReserveKey key);
    error Office__CannotLiquidateDuringDelegationCall();
    error Office__InvalidFraction(uint64 givenFraction);
    error Office__AccountNotHealthy(AccountId account, MarketId market);
    error Office__NotAuthorizedCaller(AccountId account, address caller);
    error Office__AccountStillHealthy(AccountId account, MarketId market);

    //////////////////////////////////////////////
    //               Main Functions             //
    //////////////////////////////////////////////

    /**
     * @notice Function to create a new market.
     *
     * Call will revert if the market already exists or the params are invalid.
     *
     * @param officer The address of the officer of the new market.
     * @param marketConfig The market configuration contract for the new market.
     * @return marketId The Id of the newly created market.
     */
    function createMarket(address officer, IMarketConfig marketConfig) external returns (MarketId marketId);

    /**
     * @notice Function to perform multiple calls on behalf of an account.
     *
     *  The delegatee must implement the `IDelegatee` interface and must be able to handle the `onDelegationCallback`
     *  function.
     *
     * > [!WARNING]
     * >  - This function temporarily grants the delegatee operator access to all the callers' authorized accounts.
     * >  - Health checks for the accounts involved in the delegation call are performed only after the call if necessary.
     *
     * @param params The parameters for the delegation call in the form of a `DelegationCallParams` struct.
     * @return returnData The return data from the delegatee's `onDelegationCallback` function.
     */
    function delegationCall(DelegationCallParams calldata params) external returns (bytes memory returnData);

    /**
     * @notice Function to deposit loan asset into a market.
     *
     * - Anyone can supply tokens for an account even if the account is not created yet.
     * - One can lend a supported asset even if the the asset is not borrowable. If it is enabled for borrowing,
     *   interest will start accruing automatically.
     *
     * > [!WARNING]
     *   If supplying for a non-existent account which the caller assumes will be theirs in the next transaction, make sure you consider front-running risk as
     *   you may end up supplying tokens for an account that belongs to someone else.
     *
     * @param params The parameters for supplying tokens in the form of a `SupplyParams` struct.
     * @return shares The amount of shares minted for the supplied amount.
     */
    function supply(SupplyParams calldata params) external returns (uint256 shares);

    /**
     * @notice Function to switch a collateral from escrow to lending market or vice versa.
     *
     * - Although the same can be achieved by withdrawing and then supplying the asset
     *   using `delegationCall`, this function is more gas efficient and easier to use as it doesn't transfer assets.
     *
     * @param params The parameters for switching collateral in the form of a `SwitchCollateralParams` struct.
     * @return assets The amount of assets switched from escrow to lending market or vice versa.
     * @return shares The new amount of shares minted for the `assets`.
     */
    function switchCollateral(SwitchCollateralParams calldata params)
        external
        returns (uint256 assets, uint256 shares);

    /**
     * @notice Function to withdraw an asset from a market.
     *
     * - Allows only authorized callers of the account to withdraw assets.
     * - Will revert if the account is unhealthy after withdrawal.
     *
     * @param params The parameters for withdrawing tokens in the form of a `WithdrawParams` struct.
     * @return assets The amount of assets withdrawn from the market.
     */
    function withdraw(WithdrawParams calldata params) external returns (uint256 assets);

    /**
     * @notice Function to borrow an asset from a market and then escrow some asset(s) in the account.
     *
     * - Allows users to take out an undercollateralized loan before escrowing/lending asset(s) to
     *   meet the required health check condition via `delegationCall`.
     * - Operators of an account can invoke this function.
     *
     * @param params The parameters for borrowing in the form of `BorrowParams` struct
     * @return debtShares The amount of debt shares created for the borrowed amount.
     */
    function borrow(BorrowParams calldata params) external returns (uint256 debtShares);

    /**
     * @notice Function to repay a debt position in a market.
     *
     * - Allows authorized callers of the account to repay the debt.
     * - Will revert if the account is unhealthy after withdrawal.
     *
     * @param params The parameters for repaying tokens in the form of a `RepayParams` struct.
     * @return assetsRepaid The amount of assets worth of debt repaid in the market.
     */
    function repay(RepayParams calldata params) external returns (uint256 assetsRepaid);

    /**
     * @notice Function to liquidate an unhealthy account in a market.
     *
     * - Allows anyone to liquidate an unhealthy account.
     * - The liquidator must calculate the collateral shares to liquidate for partial or full liquidation.
     * - The liquidator must approve enough debt asset amount to the Office for repayment.
     *
     * > [!WARNING]
     * > - Regardless of bad debt accrual, the liquidator will always receive a bonus.
     * > - To change this behaviour, the officer can change the bonus percentage to 0 using the before liquidation hook.
     *     However, this will make the job of liquidators harder as they need to calculate the exact amount of
     *     shares/assets to liquidate after the bonus percentage modification.
     *
     * @param params The parameters for liquidation in the form of a `LiquidationParams` struct.
     * @return assetsRepaid The amount of assets worth of debt repaid in the market.
     */
    function liquidate(LiquidationParams calldata params) external returns (uint256 assetsRepaid);

    /**
     * @notice Function to migrate supply from one market to another.
     *
     * - The asset being migrated must be the same and accepted in the new market.
     *
     * @param params The parameters for migrating supply in the form of a `MigrateSupplyParams` struct.
     * @return assetsRedeemed The amount of assets redeemed from the old market.
     * @return newSharesMinted The amount of new shares minted in the new market.
     */
    function migrateSupply(MigrateSupplyParams calldata params)
        external
        returns (uint256 assetsRedeemed, uint256 newSharesMinted);

    /**
     * @notice Function to split an account into two accounts.
     *
     * - Creates a new isolated account that gets a portion of the debt asset and collateral assets.
     * - The original account retains the remaining portion of the assets.
     * - Particularly useful for vaults which don't want to maintain instant withdrawal liquidity and to ease withdrawals.
     * - Only the original account's health is checked before splitting given that the portion receiver will always be a new account
     *   and a proportional split will not affect the original account's health.
     *
     * > [!WARNING]
     * > If the market values health of accounts differently (for example using hooks),
     * > then use the function hook(s) to determine the health after the split.
     *
     * @param params The parameters for splitting the account in the form of a `SplitAccountParams` struct.
     * @return newAccountId The ID of the newly created account.
     */
    // function splitAccount(SplitAccountParams calldata params) external returns (AccountId newAccountId);

    /**
     * @notice Function to donate to a lending reserve of a market.
     *
     * - This function increases the `supplied` amount of the reserve.
     * - Can only be called by the officer of the market.
     * - Doesn't check if the asset of the reserve is borrowable or not.
     * - Once donated, the assets can't be clawed back.
     * - Can't donate if reserve `supplied` amount is 0.
     * - It's possible to donate to a reserve whose `supplied` amount is not 0 but is currently
     *   not supported.
     *
     * @param key The reserve key for which the donation is being made.
     * @param amount The amount of the token to be donated to the reserve.
     */
    function donateToReserve(ReserveKey key, uint256 amount) external;

    /**
     * @notice Function to perform a flashloan.
     *
     * - The receiver must implement the `IFlashloanReceiver` interface and must
     *   be able to handle the `onFlashloanCallback` function.
     * - The receiver must also approve the Office contract to transfer the borrowed amount back.
     *
     * @param token The token to be borrowed in the flashloan.
     * @param amount The amount of the token to be borrowed in the flashloan.
     * @param callbackData Additional data that can be used by the receiver.
     */
    function flashloan(IERC20 token, uint256 amount, bytes calldata callbackData) external;

    /**
     * @notice Function to accrue interest for a reserve.
     *
     * - No effect if the reserve is not borrowable.
     *
     * @param key The reserve key for which the reserves are being updated.
     * @return interest The amount of interest accrued for the borrowers of the reserve since the last update.
     */
    function accrueInterest(ReserveKey key) external returns (uint256 interest);

    /**
     * @notice Checks if the `account` is healthy for a debt position in a `market`.
     *
     * - If the `account` has no debt position in the market, it's considered healthy even if
     *   the account has no collateral in the market.
     * - If the weighted collaterals' value in USD is less than (necessary conditions):
     *      - the debt value in USD for the market
     *      - the minimum margin amount in USD for the market
     *   then the account is considered unhealthy.
     *
     * @param account The account ID to check.
     * @param market The market ID to check.
     * @return isHealthy True if the account is healthy, false otherwise.
     */
    function isHealthyAccount(AccountId account, MarketId market) external view returns (bool isHealthy);

    /**
     * @notice Checks if the `caller` is authorized to operate on the `account`.
     *
     * The caller is authorized if:
     *   - The caller is the owner of the account (includes user accounts).
     *   - The caller is an operator of the account.
     *   - The caller is the delegatee of the account for the duration of a delegation call.
     *
     * @param account The AccountId of the account to check authorization for.
     * @param caller The address of the caller.
     * @return isAuthorized Returns true if the caller is authorized to operate on the account.
     */
    function isAuthorizedCaller(AccountId account, address caller) external view returns (bool isAuthorized);
}

// src/interfaces/IRegistry.sol

// solhint-disable

// solhint-enable

interface IRegistry is IERC6909TokenSupply {
    /////////////////////////////////////////////
    //                 Events                 //
    /////////////////////////////////////////////

    event Registry__AccountCreated(AccountId indexed account, address indexed owner);
    event Registry__AccountTransfer(AccountId indexed account, address indexed oldOwner, address indexed newOwner);
    event Registry__Approval(
        AccountId indexed account, AccountId indexed spender, uint256 indexed tokenId, uint256 amount
    );
    event Registry__Transfer(
        address indexed caller, AccountId indexed from, AccountId indexed to, uint256 tokenId, uint256 amount
    );
    event Registry__OperatorSet(
        address indexed owner, AccountId indexed account, address indexed operator, bool approved
    );

    /////////////////////////////////////////////
    //                  Errors                 //
    /////////////////////////////////////////////

    error Registry__ZeroAddress();
    error Registry__ZeroAccount();
    error Registry__NoAccountOwner(AccountId account);
    error Registry__DebtTokensCannotBeTransferred(uint256 tokenId);
    error Registry__IsNotAccountOwner(AccountId account, address caller);
    error Registry__TokenRemovalFromSetFailed(AccountId account, uint256 tokenId);
    error Registry__DebtIdMismatch(AccountId account, uint256 expectedDebtId, uint256 actualDebtId);
    error Registry__InsufficientBalance(AccountId account, uint256 balance, uint256 needed, uint256 tokenId);
    error Registry__InsufficientAllowance(AccountId account, uint256 allowance, uint256 needed, uint256 tokenId);

    /////////////////////////////////////////////
    //                Structs                  //
    /////////////////////////////////////////////

    /**
     * @dev Struct which stores the collateral token Ids and debt token Id per account and market.
     */
    struct TokensData {
        uint256 debtId;
        EnumerableSet.UintSet collateralIds;
    }

    /////////////////////////////////////////////
    //              User Functions             //
    /////////////////////////////////////////////

    /**
     * @dev Creates a new isolated account with the given `newOwner`.
     * @param newOwner The address of the new owner of the account.
     * @return newAccount The newly created AccountId.
     */
    function createIsolatedAccount(address newOwner) external returns (AccountId newAccount);

    /**
     * @inheritdoc IERC6909
     * @dev Implicitly uses the owner's and spender's user account.
     * @dev Note that this function only returns allowance as set by the current owner of the
     *      `owner` user account.
     */
    function allowance(address owner, address spender, uint256 id) external view returns (uint256 remaining);

    /**
     * @inheritdoc IERC6909
     * @dev Implicitly uses the caller's and spender's user accounts.
     */
    function approve(address spender, uint256 tokenId, uint256 amount) external returns (bool success);

    /**
     * @inheritdoc IERC6909
     * @dev Implicitly uses the caller's user account.
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256 balance);

    /**
     * @notice Returns the collateral token IDs for a given market and owner.
     * @dev Implicitly converts `owner` address to user account.
     * @param owner The user address.
     * @param market The market ID of the market.
     * @return collateralIds Array of collateral token IDs.
     */
    function getAllCollateralIds(
        address owner,
        MarketId market
    )
        external
        view
        returns (uint256[] memory collateralIds);

    /**
     * @notice Returns the debt token ID for a given market and user.
     * @dev Implicitly converts `owner` address to user account.
     * @param owner The user address.
     * @param market The market ID of the market.
     * @return debtId The debt token ID for the account in the market.
     */
    function getDebtId(address owner, MarketId market) external view returns (uint256 debtId);

    /**
     * @inheritdoc IERC6909
     * @dev Provides temporary operator access to the delegatee in a delegation call context.
     */
    function isOperator(address owner, address spender) external view returns (bool approved);

    /**
     * @notice Provides authorization to invoke market functions on behalf of the `spender`.
     * @dev Implicitly uses the caller's user account.
     * @param spender The address of the spender to authorize.
     * @param approved Whether the operator is approved or not.
     * @return success Returns true if the operation was successful.
     */
    function setOperator(address spender, bool approved) external returns (bool success);

    /**
     * @inheritdoc IERC165
     * @dev Returns `true` if `interfaceId` is that of IERC6909 or IERC165.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool isSupported);

    /**
     * @inheritdoc IERC6909TokenSupply
     */
    function totalSupply(uint256 id) external view returns (uint256 supply);

    /**
     * @inheritdoc IERC6909
     * @notice For isolated account transfers, the `amount` must be 1.
     * @dev Implicitly uses the caller's and receiver's user accounts.
     */
    function transfer(address receiver, uint256 tokenId, uint256 amount) external returns (bool success);

    /**
     * @inheritdoc IERC6909
     * @dev Implicitly uses the caller's and receiver's user accounts.
     */
    function transferFrom(
        address sender,
        address receiver,
        uint256 tokenId,
        uint256 amount
    )
        external
        returns (bool success);

    /////////////////////////////////////////////
    //            Account Functions            //
    /////////////////////////////////////////////

    /**
     * @notice Returns the allowance of `spender` for `tokenId` tokens of `account` as configured by
     *         a particular account owner.
     * @dev The allowances DO NOT carry over once the account is transferred to a new owner.
     * @dev This function does not include operator allowances.
     *      To check operator allowances, use `isOperator`.
     * @param owner The address of the owner of the account.
     * @param account The AccountId of the account.
     * @param spender The AccountId of the spender.
     * @param tokenId The ID of the token to check the allowance for.
     * @return remaining The allowance of the spender for the token of the account.
     */
    function allowance(
        address owner,
        AccountId account,
        AccountId spender,
        uint256 tokenId
    )
        external
        view
        returns (uint256 remaining);

    /**
     * @notice Approves a `spender` to operate on `tokenId` tokens of the `account`.
     * @param account The AccountId of the account.
     * @param spender The AccountId of the spender.
     * @param tokenId The ID of the token to approve.
     * @param amount The amount of tokens to approve.
     * @return success Returns true if the operation was successful.
     */
    function approve(
        AccountId account,
        AccountId spender,
        uint256 tokenId,
        uint256 amount
    )
        external
        returns (bool success);

    /**
     * @notice Returns the balance of `tokenId` tokens for the given `account`.
     * @param account The AccountId of the account.
     * @param tokenId The ID of the token to check the balance for.
     * @return balance The balance of the token for the account.
     */
    function balanceOf(AccountId account, uint256 tokenId) external view returns (uint256 balance);

    /**
     * @notice Returns the collateral token IDs for a given market and account.
     * @dev A collateral token ID is technically a token ID but additional details like
     *      the token type (e.g. escrow or share).
     * @dev Note that this function is gas-intensive and this limits the amount of collateral assets
     *      that can be allowed per market.
     * @param account The account ID.
     * @param market The market ID of the market.
     * @return collateralIds Array of collateral token IDs.
     */
    function getAllCollateralIds(
        AccountId account,
        MarketId market
    )
        external
        view
        returns (uint256[] memory collateralIds);

    /**
     * @notice Returns the debt token ID for a given market and account.
     * @param account The account ID.
     * @param market The market ID of the market.
     * @return debtId The debt token ID for the account in the market.
     */
    function getDebtId(AccountId account, MarketId market) external view returns (uint256 debtId);

    /**
     * @notice Returns true if:
     *           - The `operator` is approved by the owner of the `account` to operate on behalf of the owner.
     *           - If in a delegation call:
     *             - The `callerContext` is the owner of the `account` or an operator approved by the owner.
     *             - AND the `operator` is the `delegateeContext`.
     * @dev During a delegation call for `account`, if the `operator` is the same as the `delegateeContext`,
     *      it returns true.
     * @param account The AccountId of the account.
     * @param operator The address of the operator to check.
     * @return approved True if the operator is authorized to operate on the account.
     */
    function isOperator(AccountId account, address operator) external view returns (bool approved);

    /**
     * @notice Returns the owner of the `account`.
     * @dev Reverts if the `account` is not created.
     * @dev In case the `account` is a user account, it returns the address of the user.
     * @param account The AccountId of the account.
     * @return owner The address of the owner of the account.
     */
    function ownerOf(AccountId account) external view returns (address owner);

    /**
     * @notice Sets an operator for the `account` that can perform actions on behalf of the owner of the `account`.
     *
     * If the account is transferred to a new owner, the previously set operators won't have any permissions by default.
     * However, if the same account is transferred back to the previous owner, the operators will regain their permissions.
     *
     * > [!WARNING]
     * > If setting a contract as an operator, ensure that the contract has access controls to prevent unauthorized invocation of
     * > privileged functions. For example, contract `A` is set as an operator for account `X`. If `A` doesn't verify
     * > that the caller is authorized to perform actions on behalf of `X`, then anyone can call `A` to perform actions on behalf of `X`.
     *
     * @param operator The address of the operator.
     * @param account The AccountId of the account.
     * @param approved Whether the operator is approved or not.
     * @return success Returns true if the operation was successful.
     */
    function setOperator(address operator, AccountId account, bool approved) external returns (bool success);

    /**
     * @notice Transfers `amount` of token `tokenId` from the caller's account to `receiver`.
     * @dev NOTE: The following could deviate from the ERC6909 standard given that an operator cannot transfer
     *            a specific type of token (isolated account token) unless approved by the current account owner.
     * @param sender The AccountId of the sender.
     * @param receiver The AccountId of the receiver.
     * @param tokenId The ID of the token to transfer.
     * @param amount The amount of tokens to transfer.
     * @return success Returns true if the operation was successful.
     */
    function transferFrom(
        AccountId sender,
        AccountId receiver,
        uint256 tokenId,
        uint256 amount
    )
        external
        returns (bool success);
}

// src/abstracts/storages/OfficeStorage.sol

/// @title OfficeStorage
/// @author Chinmay <chinmay@dhedge.org>
abstract contract OfficeStorage {
    using ReserveKeyLibrary for *;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /////////////////////////////////////////////
    //                 Events                 //
    /////////////////////////////////////////////

    event OfficeStorage__OfficerModified(MarketId indexed market, address newOfficer, address oldOfficer);
    event OfficeStorage__MarketConfigModified(
        MarketId indexed market, IMarketConfig prevMarketConfig, IMarketConfig newMarketConfig
    );

    /////////////////////////////////////////////
    //                  Errors                 //
    /////////////////////////////////////////////

    error OfficeStorage__ZeroAddress();
    error OfficeStorage__NotOfficer(MarketId market, address caller);

    /////////////////////////////////////////////
    //                 Structs                 //
    /////////////////////////////////////////////

    /// @custom:storage-location erc7201:DYTM.storage.Office
    struct OfficeStorageStruct {
        uint88 marketCount;
        mapping(MarketId market => address officer) officers;
        mapping(ReserveKey key => ReserveData data) reserveData;
        mapping(MarketId market => IMarketConfig config) configs;
    }

    /// @dev Struct to store the asset amounts supplied and borrowed to/from a reserve.
    /// @dev `supplied` and `borrowed` accounts for interest accrued until the last update timestamp.
    /// @param supplied The amount of the asset supplied (lent) to the reserve.
    /// @param borrowed The amount of the asset borrowed from the reserve.
    /// @param lastUpdateTimestamp The last time the reserve data was updated.
    struct ReserveData {
        uint256 supplied;
        uint256 borrowed;
        uint128 lastUpdateTimestamp;
    }

    /////////////////////////////////////////////
    //                Modifiers                //
    /////////////////////////////////////////////

    modifier onlyOfficer(MarketId market) {
        _verifyOfficer(market);
        _;
    }

    /////////////////////////////////////////////
    //                 Setters                 //
    /////////////////////////////////////////////

    /// @notice Sets the market configuration for a given market.
    /// @param market The market ID for which to set the configuration.
    /// @param marketConfig The market configuration to set.
    function setMarketConfig(MarketId market, IMarketConfig marketConfig) external onlyOfficer(market) {
        _setMarketConfig(market, marketConfig);
    }

    /// @notice Changes the officer for a given market.
    /// @dev Note: The officer can be the zero address for immutable markets.
    /// @param market The market ID for which to change the officer.
    /// @param newOfficer The address of the new officer.
    function changeOfficer(MarketId market, address newOfficer) external onlyOfficer(market) {
        _setOfficer(market, newOfficer);
    }

    /////////////////////////////////////////////
    //                 Getters                 //
    /////////////////////////////////////////////

    /// @notice Returns the market configuration contract for a given market.
    /// @param market The market ID for which to retrieve the configuration.
    /// @return marketConfig The market configuration contract for the specified market.
    function getMarketConfig(MarketId market) public view returns (IMarketConfig marketConfig) {
        return getOfficeStorageStruct().configs[market];
    }

    /// @notice Returns the officer address for a given market.
    /// @param market The market ID for which to retrieve the officer.
    /// @return officer The address of the officer for the specified market.
    function getOfficer(MarketId market) public view returns (address officer) {
        return getOfficeStorageStruct().officers[market];
    }

    /// @notice Returns the reserve data for a given reserve key.
    /// @param key The reserve key for the asset.
    /// @return reserveData The reserve data for the asset.
    function getReserveData(ReserveKey key) public view returns (ReserveData memory reserveData) {
        return getOfficeStorageStruct().reserveData[key];
    }

    /////////////////////////////////////////////
    //            Internal Functions           //
    /////////////////////////////////////////////

    function _setMarketConfig(MarketId market, IMarketConfig newMarketConfig) internal {
        IMarketConfig prevMarketConfig = getMarketConfig(market);

        require(address(newMarketConfig) != address(0), OfficeStorage__ZeroAddress());

        getOfficeStorageStruct().configs[market] = newMarketConfig;

        emit OfficeStorage__MarketConfigModified(market, prevMarketConfig, newMarketConfig);
    }

    function _setOfficer(MarketId market, address newOfficer) internal {
        address oldOfficer = getOfficer(market);
        getOfficeStorageStruct().officers[market] = newOfficer;

        emit OfficeStorage__OfficerModified(market, newOfficer, oldOfficer);
    }

    function _verifyOfficer(MarketId market) internal view {
        require(msg.sender == getOfficer(market), OfficeStorage__NotOfficer(market, msg.sender));
    }
}

// src/abstracts/Registry.sol

/// @title Registry
/// @notice Tokenization as inspired by ERC6909.
/// @dev May not be fully compliant with the ERC6909 standard because of the following reasons:
///      - The `transferFrom` function does not allow transferring isolated account tokens by operators
///        unless the caller explicitly approved them.
///      - The operator scope is not limited to transfers but allows full market functions' access except for transferring
///        the account itself.
///      - The `approve` function does not allow approving debt tokens.
/// @author Chinmay <chinmay@dhedge.org>
abstract contract Registry is IRegistry, Context {
    using AccountIdLibrary for *;
    using TokenHelpers for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    /////////////////////////////////////////////
    //                 Structs                 //
    /////////////////////////////////////////////

    /// @custom:storage-location erc7201:DYTM.storage.Accounts
    struct AccountsStorageStruct {
        uint96 accountCount;
        mapping(AccountId account => address owner) ownerOf;
        mapping(uint256 tokenId => uint256 supply) totalSupplies;
        mapping(address owner => OwnerSpecificData data) ownerData;
        mapping(AccountId account => mapping(uint256 tokenId => uint256 amount)) balances;
        mapping(AccountId account => mapping(MarketId market => TokensData tokens)) marketWiseData;
    }

    /// @param operatorApprovals Owner specific mapping of operator approvals per account.
    /// @param allowances Owner specific mapping of allowances per account and tokenId.
    struct OwnerSpecificData {
        mapping(AccountId account => mapping(address operator => bool isApproved)) operatorApprovals;
        mapping(AccountId account => mapping(uint256 tokenId => mapping(AccountId spender => uint256 amount)))
            allowances;
    }

    /////////////////////////////////////////////
    //              ERC6909 Functions          //
    /////////////////////////////////////////////

    /// @inheritdoc IRegistry
    function approve(
        address spender,
        uint256 tokenId,
        uint256 amount
    )
        external
        virtual
        override
        returns (bool success)
    {
        address caller = msg.sender;

        success = approve({
            account: caller.toUserAccount(),
            spender: spender.toUserAccount(),
            tokenId: tokenId,
            amount: amount
        });

        emit Approval({owner: caller, spender: spender, id: tokenId, amount: amount});
    }

    /// @inheritdoc IRegistry
    function transfer(address receiver, uint256 tokenId, uint256 amount) external virtual returns (bool success) {
        address caller = msg.sender;

        success = transferFrom({
            sender: caller.toUserAccount(),
            receiver: receiver.toUserAccount(),
            tokenId: tokenId,
            amount: amount
        });

        emit Transfer({caller: caller, sender: caller, receiver: receiver, id: tokenId, amount: amount});
    }

    /// @inheritdoc IRegistry
    function transferFrom(
        address sender,
        address receiver,
        uint256 tokenId,
        uint256 amount
    )
        external
        virtual
        returns (bool success)
    {
        success = transferFrom({
            sender: sender.toUserAccount(),
            receiver: receiver.toUserAccount(),
            tokenId: tokenId,
            amount: amount
        });

        emit Transfer({caller: msg.sender, sender: sender, receiver: receiver, id: tokenId, amount: amount});
    }

    /// @inheritdoc IRegistry
    function setOperator(address spender, bool approved) public virtual returns (bool success) {
        address caller = msg.sender;

        _setOperator({owner: caller, account: caller.toUserAccount(), operator: spender, approved: approved});

        success = true;

        emit OperatorSet({owner: caller, spender: spender, approved: approved});
    }

    /// @inheritdoc IRegistry
    function balanceOf(address owner, uint256 id) external view returns (uint256 balance) {
        return balanceOf({account: owner.toUserAccount(), tokenId: id});
    }

    /// @inheritdoc IRegistry
    function totalSupply(uint256 id) public view virtual returns (uint256 supply) {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();

        supply = $.totalSupplies[id];
    }

    /// @inheritdoc IRegistry
    function allowance(address owner, address spender, uint256 id) external view returns (uint256 remaining) {
        AccountId account = owner.toUserAccount();
        address currentOwner = ownerOf(account);

        return allowance({owner: currentOwner, account: account, spender: spender.toUserAccount(), tokenId: id});
    }

    /// @inheritdoc IRegistry
    function isOperator(address owner, address spender) public view virtual returns (bool approved) {
        return isOperator(owner.toUserAccount(), spender);
    }

    /// @inheritdoc IRegistry
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool isSupported) {
        return interfaceId == type(IERC6909).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /////////////////////////////////////////////
    //            Account Functions            //
    /////////////////////////////////////////////

    /// @inheritdoc IRegistry
    function createIsolatedAccount(address newOwner) public returns (AccountId newAccount) {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();

        require(newOwner != address(0), Registry__ZeroAddress());

        // Pre-increment the account count to ensure the first account is 1.
        uint96 accountCount = ++$.accountCount;
        newAccount = accountCount.toIsolatedAccount();
        $.ownerOf[newAccount] = newOwner;

        // It's assumed that an isolated account with the same `accountCount` does not exist
        // and hence we are skipping the `totalSupply` check.
        _mint({to: newOwner.toUserAccount(), tokenId: newAccount.toTokenId(), amount: 1});

        emit Registry__AccountCreated(newAccount, newOwner);
    }

    /// @inheritdoc IRegistry
    function approve(
        AccountId account,
        AccountId spender,
        uint256 tokenId,
        uint256 amount
    )
        public
        virtual
        returns (bool success)
    {
        address caller = msg.sender;
        address currentOwner = ownerOf(account);

        require(currentOwner == caller, Registry__IsNotAccountOwner(account, caller));

        _approve({currentOwner: currentOwner, from: account, spender: spender, tokenId: tokenId, amount: amount});
        success = true;
    }

    /// @inheritdoc IRegistry
    function transferFrom(
        AccountId sender,
        AccountId receiver,
        uint256 tokenId,
        uint256 amount
    )
        public
        virtual
        returns (bool success)
    {
        address caller = msg.sender;
        address currentOwner = ownerOf(sender);
        bool callerIsOperator = isOperator(sender, caller);

        // 1. If caller is not the current owner or the operator, the transfer happens
        //    from the allowance amount as configured by the current account owner.
        // 2. If the caller is an operator and the tokenId is an isolated account,
        //    the transfer will only take place if the operator is approved to by the current account owner.
        if (
            (currentOwner != caller && !callerIsOperator)
                || (callerIsOperator && tokenId.getTokenType() == TokenType.ISOLATED_ACCOUNT)
        ) {
            _spendAllowance({
                currentOwner: currentOwner,
                from: sender,
                spender: receiver,
                tokenId: tokenId,
                amount: amount
            });
        }

        _transfer({from: sender, to: receiver, tokenId: tokenId, amount: amount});
        success = true;
    }

    /// @inheritdoc IRegistry
    function setOperator(address operator, AccountId account, bool approved) public virtual returns (bool success) {
        address caller = msg.sender;
        address currentOwner = ownerOf(account);

        require(currentOwner == caller, Registry__IsNotAccountOwner(account, caller));

        _setOperator({owner: currentOwner, account: account, operator: operator, approved: approved});
        success = true;
    }

    /// @dev Creates `amount` of token `tokenId` and assigns them to `account`, by transferring it from ACCOUNT_ID_ZERO.
    /// Relies on the `_update` mechanism.
    ///
    /// Emits a {Transfer} event with `from` set to the zero AccountId.
    ///
    /// NOTE: This function is not virtual, {_update} should be overridden instead.
    function _mint(AccountId to, uint256 tokenId, uint256 amount) internal {
        require(to != ACCOUNT_ID_ZERO, Registry__ZeroAccount());

        _update({from: ACCOUNT_ID_ZERO, to: to, tokenId: tokenId, amount: amount});
    }

    /// @dev Moves `amount` of token `tokenId` from `from` to `to` without checking for approvals. This function
    /// verifies
    /// that neither the sender nor the receiver are ACCOUNT_ID_ZERO, which means it cannot mint or burn tokens.
    /// Relies on the `_update` mechanism.
    ///
    /// Emits a {Transfer} event.
    ///
    /// NOTE: This function is not virtual, {_update} should be overridden instead.
    function _transfer(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal {
        require(from != ACCOUNT_ID_ZERO && to != ACCOUNT_ID_ZERO, Registry__ZeroAccount());

        _update({from: from, to: to, tokenId: tokenId, amount: amount});
    }

    /// @dev Destroys a `amount` of token `tokenId` from `account`.
    /// Relies on the `_update` mechanism.
    ///
    /// Emits a {Transfer} event with `to` set to the zero AccountId.
    ///
    /// NOTE: This function is not virtual, {_update} should be overridden instead
    function _burn(AccountId from, uint256 tokenId, uint256 amount) internal {
        require(from != ACCOUNT_ID_ZERO, Registry__ZeroAccount());

        _update({from: from, to: ACCOUNT_ID_ZERO, tokenId: tokenId, amount: amount});
    }

    /// @dev Transfers `amount` of token `tokenId` from `from` to `to`, or alternatively mints (or burns) if `from`
    /// (or `to`) is the zero AccountId. All customizations to transfers, mints, and burns should be done by overriding
    /// this function.
    ///
    /// Emits a {Transfer} event.
    function _update(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal virtual {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();
        address caller = msg.sender;
        TokenType tokenType = tokenId.getTokenType();
        bool isCollateral = tokenId.isCollateral();

        // Emitting transfer event early as zero amount transfers will return early.
        emit Registry__Transfer({caller: caller, from: from, to: to, tokenId: tokenId, amount: amount});

        // If the amount is zero, we do not need to do anything.
        // We don't explicitly revert as there could be cases where
        // token transfer computations can lead to 0 and if not taken special care,
        // it could lead to a reversion.
        if (amount == 0) {
            return;
        }

        if (from != ACCOUNT_ID_ZERO) {
            MarketId marketId = tokenId.getMarketId();
            uint256 fromBalance = $.balances[from][tokenId];

            require(fromBalance >= amount, Registry__InsufficientBalance(from, fromBalance, amount, tokenId));

            uint256 balanceDelta = fromBalance - amount;

            if (balanceDelta == 0) {
                if (isCollateral) {
                    // If tokens are NOT being minted i.e., `from` is not address(0) and
                    // if the `amount` is equal to the total balance of `from` then
                    // remove the tokenId from the `fromCollateralIds`.
                    EnumerableSet.UintSet storage fromCollateralIds = $.marketWiseData[from][marketId].collateralIds;

                    require(fromCollateralIds.remove(tokenId), Registry__TokenRemovalFromSetFailed(from, tokenId));
                } else if (tokenType == TokenType.DEBT) {
                    // If the balance of the `from` account is going to be zero after this transfer,
                    // we remove the debtId from the `from` account's market-wise data.
                    delete $.marketWiseData[from][marketId].debtId;
                }
            }

            unchecked {
                // Overflow not possible: amount <= fromBalance.
                $.balances[from][tokenId] = balanceDelta;
            }

            // Burn condition so update total supply.
            if (to == ACCOUNT_ID_ZERO) {
                unchecked {
                    // amount <= _balances[from][id] <= _totalSupplies[id]
                    $.totalSupplies[tokenId] -= amount;
                }
            }
        }

        if (to != ACCOUNT_ID_ZERO) {
            if (tokenType == TokenType.DEBT) {
                MarketId marketId = tokenId.getMarketId();
                uint256 toDebtId = $.marketWiseData[to][marketId].debtId;

                // If the `to` account doesn't have a debtId set, we set it to the `tokenId`.
                if (toDebtId == 0) {
                    $.marketWiseData[to][marketId].debtId = tokenId;
                } else if (toDebtId != tokenId) {
                    // If the `to` account already has a debtId set, it must match the `tokenId`.
                    // We don't allow minting multiple debt IDs per account per market.
                    revert Registry__DebtIdMismatch(to, tokenId, toDebtId);
                }
            } else if (isCollateral) {
                MarketId marketId = tokenId.getMarketId();

                // If tokens are not being burnt i.e., `to` is not address(0) and
                // if the tokenId doesn't exist in the `toCollateralIds` set then
                // add the tokenId regardless of `from` address.
                EnumerableSet.UintSet storage toCollateralIds = $.marketWiseData[to][marketId].collateralIds;

                toCollateralIds.add(tokenId);
            } else if (tokenType == TokenType.ISOLATED_ACCOUNT) {
                // If an isolated account is being transferred and `to` is a user account,
                // we need to update the `ownerOf` mapping.
                // Note: `toUserAddress` will revert in case `to` is not a user account.
                //       However, it won't revert if `to` is a null account (i.e., zero address).
                //       This is fine because we don't expect an account token (or an account) to be burned
                //       and transfers to the zero address are not allowed.
                $.ownerOf[AccountId.wrap(tokenId)] = to.toUserAddress();
            }

            $.balances[to][tokenId] += amount;

            // Mint condition so update total supply.
            if (from == ACCOUNT_ID_ZERO) {
                $.totalSupplies[tokenId] += amount;
            }
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the `from`'s `tokenId` tokens.
    ///
    /// This internal function is equivalent to `approve`, and can be used to e.g. set automatic allowances for certain
    /// subsystems, etc.
    ///
    /// Emits an {Approval} event.
    ///
    /// Requirements:
    /// - `from` cannot be the zero AccountId.
    /// - `spender` cannot be the zero AccountId.
    /// - `tokenId` cannot be a debt token.
    ///
    /// > [!WARNING]
    /// > - This function does not check if `currentOwner` is the zero address given that the only other place
    ///     it is used is in the `approve` function which already checks for it.
    /// > - This function does not check if the `tokenId` actually exists. As long as it's in the correct format
    ///     (i.e., is encoded as a valid token Id), it will be accepted.
    /// > - Could be breaking the ERC6909 standard given debt token approval is not allowed.
    function _approve(
        address currentOwner,
        AccountId from,
        AccountId spender,
        uint256 tokenId,
        uint256 amount
    )
        internal
        virtual
    {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();

        require(from != ACCOUNT_ID_ZERO && spender != ACCOUNT_ID_ZERO, Registry__ZeroAccount());

        $.ownerData[currentOwner].allowances[from][tokenId][spender] = amount;

        emit Registry__Approval({account: from, spender: spender, tokenId: tokenId, amount: amount});
    }

    /// @dev Approve `operator` to operate on all of `owner`'s tokens
    /// @dev This internal function is equivalent to `setOperator`, and can be used to e.g. set automatic allowances for
    ///      certain subsystems, etc.
    ///
    /// Emits an {OperatorSet} event.
    ///
    /// Requirements:
    /// - `owner` cannot be the zero address.
    /// - `operator` cannot be the zero address.
    function _setOperator(address owner, AccountId account, address operator, bool approved) internal virtual {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();

        require(owner != address(0) && operator != address(0), Registry__ZeroAddress());

        $.ownerData[owner].operatorApprovals[account][operator] = approved;

        emit Registry__OperatorSet({owner: owner, account: account, operator: operator, approved: approved});
    }

    /// @dev Updates `from`'s allowance for `spender` based on spent `amount`.
    /// - Does not update the allowance value in case of infinite allowance.
    /// - Revert if not enough allowance is available.
    /// - Does not emit an {Approval} event.
    function _spendAllowance(
        address currentOwner,
        AccountId from,
        AccountId spender,
        uint256 tokenId,
        uint256 amount
    )
        internal
        virtual
    {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();
        uint256 currentAllowance = allowance(currentOwner, from, spender, tokenId);

        if (currentAllowance < type(uint256).max) {
            require(
                currentAllowance >= amount, Registry__InsufficientAllowance(from, currentAllowance, amount, tokenId)
            );

            unchecked {
                $.ownerData[currentOwner].allowances[from][tokenId][spender] = currentAllowance - amount;
            }
        }
    }

    /////////////////////////////////////////////
    //             View Functions              //
    /////////////////////////////////////////////

    /// @inheritdoc IRegistry
    function ownerOf(AccountId account) public view virtual returns (address owner) {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();

        // If the account is a user account, the current owner is the user address.
        // Otherwise, it retrieves the owner from the storage.
        address currentOwner = (account.isUserAccount()) ? account.toUserAddress() : $.ownerOf[account];

        require(currentOwner != address(0), Registry__NoAccountOwner(account));

        owner = currentOwner;
    }

    /// @inheritdoc IRegistry
    function isOperator(AccountId account, address operator) public view virtual returns (bool approved) {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();
        address currentOwner = ownerOf(account);

        approved = $.ownerData[currentOwner].operatorApprovals[account][operator]
            || (
                isOngoingDelegationCall()
                    && (callerContext == currentOwner || $.ownerData[currentOwner].operatorApprovals[account][callerContext])
                    && operator == address(delegateeContext)
            );
    }

    /// @inheritdoc IRegistry
    function balanceOf(AccountId account, uint256 tokenId) public view virtual returns (uint256 balance) {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();

        balance = $.balances[account][tokenId];
    }

    /// @inheritdoc IRegistry
    function allowance(
        address owner,
        AccountId account,
        AccountId spender,
        uint256 tokenId
    )
        public
        view
        virtual
        returns (uint256 remaining)
    {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();

        remaining = $.ownerData[owner].allowances[account][tokenId][spender];
    }

    /// @inheritdoc IRegistry
    function getDebtId(address owner, MarketId market) public view returns (uint256 debtId) {
        return getDebtId(owner.toUserAccount(), market);
    }

    /// @inheritdoc IRegistry
    function getDebtId(AccountId account, MarketId market) public view returns (uint256 debtId) {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();

        return $.marketWiseData[account][market].debtId;
    }

    /// @inheritdoc IRegistry
    function getAllCollateralIds(address owner, MarketId market) public view returns (uint256[] memory collateralIds) {
        return getAllCollateralIds(owner.toUserAccount(), market);
    }

    /// @inheritdoc IRegistry
    function getAllCollateralIds(
        AccountId account,
        MarketId market
    )
        public
        view
        returns (uint256[] memory collateralIds)
    {
        AccountsStorageStruct storage $ = getAccountsStorageStruct();

        return $.marketWiseData[account][market].collateralIds.values();
    }
}

// src/libraries/StorageAccessors.sol

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
function getAccountsStorageStruct() pure returns (Registry.AccountsStorageStruct storage $) {
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

// src/Office.sol

/// @title Office
/// @notice Core contract of the DYTM protocol.
/// @author Chinmay <chinmay@dhedge.org>
contract Office is IOffice, OfficeStorage, Context, Registry, TransientEnumerableHashTableStorage {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;
    using TokenHelpers for uint256;
    using SharesMathLib for uint256;
    using MarketIdLibrary for uint88;
    using HooksCallHelpers for IHooks;
    using FixedPointMathLib for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    //////////////////////////////////////////////
    //                 Modifiers                //
    //////////////////////////////////////////////

    modifier onlyAuthorizedCaller(AccountId account) {
        _onlyAuthorizedCaller(account);
        _;
    }

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    /// @inheritdoc IOffice
    function createMarket(address officer, IMarketConfig marketConfig) external returns (MarketId marketId) {
        // Note that we are pre-incrementing the market count here to ensure that the marketId starts from 1.
        marketId = (++getOfficeStorageStruct().marketCount).toMarketId();

        _setOfficer(marketId, officer);
        _setMarketConfig(marketId, marketConfig);

        emit Office__MarketCreated({officer: officer, marketConfig: marketConfig, market: marketId});
    }

    /// @inheritdoc IOffice
    function delegationCall(DelegationCallParams calldata params)
        external
        useContext(params.delegatee)
        returns (bytes memory returnData)
    {
        returnData = IDelegatee(params.delegatee).onDelegationCallback(params.callbackData);

        // If the `delegatee` called any function which reduces the account's health,
        // we need to check if the account is still healthy.
        if (requiresHealthCheck) {
            uint8 length = TransientEnumerableHashTableStorage._getLength();

            for (uint8 i; i < length; ++i) {
                (AccountId account, MarketId market) = TransientEnumerableHashTableStorage._get(i);
                require(isHealthyAccount(account, market), Office__AccountNotHealthy(account, market));
            }
        }
    }

    ///////////////////////////////////////////////
    //              Market Functions             //
    ///////////////////////////////////////////////

    /// @inheritdoc IOffice
    function supply(SupplyParams calldata params) external returns (uint256 shares) {
        ReserveKey key = params.tokenId.getReserveKey();
        MarketId market = key.getMarketId();
        IMarketConfig marketConfig = getMarketConfig(market);
        IHooks hooks = marketConfig.hooks();
        IERC20 supplyAsset = key.getAsset();

        hooks.callHook({hookSelector: IHooks.beforeSupply.selector, flag: BEFORE_SUPPLY_FLAG});

        // Check if the asset is allowed for supply.
        require(marketConfig.isSupportedAsset(supplyAsset), Office__ReserveNotSupported(key));

        // Mint shares to the account and update reserve data.
        shares = _supply({
            marketConfig: marketConfig,
            tokenId: params.tokenId,
            account: params.account,
            assets: params.assets
        });

        // Transfer the asset from the caller to the Office contract.
        supplyAsset.safeTransferFrom({from: msg.sender, to: address(this), value: params.assets});

        hooks.callHook({hookSelector: IHooks.afterSupply.selector, flag: AFTER_SUPPLY_FLAG});

        emit Office__AssetSupplied({
            account: params.account,
            tokenId: params.tokenId,
            shares: shares,
            assets: params.assets
        });
    }

    /// @inheritdoc IOffice
    /// @dev We don't check health of the account after this action given that the collateral
    ///      value remains the same. However, if the market values the escrowed and lent assets
    ///      differently, the account health has to be checked using appropriate hooks.
    function switchCollateral(SwitchCollateralParams calldata params)
        external
        onlyAuthorizedCaller(params.account)
        returns (uint256 assets, uint256 shares)
    {
        ReserveKey key = params.tokenId.getReserveKey();
        IMarketConfig marketConfig = getMarketConfig(key.getMarketId());
        IHooks hooks = marketConfig.hooks();

        hooks.callHook({
            hookSelector: IHooks.beforeSwitchCollateral.selector,
            flag: BEFORE_SWITCH_COLLATERAL_FLAG
        });

        // Withdraw the assets from the lending reserve or escrow and supply them to the other reserve.
        assets = _withdraw({
            marketConfig: marketConfig,
            tokenId: params.tokenId,
            account: params.account,
            shares: params.shares
        });

        // We skip the asset support check given that the asset is already supplied to the market
        // and hence supported.
        shares = _supply({
            marketConfig: marketConfig,
            tokenId: (params.tokenId.getTokenType() == TokenType.LEND) ? key.toEscrowId() : key.toLentId(),
            account: params.account,
            assets: assets
        });

        hooks.callHook({
            hookSelector: IHooks.afterSwitchCollateral.selector,
            flag: AFTER_SWITCH_COLLATERAL_FLAG
        });

        emit Office__CollateralSwitched({
            account: params.account,
            fromTokenId: params.tokenId,
            oldShares: params.shares,
            newShares: shares,
            assets: assets
        });
    }

    /// @inheritdoc IOffice
    function withdraw(WithdrawParams calldata params)
        external
        onlyAuthorizedCaller(params.account)
        returns (uint256 assets)
    {
        MarketId market = params.tokenId.getMarketId();
        IMarketConfig marketConfig = getMarketConfig(market);
        IHooks hooks = marketConfig.hooks();

        hooks.callHook({hookSelector: IHooks.beforeWithdraw.selector, flag: BEFORE_WITHDRAW_FLAG});

        assets = _withdraw({
            marketConfig: marketConfig,
            tokenId: params.tokenId,
            account: params.account,
            shares: params.shares
        });

        // Since `_withdraw` function does not check if the account is healthy after the withdrawal,
        // we need to check it here.
        _checkHealth(params.account, market);

        // Transfer the withdrawn assets to the receiver.
        params.tokenId.getAsset().safeTransfer({to: params.receiver, value: assets});

        hooks.callHook({hookSelector: IHooks.afterWithdraw.selector, flag: AFTER_WITHDRAW_FLAG});

        emit Office__AssetWithdrawn({
            account: params.account,
            receiver: params.receiver,
            tokenId: params.tokenId,
            shares: params.shares,
            assets: assets
        });
    }

    /// @inheritdoc IOffice
    function borrow(BorrowParams calldata params)
        external
        onlyAuthorizedCaller(params.account)
        returns (uint256 debtShares)
    {
        ReserveData storage $reserveData = getReserveDataStorage(params.key);
        MarketId market = params.key.getMarketId();
        IERC20 debtAsset = params.key.getAsset();
        IMarketConfig marketConfig = getMarketConfig(market);
        IHooks hooks = marketConfig.hooks();

        hooks.callHook({hookSelector: IHooks.beforeBorrow.selector, flag: BEFORE_BORROW_FLAG});

        require(marketConfig.isBorrowableAsset(debtAsset), Office__AssetNotBorrowable(params.key));

        // Accrue interest to update the reserve data before minting debt shares
        // to price the debt shares correctly.
        _accrueInterest(params.key, marketConfig);

        // We first mint the debt shares and update the reserve data.
        {
            uint256 debtId = params.key.toDebtId();

            debtShares = params.assets.toSharesUp($reserveData.borrowed, totalSupply(debtId));
            $reserveData.borrowed += params.assets;

            // Before interacting with the receiver, we check if there was enough liquidity in the reserve.
            require($reserveData.borrowed <= $reserveData.supplied, Office__InsufficientLiquidity(params.key));

            _mint({to: params.account, tokenId: debtId, amount: debtShares});
        }

        // Check if the account is undercollateralized after the borrowing.
        _checkHealth(params.account, market);

        // Transfer the borrow asset to the receiver.
        debtAsset.safeTransfer(params.receiver, params.assets);

        hooks.callHook({hookSelector: IHooks.afterBorrow.selector, flag: AFTER_BORROW_FLAG});

        emit Office__AssetBorrowed({account: params.account, key: params.key, assets: params.assets});
    }

    /// @inheritdoc IOffice
    function repay(RepayParams calldata params)
        external
        onlyAuthorizedCaller(params.account)
        returns (uint256 assetsRepaid)
    {
        IMarketConfig marketConfig = getMarketConfig(params.key.getMarketId());
        IHooks hooks = marketConfig.hooks();

        hooks.callHook({hookSelector: IHooks.beforeRepay.selector, flag: BEFORE_REPAY_FLAG});

        // Accrue interest to update the reserve data before burning debt shares
        // to price the debt shares correctly.
        _accrueInterest(params.key, marketConfig);

        // We first burn the debt shares and update the reserve data.
        {
            ReserveData storage $reserveData = getReserveDataStorage(params.key);
            uint256 debtId = params.key.toDebtId();

            assetsRepaid = params.shares.toAssetsUp($reserveData.borrowed, totalSupply(debtId));
            $reserveData.borrowed -= assetsRepaid;

            _burn({from: params.account, tokenId: debtId, amount: params.shares});
        }

        // Transfer the exact amount of assets from the repayer to this contract.
        params.key.getAsset().safeTransferFrom({from: msg.sender, to: address(this), value: assetsRepaid});

        hooks.callHook({hookSelector: IHooks.afterRepay.selector, flag: AFTER_REPAY_FLAG});

        emit Office__DebtRepaid({
            account: params.account,
            repayer: msg.sender,
            key: params.key,
            assets: assetsRepaid,
            shares: params.shares
        });
    }

    /// @inheritdoc IOffice
    function liquidate(LiquidationParams calldata params) external returns (uint256 assetsRepaid) {
        IMarketConfig marketConfig = getMarketConfig(params.market);
        IHooks hooks = marketConfig.hooks();
        ReserveKey debtKey = getDebtId(params.account, params.market).getReserveKey();
        IERC20 debtAsset = debtKey.getAsset();

        hooks.callHook({hookSelector: IHooks.beforeLiquidate.selector, flag: BEFORE_LIQUIDATE_FLAG});

        _accrueInterest(debtKey, marketConfig);

        // Given that it's possible to liquidate an account which is otherwise healthy during
        // a delegation call, we need to ensure that the transaction is not in the middle of a delegation call
        // regardless of the context.
        require(!isOngoingDelegationCall(), Office__CannotLiquidateDuringDelegationCall());

        // Check that the account is unhealthy before liquidating.
        require(
            !isHealthyAccount(params.account, params.market), Office__AccountStillHealthy(params.account, params.market)
        );

        uint256 liquidatorRepaymentObligation;
        {
            IOracleModule oracleModule = marketConfig.oracleModule();

            for (uint256 i; i < params.collateralShares.length; ++i) {
                IERC20 collateralAsset = params.collateralShares[i].tokenId.getAsset();

                uint256 assets = _withdraw({
                    marketConfig: marketConfig,
                    tokenId: params.collateralShares[i].tokenId,
                    account: params.account,
                    shares: params.collateralShares[i].shares
                });

                uint256 assetsValue =
                    oracleModule.getQuote({inAmount: assets, base: address(collateralAsset), quote: address(debtAsset)});

                assetsRepaid += assetsValue;

                // Transfer the underlying asset to the liquidator and update the repayment obligation.
                if (collateralAsset != debtAsset) {
                    // Convert the collateral asset amount to debt asset amount and add it to repayment obligation.
                    liquidatorRepaymentObligation += assetsValue;

                    collateralAsset.safeTransfer({to: msg.sender, value: assets});
                }
            }

            // We account for the bonus that needs to be paid to the liquidator after liquidating the collateral assets.
            uint256 bonusValue = assetsRepaid.mulWadDown(marketConfig.liquidationBonusPercentage());
            assetsRepaid -= bonusValue;

            // If the liquidator's repayment obligation exceeds the bonus value,
            // we reduce the repayment obligation by the bonus value.
            if (liquidatorRepaymentObligation >= bonusValue) {
                // We arrive at the following simplification for the repayment obligation in the following manner:
                // Let x be the total amount of repayment obligation in the debt asset and
                // y be the amount liquidated but the liquidator is not obligated to repay (i.e., debtAsset ==
                // collateralAsset).
                // Then, the repayment obligation is given by:
                // obligation = x * (1 - bonusPercentage) - y * bonusPercentage.
                //            = x - (x * bonusPercentage) - (y * bonusPercentage).
                //            = x - (x + y) * bonusPercentage.
                // The `(x + y) * bonusPercentage` term is equivalent to the bonus value.
                liquidatorRepaymentObligation -= bonusValue;
            } else {
                // If however, the liquidator's repayment obligation is less than the bonus value,
                // we transfer remaining bonus value to the liquidator and the liquidator need not
                // repay with the debt asset. This can happen when the one of the collateral assets
                // is the same as the debt asset, and its value dominates the liquidation value.
                debtAsset.safeTransfer({to: msg.sender, value: bonusValue - liquidatorRepaymentObligation});

                liquidatorRepaymentObligation = 0;
            }
        }

        // Before calling the liquidator, we need to burn the shares of the debt asset equivalent to the
        // `assetsRepaid` amount and update the reserve data.
        // Note: We have used saturating sub to avoid rounding errors which could pop up when subtracting.
        uint256 debtSharesRepaid;
        uint256 debtSharesUnpaid;
        uint256 debtAssetsUnpaid;
        {
            ReserveData storage $reserveData = getReserveDataStorage(debtKey);
            uint256 debtId = debtKey.toDebtId();

            debtSharesRepaid = assetsRepaid.toSharesUp($reserveData.borrowed, totalSupply(debtId));
            $reserveData.borrowed = $reserveData.borrowed.saturatingSub(assetsRepaid);

            _burn({from: params.account, tokenId: debtId, amount: debtSharesRepaid});

            // If the position has accrued bad debt, we need to socialise the losses and remove the debt
            // from the account.
            debtSharesUnpaid = balanceOf(params.account, debtId);
            if (
                getAccountsStorageStruct().marketWiseData[params.account][params.market].collateralIds.length() == 0
                    && debtSharesUnpaid > 0
            ) {
                debtAssetsUnpaid = debtSharesUnpaid.toAssetsUp($reserveData.borrowed, totalSupply(debtId));

                $reserveData.borrowed = $reserveData.borrowed.saturatingSub(debtAssetsUnpaid);
                $reserveData.supplied = $reserveData.supplied.saturatingSub(debtAssetsUnpaid);

                _burn({from: params.account, tokenId: debtId, amount: debtSharesUnpaid});
            }
        }

        // Invoke the liquidator's callback function to allow them to perform any additional actions
        // if the callback data is present.
        if (params.callbackData.length > 0) {
            ILiquidator(msg.sender).onLiquidationCallback(liquidatorRepaymentObligation, params.callbackData);
        }

        // Transfer the debt asset from the liquidator to this contract thus reducing/repaying the debt.
        debtAsset.safeTransferFrom({from: msg.sender, to: address(this), value: liquidatorRepaymentObligation});

        hooks.callHook({hookSelector: IHooks.afterLiquidate.selector, flag: AFTER_LIQUIDATE_FLAG});

        emit Office__AccountLiquidated({
            account: params.account,
            liquidator: msg.sender,
            market: params.market,
            repaidShares: debtSharesRepaid,
            repaidAssets: assetsRepaid,
            unpaidShares: debtSharesUnpaid,
            unpaidAssets: debtAssetsUnpaid
        });
    }

    /// @inheritdoc IOffice
    function migrateSupply(MigrateSupplyParams calldata params)
        external
        onlyAuthorizedCaller(params.account)
        returns (uint256 assetsRedeemed, uint256 newSharesMinted)
    {
        MarketId fromMarket = params.fromTokenId.getMarketId();
        MarketId toMarket = params.toTokenId.getMarketId();
        IMarketConfig fromMarketConfig = getMarketConfig(fromMarket);
        IMarketConfig toMarketConfig = getMarketConfig(toMarket);
        IHooks fromHooks = fromMarketConfig.hooks();
        IHooks toHooks = toMarketConfig.hooks();
        ReserveKey toKey = params.toTokenId.getReserveKey();

        fromHooks.callHook({
            hookSelector: IHooks.beforeMigrateSupply.selector,
            flag: BEFORE_MIGRATE_SUPPLY_FLAG
        });
        toHooks.callHook({hookSelector: IHooks.beforeMigrateSupply.selector, flag: BEFORE_MIGRATE_SUPPLY_FLAG});

        // Check that the asset is accepted in the new market.
        require(toMarketConfig.isSupportedAsset(params.toTokenId.getAsset()), Office__ReserveNotSupported(toKey));

        // Withdraw the assets from the `fromTokenId` reserve and supply them to the `toTokenId` reserve.
        assetsRedeemed = _withdraw({
            marketConfig: fromMarketConfig,
            tokenId: params.fromTokenId,
            account: params.account,
            shares: params.shares
        });
        newSharesMinted = _supply({
            marketConfig: toMarketConfig,
            tokenId: params.toTokenId,
            account: params.account,
            assets: assetsRedeemed
        });

        // Because we are withdrawing from one market and transferring value to another market, we need to check
        // the account's health in the old market.
        _checkHealth(params.account, fromMarket);

        fromHooks.callHook({hookSelector: IHooks.afterMigrateSupply.selector, flag: AFTER_MIGRATE_SUPPLY_FLAG});
        toHooks.callHook({hookSelector: IHooks.afterMigrateSupply.selector, flag: AFTER_MIGRATE_SUPPLY_FLAG});

        emit Office__SupplyMigrated({
            account: params.account,
            fromTokenId: params.fromTokenId,
            toTokenId: params.toTokenId,
            assetsRedeemed: assetsRedeemed,
            newSharesMinted: newSharesMinted
        });
    }

    /// @inheritdoc IOffice
    function donateToReserve(ReserveKey key, uint256 assets) external onlyOfficer(key.getMarketId()) {
        OfficeStorage.ReserveData storage $reserveData = getReserveDataStorage(key);

        // It isn't worth donating to a reserve which has no assets supplied as all it does is
        // increase the initial exchange rate of the reserve.
        require($reserveData.supplied != 0, Office__ReserveIsEmpty(key));

        $reserveData.supplied += assets;

        // Transfer the donation from the caller to the Office contract.
        key.getAsset().safeTransferFrom({from: msg.sender, to: address(this), value: assets});

        emit Office__AssetDonated({key: key, assets: assets});
    }

    /// @inheritdoc IOffice
    function flashloan(IERC20 token, uint256 assets, bytes calldata callbackData) external {
        token.safeTransfer({to: msg.sender, value: assets});

        IFlashloanReceiver(msg.sender).onFlashloanCallback({assets: assets, callbackData: callbackData});

        token.safeTransferFrom({from: msg.sender, to: address(this), value: assets});

        emit Office__AssetFlashloaned({receiver: msg.sender, token: token, assets: assets});
    }

    /// @inheritdoc IOffice
    function accrueInterest(ReserveKey key) public returns (uint256 interest) {
        return _accrueInterest(key, getMarketConfig(key.getMarketId()));
    }

    //////////////////////////////////////////////////
    //                View Functions                //
    /////////////////////////////////////////////////

    /// @inheritdoc IOffice
    function isHealthyAccount(AccountId account, MarketId market) public view returns (bool isHealthy) {
        IMarketConfig marketConfig = getMarketConfig(market);
        IOracleModule oracleModule = marketConfig.oracleModule();
        IWeights weights = marketConfig.weights();
        uint256 debtId = getDebtId(account, market);

        // If the account has no debt, it is considered healthy.
        if (debtId == 0) {
            return true;
        }

        ReserveKey debtKey = debtId.getReserveKey();

        // First we calculate the debt value in USD.
        uint256 debtValueUSD;
        {
            // Rounding up in favour of the lenders.
            uint256 debtAmount =
                balanceOf(account, debtId).toAssetsUp(getReserveDataStorage(debtKey).borrowed, totalSupply(debtId));

            debtValueUSD = oracleModule.getQuote({
                inAmount: debtAmount,
                base: address(debtKey.getAsset()),
                quote: USD_ISO_ADDRESS
            });
        }

        uint256 minMarginAmountUSD = marketConfig.minMarginAmountUSD();
        uint256[] memory collateralIds = getAllCollateralIds(account, market);
        uint256 weightedCollateralValueUSD;

        // Next, we calculate the collateral assets' value in USD.
        for (uint256 i; i < collateralIds.length; ++i) {
            ReserveKey collateralKey = collateralIds[i].getReserveKey();

            // If the collateralId represents an escrow token, we simply convert the balance of the account
            // to the asset amount.
            // Otherwise, we need to calculate the asset amount using shares math lib.
            uint256 assetAmount;
            if (collateralIds[i].getTokenType() == TokenType.ESCROW) {
                assetAmount = balanceOf(account, collateralIds[i]);
            } else {
                assetAmount = balanceOf(account, collateralIds[i]).toAssetsDown(
                    getReserveDataStorage(collateralKey).supplied, totalSupply(collateralIds[i])
                );
            }

            // Fetch the collateral asset's value in USD and multiply it by the weight of the collateral asset
            // in relation to the debt asset and the account in context.
            weightedCollateralValueUSD += oracleModule.getQuote({
                inAmount: assetAmount,
                base: address(collateralKey.getAsset()),
                quote: USD_ISO_ADDRESS
            }).mulWadDown(
                weights.getWeight({account: account, collateralTokenId: collateralIds[i], debtAsset: debtKey})
            );

            // If at any point the weighted collateral value equals/exceeds the debt value AND
            // the weighted collateral value exceeds the minimum margin amount in USD for the market,
            // we can conclude that the account is healthy and return early.
            // If the account isn't healthy even after accounting for the last collateral asset,
            // the function will return false as it never entered this block.
            if (weightedCollateralValueUSD >= debtValueUSD && weightedCollateralValueUSD >= minMarginAmountUSD) {
                return true;
            }
        }
    }

    /// @inheritdoc IOffice
    function isAuthorizedCaller(AccountId account, address caller) public view returns (bool isAuthorized) {
        return caller == ownerOf(account) || isOperator(account, caller);
    }

    ////////////////////////////////////////////////
    //               Internal Functions           //
    ////////////////////////////////////////////////

    /// @dev Internal function to supply assets to the Office contract.
    ///      - This function checks if the `tokenId` is a valid collateral token.
    ///      - This function DOES NOT check if the `tokenId` is accepted in the market.
    function _supply(
        IMarketConfig marketConfig,
        uint256 tokenId,
        AccountId account,
        uint256 assets
    )
        internal
        returns (uint256 shares)
    {
        ReserveKey key = tokenId.getReserveKey();

        // Check if the tokenId is a valid collateral token.
        require(tokenId.isCollateral(), Office__IncorrectTokenId(tokenId));

        _accrueInterest(key, marketConfig);

        // If lending the token, shares are minted based on the amount supplied and the total supply of the shares.
        if (tokenId.getTokenType() == TokenType.LEND) {
            OfficeStorage.ReserveData storage $reserveData = getReserveDataStorage(key);

            shares = assets.toSharesDown($reserveData.supplied, totalSupply(tokenId));
            $reserveData.supplied += assets;
        } else {
            shares = assets;
        }

        _mint({to: account, tokenId: tokenId, amount: shares});
    }

    /// @dev Internal function to withdraw assets from the Office contract.
    ///      This function DOES NOT check if the account will be healthy after the withdrawal.
    function _withdraw(
        IMarketConfig marketConfig,
        uint256 tokenId,
        AccountId account,
        uint256 shares
    )
        internal
        returns (uint256 assets)
    {
        ReserveKey key = tokenId.getReserveKey();

        // Check if the tokenId is valid.
        require(tokenId.isCollateral(), Office__IncorrectTokenId(tokenId));

        // Accrue interest to update the reserve data before burning shares.
        _accrueInterest(key, marketConfig);

        if (tokenId.getTokenType() == TokenType.LEND) {
            OfficeStorage.ReserveData storage $reserveData = getReserveDataStorage(key);

            assets = shares.toAssetsDown($reserveData.supplied, totalSupply(tokenId));
            $reserveData.supplied -= assets;

            // Revert if there isn't enough liquidity in the reserve.
            require($reserveData.borrowed <= $reserveData.supplied, Office__InsufficientLiquidity(key));
        } else {
            // If the tokenId is an escrow token, shares are priced 1:1 with the assets.
            // It is assumed that the escrow reserve will always have sufficient liquidity for withdrawals
            // given that it is not borrowable and is not at a risk of bad debt accrual.
            assets = shares;
        }

        _burn({from: account, tokenId: tokenId, amount: shares});
    }

    /// @dev This function WILL NOT revert even if the asset is not borrowable.
    function _accrueInterest(ReserveKey key, IMarketConfig marketConfig) internal returns (uint256 interest) {
        ReserveData storage $reserveData = getReserveDataStorage(key);
        uint64 feePercentage = marketConfig.feePercentage();
        uint256 dt = block.timestamp - $reserveData.lastUpdateTimestamp;

        // In case no time has passed since the last update or the reserve is not borrowable we simply return 0.
        if (dt == 0 || !marketConfig.isBorrowableAsset(key.getAsset())) {
            return 0;
        }

        // Computing the compounded interest accrued over the time interval `dt`.
        // We use first 3 terms of the Taylor series expansion for e^(rt) - 1 as an approximation.
        {
            uint256 ratePerSecond = marketConfig.irm().borrowRate(key);
            uint256 rt = ratePerSecond * dt;
            uint256 rt2 = rt.mulDivDown(rt, 2 * WAD);
            uint256 rt3 = rt2.mulDivDown(rt, 3 * WAD);

            interest = $reserveData.borrowed.mulWadDown(rt + rt2 + rt3);

            // Update both the reserve data.
            $reserveData.supplied += interest;
            $reserveData.borrowed += interest;
            $reserveData.lastUpdateTimestamp = uint128(block.timestamp);
        }

        // If performance fee is set, calculate and mint the fee shares.
        if (feePercentage > 0) {
            uint256 shareId = key.toLentId();
            uint256 feeAmount = interest.mulWadDown(feePercentage);

            // Since the fee amount is accounted for already in the supplied amount, we need to subtract it
            // when calculating the fee shares to mint. This is equivalent to assuming that the fee amount is
            // being supplied to the reserve.
            uint256 feeSharesToMint = feeAmount.toSharesDown($reserveData.supplied - feeAmount, totalSupply(shareId));

            if (feeSharesToMint > 0) {
                _mint({to: marketConfig.feeRecipient().toUserAccount(), tokenId: shareId, amount: feeSharesToMint});

                emit Office__PerformanceFeeMinted({key: key, shares: feeSharesToMint});
            }
        }
    }

    /// @dev Overriden to ensure that the `from` account is healthy after `tokenId` transfer.
    ///      - Allows a delegatee to transfer collateral tokens between `from` account and `to` account
    ///        if and only if the `from` account is in delegation call context.
    function _update(AccountId from, AccountId to, uint256 tokenId, uint256 amount) internal override {
        super._update({from: from, to: to, tokenId: tokenId, amount: amount});

        TokenType tokenType = tokenId.getTokenType();

        // If `from` and `to` are both non-zero addresses and the `tokenId` represents an account token, the following check is unnecessary.
        if (
            from != ACCOUNT_ID_ZERO && to != ACCOUNT_ID_ZERO
                && (tokenType == TokenType.LEND || tokenType == TokenType.ESCROW || tokenType == TokenType.DEBT)
        ) {
            MarketId market = tokenId.getMarketId();

            // Regardless of the token type, we ensure that the `from` account is healthy after the transfer.
            _checkHealth(from, market);

            // If the `tokenId` is a debt token and the amount is greater than 0, we need to ensure that:
            // - The caller is authorized to perform actions on behalf of the `to` account.
            // - The `to` account is healthy after the debt transfer.
            if (tokenType == TokenType.DEBT && amount != 0) {
                _onlyAuthorizedCaller(to);
                _checkHealth(to, market);
            }
        }
    }

    /// @dev Checks if the account is healthy after a market operation.
    ///      - If the ongoing call is a delegation call, we defer the health checks.
    function _checkHealth(AccountId account, MarketId market) internal {
        if (isOngoingDelegationCall()) {
            requiresHealthCheck = true;
            TransientEnumerableHashTableStorage._insert(account, market);
        } else {
            require(isHealthyAccount(account, market), Office__AccountNotHealthy(account, market));
        }
    }

    /// @dev Reverts if the caller is not authorized as per ```isAuthorizedCaller``` function.
    function _onlyAuthorizedCaller(AccountId account) internal view {
        require(isAuthorizedCaller(account, msg.sender), Office__NotAuthorizedCaller(account, msg.sender));
    }
}
