// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SVCEToken is ERC20 {
    address public admin;

    constructor() ERC20("SVCE TOKEN", "SVCE") {
        admin = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "Only admin can mint");
        _mint(to, amount);
    }
}


//SVCETOKEN.sol- 0xfbA33c20a906daFC8b206d3e14d2cACD9f079256
//Tx link- https://seitrace.com/tx/0x26324020bdb84b6e645affabb0834f9f450d05d8c1606346fdd35baee85728ff?chain=atlantic-2
