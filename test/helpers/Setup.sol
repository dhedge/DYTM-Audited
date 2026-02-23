// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {IERC20Metadata} from "@openzeppelin-contracts/interfaces/IERC20Metadata.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import "../../src/Office.sol";
import "../mocks/MockERC20.sol";
import "../mocks/MockWeights.sol";
import "../mocks/MockOracleModule.sol";
import "../../src/extensions/delegatees/SimpleDelegatee.sol";
import "../../src/extensions/market-configs/SimpleMarketConfig.sol";
import "../../src/extensions/hooks/SimpleAccountWhitelist.sol";
import "../../src/extensions/hooks/BorrowerWhitelist.sol";
import "../../src/IRM/FixedBorrowRateIRM.sol";
import "../../src/interfaces/ParamStructs.sol";
import "../../src/interfaces/IContext.sol";
import "../../src/interfaces/IRegistry.sol";

import "forge-std/Test.sol";
import "forge-std/console2.sol";

abstract contract Setup is Test {
    /////////////////////////////////////////////
    //                Accounts                 //
    /////////////////////////////////////////////
    address internal admin = makeAddr("admin");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal carol = makeAddr("carol");
    address internal keeper = makeAddr("keeper");
    address internal liquidator = makeAddr("liquidator");
    address internal operator = makeAddr("operator");
    address internal feeRecipient = makeAddr("feeRecipient");
    address[] internal accounts = [admin, alice, bob, carol, keeper, liquidator, operator, feeRecipient];

    /////////////////////////////////////////////
    //             Setup Contracts             //
    /////////////////////////////////////////////
    Office internal office;
    MockERC20 internal usdc;
    MockERC20 internal weth;
    MockWeights internal weights;
    FixedBorrowRateIRM internal irm;
    SimpleDelegatee internal delegatee;
    MockOracleModule internal oracleModule;
    SimpleMarketConfig internal marketConfig;

    uint256 internal constant SECONDS_IN_YEAR = 365 days;
    IHooks internal constant NO_HOOKS_SET = IHooks(address(0xdead0000)); // The last 2 bytes/4 nibbles matter for the hooks flags.
    IHooks internal constant ALL_HOOKS_SET = IHooks(address(Constants.ALL_HOOK_MASK)); // The last 2 bytes/4 nibbles matter for the hooks flags.

    function setUp() public virtual {
        vm.startPrank(admin);

        // Contracts deployment and initialization.
        {
            office = new Office();
            irm = new FixedBorrowRateIRM(office);
            weights = new MockWeights();
            oracleModule = new MockOracleModule();
            usdc = new MockERC20();
            weth = new MockERC20();
            delegatee = new SimpleDelegatee();

            usdc.initialize("USD Coin", "USDC", 6);
            weth.initialize("Wrapped ETH", "WETH", 18);
        }

        // Labelling contracts.
        {
            vm.label(address(office), "Office");
            vm.label(address(irm), "IRM");
            vm.label(address(oracleModule), "OracleModule");
            vm.label(address(usdc), "USDC");
            vm.label(address(weth), "WETH");
            vm.label(address(weights), "Weights");
            vm.label(address(delegatee), "Delegatee");
        }

        // Funding wallets.
        {
            address[] memory tokens = new address[](3);
            tokens[0] = address(0); // Native token (ETH)
            tokens[1] = address(usdc);
            tokens[2] = address(weth);

            // While obviously not recommended in production, we use the delegatee contract
            // as a swapper and repayer of loans in tests and thus, it needs to be funded.
            accounts.push(address(delegatee));

            fillWalletsWithTokens(tokens);
        }
    }

    /////////////////////////////////////////////
    //                Helpers                  //
    /////////////////////////////////////////////
    function fillWalletsWithTokens(address[] memory tokens) public {
        for (uint256 i; i < tokens.length; ++i) {
            uint256 decimals = (tokens[i] != address(0)) ? IERC20Metadata(tokens[i]).decimals() : uint256(18);
            uint256 amount = 1_000_000 * (10 ** decimals);

            for (uint256 j; j < accounts.length; ++j) {
                // If address(0) is passed, deal the native token.
                if (tokens[i] == address(0)) {
                    deal(accounts[j], amount);
                } else {
                    deal(tokens[i], accounts[j], amount);

                    // Max approve the token for the Office contract.
                    vm.startPrank(accounts[j]);
                    IERC20Metadata(tokens[i]).approve(address(office), type(uint256).max);
                }
            }
        }
    }
}
