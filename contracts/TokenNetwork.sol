//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

error ownersonly();

contract TokenNetwork is ERC20 {

    address public bridge;
    address public owner;

    constructor() ERC20("TokenNetwork", "TNW"){
        owner = msg.sender;
    }

    function setBridgeaddress (address _input) public {
        if((msg.sender != owner) && (msg.sender != bridge))
            revert ownersonly();
        bridge = _input;
    }

    function mint(address _account, uint _amount) public {
        if((msg.sender != owner) && (msg.sender != bridge))
            revert ownersonly();
        _mint(_account, _amount);
    }

    function burn(address _account, uint _amount) public  {
        if((msg.sender != owner) && (msg.sender != bridge))
            revert ownersonly();
        _burn(_account, _amount);
    }
}