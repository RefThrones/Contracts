#!/usr/bin/env node

require('dotenv').config(); // .env load variables 
const {exec} = require('child_process');

// .env get contract addresses and verificatino arguments file pathes
function getDeployedContracts() {
    const deployedContracts = [
        {
            name: process.env.OWNER_GROUP_CONTRACT_ADDRESS,
            argsFile: './verification-arguments/OwnerGroupContract-args.js'
        }, {
            name: process.env.REFTHRONE_TYPES_CONTRACT_ADDRESS,
            argsFile: './verification-arguments/RefThroneTypes-args.js'
        }, {
            name: process.env.TOR_TOKEN_CONTRACT_ADDRESS,
            argsFile: './verification-arguments/TORTokenContract-args.js'
        }, {
            name: process.env.USER_HISTORY_CONTRACT_ADDRESS,
            argsFile: './verification-arguments/UserHistory-args.js'
        }, {
            name: process.env.ETH_TREASURY_CONTRACT_ADDRESS,
            argsFile: './verification-arguments/EthTreasuryContract-args.js'
        }, {
            name: process.env.REFTHRONE_CONTRACT_ADDRESS,
            argsFile: './verification-arguments/RefThrone-args.js'
        }, {
            name: process.env.USER_CONTRACT_ADDRESS,
            argsFile: './verification-arguments/UserContract-args.js'
        }
    ];

    for (const contract of deployedContracts) {
        if (!contract.name || !contract.argsFile) {
            throw new Error('Found not defined variables from .env file!!');
        }
    }
    return deployedContracts;
}
function verifyContract(contract, networkName) {
    return new Promise((resolve, reject) => {
        const command = `npx hardhat verify --network ${networkName} ${contract.name} --constructor-args ${contract.argsFile}`;

        console.log(`Verifying ${contract.name}`);
        exec(command, (error, stdout, stderr) => {
            if (error) {
                reject(error);
                return;
            }
            if (stderr) {
                console.error(stderr);
            }
            console.log(stdout);
            resolve();
        });
    });
}

async function verifyContracts() {
    const args = process
        .argv
        .slice(2);
    let networkName;

    if (args.length > 0) {
        if (args[0] === 'mainnet') {
            networkName = 'blast_mainnet';
        } else if (args[0] === 'testnet') {
            networkName = 'blast_sepolia';
        } else {
            console.log(
                'Please provide a valid network to verify the contract. (mainnet or testnet)'
            );
            return;
        }
    } else {
        console.log(
            'Please provide a network to verify the contract. (mainnet or testnet)'
        );
        return;
    }
    console.log('Network:', networkName);

    const deployedContracts = getDeployedContracts();
    for (const contract of deployedContracts) {
        try {
            await verifyContract(contract, networkName);
        } catch (error) {
            console.error(`Error verifying ${contract.name}: ${error.message}`);
        }
    }
}

// all contract verify
verifyContracts();
