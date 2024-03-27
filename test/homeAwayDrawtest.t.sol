//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Main} from "chance/mainContract.sol";
import {HomeAwayDraw} from "chance/homeAwayDraw.sol";
import {DeployScript} from "script/deployScript.s.sol";

contract HAD_Test is Test {

    DeployScript deployer;
    Main mainContract;
    HomeAwayDraw homeAwayDraw;

    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");
    address USER3 = makeAddr("USER3");
    address USER4 = makeAddr("USER4");
    address USER5 = makeAddr("USER5");
    address USER6 = makeAddr("USER6");
    address INITIAL_DEPLOYER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;


    uint256 STARTING_ETHER_BALANCE = 10 ether;
    uint256 BET_AMOUNT = 5 ether;
    uint256 USER2_BET_AMOUNT = 3 ether;
    uint256 USER3_BET_AMOUNT = 7 ether;
    uint256 USER4_BET_AMOUNT = 6 ether;
    uint256 USER5_BET_AMOUNT = 2 ether;
    uint256 USER6_BET_AMOUNT = 4 ether;

    string ICE_HAD = "ICE_HAD";

    HomeAwayDraw.State homeState = HomeAwayDraw.State.home;
    HomeAwayDraw.State awayState = HomeAwayDraw.State.Away;
    HomeAwayDraw.State drawState = HomeAwayDraw.State.Draw;
  
   
   modifier initiateHADContract() {
    vm.startPrank(INITIAL_DEPLOYER);
    mainContract.create_HAD_contract(ICE_HAD);
    _;
   }

   modifier hasBet() {
    vm.prank(USER1);
    homeAwayDraw.bet{value:BET_AMOUNT}(homeState);
    _;
   }

   modifier simulateHomeBet() {
    vm.prank(USER2);
     homeAwayDraw.bet{value:USER2_BET_AMOUNT}(homeState);
    _;
   }
   modifier simulateAwayBet() {
    vm.prank(USER3);
     homeAwayDraw.bet{value:USER3_BET_AMOUNT}(awayState);
     vm.prank(USER4);
     homeAwayDraw.bet{value:USER4_BET_AMOUNT}(awayState);
    _;
   }

   modifier simulateDrawBet() {
    vm.prank(USER5);
     homeAwayDraw.bet{value:USER5_BET_AMOUNT}(drawState);
     vm.prank(USER6);
     homeAwayDraw.bet{value:USER6_BET_AMOUNT}(drawState);
    _;
   }

    function setUp() public {
         deployer = new DeployScript();
    (mainContract,,homeAwayDraw,) = deployer.run();
    vm.deal(USER1, STARTING_ETHER_BALANCE);
    vm.deal(USER2,STARTING_ETHER_BALANCE);
    vm.deal(USER3,STARTING_ETHER_BALANCE);
    vm.deal(USER4,STARTING_ETHER_BALANCE);
    vm.deal(USER5,STARTING_ETHER_BALANCE);
    vm.deal(USER6,STARTING_ETHER_BALANCE);
    }

    function testCreate_HAD_contract_works() public initiateHADContract {
        vm.startPrank(USER1);
        uint256 actualLength = mainContract.returnHADLength();
        assertEq(actualLength, 1); 
    }

    function testcreateHADRevertsWithWrongCaller() public {
        vm.startPrank(USER1);
        vm.expectRevert(Main.onlyOwnerCanCallThisFunction.selector);
        mainContract.create_HAD_contract(ICE_HAD);
    }

    function testBetWorks() public initiateHADContract {
        vm.startPrank(USER1);
        homeAwayDraw.bet{value:BET_AMOUNT}(homeState);
        bool hasUserBet = homeAwayDraw.returnHasUserBet();
        assertEq(true, hasUserBet);
    }
    function testBetRevertsWhenContractHasBeenLocked() initiateHADContract public {
        vm.prank(INITIAL_DEPLOYER);
        homeAwayDraw.lockContract();
        vm.prank(USER1);
        vm.expectRevert(HomeAwayDraw.gameHasBeenLocked.selector);
        homeAwayDraw.bet{value:BET_AMOUNT}(homeState);
    }

    function testbetRevertsWhenCalledMoreThanOnce() public initiateHADContract {
        vm.startPrank(USER1);
        homeAwayDraw.bet{value:BET_AMOUNT}(homeState);
        vm.expectRevert(HomeAwayDraw.youHaveAlreadyPlacedAbet.selector);
        homeAwayDraw.bet{value:BET_AMOUNT}(homeState);
    }

    function testReturnStateWorksWell() public initiateHADContract {
        vm.startPrank(USER1);
        homeAwayDraw.bet{value:BET_AMOUNT}(homeState);
        HomeAwayDraw.State actualState = homeAwayDraw.returnUserBetState();
        assertEq(uint(actualState), uint(homeState));
    }

    function testBetRevertsWithInvalidAmount() public initiateHADContract {
        vm.startPrank(USER1);
        vm.expectRevert(HomeAwayDraw.invalidAmountPassed.selector);
        homeAwayDraw.bet{value:0}(homeState);
    }

    function testBetWorksAsItShould() public initiateHADContract hasBet simulateAwayBet simulateDrawBet simulateHomeBet {
         HomeAwayDraw.State actualState = homeAwayDraw.returnUserBetState();
         uint256 expectedTotalAmountBet = 2673e16;
         uint256 expectedTotalHomeBetAmount = 792e16; 
         uint256 expectedTotalAwayBetAmount = 1287e16;
         uint256 expectedTotalDrawBetAmount = 594e16;
         assertEq(uint(actualState), uint(homeState));
        assertEq(expectedTotalAmountBet,homeAwayDraw.returnTotalAmountBet());
        assertEq(expectedTotalHomeBetAmount,homeAwayDraw.returnStateTotalAmountBet(homeState));
        assertEq(expectedTotalAwayBetAmount,homeAwayDraw.returnStateTotalAmountBet(awayState));
        assertEq(expectedTotalDrawBetAmount,homeAwayDraw.returnStateTotalAmountBet(drawState));
        vm.startPrank(USER1);
        uint256 user1AmountBet =  homeAwayDraw.returnUserBetAmount();     
        assertEq(user1AmountBet,495e16);
    }

    function testAddToBetRevertsWhenZeroIsPassed() public hasBet initiateHADContract {
    vm.prank(USER1);
    vm.expectRevert(HomeAwayDraw.invalidAmountPassed.selector);
    homeAwayDraw.addToBet{value:0}();
}
    function testAddToBetRevertsWhenUserHasNotBet() public {
        vm.prank(USER1);
        vm.expectRevert(HomeAwayDraw.userHasNotPlacedAbet.selector);
        homeAwayDraw.addToBet{value:0}();
    }

    function testAddBetRevertsWhenContractIsLocked() public hasBet initiateHADContract {
        vm.prank(INITIAL_DEPLOYER);
        homeAwayDraw.lockContract();
        vm.prank(USER1);
        vm.expectRevert(HomeAwayDraw.gameHasBeenLocked.selector);
        homeAwayDraw.addToBet{value:BET_AMOUNT}();
    }

    function testAddBetWorks() public hasBet initiateHADContract {
        vm.startPrank(USER1);
        console.log(homeAwayDraw.returnUserBetAmount());
        homeAwayDraw.addToBet{value:BET_AMOUNT}();
        console.log(homeAwayDraw.returnUserBetAmount());
        assertEq(9.9e18, homeAwayDraw.returnUserBetAmount());
    }

    function testRefundRevertsWhenPlayerDidntBet() public initiateHADContract {
        vm.prank(USER1);
        vm.expectRevert(HomeAwayDraw.noBetWasFound.selector);
        homeAwayDraw.refund();
    }

    function testRefundRevertsWhenCalledTwice() public initiateHADContract hasBet {
        vm.startPrank(USER1);
        homeAwayDraw.refund();
        vm.expectRevert(HomeAwayDraw.userHasBeenPaid.selector);
        homeAwayDraw.refund();
    }

    function testRefundRevertsWhenContractHasBeenLocked() public initiateHADContract hasBet {
        vm.prank(INITIAL_DEPLOYER);
        homeAwayDraw.lockContract();
        vm.prank(USER1);
        vm.expectRevert(HomeAwayDraw.gameHasBeenLocked.selector);
        homeAwayDraw.refund();
    }

    function testRefundWorksWell() public initiateHADContract hasBet {
        vm.startPrank(USER1);
        homeAwayDraw.refund();
        uint256 expectedStateToTotalAmountBet = 0;
        bool expectedHasUserBet = false;
        bool expectedHasUserBeenPaid = true;
        uint256 expectedUserNewBalance = 9.95e18;
        assertEq(expectedStateToTotalAmountBet,homeAwayDraw.returnStateTotalAmountBet(homeState));
        assertEq(expectedHasUserBet,homeAwayDraw.returnHasUserBet());
        assertEq(expectedHasUserBeenPaid,homeAwayDraw.returnUserPaidState());
        assertEq(expectedUserNewBalance,homeAwayDraw.returnUserEtherBalance());
    }

    function testPayOutWorks() public hasBet simulateAwayBet simulateDrawBet simulateHomeBet {
       vm.startPrank(INITIAL_DEPLOYER);
       homeAwayDraw.lockContract();
       homeAwayDraw.setResult(homeState);
       vm.stopPrank();
       vm.startPrank(USER1);
        uint256 userBalanceAfterBet = homeAwayDraw.returnUserEtherBalance();
       homeAwayDraw.payOut();
       uint256 expectedNewUserBalance = (homeAwayDraw.returnUserBetAmount()*homeAwayDraw.returnTotalAmountBet())/homeAwayDraw.returnStateTotalAmountBet(homeAwayDraw.returnUserBetState());
       assertEq(expectedNewUserBalance + userBalanceAfterBet,homeAwayDraw.returnUserEtherBalance());
    }

   function testPayOutRevertsWhenUserDoesntWin() public hasBet simulateAwayBet simulateDrawBet simulateHomeBet {
     vm.startPrank(INITIAL_DEPLOYER);
       homeAwayDraw.lockContract();
       homeAwayDraw.setResult(homeState);
       vm.stopPrank();
       vm.startPrank(USER3);
       vm.expectRevert(HomeAwayDraw.youDidNotWin.selector);
       homeAwayDraw.payOut();
   }

   function testPayOutRevertsWhenUserDoesntBet() public  simulateAwayBet simulateDrawBet simulateHomeBet {
    vm.startPrank(USER1);
    vm.expectRevert(HomeAwayDraw.noBetWasFound.selector);
    homeAwayDraw.payOut();
   }

   function testPayOutRevertsWhenUserTriesClickingMoreThanOnce() public hasBet simulateAwayBet simulateDrawBet simulateHomeBet {
    vm.startPrank(USER1);
    homeAwayDraw.payOut();
    vm.expectRevert(HomeAwayDraw.userHasBeenPaid.selector);
    homeAwayDraw.payOut();
   }

   function testOnlyOwnersCanSetResult() public initiateHADContract hasBet simulateAwayBet simulateHomeBet simulateDrawBet {
    vm.startPrank(USER1);
    vm.expectRevert(HomeAwayDraw.onlyOwnerCanCallThisFunction.selector);
    homeAwayDraw.setResult(homeState);
   }

   function testSetResultWorks() public initiateHADContract {
    vm.startPrank(INITIAL_DEPLOYER);
    homeAwayDraw.lockContract();
    homeAwayDraw.setResult(homeState);
    assertEq(uint(homeState),uint256(homeAwayDraw.returnResult()));
   }

   function testSetResultRevertsWhenGameIsNotLocked() initiateHADContract public {
    vm.startPrank(INITIAL_DEPLOYER);
    vm.expectRevert(HomeAwayDraw.cantSetResultGameHasNotBeenLocked.selector);
    homeAwayDraw.setResult(homeState);
   }

   function testNonOwnersCantSetProtocolCut() initiateHADContract public {
    vm.startPrank(USER1);
    vm.expectRevert(HomeAwayDraw.onlyOwnerCanCallThisFunction.selector);
    homeAwayDraw.setResult(homeState);
   }

   function testSetProtocolCutRevertsWhenNonOwnersCallIt() public initiateHADContract {
    vm.startPrank(USER1);
    vm.expectRevert(HomeAwayDraw.onlyOwnerCanCallThisFunction.selector);
    homeAwayDraw.setProtocolCut(5);
   }

   function testSetProtocolCutWorks() public initiateHADContract {
    vm.startPrank(INITIAL_DEPLOYER);
    homeAwayDraw.setProtocolCut(5);
    assertEq(5, homeAwayDraw.returnProtocolCut());
   }

   function testAddNewOwnerRevertsWithWrongCaller() public initiateHADContract {
    vm.startPrank(USER1);
    vm.expectRevert(HomeAwayDraw.onlyOwnerCanCallThisFunction.selector);
    homeAwayDraw.addNewOwner(USER1);
   }

   function testAddNewOwnerWorks() public initiateHADContract {
    vm.startPrank(INITIAL_DEPLOYER);
    homeAwayDraw.addNewOwner(USER1);
    assertEq(true, homeAwayDraw.checkIfAddressIsOwner(USER1));
   }

}