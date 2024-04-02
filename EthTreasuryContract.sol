// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IBlast.sol";
import "./IERC20.sol";
import "./IUserHistory.sol";
import "./IOwnerGroupContract.sol";

contract EthTreasuryContract{

    //TOR token balances
    mapping(address account => uint256) private _balances;
    //Delegate token
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    mapping(address account => uint256) private _torBalances;
    mapping(address account => uint256) private _ethBalances;

    uint256 public _totalTorBalance=0;
    uint256 public _totalEthBalance=0;
    uint256 public _exchangeRate;
    uint8 public _depositFeeRate;
    uint8 public _withdrawFeeRate;
    uint8 private _decimal=18;
    address private _owner;
    IERC20 private _token;
    IUserHistory private _historyToken;
    IOwnerGroupContract private _ownerGroupContract;

    mapping(uint => WithdrawContractEthTransaction) private withdrawContractEthTransactions;
    mapping(uint => mapping(address =>bool)) isConfirmedWithdrawContractEthTransactions;

    uint private transactionCount = 0;
    struct WithdrawContractEthTransaction {
        address toAddress;
        uint amount;
        bool executed;
        uint confirmationCount;
    }

    event SubmitEthWithdrawTransaction(address indexed toAddress, uint amount);
    event ConfirmTransaction(address indexed owner, uint transactionIndex);
    event ExecuteTransaction(address indexed owner, uint transactionIndex);
    event RevokeConfirmation(address indexed owner, uint transactionIndex);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut);
    event Withdrawal(address indexed sender, uint256 amountOut);

    modifier onlyOwner (){
        require(_ownerGroupContract.isOwner(msg.sender), "Only Owner have a permission.");
        _;
    }

    constructor(address torTokenContractAddress, address ownerGroupContractAddress, address historyTokenContractAddress) {
        _owner = msg.sender;
        _token = IERC20(torTokenContractAddress);
        _ownerGroupContract = IOwnerGroupContract(ownerGroupContractAddress);
        _historyToken = IUserHistory(historyTokenContractAddress);
        _exchangeRate = 5000;
        _depositFeeRate = 1;
        _withdrawFeeRate = 2;
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();
    }

    function updateUserHistoryContractAddress(address historyToken) external onlyOwner returns (bool){
        _historyToken = IUserHistory(historyToken);
        return true;
    }

    function getUserHistoryContractAddress() external onlyOwner view returns (address){
        return address(_historyToken);
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

    function claimAllGas() external onlyOwner {
        // This function is public meaning anyone can claim the gas
        IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), msg.sender);
    }

    function readGasParams() external view onlyOwner returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return IBlast(0x4300000000000000000000000000000000000002).readGasParams(address(this));
    }


    function submitEthWithdrawTransaction(address toAddress, uint amount) onlyOwner public returns (uint)
    {
        require(toAddress != address(0), "Invalid withdrawal Address");
        require(address(this).balance - _totalEthBalance <= amount, "Not enough ETH Balance");

        withdrawContractEthTransactions[transactionCount] = WithdrawContractEthTransaction({
            toAddress: toAddress,
            amount: amount,
            executed: false,
            confirmationCount: 0
        });

        emit SubmitEthWithdrawTransaction(toAddress, amount);

        return transactionCount++;
    }

    function confirmTransaction(uint transactionIndex) onlyOwner public
    {
        require(!withdrawContractEthTransactions[transactionIndex].executed, "Transaction already executed");
        require(!isConfirmedWithdrawContractEthTransactions[transactionIndex][msg.sender], "Transaction already confirmed");

        withdrawContractEthTransactions[transactionIndex].confirmationCount++;
        isConfirmedWithdrawContractEthTransactions[transactionIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, transactionIndex);

        uint ownerConfirm = _ownerGroupContract.getOwnerCount() / 2;
        if(withdrawContractEthTransactions[transactionIndex].confirmationCount > ownerConfirm){
            executeTransaction(transactionIndex);
        }
    }

    function executeTransaction(uint transactionIndex) private {

        withdrawContractEthTransactions[transactionIndex].executed = true;
        _withdrawContractEth(withdrawContractEthTransactions[transactionIndex].toAddress, withdrawContractEthTransactions[transactionIndex].amount);

        emit ExecuteTransaction(withdrawContractEthTransactions[transactionIndex].toAddress, transactionIndex);
    }

    function revokeConfirmation(uint transactionIndex) onlyOwner public {
        require(!withdrawContractEthTransactions[transactionIndex].executed, "Transaction already executed");
        require(isConfirmedWithdrawContractEthTransactions[transactionIndex][msg.sender], "Transaction not confirmed");

        withdrawContractEthTransactions[transactionIndex].confirmationCount--;
        isConfirmedWithdrawContractEthTransactions[transactionIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, transactionIndex);
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

    function _withdrawContractEth(address toAddress, uint256 amount) private {
        payable(toAddress).transfer(amount);
        emit Transfer(address(this), toAddress, amount);
    }

    // Fallback function to receive Ether
    receive() external payable {
        // This function allows the contract to receive Ether directly
        deposit();
    }

    function deposit() public payable returns (bool success){
        require(msg.value > 0, "ETH amount must be greater than 0");

        // deposit fee 1%
        uint256 ethAmount =  msg.value / (100 + _depositFeeRate) * 100;

        _totalEthBalance += ethAmount;
        uint256 torTokenAmount = (ethAmount * _exchangeRate);

        _totalTorBalance+=torTokenAmount;

        _ethBalances[msg.sender]+=ethAmount;
        _torBalances[msg.sender]+=torTokenAmount;

        _token.transfer(msg.sender, torTokenAmount);

        _historyToken.setDepositActivity(msg.sender, block.timestamp, torTokenAmount, _torBalances[msg.sender]);

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

        _ethBalances[msg.sender]-=ethAmount;
        _torBalances[msg.sender]-=tokenAmount;

        // Transfer deposited ERC-20 tokens back to the sender
        _token.transferFrom(msg.sender, address(this), tokenAmount);

        // Transfer deposited ETH back to the sender
        payable(msg.sender).transfer(ethAmount);

        _historyToken.setWithdrawActivity(msg.sender, block.timestamp, tokenAmount, _torBalances[msg.sender]);

        // Emit Withdrawal event
        emit Withdrawal(msg.sender, ethAmount);
    }

    function getSwappedUserEthBalance(address account) external view returns(uint256){
        return _ethBalances[account];
    }

    function getSwappedUserTorBalance(address account) external view returns(uint256){
        return _torBalances[account];
    }
}
