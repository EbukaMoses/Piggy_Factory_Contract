//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "./KoloBank.sol";

contract KoloFactory {
    address public immutable developerAddress;
    uint256 public piggyCount;
    error youHaveFailed();

    constructor() {
        developerAddress = msg.sender;
    }

    mapping(address => address[]) public userDeployedContracts;

    function getPiggyByteCode(
        string memory _purpose,
        uint256 duedate
    ) external view returns (bytes memory) {
        bytes memory _bytecode = type(KoloBank).creationCode;
        return
            abi.encodePacked(
                _bytecode,
                abi.encode(_purpose, duedate, msg.sender, developerAddress)
            );
    }

    function createPiggy(bytes memory _bytecode) external returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, piggyCount));
        piggyCount++;

        address piggyAddress;
        assembly {
            piggyAddress := create2(
                0,
                add(_bytecode, 0x20),
                mload(_bytecode),
                salt
            )
            if iszero(piggyAddress) {
                revert(0, 0)
            }
        }

        userDeployedContracts[msg.sender].push(piggyAddress);
        return piggyAddress;
    }

    function getUserDeployedContracts(
        address user
    ) external view returns (address[] memory) {
        return userDeployedContracts[user];
    }
}
