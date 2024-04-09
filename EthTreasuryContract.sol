// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IBlast.sol";
import "./IBlastPoints.sol";
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
    address private _ownerGroupContractAddress;


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
        _depositFeeRate = 0;
        _withdrawFeeRate = 0;
        _ownerGroupContractAddress = ownerGroupContractAddress;
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();
        //testnet
        IBlastPoints(0x2fc95838c71e76ec69ff817983BFf17c710F34E0).configurePointsOperator(msg.sender);
    }

    function updateUserHistoryContractAddress(address historyToken) external onlyOwner returns (bool){
        _historyToken = IUserHistory(historyToken);
        return true;
    }

    function getUserHistoryContractAddress() external onlyOwner view returns (address){
        return address(_historyToken);
    }

    function claimYield(uint256 amount) external onlyOwner returns (uint256){
        //This function is public meaning anyone can claim the yield
        return IBlast(0x4300000000000000000000000000000000000002).claimYield(address(this), _ownerGroupContractAddress, amount);
    }

    function readClaimableYield() external view onlyOwner returns (uint256){
        //This function is public meaning anyone can claim the yield
        return IBlast(0x4300000000000000000000000000000000000002).readClaimableYield(address(this));
    }

    function claimAllYield() external onlyOwner returns (uint256){
        //This function is public meaning anyone can claim the yield
        return IBlast(0x4300000000000000000000000000000000000002).claimAllYield(address(this), _ownerGroupContractAddress);
    }

    function claimAllGas() external onlyOwner returns (uint256){
        // This function is public meaning anyone can claim the gas
        return IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), _ownerGroupContractAddress);
    }

    function readGasParams() external view onlyOwner returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return IBlast(0x4300000000000000000000000000000000000002).readGasParams(address(this));
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

    function withdrawContractEth(uint256 amount) public onlyOwner {
        require(address(this).balance - _totalEthBalance >= amount, "Not enough ETH Balance");

        payable(_ownerGroupContractAddress).transfer(amount);
        emit Transfer(address(this), _ownerGroupContractAddress, amount);
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
        require(_token.balanceOf(msg.sender) >= tokenAmount, "Not enough TOR balance.");
        require(_token.allowance(msg.sender, address(this)) >= tokenAmount, "Insufficient allowance");


        uint256 ethAmount = tokenAmount / _exchangeRate;

        _totalTorBalance -= tokenAmount;
        ethAmount = (ethAmount * (100 - _withdrawFeeRate)) / 100;
        _totalEthBalance -= ethAmount;

        _ethBalances[msg.sender]-=ethAmount;
        _torBalances[msg.sender]-=tokenAmount;

        // Transfer deposited TOR tokens back to the sender
        _token.transferFrom(msg.sender, address(this), tokenAmount);

        // Transfer deposited ETH back to the sender
        payable(msg.sender).transfer(ethAmount);

        _historyToken.setWithdrawActivity(msg.sender, block.timestamp, tokenAmount, _torBalances[msg.sender]);

        emit Withdrawal(msg.sender, ethAmount);
    }

    function getSwappedUserEthBalance(address account) external view returns(uint256){
        return _ethBalances[account];
    }

    function getSwappedUserTorBalance(address account) external view returns(uint256){
        return _torBalances[account];
    }
}
