//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import {Test} from "forge-std/Test.sol";
import {Wallet} from "src/walletToken.sol";
import {deployWallet} from "script/walletTokenDeployScript.s.sol";
import { ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract walletTest is Test {

deployWallet deployer;
Wallet wallet;
address public USER1 = makeAddr("user");
address public constant weth = 0xdd13E55209Fd76AfE204dBda4007C227904f0a81;
uint256 constant public STARTING_BALANCE = 10 ether;



function setUp() public {
    deployer = new deployWallet();
     wallet = deployer.run();
    // ERC20Mock(weth).mint(address(USER1),STARTING_BALANCE);
}

function testFundAccountWillRevertWithZero() public {
    vm.startPrank(USER1);
    ERC20Mock(weth).mint(address(USER1),STARTING_BALANCE);
    ERC20Mock(weth).approve(address(wallet),STARTING_BALANCE);
    wallet.fundAccount(weth,0);
    vm.expectRevert(Wallet.needsMoreThanZero.selector);
    vm.stopPrank();

}
 function testFundAccount() public {
       // ERC20Mock(weth).mint(USER1,STARTING_BALANCE);
        ERC20Mock(weth).approve(address(wallet), STARTING_BALANCE);
        wallet.fundAccount(weth, STARTING_BALANCE);
        assertEq(wallet.getUserTokenBalance(weth),STARTING_BALANCE);
    }

}