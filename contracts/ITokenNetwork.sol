//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "hardhat/console.sol";

interface ITokenNetwork {
    function mint(address _account, uint _amount) external;

    function burn(address _account, uint _amount) external;

}