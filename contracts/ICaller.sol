// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICaller {
    function fulfillRandomNumberRequest(uint256 randomNumber, uint256 id) external;
}