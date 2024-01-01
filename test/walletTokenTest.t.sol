//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Wallet} from "src/walletToken.sol";
import {HelperConfig} from "script/helperConfig.sol";
import {deployWallet} from "script/walletTokenDeployScript.s.sol";

contract walletTest is Test{
    Wallet wallet;
    HelperConfig helperConfig;
    deployWallet deployer;
    address wethUsdPriceFeedAddress;
    address wbtcUsdPriceFeedAddresses;
    address wethAddress;
    address wbtcAddress;
    address WRONG_TOKEN;

    address USER = makeAddr("user");

    function setUp() public {
        deployer = new deployWallet();
        (wallet,helperConfig) = deployer.run();
        (wethUsdPriceFeedAddress,wbtcUsdPriceFeedAddresses,wethAddress,wbtcAddress) = helperConfig.activeNetworkConfig();
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
       tokenPriceFeedAddresses.push(wbtcUsdPriceFeedAddresses);
       tokenAddresses.push(wethAddress);
       tokenAddresses.push(wbtcAddress);
       new Wallet(tokenPriceFeedAddresses,tokenAddresses);
       vm.expectRevert(Wallet.invalidToken.selector);
       wallet.fundAccount(WRONG_TOKEN,10);

    }
}