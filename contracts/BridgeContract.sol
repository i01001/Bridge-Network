//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ITokenNetwork.sol";
import "hardhat/console.sol";

error incorrectaddress();
error existToken(address, bool);
error nonexistToken(address, bool);
error incorrectChainID();
error chainIDdoesntexist();
error chainIDexist();
error doublespenderror();
error wrongsignatureerror();

contract BridgeContract is Ownable{
    using Counters for Counters.Counter;

    address public TokenAddress;
    Counters.Counter public _nonce; 

    struct Bridge {
        uint chainID;
        mapping (address => bool) permittedToken;
    }

    mapping (uint => Bridge) public bridges; 
    mapping (uint => mapping (address => mapping (uint => bool))) transactionCompleted; 
    
    event swapInitialized(address _sender, address _toToken, uint _amount, uint _tochainID, uint _nonce);

    constructor(){
    }

    // function setTokenAddress (address _input) public onlyOwner {
    //     TokenAddress = _input;
    // }

    function swap (address _fromToken, address _toToken, uint _amount, uint _tochainID) public {
        if((_fromToken == address(0)) || (_toToken == address(0))) 
            revert incorrectaddress();
        if(!bridges[block.chainid].permittedToken[_fromToken])
            revert nonexistToken(_fromToken, false);
        if(!bridges[_tochainID].permittedToken[_toToken])
            revert nonexistToken(_toToken, false);

        ITokenNetwork(_fromToken).burn(msg.sender, _amount);
        _nonce.increment();
        emit swapInitialized(msg.sender, _toToken, _amount, _tochainID, _nonce.current());
    }

    function redeem(address _sender, address _toToken, uint _amount, uint _tochainID, uint _Nonce, uint8 v, bytes32 r, bytes32 s) public{
        if(transactionCompleted[_tochainID][_toToken][_Nonce])
            revert doublespenderror();
        if(checkSign(_sender, _toToken, _amount, _tochainID, _Nonce, v, r, s) == true){
        transactionCompleted[_tochainID][_toToken][_Nonce] = true;
        ITokenNetwork(_toToken).mint(_sender, _amount);
        }
        else{
            revert wrongsignatureerror();
        }
    }

    function checkSign(address _sender,address _toToken, uint256 _amount, uint256 _tochainID, uint256 _Nonce, uint8 v, bytes32 r, bytes32 s ) public view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(_sender, _toToken, _amount, _tochainID, _Nonce));
        address addr = ecrecover(hashMessage(message), v, r, s);
        if (addr == _sender) {
            return true;
        } else {
            return false;
        }
    }

  function hashMessage(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }


    function updateChainById(uint _chainID, bool _action) public onlyOwner returns(bool){
        if(_chainID == 0)
            revert incorrectChainID();
        if((_action == false) && (bridges[_chainID].chainID != _chainID))
            revert chainIDdoesntexist();

        if(_action == true){
            bridges[_chainID].chainID = _chainID;
        }
        else{
            bridges[_chainID].chainID = 0;
        }
        return true;
    }

    function includeToken(uint _chainID, address _token) public onlyOwner returns(bool){
        if(_token == address(0))
            revert incorrectaddress();
        if(bridges[_chainID].permittedToken[_token])
            revert existToken(_token, true);

        updateChainById(_chainID, true);
        bridges[_chainID].permittedToken[_token] = true;

        return true;
    }

    function excludeToken(uint _chainID, address _token) public onlyOwner returns(bool){
        if(_token == address(0))
            revert incorrectaddress();
        if((bridges[_chainID].chainID == 0) || _chainID == 0)
            revert incorrectChainID();
        if(!bridges[_chainID].permittedToken[_token])
            revert nonexistToken(_token, false);

        bridges[_chainID].permittedToken[_token] = false;
        
        return true;
    }

}