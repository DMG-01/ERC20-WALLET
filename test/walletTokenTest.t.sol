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

    address public USER = makeAddr("user");

function setUp() public {
            deployer = new deployWallet();
            (wallet,helperConfig) = deployer.run();
            (wethAddress,wbtcAddress,wethUsdPriceFeedAddress,wbtcUsdPriceFeedAddress,) = helperConfig.activeNetworkConfig();
            ERC20Mock(wethAddress).mint((address(USER)),STARTING_ERC20_BALANCE);
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

    function testFundAccountWillRevertWhenZeroIsPassed() public {
        vm.startPrank(USER);
        vm.expectRevert(Wallet.needsMoreThanZero.selector);
        wallet.fundAccount(wethAddress, 0);
    }

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
    function testFundAccountWorks() public {
       // ERC20Mock(wethAddress).mint(USER, STARTING_ERC20_BALANCE);
        vm.startPrank(USER);
        ERC20Mock(wethAddress).approve(address(wallet), STARTING_ERC20_BALANCE);
        wallet.fundAccount(wethAddress,STARTING_ERC20_BALANCE);
        uint256 balance = wallet.getUserTokenBalance(wethAddress);
        vm.stopPrank();
        assertEq(balance, STARTING_ERC20_BALANCE);
    }

    function testDepositCollateralworks() public {
       //  ERC20Mock(wethAddress).mint(USER, STARTING_ERC20_BALANCE);
        vm.startPrank(USER);
        ERC20Mock(wethAddress).approve(address(wallet), STARTING_ERC20_BALANCE);
        wallet.depositCollateral(wethAddress,STARTING_ERC20_BALANCE);
        uint256 balance = wallet.getUserTokenBalance(wethAddress);
        vm.stopPrank();
        assertEq(balance, STARTING_ERC20_BALANCE);
    }
}