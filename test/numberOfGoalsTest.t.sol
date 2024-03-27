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
    address INITIAL_DEPLOYER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 STARTING_ETHER_BALANCE = 10 ether;
    uint256 USER1_BET_AMOUNT = 5 ether;

    string ICE_NOG ;
    uint256 USER1_NOG_BET = 5;

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



    function setUp() public {
        deployer = new DeployScript();
        (mainContract,,,numberOfGoal) = deployer.run();
        vm.deal(USER1,STARTING_ETHER_BALANCE);
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
        uint256 totalAmountStake = numberOfGoal.returnUserAmountBet();
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
        vm.expectRevert(NumberOfGoals.thisUserHasBeenPaid.selector);
        numberOfGoal.payOut();
    }
    }
