// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "./utils/HookMiner.sol";

import "forge-std/Script.sol";
import "forge-std/console2.sol";

contract DeployHookScript is Script {
    using HookMiner for address;

    // Deterministic deployer proxy address used for CREATE2 deployments.
    address internal constant _CREATE2_PROXY_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    /// @notice Deploy a hook contract at an address with the desired `flags`.
    /// @param hook The name of the hook contract or the path to the contract file, e.g. "Counter.sol:Counter"
    /// @param flags The desired flags for the hook address. Example `uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | ...)`
    /// @param constructorArgs The encoded constructor arguments of a hook contract. Example: `abi.encode(address(manager))`
    function run(string memory hook, uint160 flags, bytes memory constructorArgs) public {
        bytes memory creationCode = vm.getCode(hook);
        bytes memory byteCode = abi.encodePacked(creationCode, constructorArgs);

        (address hookAddress, bytes32 salt) = _CREATE2_PROXY_DEPLOYER.find(flags, creationCode, constructorArgs);

        console2.log("Found salt:", uint256(salt));
        console2.log("Hook address:", hookAddress);

        address deployedHook;

        vm.startBroadcast();
        assembly {
            deployedHook := create2(0, add(byteCode, 0x20), mload(byteCode), salt)
        }
        vm.stopBroadcast();

        require(deployedHook == hookAddress, "Deployed address mismatch");
    }
}
