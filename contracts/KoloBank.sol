//SPDX-Lincense-Identifier: UNLINCENSED
pragma solidity 0.8.28;
import "./IERC20.sol";

contract KoloBank {
    string public purpose; //Our Reason for saving
    uint256 public duedate; //Date we would like to withdraw all our fund
    address devAddr;
    address owner;
    bool hasWithDrawn;

    enum Tokens {
        USDT,
        USDC,
        DAI
    } //enum of the list of tokens accepted in this KoloBank

    struct TokenDetails {
        address tokenAddr; //Address of the contract
        uint256 balance; //Balance of the contract
    }

    mapping(Tokens => TokenDetails) public tokenDetailMap; //tracking the address and balance of all the tokens

    constructor(string memory _purpose, uint256 _duedate, address _devAddr) {
        tokenDetailMap[Tokens.USDT] = TokenDetails(
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            0
        ); //initializing my token address
        tokenDetailMap[Tokens.USDC] = TokenDetails(
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            0
        ); //initializing my token address
        tokenDetailMap[Tokens.DAI] = TokenDetails(
            0x6B175474E89094C44Da98b954EedeAC495271d0F,
            0
        ); //initializing my token address

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

    //error messages
    error TOKEN_NOT_ACCEPTED();
    error AMOUNT_NOT_ACCEPTED();
    error CUSTOMER_ADDRESS_NOT_ACCEPTED();
    error INSUFFICIENT_BALANCE();
    error SAVINGS_CLOSED();

    //events
    event Save(address indexed, uint256 _amount);
    event withdraw(address indexed, uint256 _amount);

    //function to save token
    function saveToken(uint256 _tokenId, uint256 _amount) external {
        address _tokenAddr = tokenDetailMap[_tokenId].tokenAddr;
        if (_tokenId > 0 && _tokenId < 4) revert TOKEN_NOT_ACCEPTED();
        if (_amount == 0) revert AMOUNT_NOT_ACCEPTED();
        if (msg.sender == address(0)) revert CUSTOMER_ADDRESS_NOT_ACCEPTED();
        if (IERC20(_tokenAddr).balanceOf(msg.sender) < _amount)
            revert INSUFFICIENT_BALANCE();
        if (block.timestamp > duedate) revert SAVINGS_CLOSED();
        IERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount); //tranfering _amoumt to the customer account

        tokenDetailMap[_tokenId].balance += _amount;

        emit Save(address(this), _amount);
    }

    function withdrawToken(uint256 _tokenId) external onlyOwner isWithDrawn {
        address _tokenAddr = tokenDetailMap[_tokenId].tokenAddr;
        uint256 _balance = tokenDetailMap[_tokenId].balance;

        // Check if the contract balance for the token is zero
        uint256 contractBal = IERC20(_tokenAddr).balanceOf(address(this));
        if (contractBal == 0) revert INSUFFICIENT_BALANCE();

        // Ensure the sender is not the zero address
        if (msg.sender == address(0)) revert CUSTOMER_ADDRESS_NOT_ACCEPTED();

        // If the contract has not passed the due date, apply penalty
        if (block.timestamp < duedate) {
            uint256 penaltyPercent = 15; // 15% penalty
            uint256 penaltyFee = (contractBal * penaltyPercent) / 100; // Correct penalty fee calculation
            uint256 amountAfterPenalty = contractBal - penaltyFee;

            // Update state to reflect the withdrawal
            hasWithDrawn = true;

            // Transfer the remaining balance (after penalty) to the sender
            IERC20(_tokenAddr).transfer(msg.sender, amountAfterPenalty);

            // Transfer the penalty fee to the developer address
            IERC20(_tokenAddr).transfer(devAddr, penaltyFee);

            // Emit the withdrawal event
            emit withdraw(msg.sender, amountAfterPenalty);
        } else {
            // If due date has passed, transfer the full contract balance to the sender
            hasWithDrawn = true;
            IERC20(_tokenAddr).transfer(msg.sender, contractBal);

            // Emit the withdrawal event
            emit withdraw(msg.sender, contractBal);
        }
    }
}
