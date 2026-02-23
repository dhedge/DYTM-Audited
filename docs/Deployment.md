# Deployment

The core contract to be deployed is the [Office](../src/Office.sol) contract. This can be deployed using the [DeployOfficeScript](../script/DeployOffice.s.sol). This script deploys a TransparentUpgradeableProxy pointing to the Office contract implementation. The proxy contract will be deployed to a vanity address that includes the string "0ff1ce" (case insensitive) generated using [ManyZeros](https://manyzeros.xyz) service.

The periphery contract [DYTMPeriphery](../src/periphery/DYTMPeriphery.sol) can be deployed using `forge create` command as follows:

```bash
forge create DYTMPeriphery --broadcast --verify --rpc-url <chain-name> --account <account> --optimize true --optimizer-runs 1000 --constructor-args <office-address>
```
