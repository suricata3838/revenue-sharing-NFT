// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/////////////////////////////////////////
// ______                                  _____ _                    
// | ___ \                                /  ___| |                   
// | |_/ /_____   _____ _ __  _   _  ___  \ `--.| |__   __ _ _ __ ___ 
// |    // _ \ \ / / _ \ '_ \| | | |/ _ \  `--. \ '_ \ / _` | '__/ _ \
// | |\ \  __/\ V /  __/ | | | |_| |  __/ /\__/ / | | | (_| | | |  __/
// \_| \_\___| \_/ \___|_| |_|\__,_|\___| \____/|_| |_|\__,_|_|  \___|
//                                                                                                                               
/////////////////////////////////////////
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RevenueShareForDonation is AccessControl{
  using SafeMath for uint256;
  uint256 public receiveId;
  uint256 public requestId;
  uint256 public withdrawnId;
  address public WETH;


  uint256 public totalReceivedETH;
  uint256 public totalReceivedWETH;
  uint256 public ETHbal;
  uint256 public WETHbal;
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
      address account;
  }
  uint256 numWithdrawer;
  bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

  mapping(uint256 => uint256) internal tokenToMaterial;
  mapping(uint256 => address) internal materialToDonation;
  
  constructor(
      uint256[10000] memory materialList,
      address[7] memory addresses
  ) {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _grantRole(WITHDRAWER_ROLE, msg.sender);
    
    for(uint256 i; i < materialList.length; i++){
      tokenToMaterial[i] = materialList[i];
    }
    for(uint256 i; i < addresses.length; i++){
      materialToDonation[i] = addresses[i];
    }

  }

  event ReceivedETH(uint256 receivedId, uint256 amount);
  event ReceivedWETH(uint256 receivedId, uint256 amount);
  event RequestAdded(uint tokenId, uint256 amount, address account);
  event WithdrawedETH(address indexed account, uint256 indexed amount);
  event WithdrawedWETH(address indexed account, uint256 indexed amount);
  event WithdrawerAdded(address withdrawer);
  event WithdrawerRemoved(address withdrawer);

  function addRequest(uint tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _updateReceivedWETH();
    ++requestId;
    Payment memory payment = receiveIdToPayments[requestId];
    require(payment.amount > 0, "request amount should be > 0");
    //amount is given by receivedIdToPayments
    uint256 materialId = tokenToMaterial[tokenId];
    address donation = materialToDonation[materialId];
    Request memory request =  Request(tokenId, payment.amount, donation);
    requestIdToRequest[requestId] = request;
    if (payment.isWETH) {
        claimablePerAddress[donation].amountWETH += payment.amount;
    } else {
        claimablePerAddress[donation].amountETH += payment.amount;
    }
    emit RequestAdded(tokenId, payment.amount, donation);
  }

  //receive ETH
  receive() external payable {
    _updateReceivedWETH();
    ++receiveId;
    receiveIdToPayments[receiveId] = Payment(msg.value, false);
    totalReceivedETH += msg.value;
    emit ReceivedETH(receiveId, msg.value);
  }

  // update receivedWETH
  function _updateReceivedWETH() internal {
    require(WETH != address(0), "failed setWET()");
    uint256 bal = IERC20(WETH).balanceOf(address(this));
    if(bal == 0){
      WETHbal == 0;
    } else if(bal > 0 && bal > WETHbal) {   
      uint256 diff = bal - WETHbal;
      ++receiveId;
      receiveIdToPayments[receiveId] = Payment(diff, true);
      totalReceivedWETH += diff;
      WETHbal = bal;
      emit ReceivedWETH(receiveId, diff);
    }
  }

  // onEvent: WETH is transfered to this contract
  function getWETHbal() public returns(uint256){
      console.log("hit");
      _updateReceivedWETH();
      return WETHbal;
  }

  function batchWithdraw() external onlyRole(WITHDRAWER_ROLE) payable {
    require(withdrawnId < requestId, "No Withdrawable Request");
    // transfer claimablePerAddress to all addresses if the amount is not zero.
    // to get the wallet list: requestIdToRequest[requestId(itterable)].members
    for(uint i=withdrawnId; i<=requestId; i++) {
      address account = requestIdToRequest[i].account;
        if(claimablePerAddress[account].amountETH > 0){
            uint256 claimableETH = claimablePerAddress[account].amountETH;
            withdrawnPerAddress[account].amountETH += claimableETH;
            claimablePerAddress[account].amountETH = 0;
            _transfer(account, claimableETH);
            emit WithdrawedETH(account, claimableETH);
        }
        if(claimablePerAddress[account].amountWETH > 0){
            uint256 claimableWETH = claimablePerAddress[account].amountWETH;
            withdrawnPerAddress[account].amountWETH += claimableWETH;
            claimablePerAddress[account].amountWETH = 0;
            IERC20(WETH).transfer(account, claimableWETH);
            emit WithdrawedWETH(account, claimableWETH);
        }
    }
    ETHbal = address(this).balance;
    withdrawnId = requestId;
  }

  function withdrawETH(address account, uint amount) external onlyRole(WITHDRAWER_ROLE) payable {
    require(claimablePerAddress[account].amountETH > 0, "Account has no claimable amount.");
    require(claimablePerAddress[account].amountETH > amount, "Amount exceeds claimable amount.");
    claimablePerAddress[account].amountETH -= amount;
    withdrawnPerAddress[account].amountETH += amount;
    _transfer(account, amount);
    ETHbal = address(this).balance;
    emit WithdrawedETH(account, amount);
  }

  function withdrawWETH(address account, uint amount) external onlyRole(WITHDRAWER_ROLE) payable {
    require(claimablePerAddress[account].amountWETH > 0, "Account has no claimable amount.");
    require(claimablePerAddress[account].amountWETH > amount, "Amount exceeds claimable amount.");
    claimablePerAddress[account].amountWETH -= amount;
    withdrawnPerAddress[account].amountWETH += amount;
    IERC20(WETH).transfer(account, amount);
    WETHbal = IERC20(WETH).balanceOf(address(this));
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

  /*
   * House Keepings
   */
  function setWET(address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
      require(_addr != address(0), "Invalid token address");
      WETH = _addr;
  }

  function setTokenToMaterial(uint256[] memory materialList) external onlyRole(DEFAULT_ADMIN_ROLE){
    require(materialList.length == 10000, "Invalid materialList");
    for(uint256 i; i < materialList.length; i++){
      tokenToMaterial[i] = materialList[i];
    }
  }
  
  function setMaterialToDonation(address[] memory addresses) external onlyRole(DEFAULT_ADMIN_ROLE){
    require(addresses.length == 7, "Invalid materialList");
    for(uint256 i; i < addresses.length; i++){
      materialToDonation[i] = addresses[i];
    }
  }

}