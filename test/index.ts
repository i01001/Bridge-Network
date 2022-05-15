import { expect } from 'chai';
import { BigNumber } from 'bignumber.js';
import { ethers, network} from 'hardhat';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {BridgeContract, TokenNetwork} from '../typechain'


async function getCurrentTime(){
    return (
      await ethers.provider.getBlock(await ethers.provider.getBlockNumber())
    ).timestamp;
  }

async function evm_increaseTime(seconds : number){
    await network.provider.send("evm_increaseTime", [seconds]);
    await network.provider.send("evm_mine");
  }

describe("Testing the Bridge Network Contract", () =>{
    let bC : BridgeContract;
    let tNETH : TokenNetwork;
    let tNBSC : TokenNetwork;
    let clean : any;
    let owner : SignerWithAddress, signertwo : SignerWithAddress, signerthree: SignerWithAddress;
    
    before(async () => {

        [owner, signertwo, signerthree] = await ethers.getSigners();

        const BC = await ethers.getContractFactory("BridgeContract");
        bC = <BridgeContract>(await BC.deploy());
        await bC.deployed();

        const TNETH = await ethers.getContractFactory("TokenNetwork");
        tNETH = <TokenNetwork>(await TNETH.deploy());
        await tNETH.deployed();

        const TNBSC = await ethers.getContractFactory("TokenNetwork");
        tNBSC = <TokenNetwork>(await TNBSC.deploy());
        await tNBSC.deployed();
    });


    describe("Checking TNETH Contract is run correctly", () => {
      it("Checks the setBridgeaddress is updated correctly or not", async () => {
        await tNETH.setBridgeaddress(bC.address);
          expect(await tNETH.bridge()).to.be.equal(await bC.address);
      })

      // it("Checks the setNFT1155ContractAddress is updated correctly or not", async () => {
      //   await mP.setNFT1155ContractAddress(mNFT1155.address);
      //     expect(await mP.NFT1155Contract()).to.be.equal(await mNFT1155.address);
      // })
  })

})