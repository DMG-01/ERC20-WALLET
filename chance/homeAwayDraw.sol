//SPDX-License-Identifier:MIT

pragma solidity^0.8.0;

contract HomeAwayDraw {

    address i_owner;
    string contractName;
    uint256 protocolCut = 1;
    uint256 totalBetAmount;

    constructor(string memory _name) {
     i_owner = msg.sender;
     contractName = _name;
     addressToOwnership[msg.sender] = true;
    }

    /*********ERRORS */
    error onlyOwnerCanCallThisFunction();
    error youHaveAlreadyPlacedAbet();
    error userHasNotPlacedAbet();
    error gameHasBeenLocked();
    error cantSetResultGameHasNotBeenLocked();
    error userHasBeenPaid();
    error youDidNotWin();
    error amountCanNotBeZeroOrLessThanZero();
    error invalidAmountPassed();
    error noBetWasFound();

    /********* EVENTS*/
    event betAmountHasIncreased(address _caller, uint256 _newAmount);
    event newBetHasBeenPlaced(address user, State _userBetState, uint256 betAmount);
    event protocolCutHasBeenSet(address _functionCaller, uint256 _protocolCut);
    event newOwnerAdded(address functionCaller, address newOwner);
    event refundHasBeenMade(address _funcionCaller, uint256 amount);
    event resultHasBeenSet(address _functionCaller, State _state);
    event contractHasBeenLocked(address _functionCaller, uint256 timeOfFunctionCall);
    event userHaveBeenPaid(address _caller, uint256 _amount);
        /********MODIFIER */ 
    modifier onlyOwner() {
       if(addressToOwnership[msg.sender] != true) {
        revert onlyOwnerCanCallThisFunction();
       }
       _;
    }

    modifier HasBet() {
        if(hasBet[msg.sender] != true) {
            revert userHasNotPlacedAbet();
        }
        _;
    }

    modifier isLocked() {
        if(LockContract[address(this)] == true) {
            revert gameHasBeenLocked();
        }
        _;
    }

    modifier BeenPaid() {
        if(beenPaid[msg.sender] == true) {
        revert userHasBeenPaid();
        }
        _;
    }

    modifier notZeroOrLessThan(uint256 _amount) {
        if(_amount <= 0) {
            revert amountCanNotBeZeroOrLessThanZero();
        } 
        _;
    }
    
    /********MAPPING  */
    mapping(address => State) userToState;
    mapping(address => uint256) userToAmountBet;
    mapping(State => uint256) StateToTotalAmountBet;
    mapping(address => bool) addressToOwnership; 
    mapping(address => bool) hasBet;
    mapping(address => bool) LockContract;
    mapping(address => State) result;
    mapping(address => bool) beenPaid;
    mapping(address => bool) isOwner;

    enum State {
    home, 
    Away,
    Draw
    }

    function bet(State _state) payable public isLocked   {

        if(hasBet[msg.sender] == true) {
           revert youHaveAlreadyPlacedAbet();
        }

        if(msg.value <= 0) {
            revert invalidAmountPassed();
        }
     userToState[msg.sender] = _state;
     StateToTotalAmountBet[_state] += msg.value - ((protocolCut * msg.value)/100);
     userToAmountBet[msg.sender] += msg.value - ((protocolCut * msg.value)/100);
     totalBetAmount += msg.value - ((protocolCut * msg.value)/100);
     hasBet[msg.sender] = true;
     beenPaid[msg.sender] = false;
     emit newBetHasBeenPlaced(msg.sender,_state,userToAmountBet[msg.sender]);
    }

    function addToBet() payable public HasBet isLocked  {

        if(msg.value <= 0) {
            revert invalidAmountPassed();
        }
      userToAmountBet[msg.sender] +=  msg.value - ((protocolCut * msg.value)/100);
      StateToTotalAmountBet[userToState[msg.sender]] += msg.value - ((protocolCut * msg.value)/100);
      totalBetAmount += msg.value - ((protocolCut * msg.value)/100);
      emit betAmountHasIncreased( msg.sender,userToAmountBet[msg.sender]); 
    }

    function refund() public payable BeenPaid isLocked{
        if(hasBet[msg.sender] != true) {
            revert noBetWasFound();
        }
      StateToTotalAmountBet[userToState[msg.sender]] -= userToAmountBet[msg.sender];
      hasBet[msg.sender] = false;
      beenPaid[msg.sender] = true;
      payable(msg.sender).transfer(userToAmountBet[msg.sender]);
      emit refundHasBeenMade(msg.sender,userToAmountBet[msg.sender]);
    }

    function payOut() public  BeenPaid {
        if(hasBet[msg.sender] != true) {
            revert noBetWasFound();
        }
       if((result[address(this)]) == (userToState[msg.sender])) {
          //userToAmountBet[msg.sender] = 0;
          hasBet[msg.sender] = false;
          beenPaid[msg.sender] = true;
          payable(msg.sender).transfer((userToAmountBet[msg.sender] * totalBetAmount) / StateToTotalAmountBet[userToState[msg.sender]]);
          emit userHaveBeenPaid(msg.sender, (userToAmountBet[msg.sender] * totalBetAmount) / StateToTotalAmountBet[userToState[msg.sender]]); 
       }
       else{
        revert youDidNotWin();
       }
    }

    function setResult(State _resultState) public onlyOwner returns(State) {
        if(LockContract[address(this)] != true) {
            revert cantSetResultGameHasNotBeenLocked();
        }
     result[address(this)] = _resultState;
     emit resultHasBeenSet(msg.sender, _resultState);
     return(_resultState);
    }

    function setProtocolCut(uint256 _protocolCut) public onlyOwner {
     protocolCut = _protocolCut;
     emit protocolCutHasBeenSet(msg.sender, _protocolCut);
    }

    function addNewOwner(address _newOwner) public onlyOwner {
     addressToOwnership[_newOwner] = true;
     emit newOwnerAdded(msg.sender, _newOwner);
    }
   
    function lockContract() public  onlyOwner {
        LockContract[address(this)] = true;
        emit contractHasBeenLocked( msg.sender,block.timestamp); 
    }
  
   /******************RETURN FUNCTIONS */

   function returnHasUserBet() public view returns(bool) {
    return(hasBet[msg.sender]);
   }

   function returnUserBetState() public view returns(State) {
    return (userToState[msg.sender]);
   }

   function returnTotalAmountBet() public view returns(uint256) {
    return (totalBetAmount);
   }

   function returnStateTotalAmountBet(State _stateToCheck) public view returns(uint256) {
    return (StateToTotalAmountBet[_stateToCheck]);
   }
     
    function returnUserBetAmount() public view returns(uint256) {
        return (userToAmountBet[msg.sender]);
    }
    function returnUserPaidState() public view returns(bool) {
        return (beenPaid[msg.sender]);
    }
    function returnUserEtherBalance() public view returns(uint256) {
        return (msg.sender.balance);
    }
    function returnResult() view  public returns(State) {
        return(result[address(this)]);
    }

    function returnProtocolCut() public view returns(uint256) {
        return protocolCut;
    }
     
     function checkIfAddressIsOwner(address _addressToCheck) view public returns(bool) {
        return (addressToOwnership[_addressToCheck]);
     }
}
