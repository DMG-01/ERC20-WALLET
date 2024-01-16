//SPDX-License-Identifier:MIT
// code allows user to put their token in the contract as a wallet and trade them p2p
// this is a wallet that allows use to have multiple ERC20 token and they can send,lock and even swap tokens p2p
pragma solidity ^0.8.0;
//standard ERC20 token is being installed from openZeppelin
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract Wallet is ReentrancyGuard{
// an array to store the token addresses and the token pricefeed addresses


// this enum called TransactionStatus is used to store the status of a transaction when a user intends to swap p2p it includes pending,accepted and rejected
enum TransactionStatus {
  pending,
  accepted,
  rejected
}

TransactionStatus transactionStatus;

struct transactionDetails {
  address recepient ;
  uint256 amount ;
  uint256 time;
}

uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
uint256 private constant PRECISION = 1e18;

/* a group of mapping with address as key 
  * the first mapping issecondary user to transaction status
  *the second mapping is user to their token balances
  *the third is user to their individual token transfer limit
  *the fourth is user to their locked token
  * and the fourth is user to the time of their token unlock time 
 */
mapping(address => TransactionStatus) secondaryUserToTransactionStatus;
mapping(address =>mapping(address => uint256)) addressToTokenBalance;
mapping(address =>mapping(address =>uint256)) addressToTokenLimit;
mapping(address =>mapping(address => uint256)) addresstoTokenLocked;
mapping(address =>mapping(address => uint256)) addresstoTokenLockedTime;
mapping(address =>mapping(address => uint256)) addressToTokenTimeInterval;
mapping (address => address) tokenAddressToPriceFeedAddress;
mapping(address => mapping(address => uint256)) addressToTokenIn;
mapping(address => mapping(address => uint256)) addressToTokenOut;

/*MAPPINGS INVOLVED IN SWAP TRANSACTION */
mapping(address => address) initiatorAddressToSecondUserAddress;
mapping(address => uint256) initiatorAddressToAmountToGive;
mapping(address => uint256) initiatorAddressToSecondUserAmountToReceive;
mapping(address => address) initiatorAddressToTokenToGiveOutAddress;
mapping(address => address) initiatorAddressToUserTwoTokenAddress;
/* List of all custom error */
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
error priceFeedAddressesDoesntEqualTokenAddresses();
error invalidToken();
error cannotSendEtherToSelf();
error InsufficientBalanceFromSecondUserEnd();
error parametersDontMatch();

/********EVENTS */
event accountFunded(address indexed user,address indexed tokenFunded,uint256 indexed amountFunded) ;
event tokenWithdrawn(address indexed user, address indexed tokenWithdrawn, uint256 indexed amount);
event tokenWithdrawnFromLock(address indexed user, address indexed tokenWithdrawn, uint256 indexed amountWithdrawn, uint256 timeOfWithdrawal);
event swapTokenFunctionHasBeenInitiated(address indexed caller, address indexed userTwo, uint256  callerAmount, uint256  userTwoAmount, address  callerTokenAddress, address  userTwoTokenAddress);
event tokenSwapSuccessful(address indexed caller, address indexed userTwo, uint256  callerAmount, uint256  userTwoAmount, address  callerTokenAddress, address  userTwoTokenAddress);
event etherHasBeenTransfered(address indexed recepient, uint256 amount, uint256 time);
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

modifier isAllowedToken(address token) {
  if(tokenAddressToPriceFeedAddress[token] == address(0)) {
    revert invalidToken();
  }
  _;
}



constructor(
    address[] memory  tokenPriceFeedAddresses,
    address[] memory tokenAddresses  
)
{
  owner = msg.sender;
    if(tokenPriceFeedAddresses.length != tokenAddresses.length) {
      revert priceFeedAddressesDoesntEqualTokenAddresses();
    }
    else {
             for(uint256 index;index< tokenAddresses.length;index++) {
              tokenAddressToPriceFeedAddress[tokenAddresses[index]] = tokenPriceFeedAddresses[index];
             }
    }

    }


//function signer() public {}

//function generateAddressAndPrivateKey() public {}
/*
function depositCollateral(address token,uint256 amount) public moreThanZero(amount)   /*nonReentrant() returns(bool){
    addressToTokenBalance[msg.sender][token] += amount;
    emit collateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
    bool success = IERC20(token).transferFrom(msg.sender,address(this),amount);

    if(!success){
        revert fundAccountFailed();
    }
    else {
        return true;
    }
    }
*/
function fundAccount(address token, uint256 amount) public moreThanZero(amount)  nonReentrant() returns(bool) {
      require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
     // IERC20(token).approve(address(this), amount);
      addressToTokenBalance[msg.sender][token] += amount;
      addressToTokenLimit[msg.sender][token] = 0;
      bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
      emit accountFunded(msg.sender,token,amount);
      if(!success) {
      revert fundAccountFailed();
    }else {
  return true;
 } 
}

function withdraw(address token, uint256 amount) public moreThanZero(amount) /*isAllowedToken(token)*/ nonReentrant() returns(bool){
      addressToTokenBalance[msg.sender][token] -= amount;
      bool success = IERC20(token).transfer(msg.sender, amount);
      emit tokenWithdrawn(msg.sender, token, amount);
      if(!success) {
        revert withdrawalFailed();
      }else {
      return true;
}
}



function lockTokens(address tokenToLock, uint256 amountToLock, uint256 timeLock) moreThanZero(amountToLock) nonReentrant()/*isAllowedToken(tokenToLock)*/ public {
    if(amountToLock > addressToTokenBalance[msg.sender][tokenToLock]){
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
function withdrawLockedTokens(address tokenToWithdraw)  public /*isAllowedToken(tokenToWithdraw) */nonReentrant() {
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

    

// one person swapping will input the amounts and the other person would accept the transaction
//check if the person calling the confirm transaction is the second user inputed in the contract

//add spending limit to the swap function

//emit
//return
//compare return


// mapping address one to address two
// returns msg.sender and details
//function 2 checks if they are the result to the first key
//if yes put in their own value just so it matches
//perform swap

//several mappings

function swapTokenInitiator(address userTwo, uint256 callerAmount,uint256 userTwoAmount,address callerTokenAddress, address userTwoTokenAddress) public {
  uint256 balance = addressToTokenBalance[msg.sender][callerTokenAddress];
  if(callerAmount > balance/*addressToTokenBalance[msg.sender][callerTokenAddress]*/){
    revert InsufficientBalance();
  }
  else if (callerAmount < balance) {
  initiatorAddressToSecondUserAddress[msg.sender] = userTwo;
  initiatorAddressToAmountToGive[msg.sender] = callerAmount;
  initiatorAddressToSecondUserAmountToReceive[msg.sender] = userTwoAmount;
  initiatorAddressToTokenToGiveOutAddress[msg.sender] = callerTokenAddress;
  initiatorAddressToUserTwoTokenAddress[msg.sender] = userTwoTokenAddress;
  emit swapTokenFunctionHasBeenInitiated(msg.sender,userTwo,callerAmount,userTwoAmount,callerTokenAddress,userTwoTokenAddress);
}

}

function secondUserConfirmation(address tokenToSwap, uint256 amountToSwap, address userOneAddress, address tokenAddressToReceive, uint256 amountToReceive) public {

(address userTwo, uint256 initiatorAmount, uint256 userTwoAmount, address callerTokenAddress, address userTwoTokenAddress) = returnSwapinitiatorDetails(userOneAddress);
if(amountToSwap > getUserTokenBalance(tokenToSwap)) {
  revert InsufficientBalance();
}

if( (msg.sender == userTwo) && (tokenToSwap == userTwoTokenAddress) && (amountToSwap == userTwoAmount) && (tokenAddressToReceive == callerTokenAddress) && (initiatorAmount == amountToReceive ))  {
   
   addressToTokenBalance[msg.sender][tokenToSwap] -= amountToReceive;
addressToTokenBalance[userOneAddress][tokenAddressToReceive] -= amountToReceive;
addressToTokenBalance[msg.sender][tokenAddressToReceive] += amountToReceive;
addressToTokenBalance[userOneAddress][tokenToSwap] += amountToSwap;
} else {
  revert parametersDontMatch();
}

}
/*
function swapTokens(uint256 callerAmount, uint256 userTwoAmount, address callerTokenAddress,address userTwoTokenAddress, address userTwo) public nonReentrant() {
emit swapTokenFunctionHasBeenInitiated(msg.sender,userTwo,callerAmount,userTwoAmount,callerTokenAddress,userTwoTokenAddress);
uint256 timeOfFunctionCall = block.timestamp;
if(  _secondUserConfirmTransaction(1,userTwo)) {
  

 if (callerAmount > addressToTokenBalance[msg.sender][callerTokenAddress]) {
   revert InsufficientBalance();
}
else if (userTwoAmount > addressToTokenBalance[userTwo][userTwoTokenAddress]) {
   revert InsufficientBalanceFromSecondUserEnd();
}
else {
addressToTokenBalance[msg.sender][callerTokenAddress] -= callerAmount;
addressToTokenBalance[userTwo][userTwoTokenAddress] -= userTwoAmount;
addressToTokenBalance[msg.sender][userTwoTokenAddress] += userTwoAmount;
addressToTokenBalance[userTwo][callerTokenAddress] += callerAmount;

addressToTokenIn[msg.sender][userTwoTokenAddress] += userTwoAmount;
addressToTokenOut[msg.sender][callerTokenAddress] += callerAmount;
emit tokenSwapSuccessful(msg.sender,userTwo,callerAmount,userTwoAmount,callerTokenAddress,userTwoTokenAddress);
}
}
else if (_secondUserConfirmTransaction(0,userTwo)) {
  revert secondaryUserRejectedTheTransaction();
}
else if( block.timestamp > timeOfFunctionCall + 30 minutes) {
revert functionTimeOut();
}

else {
  revert secondaryUserRejectedTheTransaction();
}
}

function _secondUserConfirmTransaction(uint256 index, address userTwo) public   returns(bool) {
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
*/
function sendToken(address tokenAddress, uint256 amount, address recepient) public  moreThanZero(amount) nonReentrant() {
if(addressToTokenBalance[msg.sender][tokenAddress] == 0)
{
  revert InsufficientBalance();
} else if(amount > addressToTokenBalance[msg.sender][tokenAddress]) {
  revert InsufficientBalance();
}
else {
SpendingLimit(tokenAddress,amount);
addressToTokenBalance[msg.sender][tokenAddress] -= amount;
addressToTokenBalance[recepient][tokenAddress] += amount;
}
}

//function createBudget() public {}
/*
function addTokenAndTokenPriceFeedAddress(address _tokenAddress, address _tokenPriceFeedAddress) public  {
tokenPriceFeedAddresses.push(_tokenPriceFeedAddress);
tokenAddresses.push(_tokenAddress);
}
*/
function SpendingLimit(address tokenAddress,uint256 amount) view internal {
uint256 spendingLimit = addressToTokenLimit[msg.sender][tokenAddress]; 
if(spendingLimit > 0){
     if(amount > spendingLimit) {
  revert amountHasExceededLimit();
}
} 
}

function _addToDailySpendingLimit(address tokenAddress, uint256 amount) public {
 addressToTokenLimit[msg.sender][tokenAddress] = amount;
//return (addressToTokenLimit[msg.sender][tokenAddress]);
}

function sendEther(address payable recepient) payable public nonReentrant() {
  if(msg.value <= 0) {
    revert needsMoreThanZero();
  }
  else if(recepient == msg.sender){
    revert cannotSendEtherToSelf();
  }
  else if(msg.value > (msg.sender.balance)){
    revert InsufficientBalance();
  }
  else{
    recepient.transfer(msg.value);
emit etherHasBeenTransfered(recepient,msg.value,block.timestamp);
}
}

/*****************GETTER
 *               FUNCTIONS
 *******************************/


function getUserEtherBalance() public view returns(uint256) {
  return msg.sender.balance;
}

function getToTalInAndOutOfToken(address token) public view returns(uint256, uint256) {
 uint256 totalIn = addressToTokenIn[msg.sender][token];
 uint256 totalOut = addressToTokenOut[msg.sender][token];
 return(totalIn,totalOut);
}

function getTokenAmountInUsd(address token, uint256 Amount) isAllowedToken(token) public view returns(uint256){
AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenAddressToPriceFeedAddress[token]);
(,int256 price,,,) = priceFeed.latestRoundData();
return ((uint256 (price) * ADDITIONAL_FEED_PRECISION) * Amount)/PRECISION;

}

function getUserLockTokenBalance(address token) public view returns(uint256) {
  if(addresstoTokenLocked[msg.sender][token] == 0){
    return 0;
  }else {
  return(addresstoTokenLocked[msg.sender][token]);
}
}


function getUserTokenBalance(address token) public /*isAllowedToken(token)*/ view returns(uint256) {
    uint256 tokenBalance = addressToTokenBalance[msg.sender][token];
    return tokenBalance;
}
function returnUserSpendingLimit(address token) public view returns (uint256) {
  return (addressToTokenLimit[msg.sender][token]);
}

//could add a modifier so that only msg.sender and userTwo can call it
function returnSwapinitiatorDetails(address initiator) view public returns(address,uint256,uint256,address,address){
   address userTwo = initiatorAddressToSecondUserAddress[initiator];
   uint256 initiatorAmount = initiatorAddressToAmountToGive[initiator];
   uint256 userTwoAmount = initiatorAddressToSecondUserAmountToReceive[initiator];
   address callerTokenAddress = initiatorAddressToTokenToGiveOutAddress[initiator];
   address userTwoTokenAddress = initiatorAddressToUserTwoTokenAddress[initiator];

    return ( userTwo,initiatorAmount,userTwoAmount,callerTokenAddress,userTwoTokenAddress);
}

function testSecondUserTokenWouldRevertWithInsufficientBalance() public {}
 
}
