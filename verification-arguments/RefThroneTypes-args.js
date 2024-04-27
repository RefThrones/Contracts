module.exports = [
   process.env.OWNER_GROUP_CONTRACT_ADDRESS, // address ownerGroupContractAddress
   process.env.BLAST_POINT_CONTRACT_ADDRESS, // address blastPointsContractAddress
   process.env.BLAST_POINT_OPERATOR_ADDRESS // address blastPointsOperatorAddress
  ];

  /*
  npx hardhat verify --network blast_sepolia CONTRACT_ADDRESS --constructor-args ./verification-arguments/RefThroneTypes-args.js
  */