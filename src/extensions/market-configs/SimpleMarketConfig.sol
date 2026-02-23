// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";
import {EnumerableMap} from "@openzeppelin-contracts/utils/structs/EnumerableMap.sol";

import {WAD} from "../../libraries/Constants.sol";
import {AccountId, MarketId, ReserveKey} from "../../types/Types.sol";
import {ReserveKeyLibrary} from "../../types/ReserveKey.sol";

import {IIRM} from "../../interfaces/IIRM.sol";
import {IHooks} from "../../interfaces/IHooks.sol";
import {IOffice} from "../../interfaces/IOffice.sol";
import {IWeights} from "../../interfaces/IWeights.sol";
import {IOracleModule} from "../../interfaces/IOracleModule.sol";
import {IMarketConfig} from "../../interfaces/IMarketConfig.sol";

/// @title SimpleMarketConfig
/// @notice A simple implementation for the market configuration contract.
/// @dev Can be used for multiple markets with the same configuration.
/// @author Chinmay <chinmay@dhedge.org>
contract SimpleMarketConfig is IMarketConfig, Ownable {
    using ReserveKeyLibrary for MarketId;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /////////////////////////////////////////////
    //                 Events                  //
    /////////////////////////////////////////////

    event SimpleMarketConfig__IrmModified(IIRM newIrm, IIRM oldIrm);
    event SimpleMarketConfig__MarketAssetsRemoved(address[] assets);
    event SimpleMarketConfig__MarketAssetsDisabled(address[] assets);
    event SimpleMarketConfig__MarketParamsSet(ConfigInitParams params);
    event SimpleMarketConfig__MarketAssetsSet(AssetConfig[] assetsConfig);
    event SimpleMarketConfig__HooksModified(IHooks newHooks, IHooks oldHooks);
    event SimpleMarketConfig__WeightsModified(IWeights newWeights, IWeights oldWeights);
    event SimpleMarketConfig__FeeRecipientModified(address newFeeRecipient, address oldFeeRecipient);
    event SimpleMarketConfig__PerformanceFeeModified(uint64 newPercentageFee, uint64 oldPercentageFee);
    event SimpleMarketConfig__OracleModuleModified(IOracleModule newOracleModule, IOracleModule oldOracleModule);
    event SimpleMarketConfig__MinDebtAmountUSDModified(uint128 newMinDebtAmountUSD, uint128 oldMinDebtAmountUSD);
    event SimpleMarketConfig__LiquidationBonusPercentageModified(
        uint256 collateralTokenId, ReserveKey debtKey, uint64 newBonusPercentage, uint64 oldBonusPercentage
    );

    /////////////////////////////////////////////
    //                 Errors                  //
    /////////////////////////////////////////////

    error SimpleMarketConfig__ZeroAddress();
    error SimpleMarketConfig__ParamsNotSet();
    error SimpleMarketConfig__RecipientNotSet();
    error SimpleMarketConfig__InvalidPercentage(uint64 givenPercentage);

    /////////////////////////////////////////////
    //                 Structs                 //
    /////////////////////////////////////////////

    struct AssetConfig {
        IERC20 asset; // The asset that can be borrowed.
        bool isBorrowable; // If true, the asset can be borrowed.
    }

    struct ConfigInitParams {
        IIRM irm;
        IHooks hooks;
        IWeights weights;
        IOracleModule oracleModule;
        address feeRecipient;
        uint64 feePercentage;
        uint128 minDebtAmountUSD;
    }

    /////////////////////////////////////////////
    //                 Storage                 //
    /////////////////////////////////////////////

    /// @dev Indicates the asset is disabled and new positions should not use this
    ///      asset as collateral or debt but existing positions should accumulate interest as normal.
    uint256 private constant _STATUS_DISABLED = 0;

    /// @dev Indicates the asset is supported but not currently borrowable.
    uint256 private constant _STATUS_ACTIVE = 1;

    /// @dev Indicates the asset is supported and borrowable.
    uint256 private constant _STATUS_BORROWABLE = 2;

    /// @notice Office contract address.
    IOffice public immutable OFFICE;

    /// @inheritdoc IMarketConfig
    IIRM public irm;

    /// @inheritdoc IMarketConfig
    IHooks public hooks;

    /// @inheritdoc IMarketConfig
    IWeights public weights;

    /// @inheritdoc IMarketConfig
    IOracleModule public oracleModule;

    /// @inheritdoc IMarketConfig
    address public feeRecipient;

    /// @inheritdoc IMarketConfig
    uint64 public feePercentage;

    /// @inheritdoc IMarketConfig
    uint128 public minDebtAmountUSD;

    /// @notice Mapping to store bonus percentage based on relationship between collateral and debt tokens.
    mapping(uint256 collateralTokenId => mapping(ReserveKey debtKey => uint64 bonusPercentage)) public bonusPercentages;

    /// @dev - Enumerable mapping containing the supported assets and their status.
    EnumerableMap.AddressToUintMap private _assets;

    /////////////////////////////////////////////
    //                Functions                //
    /////////////////////////////////////////////

    constructor(address initialOwner, IOffice office, ConfigInitParams memory initParams) Ownable(initialOwner) {
        require(address(office) != address(0), SimpleMarketConfig__ZeroAddress());

        OFFICE = office;

        // Set the market parameters.
        _setMarketParams(initParams);
    }

    /// @notice Function to accrue interest in all reserves in a market.
    /// @dev MUST be used before changing the IRM of the market or
    ///      changing the performance fee of the market.
    /// @param market The market ID whose reserves' interest needs to be accrued.
    function accrueInterestOnAllReserves(MarketId market) external {
        address[] memory assets = _assets.keys();
        uint256 length = assets.length;

        for (uint256 i; i < length; ++i) {
            OFFICE.accrueInterest(market.toReserveKey(IERC20(assets[i])));
        }
    }

    /////////////////////////////////////////////
    //                 Getters                 //
    /////////////////////////////////////////////

    /// @inheritdoc IMarketConfig
    /// @dev For the simple implementation, we return the bonus percentage from the mapping.
    ///      Without considering the `account` parameter.
    function liquidationBonusPercentage(
        AccountId,
        uint256 collateralTokenId,
        ReserveKey debtAsset
    )
        external
        view
        returns (uint64 bonusPercentage)
    {
        return bonusPercentages[collateralTokenId][debtAsset];
    }

    /// @inheritdoc IMarketConfig
    function isSupportedAsset(IERC20 asset) external view virtual returns (bool isSupported) {
        // If the asset exists then return true, otherwise false.
        // `tryGet` will not return an error if the asset does not exist, it will simply return false.
        (, uint256 status) = _assets.tryGet(address(asset));

        return status > _STATUS_DISABLED;
    }

    /// @inheritdoc IMarketConfig
    function isBorrowableAsset(IERC20 asset) external view virtual returns (bool isBorrowable) {
        // Since we can't revert if the asset is not supported, we use `tryGet`
        // to get the default value of the status if the asset does not exist.
        // If the asset exists, it will return 1, otherwise it will return 0.
        (, uint256 status) = _assets.tryGet(address(asset));

        return status == _STATUS_BORROWABLE;
    }

    /// @notice Gets all asset configurations.
    /// @dev Supposed to be used for frontend purposes.
    /// @return configs An array of `AssetConfig` structs containing the asset and its borrowable status.
    function getAssetConfigs() external view virtual returns (AssetConfig[] memory configs) {
        address[] memory supportedAssets = _assets.keys();
        configs = new AssetConfig[](supportedAssets.length);

        for (uint256 i; i < supportedAssets.length; ++i) {
            configs[i] = AssetConfig({
                asset: IERC20(supportedAssets[i]), isBorrowable: _assets.get(supportedAssets[i]) == _STATUS_BORROWABLE
            });
        }
    }

    /// @inheritdoc IMarketConfig
    /// @dev [!NOTE] This implementation allows all transfers.
    function canTransferShares(AccountId, AccountId, uint256, uint256)
        external
        view
        virtual
        returns (bool canTransfer)
    {
        // In this simple implementation, we allow all transfers.
        return true;
    }

    /////////////////////////////////////////////
    //                 Setters                 //
    /////////////////////////////////////////////

    /// @notice Function to set performance fee for the entire market.
    /// @dev - The fee percentage should be in the range of 0 to 1e18 (WAD).
    ///      - The fee recipient MUST be set before setting a non-zero fee percentage.
    /// @dev > [!WARNING] Interest should be accrued on all reserves before changing the fee percentage.
    ///      > Use the `accrueInterestOnAllReserves` function to do so.
    /// @param newFeePercentage The new performance fee percentage to set.
    function setPerformanceFee(uint64 newFeePercentage) external onlyOwner {
        uint64 oldFeePercentage = feePercentage;

        require(newFeePercentage <= WAD, SimpleMarketConfig__InvalidPercentage(newFeePercentage));
        require(feeRecipient != address(0) || newFeePercentage == 0, SimpleMarketConfig__RecipientNotSet());

        feePercentage = newFeePercentage;

        emit SimpleMarketConfig__PerformanceFeeModified(newFeePercentage, oldFeePercentage);
    }

    /// @notice Sets supported assets for the market.
    /// @dev If the asset is already in the market, it will only change its borrowable status.
    /// @param assetsConfig An array of `AssetConfig` structs containing the asset and its borrowable status.
    function addSupportedAssets(AssetConfig[] calldata assetsConfig) external onlyOwner {
        for (uint256 i; i < assetsConfig.length; ++i) {
            // If the asset is already in the market, the following line will only change its borrowable status.
            _assets.set(
                address(assetsConfig[i].asset), assetsConfig[i].isBorrowable ? _STATUS_BORROWABLE : _STATUS_ACTIVE
            );
        }

        emit SimpleMarketConfig__MarketAssetsSet(assetsConfig);
    }

    /// @notice Disables supported assets in the market.
    /// @dev Should be used instead of `removeSupportedAssets` if there is an active position
    ///      in the market with this asset but we want to prevent it being used as collateral
    ///      or debt for new positions.
    /// @dev If the asset is not in the market, it will simply do nothing.
    /// @param assets An array of asset addresses to disable in the market.
    function disableSupportedAssets(address[] calldata assets) external onlyOwner {
        for (uint256 i; i < assets.length; ++i) {
            if (_assets.contains(assets[i])) {
                _assets.set(assets[i], _STATUS_DISABLED);
            }
        }

        emit SimpleMarketConfig__MarketAssetsDisabled(assets);
    }

    /// @notice Removes supported assets from the market.
    /// @dev > [!WARNING] An asset should not be removed if there is an active position
    ///      > in the market with this asset. Instead, use the `disableSupportedAssets` function.
    /// @dev If the asset is not in the market, it will simply do nothing.
    /// @param assets An array of asset addresses to remove from the market.
    function removeSupportedAssets(address[] calldata assets) external onlyOwner {
        for (uint256 i; i < assets.length; ++i) {
            _assets.remove(assets[i]);
        }

        emit SimpleMarketConfig__MarketAssetsRemoved(assets);
    }

    /// @notice Sets the fee recipient for the market.
    /// @dev Once set, the fee recipient cannot be set to zero address.
    /// @param newFeeRecipient The address of the new fee recipient.
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        address oldFeeRecipient = feeRecipient;

        require(newFeeRecipient != address(0), SimpleMarketConfig__ZeroAddress());

        feeRecipient = newFeeRecipient;

        emit SimpleMarketConfig__FeeRecipientModified(newFeeRecipient, oldFeeRecipient);
    }

    /// @notice Sets the interest rate model for the market.
    /// @dev > [!WARNING] Always accrue interest on all reserves before changing the IRM.
    ///      > Use the `accrueInterestOnAllReserves` function to do so.
    /// @param newIrm The address of the new interest rate model.
    function setIRM(IIRM newIrm) external onlyOwner {
        IIRM oldIrm = irm;

        require(address(newIrm) != address(0), SimpleMarketConfig__ZeroAddress());

        irm = newIrm;

        emit SimpleMarketConfig__IrmModified(newIrm, oldIrm);
    }

    /// @notice Sets the new hooks contract for the market.
    /// @dev Allows setting to zero address to disable hooks.
    /// @param newHooks The address of the new hooks contract.
    function setHooks(IHooks newHooks) external onlyOwner {
        IHooks oldHooks = hooks;

        hooks = newHooks;

        emit SimpleMarketConfig__HooksModified(newHooks, oldHooks);
    }

    /// @notice Sets the new weights contract for the market.
    /// @param newWeights The address of the new weights contract.
    function setWeights(IWeights newWeights) external onlyOwner {
        IWeights oldWeights = weights;

        require(address(newWeights) != address(0), SimpleMarketConfig__ZeroAddress());

        weights = newWeights;

        emit SimpleMarketConfig__WeightsModified(newWeights, oldWeights);
    }

    /// @notice Sets the new oracle module for the market.
    /// @param newOracleModule The address of the new oracle module.
    function setOracleModule(IOracleModule newOracleModule) external onlyOwner {
        IOracleModule oldOracleModule = oracleModule;

        require(address(newOracleModule) != address(0), SimpleMarketConfig__ZeroAddress());

        oracleModule = newOracleModule;

        emit SimpleMarketConfig__OracleModuleModified(newOracleModule, oldOracleModule);
    }

    /// @notice Sets the liquidation bonus percentage for the market.
    /// @dev The percentage should be in the range of 0 to 1e18 (WAD).
    /// @param collateralTokenId The token ID of the collateral asset.
    /// @param debtKey The reserve key of the debt asset.
    /// @param newBonusPercentage The new liquidation bonus percentage to set.
    function setLiquidationBonusPercentage(
        uint256 collateralTokenId,
        ReserveKey debtKey,
        uint64 newBonusPercentage
    )
        external
        onlyOwner
    {
        uint64 oldBonusPercentage = bonusPercentages[collateralTokenId][debtKey];

        require(newBonusPercentage <= WAD, SimpleMarketConfig__InvalidPercentage(newBonusPercentage));

        bonusPercentages[collateralTokenId][debtKey] = newBonusPercentage;

        emit SimpleMarketConfig__LiquidationBonusPercentageModified({
            collateralTokenId: collateralTokenId,
            debtKey: debtKey,
            newBonusPercentage: newBonusPercentage,
            oldBonusPercentage: oldBonusPercentage
        });
    }

    /// @notice Sets the minimum debt amount in USD for the market.
    /// @dev The amount should be in WAD units (e.g. $1 = 1e18).
    /// @param newMinDebtAmountUSD The new minimum debt amount in USD to set.
    function setMinDebtAmountUSD(uint128 newMinDebtAmountUSD) external onlyOwner {
        uint128 oldMinDebtAmountUSD = minDebtAmountUSD;

        minDebtAmountUSD = newMinDebtAmountUSD;

        emit SimpleMarketConfig__MinDebtAmountUSDModified(newMinDebtAmountUSD, oldMinDebtAmountUSD);
    }

    /////////////////////////////////////////////
    //                Internal                 //
    /////////////////////////////////////////////

    function _setMarketParams(ConfigInitParams memory initParams) internal {
        require(
            address(initParams.irm) != address(0) && address(initParams.oracleModule) != address(0)
                && address(initParams.weights) != address(0)
                && (initParams.feeRecipient != address(0) || initParams.feePercentage == 0),
            SimpleMarketConfig__ZeroAddress()
        );

        irm = initParams.irm;
        hooks = initParams.hooks;
        weights = initParams.weights;
        oracleModule = initParams.oracleModule;
        feeRecipient = initParams.feeRecipient;
        feePercentage = initParams.feePercentage;
        minDebtAmountUSD = initParams.minDebtAmountUSD;

        emit SimpleMarketConfig__MarketParamsSet(initParams);
    }
}
