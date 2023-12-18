//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Wallet} from "src/walletToken.sol";

contract deployWallet is Script{

function run() external returns(Wallet){
    
    vm.startBroadcast();
    Wallet wallet =new Wallet();
    vm.stopBroadcast();
    return(wallet);
}
}