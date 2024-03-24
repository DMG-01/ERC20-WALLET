//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import {CourseWinOrLose} from "chance/courseWinOrLose.sol";
import {NumberOfGoals} from "chance/numberOfGoals.sol";
import {HomeAwayDraw} from "chance/homeAwayDraw.sol";
contract Main {

address i_owner;
address[] public owners;
address[] public _courseWinOrLoseArray;
address[] public _numberOfGoalsArray;
address[] public _homeAwayDrawArray;
CourseWinOrLose courseWinOrLose;
NumberOfGoals numberOfGoals;
HomeAwayDraw homeAwayDraw;

constructor() {
    i_owner = msg.sender;
    owners.push(msg.sender);
}
/*********MAPPING */
// @dev CWOL represents Course Win or Lose which represents the name of the contract
// @dev NOG represents number of goals
//@dev HAD represents home away draw
 mapping(string => address) contractNameTo_CWOL;
 mapping(address => bool) _canStillBet;
 mapping(string => address) contractNameTo_NOG;
 mapping(string => address) contractNameTo_HAD;

/***************ERROR */
error onlyOwnerCanCallThisFunction();

/***********EVENTS */
event newOwnerHasBeenAdded(address _caller, address _newOwner);
event CWOL_ContractCreated(address _caller, string _contractName, address _contractAddress);
event NOG_ContractCreated(address _caller, string _contractName, address _contractAddress);
event HAD_ContractCreated(address _caller, string _contractName, address _contractAddress);

/************MODIFIERS */
modifier onlyOwner() {
    for(uint256 i = 0; i < owners.length; i++ ) {
        if(msg.sender != owners[i]) {
            revert onlyOwnerCanCallThisFunction();
        }
    }
    _;
}

//function to vote on who to add 
function addOwner(address _newOwnerMember) onlyOwner public {
     owners.push(_newOwnerMember);
     emit newOwnerHasBeenAdded(msg.sender, _newOwnerMember);
}
//difference between calldata and memory
function create_CWOL_contract(string  memory _name) public onlyOwner returns(string memory , address) {
    CourseWinOrLose _courseWinOrLose = new CourseWinOrLose(_name);
    contractNameTo_CWOL[_name] = address(_courseWinOrLose);
    _canStillBet[address(_courseWinOrLose)] = true ;
    _courseWinOrLoseArray.push(address(_courseWinOrLose));
    emit CWOL_ContractCreated(msg.sender, _name, address(_courseWinOrLose));
    return(_name, address(_courseWinOrLose));
} 

// NOG represents number of goals
function create_NOG_contract(string memory _name) public onlyOwner returns(string memory, address ) {
  NumberOfGoals _numberOfGoals = new NumberOfGoals(_name);
  contractNameTo_NOG[_name] = address(_numberOfGoals);
  _numberOfGoalsArray.push(address(_numberOfGoals));
  emit NOG_ContractCreated(msg.sender, _name, address(_numberOfGoals));
  return(_name, address(_numberOfGoals));
}

function create_HAD_contract(string memory _name) public onlyOwner returns(string memory, address) {
    HomeAwayDraw _homeAwayDraw = new HomeAwayDraw(_name);
    contractNameTo_HAD[_name] = address(_homeAwayDraw);
    _homeAwayDrawArray.push(address(_homeAwayDraw));
    emit HAD_ContractCreated(msg.sender, _name, address(_homeAwayDraw));
    return(_name, address(_homeAwayDraw));
}

//function to determine result

/*RETURN FUNCTION */ 
    function returnOnlyOwner() public view  returns(address[] memory){
        return(owners);
    }

    function returnCanStillBet( address _contractAddress) public view returns(bool) {
        return(_canStillBet[address(_contractAddress)]);
    }

    function returnFirstOwner() public view returns(address){
        return (i_owner);
    }
    uint256 number = 0;
    function addnumber() public view returns(uint256){
        uint256 newNumber =  number + 7;
        return newNumber;
    }
}