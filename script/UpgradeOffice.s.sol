// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin-contracts/proxy/transparent/ProxyAdmin.sol";

import {Office} from "../src/Office.sol";

import "forge-std/Script.sol";
import "forge-std/console2.sol";

contract UpgradeOfficeScript is Script {
    function run(address proxy) external {
        Options memory opts;
        opts.referenceContract = "Office.flattened.sol:Office";

        vm.startBroadcast();
        address newImplementation = Upgrades.prepareUpgrade("Office.sol:Office", opts);
        vm.stopBroadcast();

        console2.log("New implementation deployed at: ", newImplementation);
        console2.log("Transaction data to upgrade the proxy: ");
        console2.logBytes(
            abi.encodeCall(ProxyAdmin.upgradeAndCall, (ITransparentUpgradeableProxy(proxy), newImplementation, ""))
        );
    }
}
