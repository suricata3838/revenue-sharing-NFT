// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HTLC is Ownable, ReentrancyGuard {
    uint256 public startTime;
    uint256 public lockTime = 86400 seconds; // 48 hours
    address payable public whiteHat;
    address public newerAddress;
    uint256 public amount;
    address public nftContract;

    constructor(
        address _recipient,
        address _nftContract,
        address _newAddress
    ) onlyOwner {
        // Separate and make the vairables updatable
        whiteHat = payable(_recipient);
        newerAddress = _newAddress;
        nftContract = _nftContract;
    }

    function transferOwnership(address) public override onlyOwner nonReentrant {
        revert("Not allowed.");
    }

    function fund() external payable onlyOwner nonReentrant {
        startTime = block.timestamp;
        amount += msg.value;
    }

    function withdraw() external nonReentrant {
        require(
            msg.sender == whiteHat,
            "Only Provided address can withdraw..."
        );
        require(
            block.timestamp <= startTime + lockTime,
            "Time expired to withdraw."
        );
        Ownable(nftContract).transferOwnership(newerAddress);
        whiteHat.transfer(amount);
        amount = 0;
        startTime = 0;
    }

    function refund() external onlyOwner nonReentrant {
        require(block.timestamp > startTime + lockTime, "too early");
        payable(owner()).transfer(address(this).balance);
        amount = 0;
        startTime = 0;
    }

    function resetContractOwnerAndRefund() external onlyOwner nonReentrant {
        require(block.timestamp > startTime + lockTime, "too early");
        Ownable(nftContract).transferOwnership(newerAddress);
        payable(owner()).transfer(address(this).balance);
        amount = 0;
        startTime = 0;
    }
    /**
     * Make sure: all variables are correct when we deploy the contract.
     */
}
