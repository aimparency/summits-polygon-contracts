import { expect } from "chai";
import { ethers } from "hardhat";

describe("Summits", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Summits = await ethers.getContractFactory("Summites");
    const greeter = await Summits.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
