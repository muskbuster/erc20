import { expect } from "chai";
import { ethers } from "hardhat";
import { deployWrapperERC20Fixture } from "./wrapper.fixture";
import { getSigners, initSigners } from "../signers";
import { createInstances } from "../instance";
import { awaitAllDecryptionResults } from "../asyncDecrypt";
describe("CompliantConfidentialERC20 Contract Tests", function () {
    before(async function () {
      // Initialize signers and set them for future use
      await initSigners();
      this.signers = await getSigners();
    });

    beforeEach(async function () {
        // Deploy the ConfidentialERC20Wrapper contract fixture before each test
        const { ERCtoken, wrapperContract } = await deployWrapperERC20Fixture();
        this.ERCtoken = ERCtoken ;
        this.wrapperContract = wrapperContract;
        this.wrapperaddress= wrapperContract.getAddress();
      });


it("Should deploy erc20 and wrapper", async function () {
    // Check if the contract, identity, and transfer rules were deployed
   // const mint= await this.ERCtoken.mint();
    const totalSupply = await this.ERCtoken.totalSupply();
    expect(totalSupply).to.equal(1000);
    console.log("Contracts deployed successfully.");
  });

  it("Should try to wrap erc20 to Cerc20", async function () {
    // Check if the contract, identity, and transfer rules were deployed
   // const mint= await this.ERCtoken.mint();
    const totalSupply = await this.ERCtoken.totalSupply();
    expect(totalSupply).to.equal(1000);
    const balance = await this.ERCtoken.balanceOf(this.signers.alice)
    console.log(balance);
    const approve= await this.ERCtoken.connect(this.signers.alice).approve(this.wrapperContract,200);
    const allowance = await this.ERCtoken.allowance(this.wrapperContract,this.signers.alice);
    console.log(allowance);
    const wrap = await this.wrapperContract.wrap(100)
    const totalSupply2 = await this.wrapperContract.totalSupply();
    console.log(totalSupply2);
  });
});  