const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("UserContractModule", (m) => {
    
  const UserContract = m.contract("UserContract", [   "0xDa47D6f0e6f48860977929246BDF57447E68bd58",
  "0xe347cf15b3b05Af50dFd944925e0b5d68F731706",
  "0x2fc95838c71e76ec69ff817983BFf17c710F34E0",
  "0x5b50De0439C6ecF939856d2FDcFE191659Aa4ee7"]);

  return { UserContract };
});
