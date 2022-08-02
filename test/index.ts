import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";

import { Summits } from '../typechain-types/contracts/Summits'

let initialAmount = BigNumber.from(123456789)
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
        value: initialAmount.pow(2) 
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
    let ia = BigNumber.from(9320)
    let tx = await summits.createAim(
      testAimData, 0x8000, 
      'TestToken', 'TST', 
      ia, 
      {
        value: ia.pow(2) 
      }
    )

    let rc = await tx.wait()
    let creationEvent: any = rc.events!.find((e: any) => e.event === 'AimCreation') 
    expect(creationEvent).to.not.be.undefined

  })

  it("should reject aim creations with value <> initial investment ** 2", function() {
    let badCreations = [
      {
        initialAmount: BigNumber.from(1000), 
        value: BigNumber.from(1000 * 1000 - 1), 
      }, 
      {
        initialAmount: BigNumber.from(2000), 
        value: BigNumber.from(2000 * 2000 + 1), 
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
    let initialAmount = BigNumber.from(123456789)

    let summitsFactory = await ethers.getContractFactory("Summits");
    let summits = await summitsFactory.deploy(
      initialAmount, 
      {
        value: initialAmount.pow(2) 
      }
    ) as Summits; 
    await summits.deployed();

    let tx = await summits.createAim(
      testAimData, 0x8000, 
      'TestToken', 'TST', 
      initialAmount, 
      {
        value: initialAmount.pow(2)
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

describe("Aim contribution confirmations", function () {
  let aims: Contract[] = []
  this.beforeEach(async function() {
    let initialAmount = BigNumber.from(123456789)

    let summitsFactory = await ethers.getContractFactory("Summits");
    let summits = await summitsFactory.deploy(
      initialAmount, 
      {
        value: initialAmount.pow(2)
      }
    ) as Summits; 
    await summits.deployed();

    for(let i = 0; i < 9; i++) {
      let tx = await summits.createAim(
        testAimData, 0x8000, 
        'TestToken', 'TST', 
        initialAmount, 
        {
          value: initialAmount.pow(2) 
        }
      )
      let rc = await tx.wait()
      let creationEvent: any = rc.events!.find((e: any) => e.event === 'AimCreation') 
      let aimContractAddress = creationEvent.args.aimAddress
      let aimFactory = await ethers.getContractFactory("Aim");
      aims.push(aimFactory.attach(aimContractAddress))
    }
  })


  it("exclude aim before confirming, include after confirming, and exclude after removing", async function () {
    expect(await aims[0].getConfirmedContributions()).to.have.lengthOf(0, "unexpected confirmed receivers")

    let tx = await aims[0].confirmContribution(aims[1].address)
    await tx.wait()

    expect(await aims[0].getConfirmedContributions()).to.have.members([aims[1].address], "after confirming 1") 

    tx = await aims[0].confirmContribution(aims[2].address)
    await tx.wait()

    expect(await aims[0].getConfirmedContributions())
      .to.have.members([aims[1].address, aims[2].address], "after confirming 2")

    tx = await aims[0].revokeContributionConfirmation(aims[1].address)
    await tx.wait()

    expect(await aims[0].getConfirmedContributions()).to.have.members([aims[2].address], "after revoking 1") 

    tx = await aims[0].confirmContribution(aims[1].address)
    await tx.wait()

    expect(await aims[0].getConfirmedContributions()).to.have.members([aims[1].address, aims[2].address], "after confirming 1 back again")

    tx = await aims[0].revokeContributionConfirmation(aims[1].address)
    let tx2 = await aims[0].revokeContributionConfirmation(aims[2].address)
    await Promise.all([tx.wait(), tx2.wait()])

    expect(await aims[0].getConfirmedContributions()).to.have.lengthOf(0, "after revoking all")
  }) 

  it("should set multiple confirmations and revoke if > 0 are not differing", async function () {
    let addrs = aims.map(a => a.address)

    expect(aims[0].setContributionConfirmations(
      addrs.slice(0, 4),
      [false, true, false, true]
    )).to.be.revertedWith('contribution not confirmed')

    let tx = await aims[0].setContributionConfirmations(
      addrs.slice(1, 4),
      [true, true, true]
    )
    await tx.wait()

    expect(await aims[0].getConfirmedContributions())
      .to.have.members([addrs[1], addrs[2], addrs[3]], "after confirming first 3")

    expect(aims[0].setContributionConfirmations(
      addrs.slice(0, 4),
      [true, true, false, true]
    )).to.be.revertedWith('contribution already confirmed');

    tx = await aims[0].setContributionConfirmations(
      [addrs[2], addrs[4]],
      [false, true]
    )
    await tx.wait()

    expect(await aims[0].getConfirmedContributions()).to.have.members([addrs[1], addrs[3], addrs[4]]) 
  })
})

//TBD: creating flows etc 

describe("Investing", function () {
  // E.g. invest from various accounts. Withdraw everything, make sure sums are equal. nothing lost. 
  let signers: SignerWithAddress[]
  let summits: Contract

  this.beforeEach(async function() {
    signers = await ethers.getSigners()

    let initialInves = BigNumber.from(3423042304)
    let summitsFactory = await ethers.getContractFactory("Summits");
    summits = await summitsFactory.deploy(
      initialInves, 
      {
        value: initialInves.pow(2) 
      }
    ) as Summits; 
    await summits.deployed();
    

  })

  it("should allow buying and selling", async function () {
    let initialInvest = BigNumber.from(123456789)

    let initialBalance = await signers[0].getBalance()

    let tx = await summits.createAim(
      testAimData, 0x8000, 
      'TestToken', 'TST', 
      initialInvest, 
      {
        value: initialInvest.pow(2) 
      }
    )
    let rc = await tx.wait()
    let gasExpenses = rc.gasUsed.mul(rc.effectiveGasPrice)
    let creationEvent: any = rc.events!.find((e: any) => e.event === 'AimCreation') 
    let aimAddr = creationEvent.args.aimAddress

    let aimFactory = await ethers.getContractFactory("Aim", signers[0]);
    let aim = aimFactory.attach(aimAddr)

    let balance = initialBalance.sub(initialInvest.pow(2))
    let tokenBalance = await aim.getInvestment()
    expect(tokenBalance, "initial token balance").to.equal(initialInvest)

    let investments = [10000, 20000, 15000].map(n => BigNumber.from(n)) 

    for(let invest of investments) {
      let totalSupply = await aim.totalSupply()
      let price = totalSupply.add(invest).pow(2)  - totalSupply.pow(2) 
      tx = await aim.buy(invest, {
        value: price
      })
      rc = await tx.wait()
      gasExpenses = gasExpenses.add(rc.effectiveGasPrice.mul(rc.gasUsed))

      tokenBalance = tokenBalance.add(invest)
      expect(await aim.getInvestment(), "token balance after invest").to.equal(tokenBalance)

      balance = balance.sub(price)
      expect(await signers[0].getBalance(), "balance after invest").to.equal(balance.sub(gasExpenses))
    }

    let totalInvest = initialInvest
    investments.forEach(a => totalInvest = totalInvest.add(a))

    expect(await aim.getInvestment(), "invest after invests")
      .to.equal(totalInvest, "total token balance")
    expect(await signers[0].getBalance(), "balance after invests")
      .to.equal(initialBalance.sub(totalInvest.pow(2)).sub(gasExpenses))

    let devestments = [1000, 5000]
    for(let devest of devestments) {
      let totalSupply = await aim.totalSupply()
      let price = totalSupply.pow(2) - totalSupply.sub(devest).pow(2) 
      tx = await aim.sell(devest, price)
      rc = await tx.wait()
      gasExpenses = gasExpenses.add(rc.effectiveGasPrice.mul(rc.gasUsed))

      tokenBalance = tokenBalance.sub(devest)
      expect(await aim.getInvestment(), "token balance after divest").to.equal(tokenBalance)

      balance = balance.add(price)
      expect(await signers[0].getBalance(), "balance after divest").to.equal(balance.sub(gasExpenses))
    }

    devestments.forEach(a => totalInvest = totalInvest.sub(a))
    expect(await signers[0].getBalance(), "total divest").
      to.equal(initialBalance.sub(totalInvest.pow(2)).sub(gasExpenses))

    // sell remaining tokens
    let totalSupply = await aim.totalSupply()
    let price = totalSupply.pow(2)
    tx = await aim.sell(totalSupply, price)
    await tx.wait()
    rc = await tx.wait()
    gasExpenses = gasExpenses.add(rc.effectiveGasPrice.mul(rc.gasUsed))

    expect(await aim.getInvestment(), "everything sold").to.equal(0)
    expect(await aim.totalSupply(), "total supply == 0").to.equal(0)

    expect(await signers[0].getBalance(), "got everything back (except gas costs of course)")
      .to.equal(initialBalance.sub(gasExpenses))
  })

  // it should fail when not enough funds are send or 
  // when min payout is not reached
  // should not be able to sell more than you have

  it("should work with multiple investors", async function () {
  }) 
})
