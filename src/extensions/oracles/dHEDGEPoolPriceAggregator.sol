// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.29;

import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";

import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IdHEDGEPoolFactory} from "./interfaces/IdHEDGEPoolFactory.sol";
import {IdHEDGEPoolLogic} from "./interfaces/IdHEDGEPoolLogic.sol";

import {BaseOracleModule} from "./BaseOracleModule.sol";
import {USD_ISO_ADDRESS} from "../../libraries/Constants.sol";

/// @title dHEDGEPoolPriceAggregator
/// @notice Oracle module that fetches prices from dHEDGE Vaults and converts them to USD (ISO 4217 code 840)
///         or other Chainlink price oracles supported assets if whitelisted.
/// @dev Implements the IOracleModule interface.
///      - The contract is ownable and the owner can set whitelisted assets.
///      - Whitelisting is required only for non-dHEDGE vault assets.
///      - For dHEDGE vaults, the price is fetched from the vault's `tokenPrice` function.
///      - Only Chainlink price oracles (or oracles with the same interface) are supported for non-dHEDGE vault assets.
///      - Will return price in WAD (18 decimals) if quote is USD.
/// @author Chinmay <chinmay@dhedge.org>
contract dHEDGEPoolPriceAggregator is BaseOracleModule, Ownable {
    using Math for uint256;

    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error dHEDGEPoolPriceAggregator__ZeroValue();
    error dHEDGEPoolPriceAggregator__ZeroAddress();
    error dHEDGEPoolPriceAggregator__PriceNotFound(address asset);
    error dHEDGEPoolPriceAggregator__StalePrice(address asset, uint256 staleness);

    /////////////////////////////////////////////
    //                Structs                  //
    /////////////////////////////////////////////

    /// @param oracle Chainlink AggregatorV3Interface oracle for the asset.
    /// @param maxStaleness Maximum allowed staleness for the oracle price.
    /// @param scale Sum of asset decimals and oracle feed decimals raised to the power of 10.
    struct OracleData {
        AggregatorV3Interface oracle;
        uint256 maxStaleness;
        uint256 scale;
    }

    /////////////////////////////////////////////
    //                Storage                  //
    /////////////////////////////////////////////

    IdHEDGEPoolFactory internal immutable _POOL_FACTORY;

    mapping(address asset => OracleData data) public oracles;

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    constructor(address admin, address poolFactory) Ownable(admin) {
        require(poolFactory != address(0) && admin != address(0), dHEDGEPoolPriceAggregator__ZeroAddress());

        _POOL_FACTORY = IdHEDGEPoolFactory(poolFactory);
    }

    /////////////////////////////////////////////
    //           Internal Functions            //
    /////////////////////////////////////////////

    function _getQuote(
        uint256 inAmount,
        address base,
        address quote
    )
        internal
        view
        override
        returns (uint256 outAmount)
    {
        // If same assets, return inAmount.
        if (base == quote) {
            return inAmount;
        }

        (uint256 basePriceUSD, uint256 baseScale) = _getPrice(base);
        (uint256 quotePriceUSD, uint256 quoteScale) = _getPrice(quote);

        // Calculate the quote amount using mulDiv to prevent overflow and preserve precision.
        // The formula is: outAmount = inAmount * (basePriceUSD / baseScale) / (quotePriceUSD / quoteScale)
        // Which simplifies to: outAmount = (inAmount * basePriceUSD * quoteScale) / (quotePriceUSD * baseScale)
        if (quoteScale >= baseScale) {
            uint256 scaleRatio = quoteScale / baseScale;
            return inAmount.mulDiv(basePriceUSD * scaleRatio, quotePriceUSD);
        } else {
            uint256 scaleRatio = baseScale / quoteScale;
            return inAmount.mulDiv(basePriceUSD, quotePriceUSD * scaleRatio);
        }
    }

    function _getPrice(address asset) internal view returns (uint256 priceUSD, uint256 scale) {
        // For dHEDGE vaults, fetch price from the vault's tokenPrice function.
        if (_POOL_FACTORY.isPool(asset)) {
            return (IdHEDGEPoolLogic(asset).tokenPrice(), 1e36);
        }

        // For non-dHEDGE vault assets, fetch price from Chainlink oracle.
        OracleData memory oracleData = oracles[asset];
        if (address(oracleData.oracle) != address(0)) {
            // For whitelisted assets, fetch price from Chainlink oracle.
            (, int256 answer,, uint256 updatedAt,) = oracleData.oracle.latestRoundData();

            require(answer > 0, dHEDGEPoolPriceAggregator__PriceNotFound(asset));

            uint256 staleness = block.timestamp - updatedAt;
            require(staleness <= oracleData.maxStaleness, dHEDGEPoolPriceAggregator__StalePrice(asset, staleness));

            priceUSD = uint256(answer);
            scale = oracleData.scale;
        } else if (asset == USD_ISO_ADDRESS) {
            // If asset is ISO 4217 code for USD, return 1e18 with 18 decimals.
            priceUSD = 1e18;
            scale = 1e36;
        } else {
            revert dHEDGEPoolPriceAggregator__PriceNotFound(asset);
        }
    }

    /////////////////////////////////////////////
    //            Owner Functions              //
    /////////////////////////////////////////////

    /// @notice Sets the oracle for an asset.
    ///         - Useful only for whitelisting non-dHEDGE vault assets.
    ///         - Can modify the existing oracle data for an asset.
    ///         - Can be used to unset an oracle by passing zero address.
    /// @param asset The asset for which the oracle is being set.
    /// @param oracle The Chainlink AggregatorV3Interface oracle address for the asset.
    /// @param maxStaleness The maximum allowed staleness for the oracle price.
    function setOracle(address asset, address oracle, uint256 maxStaleness) external onlyOwner {
        require(asset != address(0), dHEDGEPoolPriceAggregator__ZeroAddress());
        require(maxStaleness > 0 || oracle == address(0), dHEDGEPoolPriceAggregator__ZeroValue());

        // Unset oracle.
        if (oracle == address(0)) {
            delete oracles[asset];
            return;
        }

        uint8 assetDecimals = _getDecimals(asset);
        uint8 oracleDecimals = AggregatorV3Interface(oracle).decimals();

        oracles[asset] = OracleData({
            oracle: AggregatorV3Interface(oracle),
            maxStaleness: maxStaleness,
            scale: 10 ** (assetDecimals + oracleDecimals)
        });
    }
}
