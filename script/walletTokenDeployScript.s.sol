//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Wallet} from "src/walletToken.sol";
import {HelperConfig} from "script/helperConfig.sol";

contract deployWallet is Script{

address[] tokenAddresses;
address[] tokenPriceFeedAddresses;

function run() external returns(Wallet,HelperConfig){
    
    HelperConfig helperConfig = new HelperConfig();
    (address wethUsdPriceFeedAddress, address wbtcUsdPriceFeedAddress, address wethAddress, address wbtcAddress, uint256 deployerKey) = helperConfig.activeNetworkConfig();
    
    tokenAddresses = [wethAddress, wbtcAddress];
    tokenPriceFeedAddresses = [wethUsdPriceFeedAddress, wbtcUsdPriceFeedAddress];

    vm.startBroadcast(deployerKey);
    Wallet wallet =new Wallet(tokenPriceFeedAddresses, tokenAddresses);
    vm.stopBroadcast();
    return(wallet,helperConfig);
 }
}