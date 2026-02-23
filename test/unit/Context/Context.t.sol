// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "../../shared/CommonScenarios.sol";

contract ContextTest is CommonScenarios, IDelegatee {
    using ReserveKeyLibrary for *;
    using MarketIdLibrary for *;

    function test_whenOngoingDelegationCall() external givenAccountIsIsolated whenCallerIsOperator {
        vm.startPrank(caller);

        office.delegationCall(
            DelegationCallParams({delegatee: IDelegatee(address(this)), callbackData: abi.encode(account)})
        );
    }

    function onDelegationCallback(bytes calldata data) public view returns (bytes memory) {
        // Check if the context is set correctly.
        assertEq(office.callerContext(), caller, "Caller context should be set");
        assertEq(address(office.delegateeContext()), address(this), "Delegatee context should be set");
        assertEq(office.requiresHealthCheck(), false, "Health check should not be required");

        // Check if the ongoing delegation call is correctly identified.
        assertEq(office.isOngoingDelegationCall(), true, "Delegation call should be ongoing");
        assertEq(
            office.isOperator(abi.decode(data, (AccountId)), address(this)), true, "Should be operator of the account"
        );

        return "";
    }
}
