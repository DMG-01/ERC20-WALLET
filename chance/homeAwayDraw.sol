//SPDX-License-Identifier:MIT

pragma solidity^0.8.0;

contract HomeAwayDraw {

    address i_owner;
    string contractName;
    uint256 protocolCut;
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
        if(LockContract[msg.sender] == true) {
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

    enum State {
    home, 
    Away,
    Draw
    }

    function bet(State _state) payable public isLocked   {

        if(hasBet[msg.sender] == true) {
           revert youHaveAlreadyPlacedAbet();
        }
     userToState[msg.sender] = _state;
     StateToTotalAmountBet[_state] += msg.value - ((protocolCut/100)*msg.value); 
     userToAmountBet[msg.sender] += msg.value - ((protocolCut/100)*msg.value);
     totalBetAmount += msg.value - ((protocolCut/100)*msg.value);
     hasBet[msg.sender] = true;
     beenPaid[msg.sender] = false;
     emit newBetHasBeenPlaced(msg.sender,_state,userToAmountBet[msg.sender]);
    }

    function addToBet() payable public HasBet isLocked notZeroOrLessThan(msg.value) {
      userToAmountBet[msg.sender] +=  msg.value - ((protocolCut/100)*msg.value);
      StateToTotalAmountBet[userToState[msg.sender]] += msg.value - ((protocolCut/100)*msg.value);
      totalBetAmount += msg.value - ((protocolCut/100)*msg.value);
      emit betAmountHasIncreased( msg.sender,userToAmountBet[msg.sender]); 
    }

    function refund() public payable HasBet BeenPaid isLocked{
      State userStateBet = userToState[msg.sender];
      StateToTotalAmountBet[userStateBet] -= userToAmountBet[msg.sender];
      userToAmountBet[msg.sender] = 0;
      hasBet[msg.sender] = false;
      beenPaid[msg.sender] = true;
      payable(address(this)).transfer(userToAmountBet[msg.sender]);
      emit refundHasBeenMade(msg.sender,userToAmountBet[msg.sender]);
    }

    function payOut() public HasBet BeenPaid {
       if((result[address(this)]) == (userToState[msg.sender])) {
          userToAmountBet[msg.sender] = 0;
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
        if(LockContract[msg.sender] != true) {
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



}
