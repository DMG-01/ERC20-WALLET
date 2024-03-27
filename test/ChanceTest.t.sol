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
address USER3 = makeAddr("USER3");
address USER4 = makeAddr("USER4");
address USER5 = makeAddr("USER5");
address INITIAL_DEPLOYER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

string ICEwinsbioChem = "ICEWinsbioChem";
string ICEScores5goals;
string ICEHAD;

address CWOLAddress;
string CWOLName;


uint256 BET_AMOUNT = 5 ether;
uint256 USER2_BET_AMOUNT = 3 ether;
uint256 USER3_BET_AMOUNT = 7 ether;
uint256 USER4_BET_AMOUNT = 9 ether;
uint256 USER5_BET_AMOUNT = 6 ether;
uint256 STARTING_ETHER_BALANCE = 10 ether;

/************MODIFIER */
modifier initiateCWOLAndSetResult() {
     vm.startPrank(INITIAL_DEPLOYER);
    mainContract.create_CWOL_contract(ICEwinsbioChem);
    courseWinOrLose.lockContract();
    courseWinOrLose.setResult(true);
    _;
}

modifier simulateBetFor() {
    vm.startPrank(USER2);
    vm.deal(USER2,STARTING_ETHER_BALANCE);
    courseWinOrLose.bet{value:USER2_BET_AMOUNT}(true);
    vm.stopPrank();
    vm.startPrank(USER3);
    vm.deal(USER3,STARTING_ETHER_BALANCE);
    courseWinOrLose.bet{value:USER3_BET_AMOUNT}(true);
    _;
}
modifier simulateBetAgainst() {
    vm.startPrank(USER4);
    vm.deal(USER4, STARTING_ETHER_BALANCE);
    courseWinOrLose.bet{value:USER4_BET_AMOUNT}(false);
    vm.stopPrank();
    vm.startPrank(USER5);
    vm.deal(USER5,STARTING_ETHER_BALANCE);
    courseWinOrLose.bet{value:USER5_BET_AMOUNT}(false);
    _;
}
modifier initiateCWOL() {
    vm.startPrank(INITIAL_DEPLOYER);
    (string memory __contractName, address __contractWOLAddress) = mainContract.create_CWOL_contract(ICEwinsbioChem);
    CWOLAddress = __contractWOLAddress;
    CWOLName = __contractName;
    vm.stopPrank();
    _;
}

modifier betPlacedFor() {
     vm.startPrank(USER1);
     courseWinOrLose.bet{value:BET_AMOUNT}(true);
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

function testReturnsActualContractString() public initiateCWOL{
string memory expectedName = courseWinOrLose.returnContractName();
assertEq(expectedName,ICEwinsbioChem);
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
function testBettingTwiceReverts() public betPlacedFor {
vm.startPrank(USER1);
vm.expectRevert(CourseWinOrLose.youHaveAlreadyPlacedAbet.selector);
courseWinOrLose.bet{value:BET_AMOUNT}(true);
}

function testBetAmountWorksAsItShould() public betPlacedFor {
    vm.startPrank(USER1);
    uint256 expectedAmountPlaced = 4.95 ether;
    uint256 actualAmount = courseWinOrLose.returnUserAmountPlaced();
    assertEq(expectedAmountPlaced,actualAmount);
    assertEq(expectedAmountPlaced, courseWinOrLose.returnTotalBetFor());
    assertEq(0,courseWinOrLose.returnTotalBetAgainst());
    assertEq(expectedAmountPlaced, courseWinOrLose.returnTotalBet());
}

function testBetAmountWorksAsItShould2() public betPlacedFor simulateBetFor {
    vm.startPrank(USER1);
    uint256 expectedAmountPlaced = 4.95 ether;
    uint256 actualAmount = courseWinOrLose.returnUserAmountPlaced();
    uint256 expectedTotalAmount = 14.85 ether;
    assertEq(expectedTotalAmount, courseWinOrLose.returnTotalBet());
    assertEq(expectedTotalAmount, courseWinOrLose.returnTotalBetFor());
    assertEq(0,courseWinOrLose.returnTotalBetAgainst());
    assertEq(expectedAmountPlaced,actualAmount);
}

function testBetWorksAsItShouldBe() public betPlacedFor simulateBetAgainst simulateBetFor {
    vm.startPrank(USER1);
    uint256 expectedAmountPlaced = 4950000000000000000; // Convert 4.95 ether to wei
    uint256 actualAmount = courseWinOrLose.returnUserAmountPlaced();
    uint256 expectedTotalAmount = 29700000000000000000; // Convert 29.7 ether to wei
    uint256 actualTotalAmount = courseWinOrLose.returnTotalBet();
    uint256 expectedTotalBetFor = 14850000000000000000; // Convert 14.85 ether to wei
    uint256 actualTotalBetFor = courseWinOrLose.returnTotalBetFor();
    uint256 expectedTotalBetAgainst = 14850000000000000000; // Convert 14.85 ether to wei
    uint256 actualTotalBetAgainst = courseWinOrLose.returnTotalBetAgainst();

    assertEq(expectedAmountPlaced, actualAmount);
    assertEq(expectedTotalAmount, actualTotalAmount);
    assertEq(expectedTotalBetFor, actualTotalBetFor);
    assertEq(expectedTotalBetAgainst, actualTotalBetAgainst);
}

function testAddToBet() public betPlacedFor {
    vm.startPrank(USER1);
    courseWinOrLose.addToBet{value:3 ether}();
    uint256 expectedAmount = 7920000000000000000;
    uint256 actualAmount = courseWinOrLose.returnTotalBet();
    uint256 actualTotalAmount = courseWinOrLose.returnTotalBet();
    uint256 actualTotalBetFor = courseWinOrLose.returnTotalBetFor();
    assertEq(expectedAmount, actualTotalAmount);
    assertEq(expectedAmount,actualTotalBetFor);
    assertEq(expectedAmount,actualAmount);
}

function testAddToBetRevertsWithZeroAmountPassed() public betPlacedFor {
vm.startPrank(USER1);
vm.expectRevert(CourseWinOrLose.invalidAmountPassed.selector);
courseWinOrLose.addToBet{value:0}();
}

function testPayOutWouldRevertWhenScoresHaveNotBeenAdded() public betPlacedFor simulateBetAgainst simulateBetFor {
    vm.startPrank(USER1);
    vm.expectRevert(CourseWinOrLose.youCantWithdraw.selector);
    courseWinOrLose.payOut();
}

function testPayOutRevertsIfUserDoesntPlaceAbet() public {
    vm.startPrank(USER1);
    vm.expectRevert(CourseWinOrLose.noBetWasFound.selector);
    courseWinOrLose.payOut();
}
function testPayOutRevertsWhenPlayerLosesBet() public betPlacedFor simulateBetAgainst simulateBetFor{
    vm.startPrank(INITIAL_DEPLOYER);
    mainContract.create_CWOL_contract(ICEwinsbioChem);
    courseWinOrLose.lockContract();
    courseWinOrLose.setResult(false);
    vm.stopPrank();
    vm.startPrank(USER1);
    vm.expectRevert(CourseWinOrLose.youCantWithdraw.selector);
    courseWinOrLose.payOut();
}
function testPayOutWorksWhenUserWinsBet() public betPlacedFor simulateBetAgainst simulateBetFor {
     vm.startPrank(INITIAL_DEPLOYER);
    mainContract.create_CWOL_contract(ICEwinsbioChem);
    courseWinOrLose.lockContract();
    courseWinOrLose.setResult(true);
    vm.stopPrank();
    vm.startPrank(USER1);
    uint256 userPreviousBalance = courseWinOrLose.returnUserEtherBalance();
    courseWinOrLose.payOut();
   uint256 userExpectedNewBalance = userPreviousBalance + 9900000000000000000;
    uint256 actualUserPayOut = courseWinOrLose.returnUserEtherBalance();
    assertEq(userExpectedNewBalance,actualUserPayOut);
}

function testCantSetResultWhileContractIsNotLocked() public {
    vm.startPrank(INITIAL_DEPLOYER);
    mainContract.create_CWOL_contract(ICEwinsbioChem);
    vm.expectRevert(CourseWinOrLose.cantSetResultUsersCanStillBet.selector);
    courseWinOrLose.setResult(true);
}

function testSetResultWorks() public  initiateCWOLAndSetResult{
bool expectedResult = true;
bool actualResult = courseWinOrLose.returnResult();
assertEq(expectedResult, actualResult);
}
function testNonOwnersCantSetResult() public initiateCWOL {
    vm.startPrank(USER1);
    vm.expectRevert(CourseWinOrLose.onlyMainOwnerCanCallThisFunction.selector);
    courseWinOrLose.setResult(true);
}

function testNonOwnersCantChangeProtocolCut() public initiateCWOL {
    vm.startPrank(USER1);
    vm.expectRevert(CourseWinOrLose.onlyMainOwnerCanCallThisFunction.selector);
    courseWinOrLose.changeProtocolCut(10);

}

function testChangeProtocolCut() public initiateCWOL {
    vm.startPrank(INITIAL_DEPLOYER);
    courseWinOrLose.changeProtocolCut(10);
    assertEq(courseWinOrLose.returnProtocolCut(),10);
}

function testNonOwnersCantAddOwner() public initiateCWOL {
    vm.startPrank(USER1);
    vm.expectRevert(CourseWinOrLose.onlyMainOwnerCanCallThisFunction.selector);
    courseWinOrLose.addOwner(USER2);
}
function testCWOLAddOwnerWorks() public initiateCWOL {
    vm.startPrank(INITIAL_DEPLOYER);
    courseWinOrLose.addOwner(USER1);
    vm.stopPrank();
    vm.startPrank(USER1);
    assertEq(true,courseWinOrLose.returnIsOwner());
}

function testRefundRevertsWhenUserHasNotBet() public initiateCWOL {
vm.startPrank(USER1);
vm.expectRevert(CourseWinOrLose.noBetWasFound.selector);
courseWinOrLose.refund();
}

function testRefundWorks() public  {
     vm.startPrank(INITIAL_DEPLOYER);
    (string memory __contractName, address __contractWOLAddress) = mainContract.create_CWOL_contract(ICEwinsbioChem);
    vm.stopPrank();
    vm.startPrank(USER1);
    console.log(courseWinOrLose.returnUserEtherBalance());
    courseWinOrLose.bet{value:BET_AMOUNT}(true);
    console.log(courseWinOrLose.returnUserEtherBalance());
    uint256 previousBalance = courseWinOrLose.returnUserEtherBalance();
    courseWinOrLose.refund();
    uint256 newBalance = previousBalance + 4950000000000000000;
     console.log(courseWinOrLose.returnUserEtherBalance());
    assertEq(newBalance, courseWinOrLose.returnUserEtherBalance());
}

function testRefundRevertsWhenContractHasBeenLocked() public betPlacedFor initiateCWOL{
vm.prank(INITIAL_DEPLOYER);
courseWinOrLose.lockContract();
vm.prank(USER1);
vm.expectRevert(CourseWinOrLose.thisContractHasBeenLocked.selector);
courseWinOrLose.refund();
} 

function testRefundRevertsWhenCalledTwice() public betPlacedFor {
vm.startPrank(USER1);
courseWinOrLose.refund();
vm.expectRevert(CourseWinOrLose.userHasBeenPaid.selector);
courseWinOrLose.refund();
}

function testRefundingAfterResultFails() public betPlacedFor initiateCWOL {
vm.startPrank(INITIAL_DEPLOYER);
courseWinOrLose.lockContract();
courseWinOrLose.setResult(true);
vm.stopPrank();
vm.prank(USER1);
vm.expectRevert(CourseWinOrLose.thisContractHasBeenLocked.selector);
courseWinOrLose.refund();
}

function testBetRevertsAfterResultHasBeenSet() public initiateCWOL {
vm.startPrank(INITIAL_DEPLOYER);
courseWinOrLose.lockContract();
courseWinOrLose.setResult(true);
vm.stopPrank();
vm.prank(USER1);
vm.expectRevert(CourseWinOrLose.thisContractHasBeenLocked.selector);
courseWinOrLose.bet{value:BET_AMOUNT}(true);
}

function testNonOwnersCantLockContract() public initiateCWOL {
    vm.prank(USER1);
    vm.expectRevert(CourseWinOrLose.onlyMainOwnerCanCallThisFunction.selector);
    courseWinOrLose.lockContract();
}

function testAddToBetRevertsWhenNoBetIsFound() public initiateCWOL {
    vm.prank(USER1);
    vm.expectRevert(CourseWinOrLose.noBetWasFound.selector);
    courseWinOrLose.addToBet{value:BET_AMOUNT}();
}

function testWhenUserRefundsChangesAreDoneAsItShould() public {}

/*************HOME AWAY DRAW CONTRACT */


}