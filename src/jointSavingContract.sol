//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

/* an owner creates the contract
* the owner sets the parameter e.g 
  * time before money is distributed
  * amount to be saved per interval
  * addresses of co savers
  * token to save with
* condition to remove defaulters automatically
*co savers can opt out by themselves after they have saved for that round 
* vote is done before any parameter can be changed
*/

import {Wallet} from "src/walletToken.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract GroupSaving{

    /*    ERRORS */
error onlyOwnerCanCallThisFunction();    
error prametersCanOnlyBeSetOnce();
error alreadyAMember();
error cantJoinSavingIsOngoing();
error numberOfParticipantNotComplete();
error InsufficientBalance();
error savingFailed();
error transferFailed();
error notAMember();

      /*EVENTS */
event contributionDeducted(address saver, uint256 amount);
event rotationSavingHasCommenced();


Wallet wallet;
address immutable owner;
uint256  numberOfParticipant;
address  tokenAddress;
uint256 contributionPeriod;
uint256 timeForEachRotation;
uint256 contributionAmountPerPeriod;
uint256 numberOfRotation = savers.length;
bool isSavingOngoing = false;
uint256 expectedAmount; 
uint256 totalAmountExpected = numberOfParticipant * contributionAmountPerPeriod;

mapping(address => bool) saved;

modifier onlyOwner() {
    if (msg.sender != owner){
        revert onlyOwnerCanCallThisFunction();
    }
    _;
} 

modifier member() {
    for (uint256 index = 0; index< savers.length; index++) {
         if(msg.sender != savers[index]) {
            revert notAMember();
         }
    }
    _;
}
 
 constructor() {
owner = msg.sender;
}

uint8 initialParameterCount = 0;
address[] savers;
address[] defaulters;

// function for owner to set the initial parameter
function setInitialParameter(uint256 _numberOfParticipant, address _tokenAddress, uint256 _contributionPeriod,uint256 _amountPerPeriod, uint256 _timeForEachRotation) onlyOwner public  {
 if(initialParameterCount != 0){
    revert prametersCanOnlyBeSetOnce();
 }
 initialParameterCount = 0;
 numberOfParticipant = _numberOfParticipant;
 tokenAddress = _tokenAddress;
 contributionPeriod = _contributionPeriod;
 contributionAmountPerPeriod = _amountPerPeriod;
 timeForEachRotation =_timeForEachRotation;
 saved[msg.sender] = false;
 savers.push(msg.sender);
}

function eligibility() internal {

}
function getExpectedAmount() public returns(uint256) {
 expectedAmount = contributionAmountPerPeriod * savers.length;
return (expectedAmount);
}


function join() public  {
    if( isSavingOngoing == true) {
        revert cantJoinSavingIsOngoing();
    }
    else if(wallet.getUserTokenBalance(tokenAddress) < totalAmountExpected)  {
        revert InsufficientBalance();
    }
    else {
 for (uint256 index = 0; index < savers.length; index++) {
    if (msg.sender == savers[index]){
        revert alreadyAMember();
    }
 }
 savers.push(msg.sender);
 saved[msg.sender] = false;
    }
}

function pay() public member {
     if(isSavingOngoing != true) {
        revert cantJoinSavingIsOngoing();
     }
   bool success = IERC20(tokenAddress).transferFrom(msg.sender,address(this), contributionAmountPerPeriod);
   emit contributionDeducted(msg.sender, contributionAmountPerPeriod);
   saved[msg.sender] = true;
   if(!success) {
    revert transferFailed();
   }
}



//allow each member to pay themselves
//whosoever hasnt paid in the time frame would be kicked out

// check if initial number of savers are met up before starting
function startRotationSaving() public member {
if (savers.length != numberOfParticipant){
    revert numberOfParticipantNotComplete();
} 
//loop all the rotation
// loop each rotation
//uint256 startime = block.timestamp;
emit rotationSavingHasCommenced();
uint256 rotationCount = 0;
uint256 perRotationStartTime = 0;
uint256 perRotationEndTime = perRotationStartTime + timeForEachRotation;
isSavingOngoing = true;

while (rotationCount <= numberOfRotation) {
       
       if(block.timestamp > perRotationEndTime)  {

        for (uint256 index = 0; index < savers.length; index++ ) {
        if(saved[savers[index]] == false) {
            if(wallet.getUserTokenBalance(tokenAddress) < (numberOfParticipant * savers.length)) {
        defaulters.push(savers[index]);
        savers[index] = savers[savers.length - 1];
        savers.pop();
        }
    } else {
        IERC20(tokenAddress).transferFrom(savers[index], address(this), contributionAmountPerPeriod);
    }
        }
    perRotationStartTime = block.timestamp;
    perRotationEndTime  = perRotationStartTime + timeForEachRotation;
    rotationCount++;
    for(uint256 index = 0; index < savers.length; index++) {
        saved[savers[index]] = false; 
    }
       }
    
}

isSavingOngoing = false;
}

// functions for users to vote on a set of parameter after each round 



}