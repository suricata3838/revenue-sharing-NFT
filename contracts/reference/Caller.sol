// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOracle.sol";

contract Caller is Ownable {
    IOracle private oracle;

    mapping(uint256=>bool) requests;
    // received RandomNumbers from oracle
    mapping(uint256=>uint256) results;

    event OracleAddressChanged(address oracleAddress);
    event RandomNumberRequested(uint id);
    event RandomNumberReceived(uint256 randomNumber, uint id);

    modifier onlyOracle() {
        require(msg.sender == address(oracle), "Unauthorized oracle.");
        _;
    }

    function setOracleAddress(address _address) external onlyOwner {
        oracle = IOracle(_address);

        emit OracleAddressChanged(_address);
    }
    
    // get request ticket from Oracle's requestRandomNumber()
    function getRandomNumber() external {
        require(oracle != IOracle(address(0)), "Oracle is not initialized.");

        uint256 id = oracle.requestRandomNumber();
        requests[id] = true;

        emit RandomNumberRequested(id);
    }

    // Oracle contract can call to fulfill the ticket.
    // external onlyOracle
    function fulfillRandomNumberRequest(uint256 randomNumber, uint256 id) external onlyOracle {
        require(requests[id], "Request is invalid or already fulfilled.");

        results[id] = randomNumber;
        delete requests[id];

        emit RandomNumberReceived(randomNumber, id);
    }
}

