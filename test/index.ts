import { expect } from "chai";
import { ethers } from "hardhat";

import { Summits } from '../typechain-types/contracts/Summits'

describe("Summits", function () {
  let summits: Summits
  let initialAmount = BigInt(123456789)
  let testAimData = {
    title: "Test", 
    description: "", 
    status: "", 
    effort: 0, 
    color: [100,150,20]
  }

  this.beforeEach(async function() {
    let summitsFactory = await ethers.getContractFactory("Summits");
    summits = await summitsFactory.deploy(
      initialAmount, 
      {
        value: initialAmount ** BigInt(2) 
      }
    ) as Summits; 
    await summits.deployed();
  }) 

  it("should be able to get the base aim, which should have a certain token supply", async function () {
    const baseAimAddr = await summits.baseAim()

    const Aim = await ethers.getContractFactory("Aim");
    const baseAim = Aim.attach(
      baseAimAddr
    );

    expect(await baseAim.totalSupply()).to.equal(initialAmount)
  })

  it("should be able to create a new aim with correct value", async function () {
    let ia = BigInt(9320)
    let tx = await summits.createAim(
      testAimData, 
      'TestToken', 'TST', 
      ia, 
      {
        value: ia * ia
      }
    )

    let rc = await tx.wait()
    let creationEvent: any = rc.events!.find((e: any) => e.event === 'AimCreation') 
    expect(creationEvent).to.not.be.undefined

  })

  it("should reject aim creations with value <> initial investment ** 2", function() {
    let badCreations = [
      {
        initialAmount: BigInt(1000), 
        value: BigInt(1000 * 1000 - 1), 
      }, 
      {
        initialAmount: BigInt(2000), 
        value: BigInt(2000 * 2000 + 1), 
      }
    ]
    for(let badCreation of badCreations) {
      expect(summits.createAim(
        testAimData, 
        'TestToken', 'TST', 
        badCreation.initialAmount, 
        {
          value: badCreation.value
        }
      )).to.be.revertedWith('initial investment requires funds to equal the square of initial token amount');
    }
  });

  // test... isLegitAim

})

describe("Aim", function () {
  this.beforeEach(async function() {
    let [owner, addr1, addr2] = await ethers.getSigners()
  })

  // TBD test permissions
    // test creating permissions etc.
    // multiple users
    // test ownage transfer before implementing it - well it's prob. impl. in ownable already!

  // testdriven dev is nice. 
  // automate test, then develop into this thing
  // it makes sense for some parts of the software, ui is hard probably...
    // "create 7 aims, wait 5 seconds, see if there are intersections"... hmmm. not really

})
