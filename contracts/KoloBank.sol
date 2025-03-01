// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./IERC20.sol";

contract KoloBank {
    string public purpose; // Our Reason for saving
    uint256 public duedate; // Date we would like to withdraw all our funds
    address devAddr;
    address owner;
    bool hasWithDrawn;

    enum Tokens {
        USDT,
        USDC,
        DAI
    } // Enum of the list of tokens accepted in this KoloBank

    struct TokenDetails {
        address tokenAddr; // Address of the contract
        uint256 balance; // Balance of the contract
    }

    mapping(Tokens => TokenDetails) public tokenDetailMap; // Tracking the address and balance of all the tokens

    constructor(string memory _purpose, uint256 _duedate, address _devAddr) {
        tokenDetailMap[Tokens.USDT] = TokenDetails(
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            0
        ); // Initializing my token address
        tokenDetailMap[Tokens.USDC] = TokenDetails(
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            0
        ); // Initializing my token address
        tokenDetailMap[Tokens.DAI] = TokenDetails(
            0x6B175474E89094C44Da98b954EedeAC495271d0F,
            0
        ); // Initializing my token address

        purpose = _purpose;
        duedate = _duedate;
        owner = msg.sender;
        devAddr = _devAddr;
    }

    modifier isWithDrawn() {
        require(hasWithDrawn == false, "Withdrawal has been DONE!!!");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can do this!!");
        _;
    }

    // Error messages
    error TOKEN_NOT_ACCEPTED();
    error AMOUNT_NOT_ACCEPTED();
    error CUSTOMER_ADDRESS_NOT_ACCEPTED();
    error INSUFFICIENT_BALANCE();
    error SAVINGS_CLOSED();

    // Events
    event Save(address indexed, uint256 _amount);
    event Withdraw(address indexed, uint256 _amount);

    // Function to save token
    function saveToken(uint256 _tokenId, uint256 _amount) external {
        if (_tokenId > uint256(Tokens.DAI)) revert TOKEN_NOT_ACCEPTED(); // Validate token ID
        address _tokenAddr = tokenDetailMap[Tokens(_tokenId)].tokenAddr;

        if (_amount == 0) revert AMOUNT_NOT_ACCEPTED();
        if (msg.sender == address(0)) revert CUSTOMER_ADDRESS_NOT_ACCEPTED();

        uint256 senderBalance = IERC20(_tokenAddr).balanceOf(msg.sender);
        if (senderBalance < _amount) revert INSUFFICIENT_BALANCE();
        if (block.timestamp > duedate) revert SAVINGS_CLOSED();

        // Transfer the tokens to the contract
        IERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount);

        // Update the balance
        tokenDetailMap[Tokens(_tokenId)].balance += _amount;

        // Emit the save event
        emit Save(address(this), _amount);
    }

    // Function to withdraw token
    function withdrawToken(uint256 _tokenId) external onlyOwner isWithDrawn {
        if (_tokenId > uint256(Tokens.DAI)) revert TOKEN_NOT_ACCEPTED(); // Validate token ID

        address _tokenAddr = tokenDetailMap[Tokens(_tokenId)].tokenAddr;
        uint256 contractBal = IERC20(_tokenAddr).balanceOf(address(this));

        if (contractBal == 0) revert INSUFFICIENT_BALANCE();

        // If the contract has not passed the due date, apply penalty
        uint256 penaltyPercent = 15; // 15% penalty
        uint256 penaltyFee = (contractBal * penaltyPercent) / 100;
        uint256 amountAfterPenalty = contractBal - penaltyFee;

        hasWithDrawn = true;

        // Transfer the remaining balance (after penalty) to the owner
        IERC20(_tokenAddr).transfer(msg.sender, amountAfterPenalty);

        // Transfer the penalty fee to the developer address
        IERC20(_tokenAddr).transfer(devAddr, penaltyFee);

        // Emit the withdrawal event
        emit Withdraw(msg.sender, amountAfterPenalty);
    }
}
