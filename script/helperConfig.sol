//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Wallet } from "src/walletToken.sol";

contract HelperConfig is Script {

 struct NetworkConfig {
    address wethAddress;
    address wbtcAddress;
    address wethUsdPriceFeedAddress;
    address wbtcUsdPriceFeedAddress;
 }

 NetworkConfig public activeNetworkConfig;

 constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } 
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            wethUsdPriceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306, // ETH / USD
            wbtcUsdPriceFeedAddress: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            wethAddress: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtcAddress: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
        });
    }
}
