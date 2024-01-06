//SPDX-License-Identifier:MIT
// code allows user to put their token in the contract as a wallet and trade them p2p
// this is a wallet that allows use to have multiple ERC20 token and they can send,lock and even swap tokens p2p
pragma solidity ^0.8.0;
//standard ERC20 token is being installed from openZeppelin
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Wallet {
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


function signer() public {}

function generateAddressAndPrivateKey() public {}
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
function fundAccount(address token, uint256 amount) public moreThanZero(amount)  returns(bool) {
      require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
     // IERC20(token).approve(address(this), amount);
      addressToTokenBalance[msg.sender][token] += amount;
      bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
      emit accountFunded(msg.sender,token,amount);
      if(!success) {
      revert fundAccountFailed();
    }else {
  return true;
 } 
}

function withdraw(address token, uint256 amount) public moreThanZero(amount) /*isAllowedToken(token)*/ returns(bool){
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

function getUserTokenBalance(address token) public /*isAllowedToken(token)*/ view returns(uint256) {
    uint256 tokenBalance = addressToTokenBalance[msg.sender][token];
    return tokenBalance;
}
function lockTokens(address tokenToLock, uint256 amountToLock, uint256 timeLock) moreThanZero(amountToLock) /*isAllowedToken(tokenToLock)*/ public {
    if(amountToLock > addressToTokenBalance[msg.sender][tokenToLock]){
        revert InsufficientBalance();
    }else {
        addressToTokenBalance[msg.sender][tokenToLock] -= amountToLock;
        addresstoTokenLocked[msg.sender][tokenToLock] += amountToLock;
        addresstoTokenLockedTime[msg.sender][tokenToLock] = block.timestamp + timeLock;
     
    }
}
function getUserLockTokenBalance(address token) public view returns(uint256) {
  if(addresstoTokenLocked[msg.sender][token] == 0){
    return 0;
  }else {
  return(addresstoTokenLocked[msg.sender][token]);
}
}
//remove from locked mapping
//add to contract wallet
// add REENTRANCY
function withdrawLockedTokens(address tokenToWithdraw)  public /*isAllowedToken(tokenToWithdraw) */ {
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
function swapTokens(uint256 callerAmount, uint256 userTwoAmount, address callerTokenAddress,address userTwoTokenAddress, address userTwo) public {
emit swapTokenFunctionHasBeenInitiated(msg.sender,userTwo,callerAmount,userTwoAmount,callerTokenAddress,userTwoTokenAddress);
uint256 timeOfFunctionCall = block.timestamp;
if( _secondUserConfirmTransaction(1,userTwo)) {
addressToTokenBalance[msg.sender][callerTokenAddress] -= callerAmount;
addressToTokenBalance[userTwo][userTwoTokenAddress] -= userTwoAmount;
addressToTokenBalance[msg.sender][userTwoTokenAddress] += userTwoAmount;
addressToTokenBalance[userTwo][callerTokenAddress] += callerAmount;
addressToTokenIn[msg.sender][userTwoTokenAddress] += userTwoAmount;
addressToTokenOut[msg.sender][callerTokenAddress] += callerAmount;
emit tokenSwapSuccessful(msg.sender,userTwo,callerAmount,userTwoAmount,callerTokenAddress,userTwoTokenAddress);

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
SpendingLimit(tokenAddress,amount);
IERC20(tokenAddress).approve(address(this),amount);
bool _sendTokenSuccessful = IERC20(tokenAddress).transferFrom(msg.sender,recepient,amount);
if(!_sendTokenSuccessful) {
  revert sendTokenFailed();
}else {
 return true;
}
}

function createBudget() public {}
/*
function addTokenAndTokenPriceFeedAddress(address _tokenAddress, address _tokenPriceFeedAddress) public  {
tokenPriceFeedAddresses.push(_tokenPriceFeedAddress);
tokenAddresses.push(_tokenAddress);
}
*/
function SpendingLimit(address tokenAddress,uint256 amount) public {
(uint256 tokenLimit) = _addToDailySpendingLimit(tokenAddress,amount);
if (amount > tokenLimit) {
  revert amountHasExceededLimit();
}
}

function _addToDailySpendingLimit(address tokenAddress, uint256 amount) internal onlyOwner returns(uint256){
uint256 tokenLimit = addressToTokenLimit[msg.sender][tokenAddress] = amount;
return tokenLimit;
}

function getTokenAmountInUsd(address token, uint256 Amount) isAllowedToken(token) public view returns(uint256){
AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenAddressToPriceFeedAddress[token]);
(,int256 price,,,) = priceFeed.latestRoundData();
return ((uint256 (price) * ADDITIONAL_FEED_PRECISION) * Amount)/PRECISION;

}

function sendEther(address payable recepient) payable public {
  recepient.transfer(msg.value);
emit etherHasBeenTransfered(recepient,msg.value,block.timestamp);
}


function getUserEtherBalance() public view returns(uint256) {
  return msg.sender.balance;
}

function getToTalInAndOutOfToken(address token) public view returns(uint256, uint256) {
 uint256 totalIn = addressToTokenIn[msg.sender][token];
 uint256 totalOut = addressToTokenOut[msg.sender][token];
 return(totalIn,totalOut);
}
}
