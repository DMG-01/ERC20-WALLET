//SPDX-License-Identifier:MIT

pragma solidity ^ 0.8.0;

contract NumberOfGoals {

    /************MAPPING  *****/
  mapping(address=>uint256)  userToNumberOfGoals;
  mapping(address => bool) userToHasBet;
  mapping(address => uint256) userToAmountBet;
  mapping(address => bool) lockGame;
  mapping(address => bool) owner;
  mapping(address => uint256) contractToNumberOfGoal;
  mapping(uint256 => uint256) numberOfGoalsToTotalAmountOfBet;
  mapping(address => bool) hasBeenPaid;
 
 /****************ERRORS */
 error youHaveAlreadyPlacedAbet();
 error gameHasBeenLocked();
 error noBetFound();
 error onlyOwnerCanCallThisFunction();
 error cantSetResultGameHasNotBeenLocked();
 error numberOfGoalUserBetOnIsInvalid();
 error thisUserHasBeenPaid();
error invalidAmountPassed();
/*************EVENTS */
event betAmountHasIncreased(address _caller, uint256 _newAmount);
event betHasBeenPlaced(address _caller,uint256 _numberOfGoals, uint256 amount);
event refundHasBeenMade(address _caller, uint256 _amountPaid);
event userHaveBeenPaid(address _caller, uint256 _amount );
event resultHasBeenPaid(address _caller, uint256 amount);
event newOwnerAdded(address _caller, address newOwner);
event protocolCutHasBeenSet(address _caller, uint256 _protocolCut);
event contractHasBeenLocked(address _caller, uint256 timeOfFunctionCall);

  /**********STATE VARIABLE****/
  uint256 totalAmountStaked;
  uint256 protocolCut;
  address i_owner;
  uint256 totalOneGoal;
  uint256 totalTwoGoal;
  uint256 totalThreeGoal;
  uint256 totalFourGoal;
  uint256 totalFiveGoal;
  uint256 otherNumber;
  string contractName;

  /*************MODIFIER */

  modifier isLocked() {
    if(lockGame[address(this)] == true) {
        revert gameHasBeenLocked();
    }
    _;
  }

  modifier onlyOwner() {
    if(owner[msg.sender] != true) {
        revert onlyOwnerCanCallThisFunction();
    }
    _;
  }
  
  constructor(string memory _name) {
    i_owner = msg.sender;
    contractName = _name;
    owner[msg.sender] = true;
  }

 // checks if user has already placed A bet
    function betNumberOfGoals(uint256 _numberOfGoal) public isLocked payable {
    if(userToHasBet[msg.sender] == true) {
        revert youHaveAlreadyPlacedAbet();
    }
    if(msg.value <= 0) {
      revert invalidAmountPassed();
    }
    totalAmountStaked += msg.value - ((protocolCut * msg.value)/100);
    userToHasBet[msg.sender] = true;
    userToNumberOfGoals[msg.sender] = _numberOfGoal;
    userToAmountBet[msg.sender] =  msg.value - ((protocolCut*msg.value)/100); 
    numberOfGoalsToTotalAmountOfBet[_numberOfGoal] += msg.value - ((protocolCut*msg.value)/100); 
    hasBeenPaid[msg.sender] = false;
    emit betHasBeenPlaced(msg.sender,_numberOfGoal, msg.value);
    }

    function addToBetAmount() public payable isLocked {
      if(userToHasBet[msg.sender] != true) {
        revert noBetFound();
      }
       totalAmountStaked +=  msg.value - ((protocolCut*msg.value)/100); 
       userToAmountBet[msg.sender] =  msg.value - ((protocolCut*msg.value)/100); 
       numberOfGoalsToTotalAmountOfBet[userToAmountBet[msg.sender]] +=  msg.value - ((protocolCut*msg.value)/100); 
       emit betAmountHasIncreased(msg.sender, userToAmountBet[msg.sender]);

    }

// modifier to make sure the game has been locked
    function refund() public isLocked {
     if(userToHasBet[msg.sender] != true) {
         revert noBetFound();
     } else {
     userToHasBet[msg.sender] = false;
     totalAmountStaked -= userToAmountBet[msg.sender];
     numberOfGoalsToTotalAmountOfBet[userToNumberOfGoals[msg.sender]] -= userToAmountBet[msg.sender];
     hasBeenPaid[msg.sender] = true;
     payable(msg.sender).transfer(userToAmountBet[msg.sender]);
     emit refundHasBeenMade(msg.sender, userToAmountBet[msg.sender]);
     }
    
    }


   function payOut() public  {
    
    if(userToHasBet[msg.sender] != true) {
      revert thisUserHasBeenPaid();
    }
    if((contractToNumberOfGoal[address(this)]) == (userToNumberOfGoals[msg.sender])) {
        hasBeenPaid[msg.sender] = true;
        userToHasBet[msg.sender] = false;
        //userToAmountBet[msg.sender] = 0;
        payable(msg.sender).transfer((userToAmountBet[msg.sender]*totalAmountStaked)/ numberOfGoalsToTotalAmountOfBet[userToNumberOfGoals[msg.sender]]);
        emit userHaveBeenPaid(msg.sender,(userToAmountBet[msg.sender]*totalAmountStaked)/ numberOfGoalsToTotalAmountOfBet[userToNumberOfGoals[msg.sender]] );
       
    }

   }

   function setResult(uint256 _result) onlyOwner public returns(uint256){
     if(lockGame[address(this)] != true) {
     revert cantSetResultGameHasNotBeenLocked();
     }
     contractToNumberOfGoal[address(this)] = _result;
     emit resultHasBeenPaid(msg.sender, _result);
     return (_result);
   }


   function setNewOwner(address _newOwner) public onlyOwner {
      owner[_newOwner] = true;
      emit newOwnerAdded(msg.sender, _newOwner);
   }

   function setProtocolCut(uint256 _protocolCut) public onlyOwner{
    protocolCut = _protocolCut;
    emit protocolCutHasBeenSet(msg.sender, _protocolCut);
   }

   function setLockGame() public onlyOwner {
    lockGame[address(this)] = true;
    emit contractHasBeenLocked(msg.sender, block.timestamp);
   }

   /***************RETURN FUNCTIONS */
   function returnContractName() public view returns(string memory ) {
    return contractName;
   }

   function returnUserAmountBet() public view returns(uint256) {
    return userToAmountBet[msg.sender];
   }
   function returnTotalAmount() public view returns(uint256) {
    return totalAmountStaked;
   }
   function returnUserToHasBet() public view returns(bool) {
    return userToHasBet[msg.sender];
   }
   function  numberOfGoalUserBetOn() public view returns(uint256) {
    return userToNumberOfGoals[msg.sender];
   }
   function returnNumberOfGoalsToTalAmountBet(uint256 _numberOfGoalToCheck) public view returns(uint256) {
    return numberOfGoalsToTotalAmountOfBet[_numberOfGoalToCheck];
   }
   function returnUserHasBeenPaid()  public view returns(bool){
    return hasBeenPaid[msg.sender];
   }
   function returnUserEtherBalance() public view returns(uint256) {
    return msg.sender.balance;
   }
}