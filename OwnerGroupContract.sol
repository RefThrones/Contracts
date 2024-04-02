// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OwnerGroupContract{

    uint private ownerCount=0;
    uint private adminCount=0;
    mapping(address => bool) private owners;
    mapping(address => bool) private admins;
    mapping(uint => Transaction) private transactions;
    mapping(uint => mapping(address =>bool)) isConfirmed;


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

    uint private transactionCount = 0;
    struct Transaction {
        address owner;
        bool registerFlag;
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

    function isOwner(address ownerAddress) external view returns (bool)
    {
        return owners[ownerAddress];
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

}
