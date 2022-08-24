// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICaller.sol";

contract Oracle is AccessControl {
    // we have 2 role: admin and provider 
    bytes32 public constant PROVIDER_ROLE = keccak256("PROVIDER_ROLE");
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    uint private numProviders = 0;
    uint private providerThreshold = 1;

    uint private counter = 0; //counter to generate id

    mapping(uint256=>bool) private pendingRequests;

    struct Response {
        address providerAddress;
        address callerAddress;
        uint256 randomNumber;
    }

    // 1 id can take as many providers as responses. 
    mapping(uint256=>Response[]) private idToResponses;

    event RandomNumberRequested(address callerAddress, uint256 id);
    event RandomNumberReturned(uint256 randomNumber, address callerAddress, uint256 id);
    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);
    event ProviderThresholdChanged(uint256 providerThreshold);

    function requestRandomNumber() external returns (uint256){
        require(numProviders > 0, "No data providers");

        counter++;
        pendingRequests[counter] = true;

        // data provider watchs this event and call responseRandomNumber()
        emit RandomNumberRequested(msg.sender, counter);
        return counter;
    }


    // every data provider call externally.
    function returnRandomNumber(uint256 randomNumber, address callerAddress, uint256 id) external onlyRole(PROVIDER_ROLE) {
        // Is requestId valid?
        require(pendingRequests[id], "Request is not found.");

        Response memory res = Response(msg.sender, callerAddress, randomNumber);
        idToResponses[id].push(res);
        uint numResponse = idToResponses[id].length;

        // only when the final provider provides randomNumber
        if (numResponse == providerThreshold) {
            uint compositeRandomNumber = 0;

            for (uint i=0; i < idToResponses[id].length; i++) {
                // ignore: bitwise XOR
                compositeRandomNumber = compositeRandomNumber ^ idToResponses[id][i].randomNumber;
            }

            // Cleanup at first
            delete pendingRequests[id];
            delete idToResponses[id];

            // At the last, call external contract function!!!
            // Fulfill request calling from Caller
            ICaller(callerAddress).fulfillRandomNumberRequest(compositeRandomNumber, id);

            emit RandomNumberReturned(compositeRandomNumber, callerAddress, id);
        }
    }


    ////
    // add and remove provider_role to an address
    ////

    function addProvider(address provider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // _provider should not have PROVIDER_ROLE already.
        require(!hasRole(PROVIDER_ROLE, provider), "Provider already added.");

        _grantRole(PROVIDER_ROLE, provider);
        numProviders++;

        emit ProviderAdded(provider);
    }

    function removeProvider(address provider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // _provider should have PROVIDER_ROLE.
        require(hasRole(PROVIDER_ROLE, provider), "Provider doesn't exist.");

        _revokeRole(PROVIDER_ROLE, provider);
        numProviders--;

        emit ProviderRemoved(provider);
    }

    function setProviderThreshold(uint threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(threshold > 0, "threshold cannot be zero.");

        providerThreshold = threshold;
        emit ProviderThresholdChanged(providerThreshold);
    }
}