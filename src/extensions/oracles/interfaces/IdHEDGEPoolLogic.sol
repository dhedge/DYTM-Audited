// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IdHEDGEPoolLogic {
    function tokenPrice() external view returns (uint256 price);
}
