module.exports = [
   process.env.TOR_TOKEN_CONTRACT_ADDRESS, // address torTokenContractAddress
   process.env.USER_HISTORY_CONTRACT_ADDRESS, // address userHistoryContractAddress
   process.env.OWNER_GROUP_CONTRACT_ADDRESS, // address ownerGroupContractAddress 
   process.env.BLAST_POINT_CONTRACT_ADDRESS, // address blastPointsContractAddress
   process.env.BLAST_POINT_OPERATOR_ADDRESS // address blastPointsOperatorAddress
  ];

  /*
  npx hardhat verify --network blast_sepolia CONTRACT_ADDRESS --constructor-args ./verification-arguments/RefThrone-args.js
  */