//SPDX-License-Identifier:MIT

pragma solidity ^ 0.8.18;
import {Test, console} from "lib/forge-std/src/Test.sol";
import {Main} from "chance/mainContract.sol";
import {CourseWinOrLose} from "chance/courseWinOrLose.sol";
import {HomeAwayDraw} from "chance/homeAwayDraw.sol";
import {NumberOfGoals} from "chance/numberOfGoals.sol";
import {DeployScript} from "script/deployScript.s.sol";

contract MainTest is Test{

Main mainContract;
CourseWinOrLose courseWinOrLose;
HomeAwayDraw homeAwayDraw;
NumberOfGoals numberOfGoals;
DeployScript deployer;


address USER1 = makeAddr("USER1");
address USER2 = makeAddr("USER2");
address INITIAL_DEPLOYER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

string ICEwinsbioChem;
string ICEScores5goals;
string ICEHAD;

address CWOLAddress;
string CWOLName;


uint256 BET_AMOUNT = 5 ether;
uint256 STARTING_ETHER_BALANCE = 10 ether;

/************MODIFIER */
modifier initiateCWOL() {
    vm.startPrank(INITIAL_DEPLOYER);
    (string memory __contractName, address __contractWOLAddress) = mainContract.create_CWOL_contract(ICEwinsbioChem);
    CWOLAddress = __contractWOLAddress;
    CWOLName = __contractName;
    vm.stopPrank();
    _;
}

function setUp() public {
    deployer = new DeployScript();
    (mainContract,courseWinOrLose,homeAwayDraw,numberOfGoals) = deployer.run();
    vm.deal(USER1, STARTING_ETHER_BALANCE);
}
/*
function testDeployerIsFirstOwner() public {
   // vm.startPrank(USER1);
    deployer = new DeployScript();
    (mainContract,,,) = deployer.run();
    address actualAddress= mainContract.returnFirstOwner();
   //vm.stopPrank();
   assertEq(actualAddress,USER1);
}
*/

function testReturnDeployer() view public {
    address addressDeployer = mainContract.returnFirstOwner();
    mainContract.returnLengthOfOwnersArray();
    console.log(addressDeployer);
    console.log(mainContract.returnLengthOfOwnersArray());
}

function testaddOwnerRevertsWithWrongCaller() public {
    vm.startPrank(USER1);
    vm.expectRevert(Main.onlyOwnerCanCallThisFunction.selector);
    mainContract.addOwner(USER2);
}

function testAddOwnerWorks() public {
    vm.startPrank(INITIAL_DEPLOYER);
    mainContract.addOwner(USER1);
    assertEq(mainContract.returnLengthOfOwnersArray(), 2);
}

function testAddTwoOnwersWork() public {
    vm.prank(INITIAL_DEPLOYER);
    mainContract.addOwner(USER1);
    vm.prank(USER1);
    mainContract.addOwner(USER2);
    uint256 actualLength = mainContract.returnLengthOfOwnersArray();
    assertEq(actualLength, 3);
}

function testcreate_CWOL_contractWorks() public {
vm.startPrank(INITIAL_DEPLOYER);
mainContract.create_CWOL_contract(ICEwinsbioChem);
uint256 newLength = mainContract.returnLengthOfCWOL();
assertEq(newLength,1);
}

function testCWOLNameCorrespondsToAddress() public {
vm.startPrank(INITIAL_DEPLOYER);
(string memory __name, address __contractAddress) = mainContract.create_CWOL_contract(ICEwinsbioChem);
assertEq(__contractAddress,mainContract.returnCWOL_name(__name));
}

function testCreate_NOG_contractWorks()public {
vm.startPrank(INITIAL_DEPLOYER);
mainContract.create_NOG_contract(ICEScores5goals);
uint256 newLength = mainContract.returnNOGLength();
assertEq(newLength, 1);
}

function testNOGNameCorrespondsToAddress() public {
    vm.startPrank(INITIAL_DEPLOYER);
    (string memory __name, address __contractAddress) = mainContract.create_NOG_contract(ICEScores5goals);
    assertEq(__contractAddress, mainContract.returnNOG_name(__name));
}

function testCreate_HAD_contractWorks()public {
vm.startPrank(INITIAL_DEPLOYER);
mainContract.create_HAD_contract(ICEHAD);
uint256 newLength = mainContract.returnHADLength();
assertEq(newLength, 1);
}

function testHADNameCorrespondsToAddress() public {
    vm.startPrank(INITIAL_DEPLOYER);
    (string memory __name, address __contractAddress) = mainContract.create_HAD_contract(ICEScores5goals);
    assertEq(__contractAddress, mainContract.returnHAD_name(__name));
}

function testCanRemoveOwner() public {
    vm.startPrank(INITIAL_DEPLOYER);
    mainContract.addOwner(USER1);
    mainContract.removeOwner(USER1);
    assertEq(false, mainContract.checkIsOwner(USER1));
}

function testCantRemoveInitialDeployer() public {
    vm.prank(INITIAL_DEPLOYER);
    mainContract.addOwner(USER1);
    vm.prank(USER1);
    vm.expectRevert(Main.youCantRemoveThisUser.selector);
    mainContract.removeOwner(INITIAL_DEPLOYER);
}
function testCWOLNameCorrespondsWithContractName() initiateCWOL public  {
    vm.startPrank(INITIAL_DEPLOYER);
    (string memory __contractName, address __contractWOLAddress) = mainContract.create_CWOL_contract(ICEwinsbioChem);
    CWOLAddress = __contractWOLAddress;
    CWOLName = __contractName;
    console.log(courseWinOrLose.returnContractName());
    console.log(__contractName);
}

function testCWOLBetWorks() public initiateCWOL{
     vm.startPrank(USER1);
     courseWinOrLose.bet{value:BET_AMOUNT}(true);
     bool hasBet = courseWinOrLose.hasUserBet();
     assertEq(hasBet, true);
} 
}