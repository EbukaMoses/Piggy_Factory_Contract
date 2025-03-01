// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "./IERC20.sol";

error InsuffucientBalance();

contract Piggy {
    string public purpose;
    uint8 public constant PENALTY_FEE = 15;
    address public tokenAddress;
    uint256 public startTime;
    uint256 public endTime;

    // address[3] public supportedTokens;

    // uint256[] public saveHistory;

    constructor(
        string memory _purpose,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress
    ) {
        purpose = _purpose;
        startTime = _startTime;
        endTime = _endTime;
        tokenAddress = _tokenAddress;
    }

    function withdraw(address _saver, address _otherTokenAddress) public {
        uint256 _balance = IERC20(tokenAddress).balanceOf(address(this));

        if (_balance == 0) revert InsuffucientBalance();

        if ((endTime > block.timestamp) && (_otherTokenAddress == address(0))) {
            uint256 _fee = (_balance * PENALTY_FEE) / 100;
            uint256 _amount = _balance - _fee;
            require(
                IERC20(tokenAddress).transfer(_saver, _amount),
                "Withdrawal Failed"
            );
            require(
                IERC20(tokenAddress).transfer(msg.sender, _fee),
                "Withdrawal Failed"
            );

            return;
        } else if (
            (endTime > block.timestamp) && (_otherTokenAddress == address(0))
        ) {
            require(
                IERC20(tokenAddress).transfer(_saver, _balance),
                "Withdrawal Failed"
            );
            return;
        } else if (
            (_saver == address(0)) &&
            (_otherTokenAddress != address(0)) &&
            (tokenAddress != _otherTokenAddress)
        ) {
            uint256 _otherBalance = IERC20(_otherTokenAddress).balanceOf(
                address(this)
            );
            if (_otherBalance == 0) revert InsuffucientBalance();

            require(
                IERC20(_otherTokenAddress).transfer(msg.sender, _otherBalance),
                "withdrawal Failed"
            );

            return;
        }
    }
}
