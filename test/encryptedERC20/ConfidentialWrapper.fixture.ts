import { ethers } from "hardhat";

import type { ConfidentialERC20Wrapper, ERC20 } from "../../types";
import { getSigners } from "../signers";

export async function deployEncryptedERC20Fixture(): Promise<{ contract: ConfidentialERC20Wrapper; erc20: ERC20 }> {
  const signers = await getSigners();
  const erc20Factory = await ethers.getContractFactory("MyToken"); // Ensure the case matches "MyToken"
  const erc20 = await erc20Factory.connect(signers.alice).deploy();
  await erc20.waitForDeployment();  // Wait for deployment to complete

  // Deploy the ConfidentialERC20Wrapper contract
  const confidentialERC20WrapperFactory = await ethers.getContractFactory("ConfidentialERC20Wrapper");
  const address=await erc20.getAddress();
  console.log(address);
  const contract = await confidentialERC20WrapperFactory.connect(signers.alice).deploy(address);
  await contract.waitForDeployment();  // Wait for deployment to complete
  const wrapperAddress=await contract.getAddress();
  console.log(wrapperAddress);
  const approval= await erc20.connect(signers.alice).approve(wrapperAddress,1000);
  await approval;
  const allowance=await erc20.connect(signers.alice).allowance(wrapperAddress,signers.alice);
  console.log(allowance);
  // Deploy the MyToken contract (ERC20)


  // Return the deployed contract instances
  return {
    contract,  // Renamed from 'contract' to match the return type
    erc20,
  };
}
