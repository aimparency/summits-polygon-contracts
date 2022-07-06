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

  // const initialTokens = ethers.BigNumber.from("2000000000")
  const initialTokens = ethers.BigNumber.from("2000000") // goerli
  const initialPrice = initialTokens.pow(2)
  // We get the contract to deploy
  const Summits = await ethers.getContractFactory("Summits");
  const summits = await Summits.deploy(initialTokens, {
    value: initialPrice
  }) 

  await summits.deployed();

  console.log("Summits deployed to:", summits.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
