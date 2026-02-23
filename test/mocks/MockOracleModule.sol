// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";

import {IERC20Metadata} from "@openzeppelin-contracts/interfaces/IERC20Metadata.sol";
import {IOracleModule} from "../../src/interfaces/IOracleModule.sol";
import {USD_ISO_ADDRESS} from "../../src/libraries/Constants.sol";


contract MockOracleModule is IOracleModule {
    using Math for uint256;

    mapping(address asset => uint256 price) private _prices;

    /// @dev Set prices with proper precision/decimals.
    ///      We use the chainlink convention of 8 decimals for prices.
    function setPrice(address asset, uint256 price) external {
        _prices[asset] = price;
    }

    /// @dev Set prices with proper precision/decimals.
    ///      We use the chainlink convention of 8 decimals for prices.
    function setPrices(address[] calldata assets, uint256[] calldata prices) external {
        require(assets.length == prices.length, "Mismatched lengths");
        for (uint256 i = 0; i < assets.length; i++) {
            _prices[assets[i]] = prices[i];
        }
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount) {
        require(_prices[base] > 0 && _prices[quote] > 0, "Price not set");
        uint256 basePrice = _prices[base];
        uint256 quotePrice = _prices[quote];

        // If the base asset is USD, we assume `inAmount` has 18 decimals.
        uint8 baseDecimals = (base != USD_ISO_ADDRESS) ? IERC20Metadata(base).decimals() : 18;
        uint8 quoteDecimals = (quote != USD_ISO_ADDRESS) ? IERC20Metadata(quote).decimals() : 18;

        uint256 baseScale = 10 ** (baseDecimals + 8);
        uint256 quoteScale = 10 ** (quoteDecimals + 8);
        
        // Calculate the quote amount using mulDiv to prevent overflow and preserve precision.
        // The formula is: outAmount = inAmount * (basePriceUSD / baseScale) / (quotePriceUSD / quoteScale)
        // Which simplifies to: outAmount = (inAmount * basePriceUSD * quoteScale) / (quotePriceUSD * baseScale)
        if (quoteScale >= baseScale) {
            uint256 scaleRatio = quoteScale / baseScale;
            return inAmount.mulDiv(basePrice * scaleRatio, quotePrice);
        } else {
            uint256 scaleRatio = baseScale / quoteScale;
            return inAmount.mulDiv(basePrice, quotePrice * scaleRatio);
        }
    }
}
