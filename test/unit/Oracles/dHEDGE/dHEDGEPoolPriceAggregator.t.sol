// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../../shared/CommonScenarios.sol";
import {dHEDGEPoolPriceAggregator} from "../../../../src/extensions/oracles/dHEDGEPoolPriceAggregator.sol";
import {AggregatorV3Interface} from "../../../../src/extensions/oracles/interfaces/AggregatorV3Interface.sol";
import {IdHEDGEPoolFactory} from "../../../../src/extensions/oracles/interfaces/IdHEDGEPoolFactory.sol";
import {IdHEDGEPoolLogic} from "../../../../src/extensions/oracles/interfaces/IdHEDGEPoolLogic.sol";
import {USD_ISO_ADDRESS} from "../../../../src/libraries/Constants.sol";

contract dHEDGEPoolPriceAggregatorTest is CommonScenarios {
    using FixedPointMathLib for uint256;

    dHEDGEPoolPriceAggregator internal aggregator;

    address internal _poolFactory = makeAddr("poolFactory");
    address internal _dhedgePool = makeAddr("dhedgePool");
    address internal _validToken = makeAddr("validToken");
    address internal _chainlinkOracle = makeAddr("chainlinkOracle");

    address internal _usdc = makeAddr("USDC");
    address internal _weth = makeAddr("WETH");
    address internal _usdcOracle = makeAddr("usdcOracle");
    address internal _wethOracle = makeAddr("wethOracle");

    uint256 internal constant DEFAULT_PRICE = 2000e8; // $2000 with 8 decimals
    uint256 internal constant DHEDGE_POOL_PRICE = 1.2e18; // $1.20 with 18 decimals
    uint256 internal constant MAX_STALENESS = 3600; // 1 hour
    uint256 internal constant USDC_PRICE = 1e8; // $1
    uint256 internal constant WETH_PRICE = 2000e8; // $2000

    function setUp() public override {
        super.setUp();

        // Mock pool factory to return true for _dhedgePool
        vm.mockCall(
            _poolFactory, abi.encodeWithSelector(IdHEDGEPoolFactory.isPool.selector, _dhedgePool), abi.encode(true)
        );

        // Mock pool factory to return false for other addresses
        vm.mockCall(_poolFactory, abi.encodeWithSelector(IdHEDGEPoolFactory.isPool.selector), abi.encode(false));

        // Mock USDC decimals (6)
        vm.mockCall(_usdc, abi.encodeWithSelector(bytes4(keccak256("decimals()"))), abi.encode(uint8(6)));
        // Mock WETH decimals (18)
        vm.mockCall(_weth, abi.encodeWithSelector(bytes4(keccak256("decimals()"))), abi.encode(uint8(18)));

        // Mock dHEDGE pool token price
        vm.mockCall(
            _dhedgePool, abi.encodeWithSelector(IdHEDGEPoolLogic.tokenPrice.selector), abi.encode(DHEDGE_POOL_PRICE)
        );

        // Mock chainlink oracle calls
        vm.mockCall(
            _chainlinkOracle, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(uint8(8))
        );

        vm.mockCall(
            _chainlinkOracle,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), int256(DEFAULT_PRICE), uint256(0), block.timestamp, uint80(1))
        );

        // Mock Oracles for Precision Tests
        vm.mockCall(_usdcOracle, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(uint8(8)));
        vm.mockCall(
            _usdcOracle,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), int256(USDC_PRICE), uint256(0), block.timestamp, uint80(1))
        );

        vm.mockCall(_wethOracle, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(uint8(8)));
        vm.mockCall(
            _wethOracle,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), int256(WETH_PRICE), uint256(0), block.timestamp, uint80(1))
        );

        // Mock token decimals
        vm.mockCall(_validToken, abi.encodeWithSelector(bytes4(keccak256("decimals()"))), abi.encode(uint8(18)));

        // Deploy aggregator
        aggregator = new dHEDGEPoolPriceAggregator(admin, _poolFactory);

        // Set oracle for valid token
        vm.startPrank(admin);

        aggregator.setOracle(_validToken, _chainlinkOracle, MAX_STALENESS);
        aggregator.setOracle(_usdc, _usdcOracle, MAX_STALENESS);
        aggregator.setOracle(_weth, _wethOracle, MAX_STALENESS);
        vm.stopPrank();
    }

    /////////////////////////////////////////////
    //     When base asset is a dHEDGE vault   //
    /////////////////////////////////////////////

    function test_WhenBaseAssetIsAdHEDGEVault_GivenQuoteAssetUSD_ItShouldReturnTokenPriceOfTheVault() public view {
        uint256 inAmount = 5e18; // 5 pool tokens

        // It should return token price of the vault.
        uint256 result = aggregator.getQuote(inAmount, _dhedgePool, USD_ISO_ADDRESS);
        assertEq(result, DHEDGE_POOL_PRICE * 5, "Should return dHEDGE pool token price");
    }

    function test_WhenBaseAssetIsAdHEDGEVault_GivenQuoteAssetIsAValidToken_ItShouldReturnTokenPriceOfTheVaultInTermsOfTheQuoteAsset()
        public
        view
    {
        uint256 inAmount = 1e18; // 1 pool token

        // It should return token price of the vault in terms of the quote asset.
        uint256 result = aggregator.getQuote(inAmount, _dhedgePool, _validToken);

        // Expected calculation: (inAmount * basePriceUSD * quoteScale) / (quotePriceUSD * baseScale)
        // basePriceUSD = $1.2, quotePriceUSD = $2000
        // quote asset decimals = 18
        // 1 pool token = 1.2 * 1e18 / 2000 = 600000000000000
        assertEq(result, 600_000_000_000_000, "Should return correct price ratio");
    }

    function test_WhenBaseAssetIsAdHEDGEVault_GivenQuoteAssetIsTheSameAsTheBaseAsset_ItShouldReturnTheInputAmount()
        public
        view
    {
        uint256 inAmount = 1e18; // 1 pool token

        // It should return the input amount.
        uint256 result = aggregator.getQuote(inAmount, _dhedgePool, _dhedgePool);
        assertEq(result, inAmount, "Should return input amount when base and quote are same");
    }

    function test_RevertWhenBaseAssetIsAdHEDGEVault_GivenQuoteAssetOracleIsNotSet_WithdHEDGEPoolPriceAggregator__PriceNotFoundError()
        public
    {
        address unknownAsset = makeAddr("unknownAsset");
        uint256 inAmount = 1e18;

        // It should revert with `dHEDGEPoolPriceAggregator__PriceNotFound` error.
        vm.expectRevert(
            abi.encodeWithSelector(
                dHEDGEPoolPriceAggregator.dHEDGEPoolPriceAggregator__PriceNotFound.selector, unknownAsset
            )
        );
        aggregator.getQuote(inAmount, _dhedgePool, unknownAsset);
    }

    /////////////////////////////////////////////
    //     When quote asset is a dHEDGE vault  //
    /////////////////////////////////////////////

    function test_WhenQuoteAssetIsAdHEDGEVault_GivenBaseAssetIsUSD_ItShouldReturnTheInverseTokenPriceOfTheVault()
        public
        view
    {
        uint256 inAmount = 1e18; // 1 USD

        // It should return the inverse token price of the vault.
        uint256 result = aggregator.getQuote(inAmount, USD_ISO_ADDRESS, _dhedgePool);

        // pool token price = 1.2e18
        // 1 USD worth of pool tokens = 1 / 1.2 = 0.8333
        // => inAmount * pool_token_decimals / pool_token_price
        uint256 expected = inAmount.divWadDown(DHEDGE_POOL_PRICE);
        assertEq(result, expected, "Should return inverse pool token price");
    }

    function test_WhenQuoteAssetIsAdHEDGEVault_GivenBaseAssetIsAValidToken_ItShouldReturnTheInverseTokenPriceOfTheVaultInTermsOfTheBaseAsset()
        public
        view
    {
        uint256 inAmount = 1e18; // 1 token

        // It should return the inverse token price of the vault in terms of the base asset.
        uint256 result = aggregator.getQuote(inAmount, _validToken, _dhedgePool);

        // Expected: 1 * 2000 * 1e18 / 1.2
        assertEq(result, 1_666_666_666_666_666_666_666, "Should return correct inverse price ratio");
    }

    function test_RevertWhenQuoteAssetIsAdHEDGEVault_GivenBaseAssetOracleIsNotSet_WithdHEDGEPoolPriceAggregator__PriceNotFoundError()
        public
    {
        address unknownAsset = makeAddr("unknownAsset");
        uint256 inAmount = 1e18;

        // It should revert with `dHEDGEPoolPriceAggregator__PriceNotFound` error.
        vm.expectRevert(
            abi.encodeWithSelector(
                dHEDGEPoolPriceAggregator.dHEDGEPoolPriceAggregator__PriceNotFound.selector, unknownAsset
            )
        );
        aggregator.getQuote(inAmount, unknownAsset, _dhedgePool);
    }

    /////////////////////////////////////////////
    //          Edge case tests               //
    /////////////////////////////////////////////

    function test_RevertWhenOraclePriceIsStale_WithdHEDGEPoolPriceAggregator__StalePriceError() public {
        // Ensure we have a current timestamp that allows for staleness calculation
        vm.warp(MAX_STALENESS + 1000); // Set timestamp well beyond MAX_STALENESS

        // Mock stale oracle data (updated more than MAX_STALENESS seconds ago)
        uint256 staleTimestamp = block.timestamp - MAX_STALENESS - 1;
        vm.mockCall(
            _chainlinkOracle,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), int256(DEFAULT_PRICE), uint256(0), staleTimestamp, uint80(1))
        );

        uint256 inAmount = 1e18;
        uint256 expectedStaleness = block.timestamp - staleTimestamp; // This will be MAX_STALENESS + 1

        // It should revert with `dHEDGEPoolPriceAggregator__StalePrice` error.
        vm.expectRevert(
            abi.encodeWithSelector(
                dHEDGEPoolPriceAggregator.dHEDGEPoolPriceAggregator__StalePrice.selector, _validToken, expectedStaleness
            )
        );
        aggregator.getQuote(inAmount, _validToken, USD_ISO_ADDRESS);
    }

    function test_RevertWhenOraclePriceIsZero_WithdHEDGEPoolPriceAggregator__PriceNotFoundError() public {
        // Mock zero price oracle data
        vm.mockCall(
            _chainlinkOracle,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), int256(0), uint256(0), block.timestamp, uint80(1))
        );

        uint256 inAmount = 1e18;

        // It should revert with `dHEDGEPoolPriceAggregator__PriceNotFound` error.
        vm.expectRevert(
            abi.encodeWithSelector(
                dHEDGEPoolPriceAggregator.dHEDGEPoolPriceAggregator__PriceNotFound.selector, _validToken
            )
        );
        aggregator.getQuote(inAmount, _validToken, USD_ISO_ADDRESS);
    }

    /////////////////////////////////////////////
    //          Precision Tests               //
    /////////////////////////////////////////////

    function test_PrecisionPreserved_SmallAmount_USDC_to_WETH() public view {
        uint256 inAmount = 1; // 1 wei USDC (1e-6 USD)

        // 1 wei USDC = 1e-6 USD.
        // WETH price = 2000 USD.
        // Expected WETH = 1e-6 / 2000 = 0.5e-9 ETH = 0.5e9 wei = 5e8 wei.

        uint256 result = aggregator.getQuote(inAmount, _usdc, _weth);

        assertEq(result, 5e8, "Should preserve precision for small amounts");
    }

    function test_Overflow_Intermediate_BaseInQuote_OverflowsUint256() public {
        // Base: dHEDGE Vault (18 dec). Price $1M (1e24).
        // Quote: USDC (6 dec). Price $1 (1e8).
        // inAmount: 1e65.

        // baseScale = 1e36. quoteScale = 1e14.
        // basePriceUSD = 1e24. quotePriceUSD = 1e8.

        // Original:
        // baseInQuote = 1e65 * 1e24 / 1e8 = 1e81. (Overflows uint256 ~1.15e77)

        // New:
        // baseScale > quoteScale. scaleRatio = 1e36 / 1e14 = 1e22.
        // outAmount = mulDiv(1e65, 1e24, 1e8 * 1e22)
        // = mulDiv(1e65, 1e24, 1e30)
        // = 1e65 * 1e24 / 1e30 = 1e89 / 1e30 = 1e59.
        // 1e59 fits in uint256.

        uint256 highPrice = 1e24;
        vm.mockCall(_dhedgePool, abi.encodeWithSelector(IdHEDGEPoolLogic.tokenPrice.selector), abi.encode(highPrice));

        // Try smaller amount that fits in 256 bits product
        uint256 inAmountSmall = 1e50;
        uint256 resultSmall = aggregator.getQuote(inAmountSmall, _dhedgePool, _usdc);
        assertEq(resultSmall, 1e44, "Small amount failed");

        uint256 inAmount = 1e65;

        uint256 result = aggregator.getQuote(inAmount, _dhedgePool, _usdc);

        assertEq(result, 1e59, "Should handle intermediate overflow");
    }

    function test_SpecificValues_OverflowAndPrecisionCheck() public {
        // Test with specific values:
        // inAmount = 120_000e18
        // basePriceUSD = 1e18
        // quoteScale = 1e36 (18 decimals for token + 18 decimals for oracle)

        address baseAsset = makeAddr("baseAsset");
        address quoteAsset = makeAddr("quoteAsset");
        address baseOracle = makeAddr("baseOracle");
        address quoteOracle = makeAddr("quoteOracle");

        // Setup: base asset with 18 decimals, quote asset with 18 decimals
        vm.mockCall(baseAsset, abi.encodeWithSelector(bytes4(keccak256("decimals()"))), abi.encode(uint8(18)));
        vm.mockCall(quoteAsset, abi.encodeWithSelector(bytes4(keccak256("decimals()"))), abi.encode(uint8(18)));

        // Setup: both oracles with 18 decimals to achieve quoteScale = 1e36
        vm.mockCall(baseOracle, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(uint8(18)));
        vm.mockCall(quoteOracle, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(uint8(18)));

        // basePriceUSD = 1e18 (price $1 with 18 decimals)
        vm.mockCall(
            baseOracle,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), int256(1e18), uint256(0), block.timestamp, uint80(1))
        );

        // quotePriceUSD = 1e18 (price $1 with 18 decimals for 1:1 conversion)
        vm.mockCall(
            quoteOracle,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), int256(1e18), uint256(0), block.timestamp, uint80(1))
        );

        vm.startPrank(admin);
        aggregator.setOracle(baseAsset, baseOracle, MAX_STALENESS);
        aggregator.setOracle(quoteAsset, quoteOracle, MAX_STALENESS);
        vm.stopPrank();

        uint256 inAmount = 120_000e18;

        // Expected calculation:
        // baseScale = 10^(18+18) = 1e36
        // quoteScale = 10^(18+18) = 1e36
        // Since baseScale == quoteScale, scaleRatio = 1
        // outAmount = (inAmount * basePriceUSD) / quotePriceUSD
        // = (120_000e18 * 1e18) / 1e18 = 120_000e18

        uint256 result = aggregator.getQuote(inAmount, baseAsset, quoteAsset);

        // It should not overflow and should return the correct amount.
        assertEq(result, 120_000e18, "Should handle specified values without overflow or precision loss");
    }
}

// Generated using co-pilot: Claude-4.0-Sonnet
