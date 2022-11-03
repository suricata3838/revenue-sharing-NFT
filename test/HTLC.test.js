const { expect, use, assert } = require('chai')
const { BigNumber } = require('ethers')
const { ethers } = require('hardhat')
const { keccak256 } = ethers.utils

use(require('chai-as-promised'))

describe('HTLC', () => {
    it('test transfer ownership', async () => {
        const accounts = await ethers.getSigners()

        const whiteHat = accounts[2]
        const newOwner = accounts[1]
        
        const Mitama = await ethers.getContractFactory("Mitama")
        const mitama = await Mitama.connect(whiteHat).deploy('abc')
        await mitama.deployed();

        const HTLC = await ethers.getContractFactory("HTLC")
        const htlc = await HTLC.deploy(whiteHat.address, mitama.address, newOwner.address)
        await htlc.deployed();

        await htlc.fund({ value: ethers.utils.parseEther('20') })
        
        assert.equal((await htlc.amount()).toString(), ethers.utils.parseEther('20'), 'amount should be correct')

        await expect(htlc.connect(accounts[1]).fund({ value: ethers.utils.parseEther('0.1') })).to.be.rejectedWith('Ownable: caller is not the owner')
        await expect(htlc.connect(whiteHat).withdraw()).to.be.rejectedWith('Ownable: caller is not the owner')
        
        await mitama.connect(whiteHat).transferOwnership(htlc.address)

        await expect(htlc.withdraw()).to.be.rejectedWith('Only Provided address can withdraw...')
        await htlc.connect(whiteHat).withdraw()

        assert.equal((await htlc.amount()).toString(), '0', 'amount should be zero')
        assert.equal(await mitama.owner(), newOwner.address, 'new mitama owner should be set after withdrawing')
    })

    it('whitehat invoke the transferOwnerShip but not call withdraw', async () => {
      const accounts = await ethers.getSigners()

      const whiteHat = accounts[2]
      const newOwner = accounts[1]
      
      const Mitama = await ethers.getContractFactory("Mitama")
      const mitama = await Mitama.connect(whiteHat).deploy('abc')
      await mitama.deployed();

      const HTLC = await ethers.getContractFactory("HTLC")
      const htlc = await HTLC.deploy(whiteHat.address, mitama.address, newOwner.address)
      await htlc.deployed();

      await htlc.fund({ value: ethers.utils.parseEther('20') })
      const ownerBalance = await accounts[0].getBalance()
      
      assert.equal((await htlc.amount()).toString(), ethers.utils.parseEther('20'), 'amount should be correct')

      await expect(htlc.connect(accounts[1]).fund({ value: ethers.utils.parseEther('20') })).to.be.rejected

      await mitama.connect(whiteHat).transferOwnership(htlc.address)

      await expect(htlc.resetContractOwnerAndRefund()).to.be.rejectedWith('too early')
      await expect(htlc.refund()).to.be.rejectedWith('too early')

      // increase block.timestamp
      await ethers.provider.send("evm_increaseTime", [172800])
      await htlc.resetContractOwnerAndRefund()
      assert.equal((await htlc.amount()).toString(), '0', 'amount should be correct')

      assert.equal(await mitama.owner(), newOwner.address, 'new mitama owner should be set after withdrawing')
      expect((await accounts[0].getBalance()).gt(ownerBalance)).to.be.true
    })

    it('whitehat does not transfer owner ship', async () => {
      const accounts = await ethers.getSigners()

      const whiteHat = accounts[2]
      const newOwner = accounts[1]
      
      const Mitama = await ethers.getContractFactory("Mitama")
      const mitama = await Mitama.connect(whiteHat).deploy('abc')
      await mitama.deployed();

      const HTLC = await ethers.getContractFactory("HTLC")
      const htlc = await HTLC.deploy(whiteHat.address, mitama.address, newOwner.address)
      await htlc.deployed();

      await htlc.fund({ value: ethers.utils.parseEther('20') })
      const ownerBalance = await accounts[0].getBalance()
      
      assert.equal((await htlc.amount()).toString(), ethers.utils.parseEther('20'), 'amount should be correct')

      await expect(htlc.connect(accounts[1]).fund({ value: ethers.utils.parseEther('20') })).to.be.rejected

      await expect(htlc.resetContractOwnerAndRefund()).to.be.rejectedWith('too early')
      await expect(htlc.refund()).to.be.rejectedWith('too early')

      // increase block.timestamp
      await ethers.provider.send("evm_increaseTime", [172800])
      await expect(htlc.resetContractOwnerAndRefund()).to.be.rejected

      await htlc.refund()
      expect((await accounts[0].getBalance()).gt(ownerBalance)).to.be.true
    })

    it('None can transfer the ownership of HTLC contract', async () => {
        const accounts = await ethers.getSigners()

        const whiteHat = accounts[2]
        const newOwner = accounts[1]
        
        const Mitama = await ethers.getContractFactory("Mitama")
        const mitama = await Mitama.connect(whiteHat).deploy('abc')
        await mitama.deployed();
  
        const HTLC = await ethers.getContractFactory("HTLC")
        const htlc = await HTLC.deploy(whiteHat.address, mitama.address, newOwner.address)
        await htlc.deployed();
        
        await expect(htlc.transferOwnership(newOwner.address)).to.be.rejectedWith('Not allowed.')
    })
})
