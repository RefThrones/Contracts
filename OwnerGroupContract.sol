// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event RegisterTrustedContract(address indexed contractAddress);
    event UnRegisterTrustedContract(address indexed contractAddress);

    event SubmitEthWithdrawTransaction(address indexed toAddress, uint amount);
    event ConfirmEthWithdrawTransaction(address indexed owner, uint transactionIndex);
    event ExecuteEthWithdrawTransaction(address indexed owner, uint transactionIndex);
    event RevokeEthWithdrawTransaction(address indexed owner, uint transactionIndex);

    uint private transactionCount = 0;
    struct Transaction {
        address owner;
        bool registerFlag;
        bool executed;
        uint confirmationCount;
    }

    mapping(uint => Transaction) private transactions;
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
        require(!admins[newAdminAddress], "Already registered as admin");
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

    function isOwner(address owenerAddress) external view returns (bool)
    {
        return owners[owenerAddress];
    }

    function submitTransaction(address newOwner, bool registerFlag) onlyOwner public returns (uint)
    {
        require(newOwner != address(0), "Invalid owner");

        if(!registerFlag){
            require(owners[newOwner], "Not Owner");
        }

        transactions[transactionCount] = Transaction({
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

    function confirmTransaction(uint transactionIndex) onlyOwner public
    {
        require(!transactions[transactionIndex].executed, "Transaction already executed");
        require(!isConfirmed[transactionIndex][msg.sender], "Transaction already confirmed");

        transactions[transactionIndex].confirmationCount++;
        isConfirmed[transactionIndex][msg.sender] = true;

        emit ConfirmOwner(msg.sender, transactionIndex);

        uint ownerConfirm = ownerCount / 2;
        if(transactions[transactionIndex].confirmationCount > ownerConfirm){
            executeTransaction(transactionIndex);
        }
    }

    function executeTransaction(uint transactionIndex) private {

        transactions[transactionIndex].executed = true;
        if(transactions[transactionIndex].registerFlag){
            owners[transactions[transactionIndex].owner] = true;
            ownerCount++;
        }
        else {
            owners[transactions[transactionIndex].owner] = false;
            ownerCount--;
        }

        emit ExecuteTransaction(transactions[transactionIndex].owner, transactionIndex);
    }

    function revokeConfirmation(uint transactionIndex) onlyOwner public {
        require(!transactions[transactionIndex].executed, "Transaction already executed");
        require(isConfirmed[transactionIndex][msg.sender], "Transaction not confirmed");

        transactions[transactionIndex].confirmationCount--;
        isConfirmed[transactionIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, transactionIndex);
    }

    function submitEthWithdrawTransaction(address toAddress, uint amount) onlyOwner public returns (uint)
    {
        require(toAddress != address(0), "Invalid withdrawal Address");


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
        require(!withdrawContractEthTransactions[transactionIndex].executed, "Transaction already executed");
        require(!isConfirmWithdrawContractEthTransactions[transactionIndex][msg.sender], "Transaction already confirmed");

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
        require(address(this).balance >= amount, "Not enough ETH Balance");

        payable(toAddress).transfer(amount);
        emit Transfer(address(this), toAddress, amount);
    }

    function revokeEthWithdrawTransaction(uint transactionIndex) onlyOwner public {
        require(!withdrawContractEthTransactions[transactionIndex].executed, "Transaction already executed");
        require(isConfirmWithdrawContractEthTransactions[transactionIndex][msg.sender], "Transaction not confirmed");

        withdrawContractEthTransactions[transactionIndex].confirmationCount--;
        isConfirmWithdrawContractEthTransactions[transactionIndex][msg.sender] = false;
        emit RevokeEthWithdrawTransaction(msg.sender, transactionIndex);
    }

}
