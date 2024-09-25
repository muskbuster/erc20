import { ethers } from "hardhat";

import type { EncryptedERC20, ConfidentialERC20Wrapper, MyToken } from "../../types";
import { getSigners } from "../signers";

export async function deployWrapperERC20Fixture(): Promise<{
  ERCtoken: MyToken;
  wrapperContract: ConfidentialERC20Wrapper;
}> {
  const signers = await getSigners();

  // Get the contract factories
  const wrapperContractFactory = await ethers.getContractFactory("ConfidentialERC20Wrapper");
  const erc20Factory = await ethers.getContractFactory("MyToken");

  // Deploy MyToken (ERC20)
  const ERCtoken = await erc20Factory.connect(signers.alice).deploy();
  await ERCtoken.waitForDeployment();  // Use .deployed() to ensure it's mined

  // Deploy the ConfidentialERC20Wrapper contract with the ERC20 token address
  const wrapperContract = await wrapperContractFactory.connect(signers.alice).deploy(ERCtoken.target);
  await wrapperContract.waitForDeployment();  // Use .deployed() to ensure it's mined

  // Log the wrapper contract address
  console.log(wrapperContract.target);

  // Return all contracts
  return {
   wrapperContract,
    ERCtoken,
  };
}
