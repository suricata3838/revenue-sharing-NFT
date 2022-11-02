const { ethers } = require('hardhat')
const { utils }  = require ("ethers");

const main = async () => {
    const accounts = await ethers.getSigners()

    const Mitama = await ethers.getContractFactory("Mitama")
    const mitama = await Mitama.deploy("TESTURI")
    await mitama.deployed()

    const SwapOwnership = await ethers.getContractFactory("SwapOwnership")
    const swapOwnership = await SwapOwnership.deploy(mitama.address, accounts[1])
    await swapOwnership.deployed()
    console.log(swapOwnership.address)

    await swapOwnership.claimBounty();    

}

main()






