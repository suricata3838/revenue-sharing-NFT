// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HTLC is Ownable, ReentrancyGuard {
  uint public startTime;
  uint public lockTime = 172800 seconds;// 48 hours
  address payable public whiteHat;
  address public newerAddress; 
  uint256 public amount;
  address public nftContract;

  constructor(address _recipient, address _nftContract, address _newAddress) onlyOwner{ 
    // Separate and make the vairables updatable
    whiteHat = payable(_recipient);
    newerAddress = _newAddress; 
    nftContract = _nftContract;
  }

    function transferOwnership(address) public override onlyOwner nonReentrant{
        revert("Not allowed.");
    }

    function fund() external payable onlyOwner nonReentrant{
        startTime = block.timestamp;
        amount += msg.value;
    }

    function withdraw() external nonReentrant{ 
        require(msg.sender == whiteHat, "Only Provided address can withdraw...");
        require(block.timestamp <= startTime + lockTime, "Time expired to withdraw.");
        Ownable(nftContract).transferOwnership(newerAddress);
        whiteHat.transfer(amount);
        amount = 0;
        startTime = 0;
    }

    function refund() external onlyOwner nonReentrant{ 
        // require(msg.sender == owner, "Only Owner can withdraw funds");
        require(block.timestamp > startTime + lockTime, "too early");
        payable(owner()).transfer(address(this).balance); 
        amount = 0;
        startTime = 0;
    }
  
    function resetContractOwner() external onlyOwner nonReentrant {
        require(block.timestamp > startTime + lockTime, "too early");
        require(Ownable(nftContract).owner() == address(this), "not owner");
        Ownable(nftContract).transferOwnership(newerAddress);
    }
    
    /**
     * set functions
     */
    function resetStartTime() external onlyOwner nonReentrant {
        startTime = block.timestamp;
    }
    
    function setNewAddress(address _newerAddress) external onlyOwner nonReentrant{
        newerAddress = _newerAddress;
    }

    function setWhiteHat(address _whiteHat) external onlyOwner nonReentrant{
        whiteHat = payable(_whiteHat);
    }

    function setNftContract(address _nftContract) external onlyOwner nonReentrant{
        nftContract = _nftContract;
    }

    function setLockTime(uint256 _lockTime) external onlyOwner nonReentrant{
        lockTime = _lockTime;
    }
}