// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./IBlast.sol";

contract OwnerGroupContract{

    uint private ownerCount=0;
    uint private adminCount=0;
    mapping(address => bool) private owners;
    mapping(address => bool) private admins;
    mapping(address => bool) private trustedContracts;

    event RegisterOwner(
        address indexed owner,
        uint indexed txIndex
    );
    event UnRegisterOwner(
        address indexed owner,
        uint indexed txIndex
    );
    event RegisterAdmin(address indexed admin);
    event UnRegisterAdmin(address indexed admin);
    event ConfirmOwner(address indexed owner, uint indexed txIndex);
    event RevokeOwner(address indexed owner, uint indexed txIndex);
    event ExecuteOwnerTransaction(address indexed owner, uint indexed txIndex);
    event RevokeOwnerConfirmation(address indexed owner, uint indexed txIndex);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event RegisterTrustedContract(address indexed contractAddress);
    event UnRegisterTrustedContract(address indexed contractAddress);

    event SubmitEthWithdrawTransaction(address indexed toAddress, uint amount);
    event ConfirmEthWithdrawTransaction(address indexed owner, uint transactionIndex);
    event ExecuteEthWithdrawTransaction(address indexed owner, uint transactionIndex);
    event RevokeEthWithdrawTransaction(address indexed owner, uint transactionIndex);

    event FundsDeposited(address indexed from, uint amount);

    uint private transactionCount = 0;
    struct OwnerTransaction {
        address owner;
        bool registerFlag;
        bool executed;
        uint confirmationCount;
    }

    mapping(uint => OwnerTransaction) private ownerTransactions;
    mapping(uint => mapping(address =>bool)) isConfirmed;

    mapping(uint => WithdrawContractEthTransaction) private withdrawContractEthTransactions;
    mapping(uint => mapping(address =>bool)) isConfirmWithdrawContractEthTransactions;

    uint private withdrawContractEthTransactionCount = 0;
    struct WithdrawContractEthTransaction {
        address toAddress;
        uint amount;
        bool executed;
        uint confirmationCount;
    }


    constructor(address[] memory initialOwners) {

        for (uint256 i = 0; i < initialOwners.length; i++) {
            require(initialOwners[i] != address(0), "Invalid owner");
            owners[initialOwners[i]] = true;
            admins[initialOwners[i]] = true;
            ownerCount++;
            adminCount++;
        }

        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();
    }


    // Fallback function to receive Ether
    receive() external payable {
        // Emit an event indicating the deposit
        emit FundsDeposited(msg.sender, msg.value);
    }

    function claimYield(uint256 amount, address toAddress) external onlyOwner returns (uint256){
        //This function is public meaning anyone can claim the yield
        return IBlast(0x4300000000000000000000000000000000000002).claimYield(address(this), toAddress, amount);
    }

    function readClaimableYield() external view onlyOwner returns (uint256){
        //This function is public meaning anyone can claim the yield
        return IBlast(0x4300000000000000000000000000000000000002).readClaimableYield(address(this));
    }

    function claimAllYield(address toAddress) external onlyOwner returns (uint256){
        //This function is public meaning anyone can claim the yield
        return IBlast(0x4300000000000000000000000000000000000002).claimAllYield(address(this), toAddress);
    }

    function claimAllGas(address toAddress) external onlyOwner returns (uint256) {
        // This function is public meaning anyone can claim the gas
        return IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), toAddress);
    }

    function readGasParams() external view onlyOwner returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return IBlast(0x4300000000000000000000000000000000000002).readGasParams(address(this));
    }


    modifier onlyOwner() {
        require(owners[msg.sender], "not owner");
        _;
    }

    function getOwnerCount() external view returns (uint)
    {
        return ownerCount;
    }

    function getAdminCount() external view returns (uint)
    {
        return adminCount;
    }

    function isAdmin(address adminAddress) external view returns (bool)
    {
        return admins[adminAddress];
    }

    function isTrustedContract(address contractAddress) external view returns (bool)
    {
        return trustedContracts[contractAddress];
    }

    function registerTrustedContract(address contractAddress) public onlyOwner
    {
        trustedContracts[contractAddress] = true;
        emit RegisterTrustedContract(contractAddress);
    }

    function unRegisterContract(address contractAddress) public onlyOwner
    {
        trustedContracts[contractAddress] = false;
        emit UnRegisterTrustedContract(contractAddress);
    }

    function registerAdmin(address newAdminAddress) public onlyOwner
    {
        require(!admins[newAdminAddress], "Already registered");
        admins[newAdminAddress] = true;
        adminCount++;
        emit RegisterAdmin(newAdminAddress);
    }

    function unRegisterAdmin(address adminAddress) public onlyOwner
    {
        require(admins[adminAddress], "Not in Admin List");
        admins[adminAddress] = false;
        adminCount--;
        emit UnRegisterAdmin(adminAddress);
    }

    function isOwner(address ownerAddress) external view returns (bool)
    {
        return owners[ownerAddress];
    }

    function submitOwnerTransaction(address newOwner, bool registerFlag) onlyOwner public returns (uint)
    {
        require(newOwner != address(0), "Invalid owner");

        if(!registerFlag){
            require(owners[newOwner], "Not Owner");
        }

        ownerTransactions[transactionCount] = OwnerTransaction({
            owner: newOwner,
            registerFlag: registerFlag,
            executed: false,
            confirmationCount: 0
        });

        if(registerFlag)
        {
            emit RegisterOwner(msg.sender, transactionCount);
        }
        else {
            emit UnRegisterOwner(msg.sender, transactionCount);
        }

        return transactionCount++;
    }

    function confirmOwnerTransaction(uint transactionIndex) onlyOwner public
    {
        require(!ownerTransactions[transactionIndex].executed, "tx already executed");
        require(!isConfirmed[transactionIndex][msg.sender], "tx already confirmed");

        ownerTransactions[transactionIndex].confirmationCount++;
        isConfirmed[transactionIndex][msg.sender] = true;

        emit ConfirmOwner(msg.sender, transactionIndex);

        uint ownerConfirm = ownerCount / 2;
        if(ownerTransactions[transactionIndex].confirmationCount > ownerConfirm){
            executeOwnerTransaction(transactionIndex);
        }
    }

    function executeOwnerTransaction(uint transactionIndex) private {

        ownerTransactions[transactionIndex].executed = true;
        if(ownerTransactions[transactionIndex].registerFlag){
            owners[ownerTransactions[transactionIndex].owner] = true;
            ownerCount++;
        }
        else {
            owners[ownerTransactions[transactionIndex].owner] = false;
            ownerCount--;
        }

        emit ExecuteOwnerTransaction(ownerTransactions[transactionIndex].owner, transactionIndex);
    }

    function revokeOwnerConfirmation(uint transactionIndex) onlyOwner public {
        require(!ownerTransactions[transactionIndex].executed, "tx already executed");
        require(isConfirmed[transactionIndex][msg.sender], "tx not confirmed");

        ownerTransactions[transactionIndex].confirmationCount--;
        isConfirmed[transactionIndex][msg.sender] = false;
        emit RevokeOwnerConfirmation(msg.sender, transactionIndex);
    }

    function getPendingOwnerTransactions() public view onlyOwner returns (uint[] memory){

        // Determine the count of pending transactions
        uint pendingCount = 0;
        for (uint i = 0; i < transactionCount; i++) {
            if (!ownerTransactions[i].executed) {
                pendingCount++;
            }
        }

        // Create a dynamic array to store pending transaction indices
        uint[] memory pendingTransactions = new uint[](pendingCount);
        uint index = 0;
        for (uint i = 0; i < transactionCount; i++) {
            if (!ownerTransactions[i].executed) {
                pendingTransactions[index] = i;
                index++;
            }
        }
        return pendingTransactions;
    }

    function getOwnerTransaction(uint index) public view onlyOwner returns (address, bool, bool, uint) {
        require(index < transactionCount, "Index out of bounds");
        OwnerTransaction storage transaction = ownerTransactions[index];
        return (transaction.owner, transaction.registerFlag, transaction.executed, transaction.confirmationCount);
    }

    function getPendingWithdrawEthTransactions() public view onlyOwner returns (uint[] memory){

        // Determine the count of pending transactions
        uint pendingCount = 0;
        for (uint i = 0; i < withdrawContractEthTransactionCount; i++) {
            if (!withdrawContractEthTransactions[i].executed) {
                pendingCount++;
            }
        }

        // Create a dynamic array to store pending transaction indices
        uint[] memory pendingTransactions = new uint[](pendingCount);
        uint index = 0;
        for (uint i = 0; i < withdrawContractEthTransactionCount; i++) {
            if (!withdrawContractEthTransactions[i].executed) {
                pendingTransactions[index] = i;
                index++;
            }
        }
        return pendingTransactions;
    }

    function getWithdrawContractEthTransaction(uint index) public view onlyOwner returns (address, uint, bool, uint) {
        require(index < withdrawContractEthTransactionCount, "Index out of bounds");
        WithdrawContractEthTransaction storage transaction = withdrawContractEthTransactions[index];
        return (transaction.toAddress, transaction.amount, transaction.executed, transaction.confirmationCount);
    }

    function getEthBalance() public view returns (uint){
        return address(this).balance;
    }

    function submitEthWithdrawTransaction(address toAddress, uint amount) onlyOwner public returns (uint)
    {
        require(toAddress != address(0), "Invalid withdrawal Address");
        require(amount <= address(this).balance, "Not enough ETH Balance");

        withdrawContractEthTransactions[withdrawContractEthTransactionCount] = WithdrawContractEthTransaction({
            toAddress: toAddress,
            amount: amount,
            executed: false,
            confirmationCount: 0
        });

        emit SubmitEthWithdrawTransaction(toAddress, amount);

        return withdrawContractEthTransactionCount++;
    }

    function confirmEthWithdrawTransaction(uint transactionIndex) onlyOwner public
    {
        require(!withdrawContractEthTransactions[transactionIndex].executed, "tx already executed");
        require(!isConfirmWithdrawContractEthTransactions[transactionIndex][msg.sender], "tx already confirmed");

        withdrawContractEthTransactions[transactionIndex].confirmationCount++;
        isConfirmWithdrawContractEthTransactions[transactionIndex][msg.sender] = true;

        emit ConfirmEthWithdrawTransaction(msg.sender, transactionIndex);

        uint ownerConfirm = ownerCount / 2;
        if(withdrawContractEthTransactions[transactionIndex].confirmationCount > ownerConfirm){
            executeEthWithdrawTransaction(transactionIndex);
        }
    }

    function executeEthWithdrawTransaction(uint transactionIndex) private {

        withdrawContractEthTransactions[transactionIndex].executed = true;
        _withdrawContractEth(withdrawContractEthTransactions[transactionIndex].toAddress, withdrawContractEthTransactions[transactionIndex].amount);

        emit ExecuteEthWithdrawTransaction(withdrawContractEthTransactions[transactionIndex].toAddress, transactionIndex);
    }

    function _withdrawContractEth(address toAddress, uint256 amount) private {

        payable(toAddress).transfer(amount);
        emit Transfer(address(this), toAddress, amount);
    }

    function revokeEthWithdrawTransaction(uint transactionIndex) onlyOwner public {
        require(!withdrawContractEthTransactions[transactionIndex].executed, "tx already executed");
        require(isConfirmWithdrawContractEthTransactions[transactionIndex][msg.sender], "tx not confirmed");

        withdrawContractEthTransactions[transactionIndex].confirmationCount--;
        isConfirmWithdrawContractEthTransactions[transactionIndex][msg.sender] = false;
        emit RevokeEthWithdrawTransaction(msg.sender, transactionIndex);
    }

}
