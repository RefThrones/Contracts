const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const torTokenContract = require("../artifacts/contracts/TORTokenContract.sol/TORTokenContract.json");
const TOR_TOKEN_CONTRAT_ADDRESS = "0xA1495ff7c6857Bc57D0d12b9F35f45a953451a31";

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

describe("TORTokenContract", function () {
  console.log("This is TORTokenContract Test");
  //Deploy And Genesis Mint Test
  it("Deployment should assign the total supply of tokens to the owner", async function () {

    return;
    const [owner] = await ethers.getSigners();    
    const torToken = await ethers.deployContract("TORTokenContract",["0x0902daB19021EcBC8a02E393D6dddE644182cbE3"]);
    console.log(torToken);

    const result = await torToken.executeGenesisMint(owner.address, 1000000000000000000000000000n);

    console.log("Wait for transaction! 5 secs..");
    await sleep(5 * 1000);
    
    const ownerBalance = await torToken.balanceOf(owner.address);    
    console.log(`Address: ${owner.address} Balance: ${ownerBalance}`);

    //TOKEN TotalSupply
    const totalSupplyCnt = await torToken.totalSupply();

    console.log(totalSupplyCnt);
    // expect(await torTokenContract.totalSupply()).to.equal(ownerBalance);

  });

  //Approve Test
  it("Contract Load And Approve Test", async function(){
      return;
      const [owner] = await ethers.getSigners();
      const torToken = new ethers.Contract(TOR_TOKEN_CONTRAT_ADDRESS, torTokenContract.abi, owner);

      const spender = "0xf03Dce23D869ce9FB7363cb2C06F9F7750377710";

      //TOKEN Transfer Test
      const transferResult = await torToken.approve(spender, 100000000000000000000n);
      console.log(transferResult);

      await sleep(2 * 1000);

      const allowanceAmount = await torToken.allowance(owner.address, spender);
      console.log(`From: ${owner.address} To: ${spender} allowanceAmount: ${allowanceAmount}`);


  });

  //Transfer Test
  it("Load Contract And TransferFrom", async function(){
    return;
    const [owner] = await ethers.getSigners();
    const torToken = new ethers.Contract(TOR_TOKEN_CONTRAT_ADDRESS, torTokenContract.abi, owner);

    const receiver = "0xf03Dce23D869ce9FB7363cb2C06F9F7750377710";

    const result = await torToken.transfer(receiver, 7000000000000000000n);
    console.log(result);

    await sleep(5 * 1000);

    const balance = await torToken.balanceOf(receiver);    
    console.log(`Address: ${receiver} Balance: ${balance}`);

  });

  //TransferFrom Test
  it("Load Contract And TransferFrom", async function(){
    return;
    const [owner] = await ethers.getSigners();
    const torToken = new ethers.Contract(TOR_TOKEN_CONTRAT_ADDRESS, torTokenContract.abi, owner);

    
    const sender ="0xC5296c803e1FfFdd91561f17650757578e0D7bAb";
    const receiver = "0x563f829741ad8229B6cd13A24C3cBF95b5e4829c";

    const result = await torToken.transferFrom(sender, receiver, 900000000000000000n);
    console.log(result);

    await sleep(5 * 1000);

    const balance = await torToken.balanceOf(receiver);    
    console.log(`Address: ${receiver} Balance: ${balance}`);

  });

  //Mint And Burn Test -- Multi Sig
  it("Mint And Burn Test", async function(){
    
    const [owner] = await ethers.getSigners();
    const torToken = new ethers.Contract(TOR_TOKEN_CONTRAT_ADDRESS, torTokenContract.abi, owner);

    
    const sender ="0xC5296c803e1FfFdd91561f17650757578e0D7bAb";
    const receiver = "0x563f829741ad8229B6cd13A24C3cBF95b5e4829c";

    const result = await torToken.transferFrom(sender, receiver, 900000000000000000n);
    console.log(result);

    await sleep(5 * 1000);

    const balance = await torToken.balanceOf(receiver);    
    console.log(`Address: ${receiver} Balance: ${balance}`);

  });

  // Multi Sig Test, submit, confirmation


});
