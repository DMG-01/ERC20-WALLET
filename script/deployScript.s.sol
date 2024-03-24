//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {Script} from "lib/forge-std/src/Script.sol";
import {Main} from "chance/mainContract.sol";
import {CourseWinOrLose} from "chance/courseWinOrLose.sol";
import {HomeAwayDraw} from "chance/homeAwayDraw.sol";
import {NumberOfGoals} from "chance/numberOfGoals.sol";

contract DeployScript is Script {
  string _name = "name";

    function run() external returns(Main, CourseWinOrLose, HomeAwayDraw, NumberOfGoals){
    
    vm.startBroadcast();
    Main mainWallet = new Main();
    CourseWinOrLose courseWinOrLose = new CourseWinOrLose(_name);
    HomeAwayDraw homeAwayDraw = new HomeAwayDraw(_name);
    NumberOfGoals numberOfGoals = new NumberOfGoals(_name);
    vm.stopBroadcast();
    return(mainWallet,courseWinOrLose,homeAwayDraw,numberOfGoals);
    }
}
