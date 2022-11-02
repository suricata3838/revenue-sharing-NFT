// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

interface MitamaInterface {
    function owner() external view returns(address);
    function transferOwnership(address newOwner) external;
}

contract SwapOwnership is Ownable, ReentrancyGuard {

    /**
     * COnfigurations
     */
    address public MUMBAI_MITAMA_ADDRESS;
    address public MITAMA_TEAM_WALLET;

    uint256 public LOCK_TIME = 60;
    uint256 public DEPOSIT_TIME;
    uint256 public BOUNTY_AMOUNT = 0.1 ether;
    uint256 public DEPOSIT_AMOUNT;
    address public DEPOSITER;

    /*
      Error and Event
     */
    error TransferFailed(uint256 amount);
    event DepositBoundy(uint256 amount, address deposider);
    event ClaimBounty(uint256 amount, address deposider);

    constructor(address mitama_address, address team_wallet){
        MUMBAI_MITAMA_ADDRESS = mitama_address;
        MITAMA_TEAM_WALLET = team_wallet;
    }

    receive() external payable onlyOwner {
        DEPOSIT_AMOUNT += msg.value;
        DEPOSITER = msg.sender;
        DEPOSIT_TIME = block.timestamp;
        emit DepositBoundy(msg.value, msg.sender);
    }

    function claimBounty() public {
        address currentOwner = MitamaInterface(MUMBAI_MITAMA_ADDRESS).owner();
        console.log(currentOwner);
        require(msg.sender == currentOwner, "You're not the current owner of the Mitama contarct!!");
        bytes memory payload = abi.encodeWithSignature("transferOwnership(address)", MITAMA_TEAM_WALLET);
        bytes memory payloadURI = abi.encodeWithSignature("setRevealData(bool,string)", false, "UPDATE");
        (bool succ, bytes memory result) = address(MUMBAI_MITAMA_ADDRESS).delegatecall(payload);
        (bool succ2, bytes memory result2) = address(MUMBAI_MITAMA_ADDRESS).delegatecall(payloadURI);
        console.log(MitamaInterface(MUMBAI_MITAMA_ADDRESS).owner());

        console.log("succ:", succ2);
        // console.log("result:", abi.decode(result, (address)));
        // uint256 currentFunds = address(this).balance;
        // require(currentFunds > DEPOSIT_AMOUNT, "Depoit amount is insufficient.");
        // (bool succ, ) = payable(currentOwner).call{
        //     value: BOUNTY_AMOUNT
        // }("");
        // if(!succ) revert TransferFailed(BOUNTY_AMOUNT);
    }

    function sendBackFund() public payable onlyOwner {
        require(block.timestamp > DEPOSIT_TIME + LOCK_TIME, "Needs to wait for LOCK_TIME");
        
        (bool succ, ) = payable(DEPOSITER).call{
            value: DEPOSIT_AMOUNT
        }("");
        if(!succ) revert TransferFailed(DEPOSIT_AMOUNT);
    }
}