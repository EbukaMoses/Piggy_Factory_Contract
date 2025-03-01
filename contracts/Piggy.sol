//SPDX-Lincense-Identifier: UNLINCENSED
pagma solidity 0.8.28;
import "./IERC20.sol"

contract KoloBank{

    string public purpose;  //Our Reason for saving
    uint256 public duedate; //Date we would like to withdraw all our fund
    address devAddr;

    enum Tokens {USDT, USDC, DAI}; //enum of the list of tokens accepted in this KoloBank

    struct TokenDetails{
        address tokenAddr; //Address of the contract
        uint256 balance;      //Balance of the contract
    }

    mapping(Tokens => TokenDetails) public tokenDetailMap;  //tracking the address and balance of all the tokens
   
    constructor(string memory _purpose, uint256 _duedate, address _devAddr) {
        
        tokenDetailMap[Tokens.USDT] = TokenDetails(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0);  //initializing my token address
        tokenDetailMap[Tokens.USDC] = TokenDetails(0xdAC17F958D2ee523a2206206994597C13D831ec7, 0);  //initializing my token address
        tokenDetailMap[Tokens.DAI] = TokenDetails(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0);   //initializing my token address
        
        purposr = _purpose;
        duedate = _duedate;
        onwer = msg.sender;
        devAddr = _devAddr
        
    }

    modifier isWithDraw() {
        require(isWithDraw == false, "" );
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can do this!!");
    }

    //error messages
    error TOKEN_NOT_ACCEPTED()
    error AMOUNT_NOT_ACCEPTED()
    error CUSTOMER_ADDRESS_NOT_ACCEPTED()
    error INSUFFICIENT_BALANCE()
    error SAVINGS_CLOSED()
    


    //events
    event Save(address indexed, uint256 _amount);
    event withdrawn(address indexed, uint256 _amount);

    //function to save token
    function saveToken(uint8 _tokenId, uint256 _amount) external {
        address _tokenAddr = tokenDetailMap[_tokenId].tokenAddr;
        if(_tokenId > 0 && _tokenId < 4) revert TOKEN_NOT_ACCEPTED();
        if(_amount == 0) revert AMOUNT_NOT_ACCEPTED();
        if(msg.sender === address(0)) revert CUSTOMER_ADDRESS_NOT_ACCEPTED(); 
        if(IERC20(_tokenAddr).balanceOf(msg.sender) < _amount) revert INSUFFICIENT_BALANCE();
        if(block.timestamp > duedate) revert SAVINGS_CLOSED();
        IERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount); //tranfering _amoumt to the customer account

        tokenDetailMap[_tokenId].balance += _amount;

        emit Save(address(this), _amount);

    }

    function withdrawToken(uint8 _tokenId) external onlyOwner  isWithdraw{
        address _tokenAddr = tokenDetailMap[_tokenId].tokenAddr;
        uint256 _balance = tokenDetailMap[_tokenId].balance;
        if(IERC20(_tokenAddr).balanceOf(_balance) == 0) revert INSUFFICIENT_BALANCE();
        if(msg.sender === address(0)) revert CUSTOMER_ADDRESS_NOT_ACCEPTED(); 
        

        if(block.timestamp < duedate){
            //we take penality charge
            uint256 penaltyFee = IERC20(_tokenAddr).balanceOf(address(0)) * 0.15;
            uint256 contractBal = IERC20(_tokenAddr).balanceOf(address(0));
            uint256 amountBroken  = contractBal - penaltyFee;
            _balance = 0;
            withdraw = true;
            IERC20(_tokenAddr).transfer(msg.sender, amountBroken);
            IERC20(_tokenAddr).transfer(devAddr, penaltyFee);

            emit withdraw(msg.sender, amountBroken);

        }else{
            uint256 contractBal = IERC20(_tokenAddr).balanceOf(address(0));
            _balance = 0;
            withdrawn = true;
             IERC20(_tokenAddr).transfer(msg.sender, contractBal)
            emit withdrawn(msg.sender, contractBal);
        }

    }
}
