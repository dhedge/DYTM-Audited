# IMarketConfig
[Git Source](https://github.com/dhedge/DYTM/blob/7e26fc0ea2ef08e01be7caaabb0d58657fa9304e/src/interfaces/IMarketConfig.sol)

**Title:**
IMarketConfig

**Author:**
Chinmay <chinmay@dhedge.org>

Interface for the market configuration contract.


## Functions
### irm

The Interest Rate Model (IRM) for the market.

MUST NOT be null address.


```solidity
function irm() external view returns (IIRM irm);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`irm`|`IIRM`|The IRM contract interface.|


### hooks

The Hooks contract for the market.

MAY BE null address if no hooks are used.


```solidity
function hooks() external view returns (IHooks hooks);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`hooks`|`IHooks`|The Hooks contract interface.|


### weights

The Weights contract for the market.

MUST NOT be null address.


```solidity
function weights() external view returns (IWeights weights);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`weights`|`IWeights`|The Weights contract interface.|


### oracleModule

The Oracle Module for the market.

MUST NOT be null address.


```solidity
function oracleModule() external view returns (IOracleModule oracleModule);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`oracleModule`|`IOracleModule`|The Oracle Module contract interface.|


### feeRecipient

The recipient of the performance fees for the market.

MAY BE null address only if `feePercentage` is zero.


```solidity
function feeRecipient() external view returns (address feeRecipient);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`feeRecipient`|`address`|The address of the fee recipient.|


### feePercentage

The percentage of the performance fee for the market.

- MAY BE zero.
- MUST BE in the range of 0 to 1e18 (WAD units).


```solidity
function feePercentage() external view returns (uint64 feePercentage);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`feePercentage`|`uint64`|The fee percentage.|


### liquidationBonusPercentage

The liquidation bonus percentage for liquidators in the market.

MUST BE in the range of 0 to 1e18 (WAD units).


```solidity
function liquidationBonusPercentage() external view returns (uint64 liquidationBonusPercentage);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`liquidationBonusPercentage`|`uint64`|The liquidation bonus percentage.|


### minMarginAmountUSD

The minimum margin amount in USD for the market.

- MUST BE in WAD units (e.g. $1 = 1e18).
- MAY BE zero.


```solidity
function minMarginAmountUSD() external view returns (uint128 minMarginAmountUSD);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`minMarginAmountUSD`|`uint128`|The minimum margin amount in USD.|


### isSupportedAsset

Checks if the asset is supported.

MUST NOT revert if the asset is not supported.


```solidity
function isSupportedAsset(IERC20 asset) external view returns (bool isSupported);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`IERC20`|The asset to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isSupported`|`bool`|`true` if the asset is supported, `false` otherwise.|


### isBorrowableAsset

Checks if the asset is borrowable.

MUST NOT revert if the asset is not supported and/or not borrowable.


```solidity
function isBorrowableAsset(IERC20 asset) external view returns (bool isBorrowable);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`IERC20`|The asset to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isBorrowable`|`bool`|`true` if the asset is borrowable, `false` otherwise.|


### canTransferShares

Checks if the transfer of shares between two accounts is allowed.
> [!WARNING]
> Doesn't prevent minting/redemption of shares even if the account
> is explicitly restricted from transferring/receiving shares.
> Make sure proper hook checks are in place if needed for such cases.

MAY revert.


```solidity
function canTransferShares(
    AccountId from,
    AccountId to,
    uint256 tokenId,
    uint256 shares
)
    external
    view
    returns (bool canTransfer);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`AccountId`|The account from which shares are transferred.|
|`to`|`AccountId`|The account to which shares are transferred.|
|`tokenId`|`uint256`|The tokenId of the shares to be transferred.|
|`shares`|`uint256`|The amount of shares to be transferred.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`canTransfer`|`bool`|`true` if the transfer is allowed, `false` otherwise.|


