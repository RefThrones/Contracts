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

brew install node

nvm install v20.12.2 

npm install @openzeppelin/contracts

npm hardhat install

npm install dotenv

npm install --save-dev @nomicfoundation/hardhat-verify 



# HardHat
**Compile:** npx hardhat compile  

**Deploy:** npx hardhat ignition deploy ignition/modules/TORTokenContract.js --network blast_sepolia  

**Verify:** npx hardhat verify --network blast_sepolia [deployed contract address] --constructor-args arguments.js 

ex) npx hardhat verify --network blast_sepolia 0xB4006ccac99b73F227B314fD1d0274DAAAB8021F --constructor-args arguments.js 





