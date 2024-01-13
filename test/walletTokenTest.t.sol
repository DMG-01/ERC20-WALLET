//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Wallet} from "src/walletToken.sol";
import {HelperConfig} from "script/helperConfig.sol";
import {deployWallet} from "script/walletTokenDeployScript.s.sol";
import { ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {console} from "forge-std/Test.sol";


contract walletTest is Test{
    deployWallet deployer;
    Wallet wallet;
    HelperConfig helperConfig;
    address wethUsdPriceFeedAddress;
    address wbtcUsdPriceFeedAddress;
    address wethAddress;
    address wbtcAddress;


    address WRONG_TOKEN;
    uint256 constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 constant STARTING_ETHER_BALANCE = 10 ether;
    uint256 constant EXCESS_AMOUNT = 15 ether;
    uint256 constant ALLOWED_AMOUNT = 20 ether;
    uint256 constant LOCK_TIME = 10 days;
    uint256 constant SPENDING_LIMIT = 4 ether;
    uint256 constant AMOUNT_TO_SEND = 5 ether;
    uint256 constant SEND_ETHER = 5 ether;
    uint256 constant USER1_STARTING_ETHER = 3 ether;
    uint256 constant USER_TOKEN_TO_SWAP = 3 ether;
    uint256 constant USER2_TOKEN_TO_SWAP = 4 ether;

    address public USER = makeAddr("user");
    address public USER1 = makeAddr("user1");
    address public  USER2 = makeAddr("user2");

function setUp() public {
            deployer = new deployWallet();
            (wallet,helperConfig) = deployer.run();
            (wethAddress,wbtcAddress,wethUsdPriceFeedAddress,wbtcUsdPriceFeedAddress,) = helperConfig.activeNetworkConfig();
            ERC20Mock(wethAddress).mint((address(USER)),STARTING_ERC20_BALANCE);
            ERC20Mock(wbtcAddress).mint((address(USER)),STARTING_ERC20_BALANCE);
            ERC20Mock(wbtcAddress).mint((address(USER2)),STARTING_ERC20_BALANCE);

            ERC20Mock(wethAddress).approve((address(wallet)),STARTING_ERC20_BALANCE);
            ERC20Mock(wbtcAddress).approve((address(wallet)),STARTING_ERC20_BALANCE); 
            ERC20Mock(wethAddress).approve((address(USER1)),STARTING_ERC20_BALANCE);
            ERC20Mock(wbtcAddress).approve((address(USER1)),STARTING_ERC20_BALANCE);
            ERC20Mock(wbtcAddress).approve((address(USER2)),STARTING_ERC20_BALANCE);
            vm.deal(USER,STARTING_ETHER_BALANCE);
            vm.deal(USER1,USER1_STARTING_ETHER);

}
    address[] tokenPriceFeedAddresses;
    address[] tokenAddresses;
    function testExpectToRevertWhenLengthOfPriceFeedAndTokensAreNotTheSame() public {
       vm.startPrank(USER);
       tokenPriceFeedAddresses.push(wethUsdPriceFeedAddress);
       tokenAddresses.push(wethAddress);
       tokenAddresses.push(wbtcAddress);
       vm.expectRevert(Wallet.priceFeedAddressesDoesntEqualTokenAddresses.selector);
       new Wallet(tokenPriceFeedAddresses,tokenAddresses);
    }

    modifier fundAccountWithWeth() {
    vm.startPrank(USER);
    ERC20Mock(wethAddress).approve(address(wallet), ALLOWED_AMOUNT);
    wallet.fundAccount(wethAddress,STARTING_ERC20_BALANCE);
    _;
    }
    
     modifier fundAccountWithWbtc() {
    vm.startPrank(USER);
    ERC20Mock(wbtcAddress).approve(address(wallet), ALLOWED_AMOUNT);
    wallet.fundAccount(wbtcAddress,STARTING_ERC20_BALANCE);
    _;
    }

         modifier fundUSER2WithWbtc() {
    vm.startPrank(USER2);
    ERC20Mock(wbtcAddress).approve(address(wallet), ALLOWED_AMOUNT);
    wallet.fundAccount(wbtcAddress,USER2_TOKEN_TO_SWAP);
    _;
    }

    function testFundAccountWillRevertWhenZeroIsPassed() public {
        vm.startPrank(USER);
        vm.expectRevert(Wallet.needsMoreThanZero.selector);
        wallet.fundAccount(wethAddress, 0);
    }
/*
    function testFundAccountWillRevertWithInvalidtoken() public {
        vm.startPrank(USER);
       tokenPriceFeedAddresses.push(wethUsdPriceFeedAddress);
       tokenPriceFeedAddresses.push(wbtcUsdPriceFeedAddress);
       tokenAddresses.push(wethAddress);
       tokenAddresses.push(wbtcAddress);
       new Wallet(tokenPriceFeedAddresses,tokenAddresses);
       vm.expectRevert(Wallet.invalidToken.selector);
       wallet.fundAccount(WRONG_TOKEN,10);

    }
    */
    function testFundAccountWorks() public {
        vm.startPrank(USER);
        ERC20Mock(wethAddress).approve(address(wallet), STARTING_ERC20_BALANCE);
        wallet.fundAccount(wethAddress,STARTING_ERC20_BALANCE);
        uint256 balance = wallet.getUserTokenBalance(wethAddress);
        vm.stopPrank();
        assertEq(balance, STARTING_ERC20_BALANCE);
    }
/*
    function testDepositCollateralworks() public {
        vm.startPrank(USER);
        ERC20Mock(wethAddress).approve(address(wallet), STARTING_ERC20_BALANCE);
        wallet.depositCollateral(wethAddress,STARTING_ERC20_BALANCE);
        uint256 balance = wallet.getUserTokenBalance(wethAddress);
        vm.stopPrank();
        assertEq(balance, STARTING_ERC20_BALANCE);
    }
    */
   function testWithdrawal() fundAccountWithWbtc public {
         vm.startPrank(USER);
         wallet.withdraw(wbtcAddress,STARTING_ERC20_BALANCE);
       uint256 balance = wallet.getUserTokenBalance(wethAddress);
       vm.stopPrank();
       assertEq(balance,0);
   }

   function testWithdrawalRevertsWithZero() fundAccountWithWeth public {
      vm.startPrank(USER);
      vm.expectRevert(Wallet.needsMoreThanZero.selector);
      wallet.withdraw(wethAddress,0);
      vm.stopPrank();
   }

   function testWithdrawalRevertsWhenAmountIsMoreThanDeposit()  fundAccountWithWeth public {
    vm.startPrank(USER);
    vm.expectRevert();
    wallet.fundAccount(wethAddress,EXCESS_AMOUNT);
   } 

   function testTokenWillRevertWithInSufficientFunds() public fundAccountWithWeth {
    vm.startPrank(USER);
    vm.expectRevert(Wallet.InsufficientBalance.selector);
    wallet.lockTokens(wethAddress,EXCESS_AMOUNT,LOCK_TIME);
   }

   function testLockTokenWorks() fundAccountWithWeth public {
    vm.startPrank(USER);
    wallet.lockTokens(wethAddress,STARTING_ERC20_BALANCE, LOCK_TIME);
    uint256 actualLockedTokenAmount = wallet.getUserLockTokenBalance(wethAddress);
    uint256 actualTokenBalance = wallet.getUserTokenBalance(wethAddress);
    assertEq(STARTING_ERC20_BALANCE,actualLockedTokenAmount);
    assertEq(actualTokenBalance, 0);
   }
   // test multiple token
   function testOneLockedTokenWontAffectAnother() fundAccountWithWeth fundAccountWithWbtc public {
       vm.startPrank(USER);
       wallet.lockTokens(wethAddress, STARTING_ERC20_BALANCE,LOCK_TIME);
       wallet.lockTokens(wbtcAddress, STARTING_ERC20_BALANCE, LOCK_TIME);
      uint256 actualWethBalance = wallet.getUserTokenBalance(wethAddress);
       uint256 actualWbtcBalance = wallet.getUserTokenBalance(wbtcAddress);
       assertEq(actualWethBalance,actualWbtcBalance);
     
   }

   function testWithdrawTokenRevertsWhenItsNotTime() fundAccountWithWeth public {
    vm.startPrank(USER);
    wallet.lockTokens(wethAddress,STARTING_ERC20_BALANCE,LOCK_TIME);
    vm.expectRevert(Wallet.youCantWithdrawTokenYet.selector);
    wallet.withdrawLockedTokens(wethAddress);
   }
/*
   function testWithdrawalFunctionWorks() fundAccountWithWbtc public {
    vm.startPrank(USER);
  uint256  currentTimeStamp = block.timestamp;
  wallet.lockTokens(wethAddress,STARTING_ERC20_BALANCE,LOCK_TIME);
    block.timestamp = block.timestamp + LOCK_TIME;
  wallet.withdrawLockedTokens(wbtcAddress);
  uint256 actualLockedTokenBalance = wallet.getUserTokenBalance(wbtcAddress);
  assertEq(actualLockedTokenBalance, 0);
   }
   */
  function testSendTokenWorks() public fundAccountWithWbtc {
    vm.startPrank(USER);
    wallet.sendToken(wbtcAddress,AMOUNT_TO_SEND,USER1);
    uint256 actualUSERBalance = wallet.getUserTokenBalance(wbtcAddress); 
    vm.stopPrank();
    vm.prank(USER1);
    uint256 actualUSER1Balance = wallet.getUserTokenBalance(wbtcAddress);
    assertEq(actualUSERBalance,actualUSER1Balance);
    console.log(actualUSERBalance);
  }

function testSpendingLimitWorks() public fundAccountWithWbtc {
    vm.startPrank(USER);
    wallet._addToDailySpendingLimit(wbtcAddress,SPENDING_LIMIT);
    vm.expectRevert(Wallet.amountHasExceededLimit.selector);
    wallet.sendToken(wbtcAddress,AMOUNT_TO_SEND,USER1);
    
}

function testCannotSendLockedToken() public fundAccountWithWbtc {
     vm.startPrank(USER);
     wallet.lockTokens(wbtcAddress,STARTING_ERC20_BALANCE,LOCK_TIME);
     vm.expectRevert(Wallet.InsufficientBalance.selector);
     wallet.sendToken(wbtcAddress,STARTING_ERC20_BALANCE,USER1);
}
function testSendEtherWorks() public {
    vm.startPrank(USER);
    wallet.sendEther{value:SEND_ETHER}(payable(USER1));
    uint256 actualSenderBalance = wallet.getUserEtherBalance();
    vm.stopPrank();
    uint256 expectedSenderBalance = 5 ether;
    assertEq(actualSenderBalance,expectedSenderBalance);
}
function testSendEtherRevertsWhenRecepientIsFunctionCaller() public {
    vm.startPrank(USER);
    vm.expectRevert(Wallet.cannotSendEtherToSelf.selector);
    wallet.sendEther{value:SEND_ETHER}(payable(USER));
}
function testSendEtherWillRevertWithInsufficientBalance() public {
    vm.startPrank(USER1);
    vm.expectRevert(/*Wallet.InsufficientBalance.selector*/);
    wallet.sendEther{value:SEND_ETHER}(payable(USER));
}
function testSendEtherRevertsWhenValueIsZero() public {
    vm.startPrank(USER);
    vm.expectRevert(Wallet.needsMoreThanZero.selector);
    wallet.sendEther{value:0}(payable(USER1));
}

function testTokenLimitCanChange() public fundAccountWithWbtc {
   vm.startPrank(USER);
   wallet._addToDailySpendingLimit(wbtcAddress,SPENDING_LIMIT);
   uint256 NEW_SPENDING_LIMIT = 2 ether;
   wallet._addToDailySpendingLimit(wbtcAddress,NEW_SPENDING_LIMIT);
   uint256 actualSpendingLimit = wallet.returnUserSpendingLimit(wbtcAddress);
   assertEq(actualSpendingLimit,NEW_SPENDING_LIMIT);
}
function testSwapTokenFunctionWorks() public fundAccountWithWeth fundUSER2WithWbtc {
   vm.prank(USER);
   wallet.swapTokens(USER_TOKEN_TO_SWAP,USER2_TOKEN_TO_SWAP,wethAddress,wbtcAddress,USER1);
   vm.startPrank(USER2);
   wallet._secondUserConfirmTransaction(1,USER2);
   uint256 user2ActualWethBalance = wallet.getUserTokenBalance(wethAddress);
   assertEq(user2ActualWethBalance,3);
   console.log(user2ActualWethBalance);
   console.log(USER2_TOKEN_TO_SWAP);
}
//interchange the caller

function testSecondUserRejectTransaction() public fundAccountWithWeth /*fundAccountWithWbtc*/ fundUSER2WithWbtc {
    vm.prank(USER);
    //vm.expectRevert();
    wallet.swapTokens(USER_TOKEN_TO_SWAP,USER2_TOKEN_TO_SWAP,wethAddress,wbtcAddress,USER2);
    vm.startPrank(USER2);
    wallet._secondUserConfirmTransaction(1,USER2);
    uint256 userTwoActualWethBalance = wallet.getUserTokenBalance(wethAddress);
    vm.stopPrank();
    vm.prank(USER);
    uint256 userActualWbtcBalance = wallet.getUserTokenBalance(wbtcAddress);
    assertEq(userTwoActualWethBalance,USER_TOKEN_TO_SWAP); 
    assertEq(userActualWbtcBalance,USER2_TOKEN_TO_SWAP);
    
}
}