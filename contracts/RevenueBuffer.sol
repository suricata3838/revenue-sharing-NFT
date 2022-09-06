// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RevenueBuffer is AccessControl{
  using SafeMath for uint256;
  uint256 public receiveId;
  uint256 public requestId;
  uint256 public withdrawnId;

  uint public totalReceived;
  mapping(address=>uint256) public claimablePerAddress;
  mapping(address=>uint256) public withdrawnPerAddress;
  mapping(uint256=>uint256) public receiveIdToAmount;
  mapping(uint256=>Request) public requestIdToRequest;
  struct Request {
      uint256 tokenId;
      uint256 amount;
      address[] members;
  }
  mapping(uint256=>MemberAmount[]) public tokenIdToMemberAmounts;
  struct MemberAmount {
      address member;
      uint256 amount;
  }
  uint256 numWithdrawer;

  // we have 2 role: admin and provider 
  bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
  constructor() {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  event RequestAdded(uint tokenId, uint256 amount, address[] m);
  event Withdrawed(address indexed account, uint256 indexed amount);
  event WithdrawerAdded(address withdrawer);
  event WithdrawerRemoved(address withdrawer);

  function addRequest(uint tokenId, address[] memory m) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // TODO: commentout
    require(requestId == receiveId -1, "Invalid requestId");
    ++requestId;
    uint256 amount = receiveIdToAmount[requestId];
    require(amount > 0, "request amount should be > 0");
    Request memory request =  Request(tokenId, amount, m);
    requestIdToRequest[requestId] = request;
    (bool res, uint256 revenuePerMember) = amount.tryDiv(m.length);
    require(res, "Failed to devide receive amount");
    for(uint i=0; i<m.length; i++) {
      claimablePerAddress[m[i]] += revenuePerMember;
      MemberAmount memory ma = MemberAmount(m[i], revenuePerMember);
      tokenIdToMemberAmounts[tokenId].push(ma);
    }
    emit RequestAdded(tokenId, amount, m);
  }

  receive () external payable {
    ++receiveId;
    receiveIdToAmount[receiveId] = msg.value;
    totalReceived += msg.value;
  }

  function batchWithdraw() external onlyRole(WITHDRAWER_ROLE) payable {
    require(withdrawnId < requestId, "No Withdrawable Request");
    // transfer claimablePerAddress to all addresses if the amount is not zero.
    // how to get the wallet list: requestIdToRequest[requestId(itterable)].members
    for(uint i=withdrawnId; i<=requestId; i++) {
      address[] memory m = requestIdToRequest[i].members;
      for (uint j=0; j<m.length; j++) {
        if(claimablePerAddress[m[j]] > 0){
          address account = m[j];
          uint256 payment = claimablePerAddress[account];
          withdrawnPerAddress[account] += payment;
          claimablePerAddress[account] = 0;
          totalReceived -= payment;
          _transfer(account, payment);
          emit Withdrawed(account, payment);
        }
      }
    }
    withdrawnId = requestId;
  }

  function withdraw(address account, uint amount) external onlyRole(WITHDRAWER_ROLE) payable {
    require(claimablePerAddress[account] > 0, "Account has no claimable amount.");
    require(claimablePerAddress[account] > amount, "Amount exceeds claimable amount.");
    claimablePerAddress[account] -= amount;
    totalReceived -= amount;
    withdrawnPerAddress[account] += amount;
    _transfer(account, amount);
    emit Withdrawed(account, amount);
  }
  
  ////
  // add and remove provider_role to an address
  ////

  function addProvider(address withdrawer) external onlyRole(DEFAULT_ADMIN_ROLE) {
      // withdrawer should not have WITHDRAWER_ROLE already.
      require(!hasRole(WITHDRAWER_ROLE, withdrawer), "Withdrawer already added.");

      _grantRole(WITHDRAWER_ROLE, withdrawer);
      numWithdrawer++;

      emit WithdrawerAdded(withdrawer);
  }

  function removeProvider(address withdrawer) external onlyRole(DEFAULT_ADMIN_ROLE) {
      // withdrawer should have WITHDRAWER_ROLE.
      require(hasRole(WITHDRAWER_ROLE, withdrawer), "Withdrawer doesn't exist.");

      _revokeRole(WITHDRAWER_ROLE, withdrawer);
      numWithdrawer--;

      emit WithdrawerRemoved(withdrawer);
  }


  // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
  error TransferFailed();
  function _transfer(address to, uint256 amount) internal {
    bool callStatus;
    assembly {
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!callStatus) revert TransferFailed();
  }
}