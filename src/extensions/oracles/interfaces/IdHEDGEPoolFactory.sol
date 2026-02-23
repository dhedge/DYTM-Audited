// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IdHEDGEPoolFactory {
    function isPool(address pool) external view returns (bool);
}
