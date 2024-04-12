const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("TORTokenContractModule", (m) => {
  //const TORTokenContract = m.contract("TORTokenContract", ["RefThrones", "TOR"]);
  
  const TORTokenContract = m.contract("TORTokenContract", ["0x0902daB19021EcBC8a02E393D6dddE644182cbE3"]);

  return { TORTokenContract };
});
