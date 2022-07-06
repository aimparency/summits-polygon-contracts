import { expect } from "chai";
import { ethers } from "hardhat";

import Summits from '../typechain/Summits'

describe("Summits", function () {
  let summits: Summits.Summits

  this.beforeEach(async function() {
    let summitsFactory = await ethers.getContractFactory("Summits");
    summits = await summitsFactory.deploy();
    await summits.deployed();
  }) 

  it("should be able to get the base aim, which should have a certain token supply", async function () {
    const baseAimAddr = await summits.baseAim()

    const Aim = await ethers.getContractFactory("Aim");
    const baseAim = Aim.attach(
      baseAimAddr
    );

    expect(await baseAim.totalSupply()).to.equal(2000000000)
  })

  it("should be able to create a new aim", async function () {
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

  it("should successfully call test function", async function () {
    summits.test()
  })

  // TBD test permissions
    // test creating permissions etc.

});

describe("Aim", function () {
})
