//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Wallet} from "src/walletToken.sol";
import {HelperConfig} from "script/helperConfig.sol";
import {deployWallet} from "script/walletTokenDeployScript.s.sol";
import { ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";

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
    uint256 constant EXCESS_AMOUNT = 15 ether;
    uint256 constant ALLOWED_AMOUNT = 20 ether;
    uint256 constant LOCK_TIME = 10 days;

    address public USER = makeAddr("user");

function setUp() public {
            deployer = new deployWallet();
            (wallet,helperConfig) = deployer.run();
            (wethAddress,wbtcAddress,wethUsdPriceFeedAddress,wbtcUsdPriceFeedAddress,) = helperConfig.activeNetworkConfig();
            ERC20Mock(wethAddress).mint((address(USER)),STARTING_ERC20_BALANCE);
            ERC20Mock(wbtcAddress).mint((address(USER)),STARTING_ERC20_BALANCE);
            ERC20Mock(wethAddress).approve((address(wallet)),STARTING_ERC20_BALANCE);
            ERC20Mock(wbtcAddress).approve((address(wallet)),STARTING_ERC20_BALANCE); 
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
   function testWithdrawal() fundAccountWithWeth public {
         vm.startPrank(USER);
         wallet.withdraw(wethAddress,STARTING_ERC20_BALANCE);
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
   function testOneLockedTokenWontAffectAnother() fundAccountWithWbtc fundAccountWithWbtc public {
       vm.startPrank(USER);
       wallet.lockTokens(wethAddress, STARTING_ERC20_BALANCE,LOCK_TIME);
       wallet.lockTokens(wbtcAddress, STARTING_ERC20_BALANCE, LOCK_TIME);
       //uint256 actualLockedWethAmount = wallet.getUserLockTokenBalance(wethAddress);
      uint256 actualWethBalance = wallet.getUserTokenBalance(wethAddress);
       uint256 actualWbtcBalance = wallet.getUserTokenBalance(wbtcAddress);
     //  uint256 actualWethTokenAmount = wallet.getUserLockTokenBalance(wethAddress);
       assertEq(actualWethBalance,actualWbtcBalance);
      // assertEq(actualWbtcBalance,STARTING_ERC20_BALANCE);

   }
}