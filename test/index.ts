import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

import { Summits } from '../typechain-types/contracts/Summits'

let initialAmount = BigInt(123456789)
let testAimData = {
  title: "Test", 
  description: "", 
  status: "", 
  effort: 0, 
  color: [100,150,20]
}


describe("Summits", function () {
  let summits: Summits

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

    let aimFactory = await ethers.getContractFactory("Aim");
    const baseAim = aimFactory.attach(
      baseAimAddr
    );

    expect(await baseAim.totalSupply()).to.equal(initialAmount)
  })

  it("should be able to create a new aim with correct value", async function () {
    let ia = BigInt(9320)
    let tx = await summits.createAim(
      testAimData, 0x8000, 
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
        0x8000, 
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

describe("Aim owner transfer", function () {
  let signers: SignerWithAddress[]
  let addresses: string[]
  let aim0 : Contract
  this.beforeEach(async function() {
    signers = await ethers.getSigners()
    addresses = await Promise.all(signers.map(s => s.getAddress()))
    let initialAmount = BigInt(123456789)

    let summitsFactory = await ethers.getContractFactory("Summits");
    let summits = await summitsFactory.deploy(
      initialAmount, 
      {
        value: initialAmount ** BigInt(2), 
      }
    ) as Summits; 
    await summits.deployed();

    let tx = await summits.createAim(
      testAimData, 0x8000, 
      'TestToken', 'TST', 
      initialAmount, 
      {
        value: initialAmount * initialAmount
      }
    )
    let rc = await tx.wait()
    let creationEvent: any = rc.events!.find((e: any) => e.event === 'AimCreation') 
    let aimContractAddress = creationEvent.args.aimAddress
    let aimFactory = await ethers.getContractFactory("Aim");
    aim0 = aimFactory.attach(aimContractAddress)

  })

  // TBD test permissions
    // test creating permissions etc.
    // multiple users
    // test ownage transfer before implementing it - well it's prob. impl. in ownable already!

  // TBD transfer ownership only when owner 
    // permissions shouldn't change when fail 
    // permissions should be max after changed

  it("should not change any permissions if sender is not owner", async function () {
    let newOwner = addresses[2]
    let nonOwner = addresses[1]

    let previousNonOwnerPermissions = await aim0.permissions(nonOwner)
    let previousNewOwnerPermissions = await aim0.permissions(newOwner)
    let owner = await aim0.owner()

    let tx = aim0.transferOwnership(newOwner, {from: nonOwner})
    expect(tx).to.be.revertedWith('Ownable: caller is not the owner')

    let nonOwnerPermissions = await aim0.permissions(nonOwner) 
    expect(nonOwnerPermissions).to.equal(previousNonOwnerPermissions)

    let newOwnerPermissions = await aim0.permissions(newOwner)
    expect(newOwnerPermissions).to.equal(previousNewOwnerPermissions) 

    expect(await aim0.owner()).to.equal(owner)
  }) 

  it("should give the transferrer all possible permissions after transferring", async function () {
    let owner = addresses[0]
    let newOwner = addresses[1]

    expect(await aim0.owner()).to.equal(owner)
    let previousNewOwnerPermissions = await aim0.permissions(newOwner)

    let tx = await aim0.transferOwnership(newOwner, {from: owner})
    await tx.wait() 

    let oldOwnerPermissions = await aim0.permissions(owner)
    expect(oldOwnerPermissions).to.equal(0x7f) 

    let newOwnerPermissions = await aim0.permissions(newOwner)
    expect(newOwnerPermissions).to.equal(previousNewOwnerPermissions) // permissions are not changed

    expect(await aim0.owner()).to.equal(newOwner) // but he is the new owner
  }) 
})
