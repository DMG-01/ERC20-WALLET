//SPDX-License-Identifier: MIT
//create a function to remove our charges

pragma solidity ^0.8.0;
//why am i makeing it abstract
//import {Main} from "chance/mainContract.sol; 


 contract CourseWinOrLose {
     


     /**ERRORS */
     error onlyMainOwnerCanCallThisFunction();
     error cantSetResultUsersCanStillBet();
     error youCantWithdraw();
     error youHaveAlreadyPlacedAbet();
     error noBetWasFound();
     error thisContractHasBeenLocked();
     error userHasBeenPaid();
     error invalidAmountPassed();


     /*****EVENTS */
     event betHasBeenPlaced(address _caller, uint256 amount, bool forOrAgainst);
     event betAmountHasBeenIncreased(address _caller, uint256 _newAmount);
     event payOutHasBeenMade(address _caller, uint256 _amount);
     event resultHasBeenSet(address _caller,bool _result);
     event protocolCutHasBeenChanged(address _caller, uint256 _protocolCut);
     event newOwnerHasBeenAdded(address _caller, address _newOwner);
     event refundHasBeenMade(address _caller, uint256 amount);
     event contractHasBeenLocked(address _caller, uint256 timeOfLock);

    constructor(string memory _name) {
    contractName = _name;
    owner = msg.sender;
    addressToOwner[msg.sender] = true;
    }
    // Main main;
     address owner;
     string contractName ;
     bool contractBet;
     uint256 _totalBetFor;
     uint256 _totalBetAgainst;
     uint256 total;
     uint256 protocolCut = 1;

    //
     address[] _addressesBetFor;
     address[] _addressesBetAgainst;
     
    mapping(address => bool) usersToBet;
    mapping(address => uint256) addressToAmountPlaced;
    mapping(address => bool) thisContractToResult;
    mapping(address => bool) addressToHasUserBet;
    mapping(address => bool) addressToOwner;
    mapping(address => bool) thisContractToLock;
    mapping(address => bool) hasBeenPaid;
    
    /**MODIFIER */
    modifier onlyMainOwners() {
    if(addressToOwner[msg.sender] != true ) {
     revert onlyMainOwnerCanCallThisFunction();
    }
        _;
    }

    modifier hasContractBeenLocked() {
        if(thisContractToLock[address(this)] == true) {
            revert thisContractHasBeenLocked();
        }
        _;
    }

    modifier _hasBeenPaid() {
        if(hasBeenPaid[msg.sender] == true) {
            revert userHasBeenPaid();
        }
        _;
    }

// meant to check if users can still bet
    function bet(bool _bet) payable public hasContractBeenLocked {
    if(addressToHasUserBet[msg.sender] == true) {
        revert youHaveAlreadyPlacedAbet();
    }

    // Ensure that protocolCut is not zero to prevent division by zero
    require(protocolCut != 0, "Protocol cut should not be zero");

    // Calculate the bet amount after subtracting the protocol cut
    uint256 betAmount = msg.value - ((protocolCut * msg.value) / 100);
    total += betAmount;

    if(_bet == true) {
        _totalBetFor += betAmount;
        _addressesBetFor.push(msg.sender);
        addressToAmountPlaced[msg.sender] = betAmount;
        emit betHasBeenPlaced(msg.sender, betAmount, true);
    } else {
        _totalBetAgainst += betAmount;
        _addressesBetAgainst.push(msg.sender);
        emit betHasBeenPlaced(msg.sender, betAmount, false);
    }

    // Mark the user as having placed a bet
    usersToBet[msg.sender] = _bet;
    addressToHasUserBet[msg.sender] = true;
}

function addToBet() public payable hasContractBeenLocked {
        if(msg.value <= 0) {
            revert invalidAmountPassed();
        }
        if(addressToHasUserBet[msg.sender]== false) {
            revert noBetWasFound();
        }
        addressToAmountPlaced[msg.sender] += msg.value - ((protocolCut * msg.value)/100);
        total += msg.value - ((protocolCut * msg.value)/100);

        if(usersToBet[msg.sender] == true) {
            _totalBetFor += msg.value - ((protocolCut * msg.value)/100);
        }
        else {
            _totalBetAgainst += msg.value - ((protocolCut * msg.value)/100);
        }
        emit betAmountHasBeenIncreased(msg.sender, addressToAmountPlaced[msg.sender]);
    } 

//anyone can decide to pay out, maybe??
function payOut() payable public _hasBeenPaid {
    if(addressToHasUserBet[msg.sender] == true) {
    if( (thisContractToResult[address(this)] == true) && (usersToBet[msg.sender] = true)){
        hasBeenPaid[msg.sender] = true;
        payable(msg.sender).transfer(((addressToAmountPlaced[msg.sender])* total )/_totalBetFor);
        emit payOutHasBeenMade(msg.sender, ((addressToAmountPlaced[msg.sender])* total )/_totalBetFor);
       
    } else {
        revert youCantWithdraw();//change to you cant withdraw
    }
    }else {
        revert noBetWasFound();
    }
}
    
//function to set the result 
// two check to see if the contract is locked 
function setResult(bool _result) public onlyMainOwners returns(bool){
if(thisContractToLock[address(this)] == false){
revert cantSetResultUsersCanStillBet();
} else 
thisContractToResult[address(this)] = _result;
emit resultHasBeenSet(msg.sender, _result);
return(_result);
}

function changeProtocolCut(uint256 _protocolCut) public onlyMainOwners {
protocolCut = _protocolCut;
emit protocolCutHasBeenChanged(msg.sender, _protocolCut);
}

function addOwner(address _owner) public onlyMainOwners {
addressToOwner[_owner] = true ;
emit newOwnerHasBeenAdded(msg.sender, _owner);
}

function refund() payable public hasContractBeenLocked  _hasBeenPaid {
    if(addressToHasUserBet[msg.sender] != true) {
        revert noBetWasFound();
    }
    if(usersToBet[msg.sender] == true) {
        _totalBetFor -= addressToAmountPlaced[msg.sender];
    } else if(usersToBet[msg.sender] == false){
        _totalBetAgainst -= addressToAmountPlaced[msg.sender];
    }
 
    addressToHasUserBet[msg.sender] = false;
    hasBeenPaid[msg.sender] = true;
    payable(msg.sender).transfer(addressToAmountPlaced[msg.sender]);
    emit refundHasBeenMade(msg.sender, addressToAmountPlaced[msg.sender]);
}

function lockContract() payable public onlyMainOwners {
    thisContractToLock[address(this)] = true;
    emit contractHasBeenLocked(msg.sender, block.timestamp);
}

/*******************RETURN FUNCTIONS  */
function returnContractName() public view returns(string memory ){
return(contractName);
}

function hasUserBet() public view returns(bool) {
 return(addressToHasUserBet[msg.sender]);
}

function returnTotalBetFor() public view returns(uint256) {
    return(_totalBetFor);
}
function returnTotalBetAgainst() public view returns(uint256) {
    return(_totalBetAgainst);
}
function returnTotalBet() public view returns(uint256) {
    return(total);
}
function returnUserAmountPlaced() public view returns(uint256) {
    return(addressToAmountPlaced[msg.sender]);
}
function returnUserEtherBalance() public view returns(uint256) {
    return (msg.sender.balance);
}
function returnResult() public view returns(bool) {
    return(thisContractToResult[address(this)]);
}
function returnProtocolCut() public view returns(uint256) {
    return(protocolCut);
}
function returnIsOwner() public view returns(bool) {
    return(addressToOwner[msg.sender]);
}
}


 