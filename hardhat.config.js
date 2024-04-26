require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ignition");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    blast_sepolia: {
      url: 'https://sepolia.blast.io',
      accounts: [process.env.PRIVATE_KEY]
    },
    blast_mainnet: {
      url: 'https://rpc.blast.io',
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      blast_mainnet: "1KFN1WUABD86U581ATRN9QFQSQSYT7AIRG", 
      blast_sepolia: "1KFN1WUABD86U581ATRN9QFQSQSYT7AIRG", 
    },
    customChains: [
      {
        network: "blast_mainnet",
        chainId: 81457,
        urls: {
          apiURL: "https://api.blastscan.io/api",
          browserURL: "https://blastscan.io"
        }
      },
      {
        network: "blast_sepolia",
        chainId: 168587773,
        urls: {
          apiURL: "https://api-sepolia.blastscan.io/api",
          browserURL: "https://testnet.blastscan.io"
        }
      }
    ]
  }
};
