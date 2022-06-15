import { expect } from "chai";
import { ethers } from "hardhat";

describe("Summits", function () {
  it("should be able to get the base aim, which should have a certain token supply", async function () {
    const Summits = await ethers.getContractFactory("Summits");
    const summits = await Summits.deploy();
    await summits.deployed();

    const baseAimAddr = await summits.baseAim()

    const Aim = await ethers.getContractFactory("Aim");
    const baseAim = Aim.attach(
      baseAimAddr
    );

    expect(await baseAim.totalSupply()).to.equal(2000000000)
  })

  it("should be able to create a new aim", async function () {
    const Summits = await ethers.getContractFactory("Summits");
    const summits = await Summits.deploy()
    await summits.deployed()

    let [owner] = await ethers.getSigners()

    await summits.createAim(
      '', '', 20, [255,0,0], 'Testaim', 'TST', 0
    )

    const response = await summits.createAim(
      'test', 'descr..', 10000, [255,0,0], 'Testaim', 'TST', 0
    )

    console.log(response)

    // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // // wait until the transaction is mined
    // await setGreetingTx.wait();

    // expect(await greeter.greet()).to.equal("Hola, mundo!");

  })

});

describe("Aim", function () {
})
