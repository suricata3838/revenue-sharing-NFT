// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IOracle {
    function requestRandomNumber() external returns (uint256);
    function requestLastSoldPrice(uint256) external returns (uint256);
}