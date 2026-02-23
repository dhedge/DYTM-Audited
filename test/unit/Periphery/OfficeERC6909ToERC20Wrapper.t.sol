// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

// Import wrapper contracts
import {OfficeERC6909ToERC20Wrapper} from "../../../src/periphery/OfficeERC6909ToERC20Wrapper.sol";
import {WrappedERC6909ERC20} from "../../../src/periphery/WrappedERC6909ERC20.sol";

contract OfficeERC6909ToERC20WrapperTest is CommonScenarios {
    using ReserveKeyLibrary for *;
    using AccountIdLibrary for *;

    OfficeERC6909ToERC20Wrapper internal _wrapper;
    address internal _erc20Token;

    /// @dev Must be used only after setting `tokenId` using `whenLendingAsset(usdcKey)`.
    modifier whenTokenIdIsRegistered() {
        vm.startPrank(admin);
        _erc20Token = _wrapper.register(tokenId, "Wrapped USDC Lent", "wUSDC-L", 6);
        vm.stopPrank();
        _;
    }

    function setUp() public override {
        super.setUp();

        _wrapper = new OfficeERC6909ToERC20Wrapper(address(office));
    }

    // Test case 1
    function test_WhenOfficerRegistersATokenIdAsERC20()
        public
        whenReserveExists
        whenCallerIsOfficer
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // It should deploy a new `WrappedERC6909ERC20` contract.
        _erc20Token = _wrapper.register(tokenId, "Wrapped USDC Lent", "wUSDC-L", 6);

        assertTrue(_erc20Token != address(0), "ERC20 contract should be deployed");

        // It should map the token id to the deployed `WrappedERC6909ERC20` contract.
        assertEq(_wrapper.getERC20(tokenId), _erc20Token, "Token ID should be mapped to ERC20 contract");
    }

    // Test case 2
    function test_Revert_WhenOfficerReregistersATokenIdAsERC20()
        public
        whenReserveExists
        whenCallerIsOfficer
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // Register the token ID first
        _erc20Token = _wrapper.register(tokenId, "Wrapped USDC Lent", "wUSDC-L", 6);

        // It should revert with `OfficeERC6909ToERC20Wrapper__ERC20AlreadyRegistered` error.
        vm.expectRevert(
            abi.encodeWithSelector(
                OfficeERC6909ToERC20Wrapper.OfficeERC6909ToERC20Wrapper__ERC20AlreadyRegistered.selector, tokenId
            )
        );
        _wrapper.register(tokenId, "Wrapped USDC Lent", "wUSDC-L", 6);
    }

    // Test case 3
    function test_Revert_WhenARandomAddressTriesToRegisterATokenIdAsERC20_WhenReserveExists()
        public
        whenReserveExists
        whenCallerIsNotAuthorized
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        // It should revert with `OfficeERC6909ToERC20Wrapper__NotOfficer` error.
        vm.expectRevert(
            abi.encodeWithSelector(
                OfficeERC6909ToERC20Wrapper.OfficeERC6909ToERC20Wrapper__NotOfficer.selector, market, caller
            )
        );
        _wrapper.register(tokenId, "Wrapped USDC Lent", "wUSDC-L", 6);
    }

    // Test case 4
    function test_WhenCallingWrapFunction_GivenTheTokenIdIsRegistered()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenLendingAsset(usdcKey)
        whenTokenIdIsRegistered
    {
        vm.startPrank(caller);

        // Approve wrapper to transfer ERC6909 tokens
        office.approve(address(_wrapper), tokenId, type(uint256).max);

        // Store initial states
        uint256 erc20BalanceBefore = WrappedERC6909ERC20(_erc20Token).balanceOf(caller);
        uint256 erc20TotalSupplyBefore = WrappedERC6909ERC20(_erc20Token).totalSupply();
        uint256 callerTokenIdBalanceBefore = office.balanceOf(caller, tokenId);
        uint256 wrapperTokenIdBalanceBefore = office.balanceOf(address(_wrapper), tokenId);
        uint256 wrapAmount = callerTokenIdBalanceBefore / 2;

        _wrapper.wrap(tokenId, wrapAmount);

        // It should mint wrapped ERC20 tokens to the caller.
        assertEq(
            WrappedERC6909ERC20(_erc20Token).balanceOf(caller),
            erc20BalanceBefore + wrapAmount,
            "Should mint wrapped tokens to caller"
        );

        // It should increase the total supply of the wrapped ERC20 tokens.
        assertEq(
            WrappedERC6909ERC20(_erc20Token).totalSupply(),
            erc20TotalSupplyBefore + wrapAmount,
            "Should increase total supply"
        );

        // It should transfer the underlying ERC6909 tokens from the caller to the wrapper contract.
        assertEq(
            office.balanceOf(caller, tokenId),
            callerTokenIdBalanceBefore - wrapAmount,
            "Should transfer tokens from caller"
        );
        assertEq(
            office.balanceOf(address(_wrapper), tokenId),
            wrapperTokenIdBalanceBefore + wrapAmount,
            "Should transfer tokens to wrapper"
        );
    }

    function test_Revert_WhenCallingWrapFunction_GivenTheTokenIdIsNotRegistered()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        uint256 wrapAmount = office.balanceOf(caller, tokenId) / 2;

        // Approve wrapper to transfer ERC6909 tokens
        office.approve(address(_wrapper), tokenId, type(uint256).max);

        // It should revert because the erc20 contract call will fail.
        vm.expectRevert();
        _wrapper.wrap(tokenId, wrapAmount);
    }

    // Test case 5
    function test_WhenCallingUnwrapFunction_GivenTheTokenIdIsRegistered()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenLendingAsset(usdcKey)
        whenTokenIdIsRegistered
    {
        vm.startPrank(caller);

        // Approve wrapper to transfer ERC6909 tokens
        office.approve(address(_wrapper), tokenId, type(uint256).max);

        uint256 wrapAmount = office.balanceOf(caller, tokenId) / 2;

        _wrapper.wrap(tokenId, wrapAmount);

        // Store initial states
        uint256 erc20BalanceBefore = WrappedERC6909ERC20(_erc20Token).balanceOf(caller);
        uint256 erc20TotalSupplyBefore = WrappedERC6909ERC20(_erc20Token).totalSupply();
        uint256 callerTokenIdBalanceBefore = office.balanceOf(caller, tokenId);
        uint256 wrapperTokenIdBalanceBefore = office.balanceOf(address(_wrapper), tokenId);
        uint256 unwrapAmount = wrapAmount / 2;

        _wrapper.unwrap(tokenId, unwrapAmount);

        // It should burn wrapped ERC20 tokens to the caller.
        assertEq(
            WrappedERC6909ERC20(_erc20Token).balanceOf(caller),
            erc20BalanceBefore - unwrapAmount,
            "Should burn wrapped tokens from caller"
        );

        // It should decrease the total supply of the wrapped ERC20 tokens.
        assertEq(
            WrappedERC6909ERC20(_erc20Token).totalSupply(),
            erc20TotalSupplyBefore - unwrapAmount,
            "Should decrease total supply"
        );

        // It should transfer the underlying ERC6909 tokens from the wrapper contract to the caller.
        assertEq(
            office.balanceOf(address(_wrapper), tokenId),
            wrapperTokenIdBalanceBefore - unwrapAmount,
            "Should transfer tokens from wrapper to caller"
        );
        assertEq(
            office.balanceOf(caller, tokenId),
            callerTokenIdBalanceBefore + unwrapAmount,
            "Should transfer tokens to wrapper"
        );
    }

    function test_Revert_WhenCallingUnwrapFunction_GivenTheTokenIdIsNotRegistered()
        public
        whenReserveExists
        givenAccountIsNotIsolated
        whenCallerIsOwner
        whenUsingSuppliedPlusEscrowedAssets
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(caller);

        uint256 unwrapAmount = office.balanceOf(caller, tokenId);

        // It should revert because the erc20 contract call will fail.
        vm.expectRevert();
        _wrapper.unwrap(tokenId, unwrapAmount);
    }

    // Test case 6
    function test_Revert_WhenARandomAddressTriesToRegisterATokenIdAsERC20_WhenReserveDoesNotExist()
        public
        whenLendingAsset(usdcKey)
    {
        vm.startPrank(alice);

        // It should revert due to `getOfficer` call failing.
        vm.expectRevert();
        _wrapper.register(tokenId, "Wrapped USDC Lent", "wUSDC-L", 6);
    }
}
