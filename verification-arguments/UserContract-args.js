module.exports = [
   process.env.USER_HISTORY_CONTRACT_ADDRESS, // address historyToken
   process.env.OWNER_GROUP_CONTRACT_ADDRESS, // address ownerGroupContractAddress 
   process.env.BLAST_POINT_CONTRACT_ADDRESS, // address blastPointAddress
   process.env.BLAST_POINT_OPERATOR_ADDRESS // address operatorAddress
  ];

/*
npx hardhat verify --network blast_sepolia CONTRACT_ADDRESS --constructor-args ./verification-arguments/UserContract-args.js
*/