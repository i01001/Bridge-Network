import { expect } from 'chai';
import { BigNumber } from 'bignumber.js';
import { ethers, network} from 'hardhat';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {BridgeContract, TokenNetwork} from '../typechain'
import "@nomiclabs/hardhat-web3";


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

      it("Checks the mint function of the TNETH Contract is working correctly or not", async () => {
        await tNETH.mint(owner.address, 1000);
          expect(await tNETH.balanceOf(owner.address)).to.be.equal(1000);
      })

      it("Checks the balance function of the TNBSC Contract is correct or not", async () => {
          expect(await tNBSC.balanceOf(owner.address)).to.be.equal(0);
      })

      it("Checks the updateChainById function of the Bridge Contract is working correctly or not", async () => {
          expect(bC.connect(owner).updateChainById(31337, true)).to.be.revertedWith("true");
      })

      it("Checks the includeToken function of the Bridge Contract is working correctly or not", async () => {
        expect(bC.connect(owner).includeToken(31337, tNETH.address)).to.be.revertedWith("true");
      })

      it("Checks the includeToken function of the Bridge Contract is working correctly or not", async () => {
      expect(bC.connect(owner).includeToken(31337, tNBSC.address)).to.be.revertedWith("true");
      })

      it("Checks the swap function of the Bridge Contract is working correctly or not", async () => {
      await bC.connect(owner).swap(tNETH.address, tNBSC.address, 1000, 31337);
      expect(await tNETH.balanceOf(owner.address)).to.be.equal(0);
      })

      it("Checks the setBridgeaddress is updated correctly or not for tNBSC Network Contract", async () => {
        await tNBSC.setBridgeaddress(bC.address);
          expect(await tNBSC.bridge()).to.be.equal(await bC.address);
      })

      it("Checks the redeem function of the Bridge Contract is working correctly or not", async () => {
        let msg = ethers.utils.solidityKeccak256(["address", "address", "uint256", "uint256", "uint256"], [owner.address, tNBSC.address, 1000, 31337, 1]);
        let signature = await owner.signMessage(ethers.utils.arrayify(msg));
        console.log(signature);
        let split = await ethers.utils.splitSignature(signature);

        let testing = await bC.connect(owner).redeem(owner.address, tNBSC.address, 1000, 31337, 1, split.v, split.r, split.s);
        console.log(testing);
        expect(await tNBSC.balanceOf(owner.address)).to.be.equal(1000);
      })

      
      })

})