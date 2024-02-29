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



contract GroupSaving{

    /*    ERRORS */
error onlyOwnerCanCallThisFunction();    
error prametersCanOnlyBeSetOnce();
error alreadyAMember();
error cantJoinSavingIsOngoing();
error numberOfParticipantNotComplete();

address immutable owner;
uint256  numberOfParticipant;
address  tokenAddress;
uint256 contributionPeriod;
uint256 contributionAmountPerPeriod;
uint256 numberOfRotation;
bool isSavingOngoing = false;
uint256 expectedAmount; 

modifier onlyOwner() {
    if (msg.sender != owner){
        revert onlyOwnerCanCallThisFunction();
    }
    _;
} 
 
 constructor() {
owner = msg.sender;
}

uint8 initialParameterCount = 0;
address[] savers;

// function for owner to set the initial parameter
function setInitialParameter(uint256 _numberOfParticipant, address _tokenAddress, uint256 _contributionPeriod,uint256 _amountPerPeriod) onlyOwner public  {
 if(initialParameterCount != 0){
    revert prametersCanOnlyBeSetOnce();
 }
 initialParameterCount = 0;
 numberOfParticipant = _numberOfParticipant;
 tokenAddress = _tokenAddress;
 contributionPeriod = _contributionPeriod;
 contributionAmountPerPeriod = _amountPerPeriod;
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
    else {
 for (uint256 index = 0; index < savers.length; index++) {
    if (msg.sender == savers[index]){
        revert alreadyAMember();
    }
 }
 savers.push(msg.sender);
    }
}

// check if initial number of savers are met up before starting
function startRotationSaving() public  {
    if(numberOfParticipant != savers.length) {
      revert numberOfParticipantNotComplete();
    }
uint256 timeInterval = block.timestamp + contributionPeriod;
while (block.timestamp < timeInterval)
    for(uint256 index = 0; index<savers.length; index++ ) {

    
}

}
// functions for users to vote on a set of parameter after each round 



}