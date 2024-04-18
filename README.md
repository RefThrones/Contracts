# Latest contract deployment information

**TOR Token:** [0x32aACF8e2776578Fd1ED55211355C538D54ECc8c](https://testnet.blastscan.io/address/0x32aACF8e2776578Fd1ED55211355C538D54ECc8c),	latest (04.11)		

**EthTreasury:** [0x08e913880139B9224afF2133149C7fb138Ed5836](https://testnet.blastscan.io/address/0x08e913880139B9224afF2133149C7fb138Ed5836),	latest (04.11)			

**User:** [0xc3236EA1b42900Fc613db657130DDB9219b8E7A7](https://testnet.blastscan.io/token/0xc3236EA1b42900Fc613db657130DDB9219b8E7A7),	latest (04.11)			

**UserHistory:** [0xb8410C172bEFAC21FeE558d36e095dA50a125537](https://testnet.blastscan.io/token/0xb8410C172bEFAC21FeE558d36e095dA50a125537),	  latest (04.11)

**RefThrone:** [0x6e1b222516472e693E3D3Bb0fc2745fA9A4914D2](https://testnet.blastscan.io/address/0xf91d93A22CEe0B8b8c76a0412523C3566eAe0938),	latest (04.18)		

**RefThroneTypes:** [0x359aAd7322d1374B4B739E5bB17C846c7dC15f10](https://testnet.blastscan.io/address/0x2715BADd0622E3d6f84eFFaEB742f5ae712199c4),	latest (04.11)

**OwnerGroupContract:** [0x0902daB19021EcBC8a02E393D6dddE644182cbE3](https://testnet.blastscan.io/address/0x0902daB19021EcBC8a02E393D6dddE644182cbE3),	latest (04.11)


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





