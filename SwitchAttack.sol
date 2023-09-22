// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Switch.sol";

contract SwitchAttack {

    address public sw;

    constructor(address _switch) {
        sw = _switch;
    }

    function turn(bytes memory _data) external returns (bool) {
        (bool success, ) = sw.call(_data);
        return success;
    }

}