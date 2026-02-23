// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin-contracts/proxy/transparent/ProxyAdmin.sol";

import {Office} from "../src/Office.sol";

import "forge-std/Script.sol";

interface IVanityMarket {
    function deploy(uint256 id, bytes calldata initcode) external payable returns (address deployed);
}

/// @title DeployOfficeScript
/// @author Chinmay <chinmay@dhedge.org>
/// @notice Script to deploy the Office contract at a vanity address generated using manyzeros <https://manyzeros.xyz>
contract DeployOfficeScript is Script {
    address constant _OWNER = 0x255bfAfC9Dcb926e71e172B6AA8d912A158A32B9;
    address constant _VANITY_ADDRESS = 0x0fF1CEE337d7af25eEF4c1a7A2CaF83f98d80001;
    uint256 constant _ID = 0x2c8b14a270eb080c2662a12936bb6b2babf15bf89cc35baf8d47a600a81c5ec6;
    IVanityMarket constant _VANITY_MARKET = IVanityMarket(0x000000000000b361194cfe6312EE3210d53C15AA);

    function run() external {
        /* Deploy the implementation contract */

        // No need for special options during deployment (only for the first time).
        Options memory opts;

        vm.startBroadcast();
        address officeImplementation = Upgrades.deployImplementation("Office.sol:Office", opts);
        vm.stopBroadcast();

        /* Deploy the proxy at the vanity address */
        bytes memory initcode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(
                officeImplementation,
                _OWNER, // DYTM Contracts Owner Safe
                "" // No initialization data.
            )
        );

        vm.startBroadcast();
        address proxy = _VANITY_MARKET.deploy(_ID, initcode);
        vm.stopBroadcast();

        /* Assertions */

        address actualImplementation = Upgrades.getImplementationAddress(proxy);
        address proxyAdmin = Upgrades.getAdminAddress(proxy);

        require(proxy == _VANITY_ADDRESS, "Proxy address mismatch");
        require(actualImplementation == officeImplementation, "Office implementation address mismatch");
        require(ProxyAdmin(proxyAdmin).owner() == _OWNER, "ProxyAdmin owner address mismatch");

        console2.log("Office implementation deployed successfully at: ", officeImplementation);
        console2.log("Proxy deployed successfully at: ", proxy);
        console2.log("ProxyAdmin deployed successfully at: ", proxyAdmin);
    }
}
