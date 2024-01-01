//SPDX-License-Identifier:MIT

pragma solidity ^ 0.8.0;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
contract walletToken is ERC20 {

constructor(uint256 _initialSupply) ERC20("divineToken","DVT") {
_mint(msg.sender,_initialSupply);
}

function mint() public {
    
}
}