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

    function setTokenAddress (address _input) public onlyOwner {
        TokenAddress = _input;
    }

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

    function redeem(address _sender, address _toToken, uint _amount, uint _tochainID, uint _Nonce, bytes memory _signature) public{
        if(!transactionCompleted[_tochainID][_toToken][_Nonce])
            revert doublespenderror();
        bytes32 message = prefixed(keccak256(abi.encodePacked(_sender, _toToken, _amount, _tochainID, _Nonce)));
        if(recoverSigner(message, _signature) != _sender)
            revert wrongsignatureerror();
        transactionCompleted[_tochainID][_toToken][_Nonce] = true;
        ITokenNetwork(_toToken).mint(_sender, _amount);
    }


  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }

  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
  
    (v, r, s) = splitSignature(sig);
  
    return ecrecover(message, v, r, s);
  }

  function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
    bytes32 r;
    bytes32 s;
    uint8 v;
  
    assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
    }
    return (v, r, s);
  }

    function updateChainById(uint _chainID, bool _action) public onlyOwner{
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
    }

    function includeToken(uint _chainID, address _token) public onlyOwner{
        if(_token == address(0))
            revert incorrectaddress();
        if(bridges[_chainID].permittedToken[_token])
            revert existToken(_token, true);

        updateChainById(_chainID, true);
        bridges[_chainID].permittedToken[_token] = true;
    }

    function excludeToken(uint _chainID, address _token) public onlyOwner{
        if(_token == address(0))
            revert incorrectaddress();
        if((bridges[_chainID].chainID == 0) || _chainID == 0)
            revert incorrectChainID();
        if(!bridges[_chainID].permittedToken[_token])
            revert nonexistToken(_token, false);

        bridges[_chainID].permittedToken[_token] = false;
    }

}