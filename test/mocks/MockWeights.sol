// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";

import {IWeights} from "../../src/interfaces/IWeights.sol";

import {ReserveKey, AccountId} from "../../src/types/Types.sol";
import {TokenHelpers} from "../../src/libraries/TokenHelpers.sol";

import {WAD} from "../../src/libraries/Constants.sol";

contract MockWeights is IWeights {
    using TokenHelpers for *;

    error Weights__WeightNotFound(uint256 collateralTokenId, ReserveKey debtAsset);

    mapping(ReserveKey collateralKey => mapping(ReserveKey debtKey => uint64 weight)) private _weights;

    function setWeight(ReserveKey collateralAsset, ReserveKey debtAsset, uint64 weight) external {
        _weights[collateralAsset][debtAsset] = weight;
        _weights[debtAsset][collateralAsset] = weight; // Assuming symmetric weights for simplicity
    }

    function getWeight(
        AccountId /* account */,
        uint256 collateralTokenId,
        ReserveKey debtAsset
    )
        external
        view
        returns (uint64 weight)
    {
        ReserveKey collateralAsset = collateralTokenId.getReserveKey();

        // If the assets are the same, return 1 as the weight.
        if (collateralAsset == debtAsset) {
            return uint64(WAD);
        }

        weight = _weights[collateralAsset][debtAsset];

        if (weight == 0) {
            revert Weights__WeightNotFound(collateralTokenId, debtAsset);
        }
    }
}
