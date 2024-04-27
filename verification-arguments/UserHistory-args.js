module.exports = [
   process.env.OWNER_GROUP_CONTRACT_ADDRESS, // OwnerGroup
   process.env.BLAST_POINT_CONTRACT_ADDRESS, // BLAST_POINT_CONTRACT_ADDRESS
   process.env.BLAST_POINT_OPERATOR_ADDRESS // BLAST_POINT_OPERATOR_ADDRESS
  ];
  
/*
npx hardhat verify --network blast_sepolia CONTRACT_ADDRESS --constructor-args ./verification-arguments/UserHistory-args.js
*/