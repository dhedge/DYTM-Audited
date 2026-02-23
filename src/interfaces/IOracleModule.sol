// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.29;

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
