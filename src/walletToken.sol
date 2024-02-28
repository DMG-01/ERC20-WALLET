//SPDX-License-Identifier:MIT
// code allows user to put their token in the contract as a wallet and trade them p2p
// this is a wallet that allows use to have multiple ERC20 token and they can send,lock and even swap tokens p2p
pragma solidity ^0.8.0;
//standard ERC20 token is being installed from openZeppelin
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract Wallet is ReentrancyGuard{



uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
uint256 private constant PRECISION = 1e18;

/* a group of mapping with address as key 
  * the first mapping issecondary user to transaction status
  *the second mapping is user to their token balances
  *the third is user to their individual token transfer limit
  *the fourth is user to their locked token
  * and the fourth is user to the time of their token unlock time 
 */

mapping(address =>mapping(address => uint256)) addressToTokenBalance;
mapping(address => uint256) addressToEtherBalance;
mapping(address =>mapping(address =>uint256)) addressToTokenLimit;
mapping(address =>mapping(address => uint256)) addresstoTokenLocked;
mapping(address =>mapping(address => uint256)) addresstoTokenLockedTime;
mapping(address =>mapping(address => uint256)) addressToTokenTimeInterval;
mapping (address => address) tokenAddressToPriceFeedAddress;
mapping(address => mapping(address => uint256)) addressToTokenIn;
mapping(address => mapping(address => uint256)) addressToTokenOut;
mapping(address => uint256) addressToEtherInWalletBalance;

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
/**
 * modifiers that are used in the contract 
 * e.g onlyOwner, moreThanZero, isAllowedToken
 */

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

/**
 * a constructor that takes in a two parameters of data type array
 * the priceFeedAddresses is an array that consist of the token chainlink price feed address
 * and the tokenAddress consist of the address of the token
 * the constructor ensures the token price feed address array is the same as the token address and assign the price feed to its token address
 */

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

/* fund Account function that allows user to fund their contract wallet with any token from their external wallet such as metamask   */

function fundAccount(address token, uint256 amount) public  moreThanZero(amount)  nonReentrant() returns(bool) {
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

// this function strictly funds the user account with ether
function fundAccountWithEther() public payable {
addressToEtherInWalletBalance[msg.sender] += msg.value;
}
// this function is supposed to withdraw ether back to the user wallet 
function withdrawFundedEther(uint256 amount) public payable {
 if (amount > addressToEtherInWalletBalance[msg.sender]){
  revert InsufficientBalance();
 }
 addressToEtherInWalletBalance[msg.sender] -= amount;
(bool success,) = owner.call{value: amount}("");
        require(success);
}

/* this function withdraws the token  to the address of the user
it takes in two parameter token which is the address of the token to withdraw and amount which is the amount of the token the user wants to withdraw
 */
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

/** the lock token function allows user to lock their token over a period of time 
 *  it takes in three parameters tokenToLock which is the address of the token the user wants to lock, amountToLock which is the amount of the token the user wants to lock and, the locktime which is the time before the token is allowed to be withdrawn 
 */

function lockTokens(address tokenToLock, uint256 amountToLock, uint256 timeLock) moreThanZero(amountToLock) nonReentrant()/*isAllowedToken(tokenToLock)*/ public {
    if(amountToLock > addressToTokenBalance[msg.sender][tokenToLock]){
        revert InsufficientBalance();
    }else {
        addressToTokenBalance[msg.sender][tokenToLock] -= amountToLock;
        addresstoTokenLocked[msg.sender][tokenToLock] += amountToLock;
        addresstoTokenLockedTime[msg.sender][tokenToLock] = block.timestamp + timeLock;
     
    }
}

/* withdrawLockedToken function withdraws the token that was locked in the above contract once the ripe time has been reached 
* it takes in one parameter which is the token to withdraw 
 */
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

function swapTokenInitiator( uint256 callerAmount,uint256 userTwoAmount,address callerTokenAddress, address userTwoTokenAddress,address userTwo) public nonReentrant {
  uint256 balance = addressToTokenBalance[msg.sender][callerTokenAddress];
  if(callerAmount > balance){
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

function secondUserConfirmation(uint256 amountToReceive,uint256 amountToSwap, address tokenAddressToReceive,address tokenToSwap,  address userOneAddress) public nonReentrant {

(address initiator, address userTwo, uint256 initiatorAmount, uint256 userTwoAmount, address callerTokenAddress, address userTwoTokenAddress) = returnSwapinitiatorDetails(userOneAddress);
if(amountToSwap > getUserTokenBalance(tokenToSwap)) {
  revert InsufficientBalance();
}

if ((amountToReceive == initiatorAmount) &&(amountToSwap == userTwoAmount) && (tokenAddressToReceive == callerTokenAddress) && (tokenToSwap == userTwoTokenAddress) && (userOneAddress == initiator) && (msg.sender == userTwo))  {
   
   addressToTokenBalance[msg.sender][tokenToSwap] -= amountToReceive;
addressToTokenBalance[userOneAddress][tokenAddressToReceive] -= amountToReceive;
addressToTokenBalance[msg.sender][tokenAddressToReceive] += amountToReceive;
addressToTokenBalance[userOneAddress][tokenToSwap] += amountToSwap;
} else {
  revert parametersDontMatch();
}

}

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

function getUserWalletEtherBalance() public view returns(uint256) {
return (addressToEtherInWalletBalance[msg.sender]);
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
function returnSwapinitiatorDetails(address initiator) view public returns(address, address,uint256,uint256,address,address){
   address userTwo = initiatorAddressToSecondUserAddress[initiator];
   uint256 initiatorAmount = initiatorAddressToAmountToGive[initiator];
   uint256 userTwoAmount = initiatorAddressToSecondUserAmountToReceive[initiator];
   address callerTokenAddress = initiatorAddressToTokenToGiveOutAddress[initiator];
   address userTwoTokenAddress = initiatorAddressToUserTwoTokenAddress[initiator];

    return (initiator,userTwo,initiatorAmount,userTwoAmount,callerTokenAddress,userTwoTokenAddress);
}

function returnTrackedEtherBalance() public view returns(uint256) {
  return addressToEtherBalance[msg.sender];
}
 //ALERT TOKEN PRICES
 //SWAP WITH LIQUIDITY POOL
}
