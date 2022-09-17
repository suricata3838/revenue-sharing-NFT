// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RevenueBuffer is AccessControl{
  using SafeMath for uint256;
  uint256 public receiveId;
  uint256 public requestId;
  uint256 public withdrawnId;
  address public WETH;


  uint public totalReceivedETH;
  uint public totalReceivedWETH;
  uint public WETHbalance;
  mapping(address=>Amount) public claimablePerAddress;
  mapping(address=>Amount) public withdrawnPerAddress;
  struct Amount {
    uint256 amountETH;
    uint256 amountWETH;
  }
  mapping(uint256=>Payment) public receiveIdToPayments;
  struct Payment {
    uint256 amount;
    bool isWETH;
  }
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
  event WithdrawedETH(address indexed account, uint256 indexed amount);
  event WithdrawedWETH(address indexed account, uint256 indexed amount);
  event WithdrawerAdded(address withdrawer);
  event WithdrawerRemoved(address withdrawer);

  function setTokenAddress(address token_) external onlyRole(DEFAULT_ADMIN_ROLE) {
      require(token_ != address(0), "Invalid token address");
      WETH = token_;
  }

  function addRequest(uint tokenId, address[] memory m) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // TODO: check any update of receiveing amount of WETH.
    updateReceivedWETH();
    require(requestId == receiveId -1, "Invalid requestId");
    ++requestId;
    uint256 amount = receiveIdToPayments[requestId].amount;
    bool isWETH = receiveIdToPayments[requestId].isWETH;
    require(amount > 0, "request amount should be > 0");
    //amount is given by receivedIdToPayments
    Request memory request =  Request(tokenId, amount, m);
    requestIdToRequest[requestId] = request;
    (bool res, uint256 revenuePerMember) = amount.tryDiv(m.length);
    require(res, "Failed to devide receive amount");
    for(uint i=0; i<m.length; i++) {
      if (isWETH) {
        claimablePerAddress[m[i]].amountWETH += revenuePerMember;
      } else {
        claimablePerAddress[m[i]].amountETH += revenuePerMember;
      }
      MemberAmount memory ma = MemberAmount(m[i], revenuePerMember);
      tokenIdToMemberAmounts[tokenId].push(ma);
    }
    emit RequestAdded(tokenId, amount, m);
  }

  //receive ETH
  receive() external payable {
    ++receiveId;
    receiveIdToPayments[receiveId] = Payment(msg.value, false);
    totalReceivedETH += msg.value;
  }

  // update receivedWETH
  function updateReceivedWETH() internal {
    uint256 bal = IERC20(WETH).balanceOf(address(this));
    if(bal > WETHbalance) {
      ++receiveId;
      receiveIdToPayments[receiveId] = Payment(bal - WETHbalance, true);
      totalReceivedWETH += bal - WETHbalance;
      WETHbalance = bal;
    }
  }

  function batchWithdraw() external onlyRole(WITHDRAWER_ROLE) payable {
    require(withdrawnId < requestId, "No Withdrawable Request");
    // transfer claimablePerAddress to all addresses if the amount is not zero.
    // to get the wallet list: requestIdToRequest[requestId(itterable)].members
    for(uint i=withdrawnId; i<=requestId; i++) {
      address[] memory m = requestIdToRequest[i].members;
      for (uint j=0; j<m.length; j++) {
        address account = m[j];
        if(claimablePerAddress[account].amountETH > 0){
          uint256 claimableETH = claimablePerAddress[account].amountETH;
          withdrawnPerAddress[account].amountETH += claimableETH;
          claimablePerAddress[account].amountETH = 0;
          totalReceivedETH -= claimableETH;
          _transfer(account, claimableETH);
          emit WithdrawedETH(account, claimableETH);
        }
        if(claimablePerAddress[account].amountWETH > 0){
          uint256 claimableWETH = claimablePerAddress[account].amountWETH;
          withdrawnPerAddress[account].amountWETH += claimableWETH;
          claimablePerAddress[account].amountWETH = 0;
          totalReceivedWETH -= claimableWETH;
          IERC20(WETH).transfer(account, claimableWETH);
          emit WithdrawedWETH(account, claimableWETH);
        }
      }
    }
    withdrawnId = requestId;
  }

  function withdrawETH(address account, uint amount) external onlyRole(WITHDRAWER_ROLE) payable {
    require(claimablePerAddress[account].amountETH > 0, "Account has no claimable amount.");
    require(claimablePerAddress[account].amountETH > amount, "Amount exceeds claimable amount.");
    claimablePerAddress[account].amountETH -= amount;
    totalReceivedETH -= amount;
    withdrawnPerAddress[account].amountETH += amount;
    _transfer(account, amount);
    emit WithdrawedETH(account, amount);
  }

  function withdrawWETH(address account, uint amount) external onlyRole(WITHDRAWER_ROLE) payable {
    require(claimablePerAddress[account].amountWETH > 0, "Account has no claimable amount.");
    require(claimablePerAddress[account].amountWETH > amount, "Amount exceeds claimable amount.");
    claimablePerAddress[account].amountWETH -= amount;
    totalReceivedWETH -= amount;
    withdrawnPerAddress[account].amountWETH += amount;
    IERC20(WETH).transfer(account, amount);
    emit WithdrawedWETH(account, amount);
  }
  
  ////
  // add and remove Withdrawer
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