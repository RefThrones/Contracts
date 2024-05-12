# Latest contract deployment information

**TOR Token:** [0xd1656cd192ab0a3d094CC7338e6852CC84d27249](https://testnet.blastscan.io/address/0xd1656cd192ab0a3d094CC7338e6852CC84d27249),	latest (04.24)		

**EthTreasury:** [0xf969D1644E9F1fE7e962170bD9a1CCE480F8Aa19](https://testnet.blastscan.io/address/0xf969D1644E9F1fE7e962170bD9a1CCE480F8Aa19),	latest (04.24)			

**User:** [0x20836F89Ab9ba41872482d3b9ECEddA6B3f6088A](https://testnet.blastscan.io/token/0x20836F89Ab9ba41872482d3b9ECEddA6B3f6088A),	latest (04.25)			

**UserHistory:** [0xDa47D6f0e6f48860977929246BDF57447E68bd58](https://testnet.blastscan.io/token/0xDa47D6f0e6f48860977929246BDF57447E68bd58),	  latest (04.24)

**RefThrone:** [0x3e039A13c1338862f160836cd246fB87Ea157f74](https://testnet.blastscan.io/address/0x3e039A13c1338862f160836cd246fB87Ea157f74),	latest (04.24)		

**RefThroneTypes:** [0x8e013061903E4a06562f715620806822449E55bb](https://testnet.blastscan.io/address/0x8e013061903E4a06562f715620806822449E55bb),	latest (04.24)

**OwnerGroupContract:** [0xe347cf15b3b05Af50dFd944925e0b5d68F731706](https://testnet.blastscan.io/address/0xe347cf15b3b05Af50dFd944925e0b5d68F731706),	latest (04.24)

**Contract Deployer address:** 0xcEBc0Cea4d6644e395aFa338D7b17514904074e1

# Dev Env configuration

> brew install node

> nvm install v20.12.2 

> npm install @openzeppelin/contracts

> npm hardhat install

> npm install dotenv

> npm install --save-dev @nomicfoundation/hardhat-verify 



# DEPLOYMENT, VERIFICATION (Using HardHat)
**Compile:** 
> npx hardhat compile  

**Deploy (Blast_Sepolia):** 
> npx hardhat ignition deploy ignition/modules/ReferralThrones.js --network blast_sepolia

**Deploy (Blast_Mainnet):** 
> npx hardhat ignition deploy ignition/modules/ReferralThrones.js --network blast_mainnet  

**Verify all contracts (Blast_Sepolia):** 
> chmod +x execVerifyAll.js
> 
> execVerifyAll.js testnet

**Verify all contracts (Blast_Mainnet):** 
> chmod +x execVerifyAll.js
> 
> execVerifyAll.js mainnet

**Verify individual contract (Blast_Sepolia):** 
> npx hardhat verify --network blast_sepolia [deployed contract address] --constructor-args ./verification-arguments/CONTRACT_FILE_NAME-args.js

**Verify individual contract (Blast_Sepolia):** 
> npx hardhat verify --network blast_mainnet [deployed contract address] --constructor-args ./verification-arguments/CONTRACT_FILE_NAME-args.js


# TEST (Using HardHat)
> npx hardhat test --network blast_sepolia


# .env
OWNER_GROUP_ADDRESSES="0x6a7646E5c6A26F662415Aa763BE1D38987CcBaf7,0x156aD54B68362F2D54520de9951499d5cd251033,0x0Aa5447B53A74c5a8EFc23e7f638108BC86D1028,0xC5296c803e1FfFdd91561f17650757578e0D7bAb,0x58179fe0488e8224039DDd093F652B4605Ed11d4"
BLAST_POINT_CONTRACT_ADDRESS="0x2fc95838c71e76ec69ff817983BFf17c710F34E0"
BLAST_POINT_OPERATOR_ADDRESS="0x5b50De0439C6ecF939856d2FDcFE191659Aa4ee7"

PRIVATE_KEY = OWNER's PRIVATE KEY
ETHERSCAN_API_KEY = YOUR_API_KEY
BLASTSCAN_API_KEY = YOUR_API_KEY

OWNER_GROUP_CONTRACT_ADDRESS = DEPLOYED_CONTRACT_ADDRESS
REFTHRONE_TYPES_CONTRACT_ADDRESS = DEPLOYED_CONTRACT_ADDRESS
TOR_TOKEN_CONTRACT_ADDRESS = DEPLOYED_CONTRACT_ADDRESS
USER_HISTORY_CONTRACT_ADDRESS = DEPLOYED_CONTRACT_ADDRESS
ETH_TREASURY_CONTRACT_ADDRESS = DEPLOYED_CONTRACT_ADDRESS
REFTHRONE_CONTRACT_ADDRESS = DEPLOYED_CONTRACT_ADDRESS
USER_CONTRACT_ADDRESS = DEPLOYED_CONTRACT_ADDRESS




