//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Main} from "chance/mainContract.sol";
import {DeployScript} from "script/deployScript.s.sol";
import {NumberOfGoals} from "chance/numberOfGoals.sol";

contract numberOfGoals is Test {
    DeployScript deployer;
    Main mainContract;
    NumberOfGoals numberOfGoal;

    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");
    address USER3 = makeAddr("USER3");
    address USER4 = makeAddr("USER4");

    address INITIAL_DEPLOYER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 STARTING_ETHER_BALANCE = 10 ether;
    uint256 USER1_BET_AMOUNT = 5 ether;
    uint256 USER2_BET_AMOUNT = 3 ether;
    uint256 USER3_BET_AMOUNT = 7 ether;
    uint256 USER4_BET_AMOUNT = 5 ether;

    string ICE_NOG ;
    uint256 USER1_NOG_BET = 5;
    uint256 USER2_NOG_BET = 2;
    uint256 USER3_NOG_BET = 1;
    uint256 USER4_NOG_BET = 7;
    
    modifier initiateNumberOfGoals() {
        vm.startPrank(INITIAL_DEPLOYER);
        mainContract.create_HAD_contract(ICE_NOG);
        _;
    }

    modifier placeBet() {
        vm.startPrank(USER1);
        numberOfGoal.betNumberOfGoals{value:USER1_BET_AMOUNT}(USER1_NOG_BET);
        
        _;
    }

    modifier simulateBets() {
       vm.startPrank(USER2);
        numberOfGoal.betNumberOfGoals{value:USER2_BET_AMOUNT}(USER2_NOG_BET);
        vm.startPrank(USER3);
        numberOfGoal.betNumberOfGoals{value:USER3_BET_AMOUNT}(USER3_NOG_BET);
        vm.startPrank(USER4);
        numberOfGoal.betNumberOfGoals{value:USER4_BET_AMOUNT}(USER4_NOG_BET);
        _;
    }



    function setUp() public {
        deployer = new DeployScript();
        (mainContract,,,numberOfGoal) = deployer.run();
        vm.deal(USER1,STARTING_ETHER_BALANCE);
        vm.deal(USER2,STARTING_ETHER_BALANCE);
        vm.deal(USER3,STARTING_ETHER_BALANCE);
        vm.deal(USER4,STARTING_ETHER_BALANCE);
    }

    function testBetNumberOfGoalsRevertWhenClickedTwice() public initiateNumberOfGoals placeBet {
      vm.startPrank(USER1);
      vm.expectRevert(NumberOfGoals.youHaveAlreadyPlacedAbet.selector);
    numberOfGoal.betNumberOfGoals{value:USER1_BET_AMOUNT}(USER1_NOG_BET);
    }

    function testBetNumberOfGoalsWouldRevertWhenZeroIsPassed() public initiateNumberOfGoals  {
      vm.startPrank(USER1);
      vm.expectRevert(NumberOfGoals.invalidAmountPassed.selector);
      numberOfGoal.betNumberOfGoals(USER1_BET_AMOUNT);
    }
    function testBetWouldRevertWhenContractHasBeenLocked() public initiateNumberOfGoals {
        vm.prank(INITIAL_DEPLOYER);
        numberOfGoal.setLockGame();
        vm.prank(USER1);
        vm.expectRevert(NumberOfGoals.gameHasBeenLocked.selector);
        numberOfGoal.betNumberOfGoals{value:USER1_BET_AMOUNT}(USER1_BET_AMOUNT);
    }

    function testBetNumberOfGoalsWorkWell() public initiateNumberOfGoals placeBet {
        vm.startPrank(USER1);
        uint256 totalAmountStake = numberOfGoal.returnTotalAmount();
        assertEq(totalAmountStake,numberOfGoal.returnTotalAmount());
        assertEq(true,numberOfGoal.returnUserToHasBet());
        assertEq(USER1_NOG_BET,numberOfGoal.numberOfGoalUserBetOn());
        assertEq(numberOfGoal.returnUserAmountBet(), numberOfGoal.returnNumberOfGoalsToTalAmountBet(USER1_NOG_BET));
        assertEq(numberOfGoal.returnUserHasBeenPaid(), false);
    }

    function testRefundRevertsWhenContractHasBeenLocked() public initiateNumberOfGoals placeBet {
        vm.prank(INITIAL_DEPLOYER);
        numberOfGoal.setLockGame();
        vm.prank(USER1);
        vm.expectRevert(NumberOfGoals.gameHasBeenLocked.selector);
        numberOfGoal.refund();
    }

    function testrefundRevertsWhenUserDoesntBet() public initiateNumberOfGoals {
        vm.startPrank(USER1);
        vm.expectRevert(NumberOfGoals.noBetFound.selector);
        numberOfGoal.refund();
    }

    function testRefundWorksWell() public placeBet initiateNumberOfGoals {
        vm.startPrank(USER1);
        uint256 previousBalance = numberOfGoal.returnUserEtherBalance();
        uint256 amountPlaced = numberOfGoal.returnUserAmountBet();
        console.log(numberOfGoal.returnUserAmountBet());
        console.log(numberOfGoal.returnTotalAmount());
        numberOfGoal.refund();
        assertEq(false,numberOfGoal.returnUserToHasBet());
        assertEq(0,numberOfGoal.returnTotalAmount());
        assertEq(0,numberOfGoal.returnNumberOfGoalsToTalAmountBet(numberOfGoal.numberOfGoalUserBetOn()));
        assertEq(true,numberOfGoal.returnUserHasBeenPaid());
        assertEq(previousBalance + amountPlaced,numberOfGoal.returnUserEtherBalance());
        console.log(numberOfGoal.returnUserAmountBet());
        console.log(numberOfGoal.returnTotalAmount());
    }

    function testRefundRevertsWhenClickedMoreThanOne() public placeBet initiateNumberOfGoals {
      vm.startPrank(USER1);
      numberOfGoal.refund();
      vm.expectRevert(NumberOfGoals.noBetFound.selector);
      numberOfGoal.refund();
    }
    function testPayOutRevertsWhenNoBetWasPlaced() public initiateNumberOfGoals {
        vm.startPrank(USER1);
        vm.expectRevert(NumberOfGoals.noBetFound.selector);
        numberOfGoal.payOut();
    }
    function testPayOutRevertsWhenClickedMoreThanOnce() public initiateNumberOfGoals placeBet  {
        vm.startPrank(INITIAL_DEPLOYER);
        numberOfGoal.setLockGame();
        numberOfGoal.setResult(USER1_NOG_BET);
        vm.startPrank(USER1);
        numberOfGoal.payOut();
        vm.expectRevert(NumberOfGoals.noBetFound.selector);
        numberOfGoal.payOut();
    }

    function testPayOutWorks() simulateBets placeBet initiateNumberOfGoals public  {
          vm.startPrank(INITIAL_DEPLOYER);
          numberOfGoal.setLockGame();
          numberOfGoal.setResult(USER1_NOG_BET);
          vm.startPrank(USER1);
          uint256 previousBalance = numberOfGoal.returnUserEtherBalance();
          numberOfGoal.payOut();
          assertEq(true,numberOfGoal.returnUserHasBeenPaid());
          assertEq(false,numberOfGoal.returnUserToHasBet());
          assertEq(previousBalance + numberOfGoal.returnTotalAmount(),numberOfGoal.returnUserEtherBalance());

    }
    function testPayOutRevertsWhenUserLosesBet() placeBet initiateNumberOfGoals public {
         vm.startPrank(INITIAL_DEPLOYER);
          numberOfGoal.setLockGame();
          numberOfGoal.setResult(USER2_NOG_BET);
          vm.startPrank(USER1);
          vm.expectRevert(NumberOfGoals.noBetFound.selector);
          numberOfGoal.payOut();
    }
    function testPayOutRevertsWhenResultHasNotBeenSet() placeBet initiateNumberOfGoals public {
         vm.startPrank(USER1);
         vm.expectRevert(NumberOfGoals.noBetFound.selector);
         numberOfGoal.payOut();
    }

    function testSetResultRevertsWhenNonOnwerCallIt() public placeBet initiateNumberOfGoals {
     vm.prank(USER1);
     vm.expectRevert(NumberOfGoals.onlyOwnerCanCallThisFunction.selector);
     numberOfGoal.setResult(USER1_NOG_BET);
    }
    function testSetResultRevertsWhenGameIsNotLocked() public placeBet initiateNumberOfGoals {
        vm.prank(INITIAL_DEPLOYER);
        vm.expectRevert(NumberOfGoals.cantSetResultGameHasNotBeenLocked.selector);
        numberOfGoal.setResult(USER1_NOG_BET);
    }
    function testSetResultWorks() public initiateNumberOfGoals {
        vm.startPrank(INITIAL_DEPLOYER);
        numberOfGoal.setLockGame();
        numberOfGoal.setResult(USER1_NOG_BET);
        assertEq(USER1_NOG_BET,numberOfGoal.returnResult());
    }

    function testSetNewOwnerRevertsWhenNonCallerCalls() public placeBet initiateNumberOfGoals {
        vm.prank(USER1);
         vm.expectRevert(NumberOfGoals.onlyOwnerCanCallThisFunction.selector);
        numberOfGoal.setNewOwner(USER2);
    }

    function testSetNewOwner() public initiateNumberOfGoals {
        vm.startPrank(INITIAL_DEPLOYER);
        numberOfGoal.setNewOwner(USER1);
        assertEq(true,numberOfGoal.checkIsOwner(USER1));
    }

    function testSetProtocolCutRevertsWithWrongCaller() public placeBet initiateNumberOfGoals {
        vm.prank(USER1);
         vm.expectRevert(NumberOfGoals.onlyOwnerCanCallThisFunction.selector);
        numberOfGoal.setProtocolCut(5);
}
    function testProtocolCutWorks() public placeBet initiateNumberOfGoals {
         vm.startPrank(INITIAL_DEPLOYER);
        numberOfGoal.setProtocolCut(5);
        assertEq(5,numberOfGoal.returnProtocolCut());
    }

    function testSetLockGameRevertsWithWrongCaller() public initiateNumberOfGoals {
        vm.prank(USER1);
         vm.expectRevert(NumberOfGoals.onlyOwnerCanCallThisFunction.selector);
        numberOfGoal.setLockGame();
}

  function testSetLockWorks() public initiateNumberOfGoals {
    vm.startPrank(INITIAL_DEPLOYER);
        numberOfGoal.setLockGame();
        assertEq(true,numberOfGoal.returnIsGameLocked());
  }

  function testAddToBetRevertsWhenContractIsLocked() public placeBet  initiateNumberOfGoals {
    vm.prank(INITIAL_DEPLOYER);
    numberOfGoal.setLockGame();
    vm.expectRevert(NumberOfGoals.gameHasBeenLocked.selector);
    numberOfGoal.addToBetAmount{value:USER1_BET_AMOUNT}();
  }

  function testAddToBetRevertsWhenNoBetIsFound() public initiateNumberOfGoals {
    vm.prank(USER1);
    vm.expectRevert(NumberOfGoals.noBetFound.selector);
    numberOfGoal.addToBetAmount{value:USER1_BET_AMOUNT}();
  }

 function testAddToBetWorksWell() public initiateNumberOfGoals placeBet {
    vm.startPrank(USER1);
    numberOfGoal.addToBetAmount{value:USER1_BET_AMOUNT}();
    assertEq(numberOfGoal.returnUserAmountBet(),numberOfGoal.returnTotalAmount());
    assertEq(numberOfGoal.returnUserAmountBet(),numberOfGoal.returnNumberOfGoalsToTalAmountBet(USER1_NOG_BET));
 }
}