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
        const contract = await HTLC.deploy(whiteHat.address, mitama.address, newOwner.address)
        await contract.deployed();

        await contract.fund({ value: ethers.utils.parseEther('20') })
        
        assert.equal((await contract.amount()).toString(), ethers.utils.parseEther('20'), 'amount should be correct')

        await expect(contract.connect(accounts[1]).fund({ value: ethers.utils.parseEther('20') })).to.be.rejected

        await mitama.connect(whiteHat).transferOwnership(contract.address)

        await expect(contract.withdraw()).to.be.rejectedWith('Only Provided address can withdraw...')
        await contract.connect(whiteHat).withdraw()

        assert.equal((await contract.amount()).toString(), '0', 'amount should be zero')
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
      const contract = await HTLC.deploy(whiteHat.address, mitama.address, newOwner.address)
      await contract.deployed();

      await contract.fund({ value: ethers.utils.parseEther('20') })
      const ownerBalance = await accounts[0].getBalance()
      
      assert.equal((await contract.amount()).toString(), ethers.utils.parseEther('20'), 'amount should be correct')

      await expect(contract.connect(accounts[1]).fund({ value: ethers.utils.parseEther('20') })).to.be.rejected

      await mitama.connect(whiteHat).transferOwnership(contract.address)

      await expect(contract.resetContractOwnerAndRefund()).to.be.rejectedWith('too early')
      await expect(contract.refund()).to.be.rejectedWith('too early')

      // increase block.timestamp
      await ethers.provider.send("evm_increaseTime", [172800])
      await contract.resetContractOwnerAndRefund()
      assert.equal((await contract.amount()).toString(), '0', 'amount should be correct')

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
      const contract = await HTLC.deploy(whiteHat.address, mitama.address, newOwner.address)
      await contract.deployed();

      await contract.fund({ value: ethers.utils.parseEther('20') })
      const ownerBalance = await accounts[0].getBalance()
      
      assert.equal((await contract.amount()).toString(), ethers.utils.parseEther('20'), 'amount should be correct')

      await expect(contract.connect(accounts[1]).fund({ value: ethers.utils.parseEther('20') })).to.be.rejected

      await expect(contract.resetContractOwnerAndRefund()).to.be.rejectedWith('too early')
      await expect(contract.refund()).to.be.rejectedWith('too early')

      // increase block.timestamp
      await ethers.provider.send("evm_increaseTime", [172800])
      await expect(contract.resetContractOwnerAndRefund()).to.be.rejected

      await contract.refund()
      expect((await accounts[0].getBalance()).gt(ownerBalance)).to.be.true
    })
})
