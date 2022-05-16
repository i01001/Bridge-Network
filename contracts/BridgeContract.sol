//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ITokenNetwork.sol";
import "hardhat/console.sol";

/// @dev error messages to revert functions
error incorrectaddress();
error existToken(address, bool);
error nonexistToken(address, bool);
error incorrectChainID();
error chainIDdoesntexist();
error chainIDexist();
error doublespenderror();
error wrongsignatureerror();

/// @title Bridge Network Contract for transferring ERC20 tokens across different chains
/// @author Ikhlas
/// @notice The contract does not have the ERC20 Tokens Contract hardcorded and can be used with other Token Contracts
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract BridgeContract is Ownable {
    using Counters for Counters.Counter;

    /// @notice Allows users to transfer ERC20 tokens across chains
    /// @dev Additional features can be added such as limiting token transfers to certain pairs or conversion / exchange rates
    /// @notice Counters are used for couting the nonce
    address public TokenAddress;
    Counters.Counter public _nonce;

    /// @dev Variables for the contract
    /// @notice Struct Bridge - to store the permitted chains and tokens
    struct Bridge {
        uint256 chainID;
        mapping(address => bool) permittedToken;
    }

    /// @notice bridges - mapping the chainID to the bridge struct
    /// @notice transactionCompleted - mapping the chainID to the Token Contract to the Nonce to the bool whether transaction completed
    mapping(uint256 => Bridge) public bridges;
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) transactionCompleted;

    /// @notice swapInitialized - Event emitted when successful swap function executed
    event swapInitialized(
        address _sender,
        address _toToken,
        uint256 _amount,
        uint256 _tochainID,
        uint256 _nonce
    );

    constructor() {}

    // function setTokenAddress (address _input) public onlyOwner {
    //     TokenAddress = _input;
    // }

    /// @notice swap - Deducts the token from the user and creates the swapInitialized event
    function swap(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        uint256 _tochainID
    ) public {
        if ((_fromToken == address(0)) || (_toToken == address(0)))
            revert incorrectaddress();
        if (!bridges[block.chainid].permittedToken[_fromToken])
            revert nonexistToken(_fromToken, false);
        if (!bridges[_tochainID].permittedToken[_toToken])
            revert nonexistToken(_toToken, false);

        ITokenNetwork(_fromToken).burn(msg.sender, _amount);
        _nonce.increment();
        emit swapInitialized(
            msg.sender,
            _toToken,
            _amount,
            _tochainID,
            _nonce.current()
        );
    }

    /// @notice redeem - Verifies whether the signature matches the hash and transacts the new tokens
    function redeem(
        address _sender,
        address _toToken,
        uint256 _amount,
        uint256 _tochainID,
        uint256 _Nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        if (transactionCompleted[_tochainID][_toToken][_Nonce])
            revert doublespenderror();
        if (
            checkSign(
                _sender,
                _toToken,
                _amount,
                _tochainID,
                _Nonce,
                v,
                r,
                s
            ) == true
        ) {
            transactionCompleted[_tochainID][_toToken][_Nonce] = true;
            ITokenNetwork(_toToken).mint(_sender, _amount);
        } else {
            revert wrongsignatureerror();
        }
    }

    /// @notice checkSign - Internal function to verify the hash message and signature matches with the signer
    function checkSign(
        address _sender,
        address _toToken,
        uint256 _amount,
        uint256 _tochainID,
        uint256 _Nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes32 message = keccak256(
            abi.encodePacked(_sender, _toToken, _amount, _tochainID, _Nonce)
        );
        address addr = ecrecover(hashMessage(message), v, r, s);
        if (addr == _sender) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice hashMessage - Internal function to hash the parameter message with the phrase
    function hashMessage(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /// @notice updateChainById - Adding or removing chainIDs that could be transacted through this contract
    function updateChainById(uint256 _chainID, bool _action)
        public
        onlyOwner
        returns (bool)
    {
        if (_chainID == 0) revert incorrectChainID();
        if ((_action == false) && (bridges[_chainID].chainID != _chainID))
            revert chainIDdoesntexist();

        if (_action == true) {
            bridges[_chainID].chainID = _chainID;
        } else {
            bridges[_chainID].chainID = 0;
        }
        return true;
    }

    /// @notice includeToken - Adding tokens with respective chainID that could be transacted through this contract
    function includeToken(uint256 _chainID, address _token)
        public
        onlyOwner
        returns (bool)
    {
        if (_token == address(0)) revert incorrectaddress();
        if (bridges[_chainID].permittedToken[_token])
            revert existToken(_token, true);

        updateChainById(_chainID, true);
        bridges[_chainID].permittedToken[_token] = true;

        return true;
    }

    /// @notice excludeToken - Removing tokens with respective chainID that could be transacted through this contract
    function excludeToken(uint256 _chainID, address _token)
        public
        onlyOwner
        returns (bool)
    {
        if (_token == address(0)) revert incorrectaddress();
        if ((bridges[_chainID].chainID == 0) || _chainID == 0)
            revert incorrectChainID();
        if (!bridges[_chainID].permittedToken[_token])
            revert nonexistToken(_token, false);

        bridges[_chainID].permittedToken[_token] = false;

        return true;
    }
}
