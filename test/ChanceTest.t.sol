//SPDX-License-Identifier:MIT

pragma solidity ^ 0.8.18;
import {Test, console} from "lib/forge-std/src/Test.sol";
import {Main} from "chance/mainContract.sol";
import {CourseWinOrLose} from "chance/courseWinOrLose.sol";
import {HomeAwayDraw} from "chance/homeAwayDraw.sol";
import {NumberOfGoals} from "chance/numberOfGoals.sol";
import {DeployScript} from "script/deployScript.s.sol";

contract MainTest is Test{

Main mainContract;
CourseWinOrLose courseWinOrlose;
HomeAwayDraw homeAwayDraw;
NumberOfGoals numberOfGoals;
DeployScript deployer;


address USER1 = makeAddr("USER1");


function setUp() public {
    deployer = new DeployScript();
    (mainContract,courseWinOrlose,homeAwayDraw,numberOfGoals) = deployer.run();
    
}

function testDeployerIsFirstOwner() public {
    vm.startPrank(USER1);
    deployer = new DeployScript();
    (mainContract,,,) = deployer.run();
    address actualAddress= mainContract.returnFirstOwner();
   vm.stopPrank();
   assertEq(actualAddress,USER1);
}


}