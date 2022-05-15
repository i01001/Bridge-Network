// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const BridgeContract = await ethers.getContractFactory("BridgeContract");
  const bridgeContract = await BridgeContract.deploy();

  await bridgeContract.deployed();

  console.log("BridgeContract deployed to:", bridgeContract.address);


  const TokenNetworkETH = await ethers.getContractFactory("TokenNetwork");
  const tokenNetworkETH = await TokenNetworkETH.deploy();

  await tokenNetworkETH.deployed();

  console.log("tokenNetworkETH deployed to:", tokenNetworkETH.address);



  const TokenNetworkBSC = await ethers.getContractFactory("TokenNetwork");
  const tokenNetworkBSC = await TokenNetworkBSC.deploy();

  await tokenNetworkBSC.deployed();

  console.log("TokenNetworkBSC deployed to:", tokenNetworkBSC.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
