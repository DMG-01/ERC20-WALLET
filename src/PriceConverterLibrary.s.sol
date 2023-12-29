//SPDX-License-Identifier:MIT

pragma solidity ^ 0.8.0;

import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
library  priceConverter {

function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
(, int price,,,) = priceFeed.latestRoundData();
return uint256(price * 1e10);
}

 function  getConversionRate(uint256 amount, AggregatorV3Interface _priceFeed) public view returns(uint256) {
    uint256 ethAmount = getPrice(_priceFeed);
    uint256 ethAmountInUsd = (amount * ethAmount) / 1e18;
    return(ethAmountInUsd);
 } 
}