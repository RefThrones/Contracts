module.exports = [
   process.env.TOR_TOKEN_CONTRACT_ADDRESS, // address torTokenContractAddress
   process.env.OWNER_GROUP_CONTRACT_ADDRESS, // address ownerGroupContractAddress
   process.env.USER_HISTORY_CONTRACT_ADDRESS, // address historyTokenContractAddress
   process.env.BLAST_POINT_CONTRACT_ADDRESS, // address blastPointAddress
   process.env.BLAST_POINT_OPERATOR_ADDRESS // address operatorAddress
  ];

/*
npx hardhat verify --network blast_sepolia CONTRACT_ADDRESS --constructor-args ./verification-arguments/EthTreasuryContract-args.js
*/
  