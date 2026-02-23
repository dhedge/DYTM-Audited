// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "../../shared/CommonScenarios.sol";

contract Office_flashloan is CommonScenarios {
    using AccountIdLibrary for *;
    using ReserveKeyLibrary for *;

    address internal _flashloanReceiver = makeAddr("FlashloanReceiver");
    uint256 internal _flashloanAmount = 1000e6; // 1000 USDC
    bytes internal _callbackData = "test callback data";

    function setUp() public override {
        super.setUp();

        // Provide enough tokens to the flashloan receiver in order to make a successful flashloan.
        // We will instead be playing with approvals for creating test scenarios.
        deal(address(usdc), address(_flashloanReceiver), _flashloanAmount);

        vm.mockCall(
            address(_flashloanReceiver),
            abi.encodeWithSelector(IFlashloanReceiver.onFlashloanCallback.selector, _flashloanAmount, _callbackData),
            abi.encode("")
        );
    }

    modifier givenNotEnoughLiquidity() {
        // Empty modifier - no liquidity provided
        _;
    }

    modifier whenTheLoanerDoesNotReturnEnoughTokens() {
        // Approve less than flashloaned amount.
        usdc.approve(address(office), _flashloanAmount - 1);
        _;
    }

    modifier whenTheLoanerDoesNotReturnTokens() {
        // Approve 0 tokens to simulate not returning any tokens.
        usdc.approve(address(office), 0);
        _;
    }

    modifier whenLoanerReturnsAllTokens() {
        // Approve the exact amount borrowed
        usdc.approve(address(office), _flashloanAmount);
        _;
    }

    modifier whenCallerIsFlashloanReceiver() {
        vm.startPrank(address(_flashloanReceiver));
        _;
    }

    function test_WhenTokenIsPresentInTheOffice_GivenEnoughLiquidity()
        external
        whenReserveExists
        givenEnoughLiquidityInTheReserve
        whenCallerIsFlashloanReceiver
        whenLoanerReturnsAllTokens
    {
        uint256 officeBefore = usdc.balanceOf(address(office));
        uint256 receiverBefore = usdc.balanceOf(address(_flashloanReceiver));

        vm.expectCall(
            address(_flashloanReceiver),
            abi.encodeWithSelector(IFlashloanReceiver.onFlashloanCallback.selector, _flashloanAmount, _callbackData)
        );

        // It should allow the flashloan
        office.flashloan(usdc, _flashloanAmount, _callbackData);

        // Verify balances are back to original state
        uint256 officeAfter = usdc.balanceOf(address(office));
        uint256 receiverAfter = usdc.balanceOf(address(_flashloanReceiver));

        assertEq(officeAfter, officeBefore, "Office balance should be unchanged");
        assertEq(receiverAfter, receiverBefore, "Receiver balance should be unchanged");
    }

    function test_RevertWhen_TokenIsPresentInTheOffice_GivenEnoughLiquidity_WhenTheLoanerDoesNotReturnEnoughTokens()
        external
        whenReserveExists
        givenEnoughLiquidityInTheReserve
        whenCallerIsFlashloanReceiver
        whenTheLoanerDoesNotReturnEnoughTokens
    {
        // It should revert
        vm.expectRevert("ERC20: subtraction underflow");
        office.flashloan(usdc, _flashloanAmount, _callbackData);
    }

    function test_RevertWhen_TokenIsPresentInTheOffice_GivenNotEnoughLiquidity()
        external
        whenReserveExists
        givenNotEnoughLiquidity
        whenCallerIsFlashloanReceiver
    {
        deal(address(usdc), address(office), _flashloanAmount - 1);

        vm.expectRevert("ERC20: subtraction underflow");
        office.flashloan(usdc, _flashloanAmount, _callbackData);
    }

    function test_RevertWhen_TokenIsNotPresentInTheOffice() external whenCallerIsFlashloanReceiver {
        // Use a token that doesn't exist in any market
        MockERC20 nonExistentToken = new MockERC20();
        nonExistentToken.initialize("Non-existent", "NONE", 18);

        // It should revert
        vm.expectRevert("ERC20: subtraction underflow");
        office.flashloan(IERC20(address(nonExistentToken)), 1e18, _callbackData);
    }

    function test_RevertWhen_TokenIsPresentInTheOffice_GivenEnoughLiquidity_WhenTheLoanerDoesNotReturnAnyTokens()
        external
        whenReserveExists
        givenEnoughLiquidityInTheReserve
        whenCallerIsFlashloanReceiver
        whenTheLoanerDoesNotReturnTokens
    {
        // It should revert
        vm.expectRevert("ERC20: subtraction underflow");
        office.flashloan(usdc, _flashloanAmount, _callbackData);
    }
}
