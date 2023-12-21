//SPDX-License-Identifier:MIT
// code allows user to put their token in the contract as a wallet and trade them p2p
pragma solidity ^0.8.0;

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


contract Wallet {

address[] public tokenAddresses;
address[] public tokenPriceFeedAddresses;
address[] tokenLockersAddress;

enum TransactionStatus {
  pending,
  accepted,
  rejected
}

TransactionStatus transactionStatus;

mapping(address => TransactionStatus) secondaryUserToTransactionStatus;
mapping(address =>mapping(address => uint256)) addressToTokenBalance;
mapping(address =>mapping(address =>uint256)) addressToTokenLimit;
mapping(address =>mapping(address => uint256)) addresstoTokenLocked;
mapping(address =>mapping(address => uint256)) addresstoTokenLockedTime;


error onlyOwnerCanCallThisFunction();
error tokenNotAllowed();
error fundAccountFailed();
error withdrawalFailed();
error needsMoreThanZero();
error InsufficientBalance();
error youCantWithdrawTokenYet();
error sendTokenFailed();
//error invalidIndexedPassed();
error secondaryUserRejectedTheTransaction();
error functionTimeOut();
error amountHasExceededLimit();

/********EVENTS */
event accountFunded(address indexed user,address indexed tokenFunded,uint256 indexed amountFunded) ;
event tokenWithdrawn(address indexed user, address indexed tokenWithdrawn, uint256 indexed amount);
event tokenWithdrawnFromLock(address indexed user, address indexed tokenWithdrawn, uint256 indexed amountWithdrawn, uint256 timeOfWithdrawal);
event swapTokenFunctionHasBeenInitiated(address indexed caller, address indexed userTwo, uint256  callerAmount, uint256  userTwoAmount, address  callerTokenAddress, address  userTwoTokenAddress);

address public owner ;

modifier onlyOwner() {
    if(msg.sender != owner){
    revert("only the owner can call this function");
}
_;
}

modifier moreThanZero(uint256 amount) {
    if(amount <= 0) {
        revert needsMoreThanZero();
    }
    _;
}

constructor() {
    owner = msg.sender;
    }


function signer() public {}

function generateAddressAndPrivateKey() public {}

function fundAccount(address token, uint256 amount) public moreThanZero(amount) returns(bool) {
      require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
      addressToTokenBalance[msg.sender][token] += amount;
      bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
      emit accountFunded(msg.sender,token,amount);
      if(!success) {
      revert fundAccountFailed();
    }else {
  return true;
 } 
}

function withdraw(address token, uint256 amount) public moreThanZero(amount) returns(bool){
      addressToTokenBalance[msg.sender][token] -= amount;
      bool success = IERC20(token).transfer(msg.sender, amount);
      emit tokenWithdrawn(msg.sender, token, amount);
      if(!success) {
        revert withdrawalFailed();
      }else {
      return true;
}
}

function sendTokenToSameWalletUsers() public{}

function getUserTokenBalance(address token) public view returns(uint256) {
    uint256 tokenBalance = addressToTokenBalance[msg.sender][token];
    return tokenBalance;
}
function lockTokens(address tokenToLock, uint256 amountToLock, uint256 timeLock) moreThanZero(amountToLock) public {
    if(amountToLock < addressToTokenBalance[msg.sender][tokenToLock]){
        revert InsufficientBalance();
    }else {
        addressToTokenBalance[msg.sender][tokenToLock] -= amountToLock;
        addresstoTokenLocked[msg.sender][tokenToLock] += amountToLock;
        addresstoTokenLockedTime[msg.sender][tokenToLock] = block.timestamp + timeLock;
     
    }
}
//remove from locked mapping
//add to contract wallet
// add REENTRANCY
function withdrawLockedTokens(address tokenToWithdraw)  public {
  uint256 lockedBalance = addresstoTokenLocked[msg.sender][tokenToWithdraw];
  if (block.timestamp > (addresstoTokenLockedTime[msg.sender][tokenToWithdraw])){
    addresstoTokenLocked[msg.sender][tokenToWithdraw] = 0;
    addressToTokenBalance[msg.sender][tokenToWithdraw] += lockedBalance;
    addresstoTokenLockedTime[msg.sender][tokenToWithdraw] = 0;
    emit tokenWithdrawnFromLock(msg.sender,tokenToWithdraw,lockedBalance,block.timestamp);
  }else {
     revert youCantWithdrawTokenYet();
  }
}
/**may be removed */
function AutoBuyTokens() public {}    


// one person swapping will input the amounts and the other person would accept the transaction
//check if the person calling the confirm transaction is the second user inputed in the contract
function swapTokens(uint256 callerAmount, uint256 userTwoAmount, address callerTokenAddress,address userTwoTokenAddress, address userTwo) public {
emit swapTokenFunctionHasBeenInitiated(msg.sender,userTwo,callerAmount,userTwoAmount,callerTokenAddress,userTwoTokenAddress);
uint256 timeOfFunctionCall = block.timestamp;
if( _secondUserConfirmTransaction(1,userTwo)) {
addressToTokenBalance[msg.sender][callerTokenAddress] -= callerAmount;
addressToTokenBalance[userTwo][userTwoTokenAddress] -= userTwoAmount;
addressToTokenBalance[msg.sender][userTwoTokenAddress] += userTwoAmount;
addressToTokenBalance[userTwo][callerTokenAddress] += callerAmount;
}
else if (_secondUserConfirmTransaction(0,userTwo)) {
  revert secondaryUserRejectedTheTransaction();
}
else if( block.timestamp > timeOfFunctionCall + 15 minutes) {
revert functionTimeOut();

}
else {
  revert secondaryUserRejectedTheTransaction();
}
}

function _secondUserConfirmTransaction(uint256 index, address userTwo) internal  returns(bool) {
  require(userTwo == msg.sender,"only the second user can call this function");
   if(index == 1) {
    secondaryUserToTransactionStatus[msg.sender] = TransactionStatus.accepted;
    return true;
   }
   else  {
    secondaryUserToTransactionStatus[msg.sender] = TransactionStatus.rejected;
    return false;
   }
 
}

function _sendToken(address tokenAddress, uint256 amount, address recepient) internal moreThanZero(amount) returns(bool) {
activateDailySpendingLimit(tokenAddress,amount);
IERC20(tokenAddress).approve(address(this),amount);
bool _sendTokenSuccessful = IERC20(tokenAddress).transferFrom(msg.sender,recepient,amount);
if(!_sendTokenSuccessful) {
  revert sendTokenFailed();
}else {
 return true;
}
}

function createBudget() public {}

function addTokenAndTokenPriceFeedAddress(address tokenAddress, address tokenPriceFeedAddress) public  {
 tokenAddresses.push(tokenAddress);
 tokenPriceFeedAddresses.push(tokenPriceFeedAddress);

}

function activateDailySpendingLimit(address tokenAddress,uint256 amount) public {
(uint256 tokenLimit) = _addToDailySpendingLimit(tokenAddress,amount);
if (amount > tokenLimit) {
  revert amountHasExceededLimit();
}
}

function _addToDailySpendingLimit(address tokenAddress, uint256 amount) internal onlyOwner returns(uint256){
uint256 tokenLimit = addressToTokenLimit[msg.sender][tokenAddress] = amount;
return tokenLimit;
}

}
