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
address public weth;



function setUp() public {
    deployer = new deployWallet();
     wallet = deployer.run();
}

function testFundAccountWillRevertWithZero() public {
    vm.startPrank(USER1);
    wallet.fundAccount(weth,0);
    vm.expectRevert(Wallet.needsMoreThanZero.selector);
    vm.stopPrank();

}

}