// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IOwnerGroupContract.sol";
import "./IBlast.sol";

contract TORTokenContract {


    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    mapping(uint => MintOrBurnTransaction) private mintOrBurnTransaction;
    mapping(uint => mapping(address =>bool)) isConfirmed;
    address private _ownerGroupContractAddress;

    uint private transactionCount = 0;
    struct MintOrBurnTransaction {
        address toAddress;
        uint amount;
        bool executed;
        bool mintOrBurn;
        uint confirmationCount;
    }

    uint256 private _totalSupply;
    uint8 private _decimal=18;
    uint private torToWei = (10**_decimal);
    string public _name;
    string public _symbol;
    IOwnerGroupContract private _ownerGroupContract;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event SubmitMintOrBurnTransaction(address indexed admin, uint amount, bool mintOrBurn);
    event ConfirmTransaction(address indexed owner, uint transactionIndex);
    event ExecuteTransaction(address indexed owner, uint transactionIndex);
    event RevokeConfirmation(address indexed owner, uint transactionIndex);


    constructor(address ownerGroupContractAddress) {
        _name = "TOR Token";
        _symbol = "TOR";
        _totalSupply = 1_000_000_000 * torToWei;
        _ownerGroupContract = IOwnerGroupContract(ownerGroupContractAddress);
        _ownerGroupContractAddress = ownerGroupContractAddress;
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();
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

    function claimAllGas() external onlyOwner {
        // This function is public meaning anyone can claim the gas
        IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), _ownerGroupContractAddress);
    }

    function readGasParams() external view onlyOwner returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return IBlast(0x4300000000000000000000000000000000000002).readGasParams(address(this));
    }

    modifier onlyOwner (){
        require(_ownerGroupContract.isOwner(msg.sender), "Only Owner have a permission.");
        _;
    }

    function submitMintOrBurnTransaction(address toAddress, uint amount, bool mintOrBurn) onlyOwner public returns (uint)
    {
        if(!mintOrBurn){
            require(toAddress != address(0), "Invalid Mint Address");
        }
        else {
            require(_balances[toAddress] >= amount, "Insufficient balance to burn.");
        }

        mintOrBurnTransaction[transactionCount] = MintOrBurnTransaction({
            toAddress: toAddress,
            amount: amount,
            executed: false,
            mintOrBurn: mintOrBurn,
            confirmationCount: 0
        });

        emit SubmitMintOrBurnTransaction(toAddress, amount, mintOrBurn);

        return transactionCount++;
    }

    function confirmTransaction(uint transactionIndex) onlyOwner public
    {
        require(!mintOrBurnTransaction[transactionIndex].executed, "Transaction already executed");
        require(!isConfirmed[transactionIndex][msg.sender], "Transaction already confirmed");

        mintOrBurnTransaction[transactionIndex].confirmationCount++;
        isConfirmed[transactionIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, transactionIndex);

        uint ownerConfirm = _ownerGroupContract.getOwnerCount() / 2;
        if(mintOrBurnTransaction[transactionIndex].confirmationCount > ownerConfirm){
            executeTransaction(transactionIndex);
        }
    }

    function executeTransaction(uint transactionIndex) private {

        mintOrBurnTransaction[transactionIndex].executed = true;
        if(!mintOrBurnTransaction[transactionIndex].mintOrBurn){
            _mint(mintOrBurnTransaction[transactionIndex].toAddress, mintOrBurnTransaction[transactionIndex].amount);
        }
        else {
            _burn(mintOrBurnTransaction[transactionIndex].toAddress, mintOrBurnTransaction[transactionIndex].amount);
        }

        emit ExecuteTransaction(mintOrBurnTransaction[transactionIndex].toAddress, transactionIndex);
    }

    function revokeConfirmation(uint transactionIndex) onlyOwner public {
        require(!mintOrBurnTransaction[transactionIndex].executed, "Transaction already executed");
        require(isConfirmed[transactionIndex][msg.sender], "Transaction not confirmed");

        mintOrBurnTransaction[transactionIndex].confirmationCount--;
        isConfirmed[transactionIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, transactionIndex);
    }

    function _mint(address to, uint256 amount) internal onlyOwner {
        _balances[to] += amount * torToWei;
    }

    function _burn(address account, uint256 value) internal onlyOwner{

        _balances[account] = _balances[account] - value * torToWei;
        _totalSupply = _totalSupply - value * torToWei;
        emit Transfer(account, address(0), value * torToWei);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: insufficient balance");

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}
