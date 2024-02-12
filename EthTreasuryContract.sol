// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IBlast.sol";
import "./IERC20.sol";


contract EthTreasuryContract {

    //TOR token balances
    mapping(address account => uint256) private _balances;
    //Delegate token
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 public _totalTorBalance=0;
    uint256 public _totalEthBalance=0;
    uint256 public _exchangeRate;
    uint8 public _depositFeeRate;
    uint8 public _withdrawFeeRate;
    uint8 private _decimal=18;
    address private _owner;
    IERC20 public _token;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
        // Event emitted when a swap occurs
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut);
    event Withdrawal(address indexed sender, uint256 amountOut);


    modifier onlyOwner(){
        require(msg.sender == _owner, "You are not the owner");
        _;
    }

    constructor(address token) {
        _token = IERC20(token);
        _owner = msg.sender;
        _exchangeRate = 5000;
        _depositFeeRate = 1;
        _withdrawFeeRate = 2;
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
    }

    function claimYield(uint256 amount, address recipientOfYield) external onlyOwner returns (uint256){
	  //This function is public meaning anyone can claim the yield
		return IBlast(0x4300000000000000000000000000000000000002).claimYield(address(this), recipientOfYield, amount);
    }

	function readClaimableYield(address contractAddress) external view onlyOwner returns (uint256){
	  //This function is public meaning anyone can claim the yield
		return IBlast(0x4300000000000000000000000000000000000002).readClaimableYield(contractAddress);
    }

	function claimAllYield(address recipientOfYield) external onlyOwner returns (uint256){
	  //This function is public meaning anyone can claim the yield
		return IBlast(0x4300000000000000000000000000000000000002).claimAllYield(address(this), recipientOfYield);
    }

    function transferEthToOwner(uint256 amount) external onlyOwner{
        payable(_owner).transfer(amount);
    }

    function getContractEthBalance() external view returns (uint256){
        return address(this).balance;
    }

    function getTorTokenBalance(address account)  external view returns (uint256) {
        return _token.balanceOf(account);
    }

    function getTorTokenName() external view returns (string memory){
        return _token._name();
    }

    function getTorTokenSymbol() external view returns (string memory){
        return _token._symbol();
    }

    function setDepositFeeRate(uint8 feeRate) external onlyOwner{
        _depositFeeRate = feeRate;
    }

    function setWithdrawFeeRate(uint8 feeRate) external onlyOwner{
        _withdrawFeeRate = feeRate;
    }

    function getAvailiableContractEthBalance() external view onlyOwner returns (uint256){

        return address(this).balance - _totalEthBalance;
    }

    function withdrawContractEth(uint256 amount) external onlyOwner {
        require(address(this).balance - _totalEthBalance <= amount, "Not enough ETH Balance");
        payable(_owner).transfer(amount);

        emit Transfer(address(this), _owner, amount);
    }

        // Fallback function to receive Ether
    receive() external payable {
        // This function allows the contract to receive Ether directly
        deposit();
    }

    function deposit() public payable returns (bool success){
        require(msg.value > 0, "ETH amount must be greater than 0");

        // deposit fee 1%
        uint256 ethAmount =  (msg.value * (100 - _depositFeeRate)) / 100;

        _totalEthBalance += ethAmount;
        uint256 torTokenAmount = (ethAmount * _exchangeRate);

        _totalTorBalance+=torTokenAmount;

        _token.transfer(msg.sender, torTokenAmount);

        emit Swap(msg.sender, ethAmount, torTokenAmount);

        return true;
    }

       // Function to withdraw deposited ETH and ERC-20 tokens
    function withdraw(uint256 tokenAmount) external {
        require(tokenAmount > 0, "Token amount must be greater than 0");
        require(_token.balanceOf(msg.sender) > tokenAmount, "Not enough TOR balance.");
        require(_token.allowance(msg.sender, address(this)) >= tokenAmount, "Insufficient allowance");


        uint256 ethAmount = tokenAmount / _exchangeRate;

        _totalTorBalance -= tokenAmount;
        // withdrawal amount fee 2%
        ethAmount = (ethAmount * (100 - _withdrawFeeRate)) / 100;
        _totalEthBalance -= ethAmount;

        // Transfer deposited ERC-20 tokens back to the sender
        _token.transferFrom(msg.sender, address(this), tokenAmount);

        // Transfer deposited ETH back to the sender
        payable(msg.sender).transfer(ethAmount);

        // Emit Withdrawal event
        emit Withdrawal(msg.sender, ethAmount);
    }


}
