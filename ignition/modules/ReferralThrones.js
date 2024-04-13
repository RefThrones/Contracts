const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("ReferralThronesModule", (m) => {
  const OwnerGroupContract = m.contract(
    "OwnerGroupContract", 
    [
      process.env.OWNER_GROUP_ADDRESSES.split(","),
      process.env.BLAST_POINT_CONTRACT_ADDRESS,
      process.env.BLAST_POINT_OPERATOR_ADDRESS,
    ],
  );

  const TORTokenContract = m.contract(
    "TORTokenContract", 
    [OwnerGroupContract]
  );

  const UserHistoryContract = m.contract(
    "UserHistory", 
    [
      OwnerGroupContract,
      process.env.BLAST_POINT_CONTRACT_ADDRESS,
      process.env.BLAST_POINT_OPERATOR_ADDRESS,
    ]
  );

  const EthTreasuryContract = m.contract(
    "EthTreasuryContract", 
    [
      TORTokenContract,
      OwnerGroupContract,
      UserHistoryContract,
      process.env.BLAST_POINT_CONTRACT_ADDRESS,
      process.env.BLAST_POINT_OPERATOR_ADDRESS,
    ]
  );

  const UserContract = m.contract(
    "UserContract", 
    [
      UserHistoryContract,
      OwnerGroupContract,
      process.env.BLAST_POINT_CONTRACT_ADDRESS,
      process.env.BLAST_POINT_OPERATOR_ADDRESS,
    ]
  );

  const RefThroneContract = m.contract(
    "RefThrone", 
    [
      TORTokenContract,
      UserHistoryContract,
      OwnerGroupContract,
      process.env.BLAST_POINT_CONTRACT_ADDRESS,
      process.env.BLAST_POINT_OPERATOR_ADDRESS,
    ]
  );
  
  const RefThroneTypesContract = m.contract(
    "RefThroneTypes", 
    [
      OwnerGroupContract,
      process.env.BLAST_POINT_CONTRACT_ADDRESS,
      process.env.BLAST_POINT_OPERATOR_ADDRESS,
    ]
  );

  return { 
    OwnerGroupContract, 
    TORTokenContract, 
    UserHistoryContract,
    EthTreasuryContract,
    UserContract,
    RefThroneContract,
    RefThroneTypesContract,
  };
});
