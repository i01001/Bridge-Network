import { task } from "hardhat/config";
// import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
// import "@typechain/hardhat";
// import "hardhat-gas-reporter";
// import "solidity-coverage";
// import "@nomiclabs/hardhat-web3";


task("redeem", "Redeem Tokens")
.addParam("sender", "Address to which tokens will be transferred")
.addParam("totoken", "Contract address to which tokens will be sent to")
.addParam("amount", "Amount of tokens to be transferred")
.addParam("tochainID", "Chain ID of the receiving contract address")
.addParam("nonce", "Unique identifier number of transfer token")
.addParam("v", "Cryptography parameter v")
.addParam("r", "Cryptography parameter r")
.addParam("s", "Cryptography parameter s")



.setAction(async (taskArgs,hre) => {
  const [sender, secondaccount, thirdaccount, fourthaccount] = await hre.ethers.getSigners();

  const BridgeContract = await hre.ethers.getContractFactory("BridgeContract");
  const bridgeContract = await BridgeContract.deploy();
  await bridgeContract.deployed();

  console.log("BridgeContract deployed to:", bridgeContract.address);


  const TokenNetworkETH = await hre.ethers.getContractFactory("TokenNetwork");
  const tokenNetworkETH = await TokenNetworkETH.deploy();
  await tokenNetworkETH.deployed();

  console.log("tokenNetworkETH deployed to:", tokenNetworkETH.address);

  const TokenNetworkBSC = await hre.ethers.getContractFactory("TokenNetwork");
  const tokenNetworkBSC = await TokenNetworkBSC.deploy();
  await tokenNetworkBSC.deployed();

  console.log("TokenNetworkBSC deployed to:", tokenNetworkBSC.address);

  await tokenNetworkETH.setBridgeaddress(bridgeContract.address);
  await tokenNetworkBSC.setBridgeaddress(bridgeContract.address);

  let output = await bridgeContract.connect(sender).redeem(taskArgs.fromtoken, taskArgs.totoken,taskArgs.amount, taskArgs.tochainID, taskArgs.nonce, taskArgs.v, taskArgs.r, taskArgs.s);

console.log(await output);
});
