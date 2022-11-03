const { ethers } = require('hardhat')
const { utils }  = require ("ethers");

/**
 * Scenario
 */
//  1) Deploy original Mitama contract and the swap contract
//  2) "Steal" the Mitama contract via a second wallet
//  3) Test:
//    a) That you can correctly recover ownership from the hacker via the swap contract
//    b) That the hacker can't steal your ransom without giving back ownership
//    c) That some other third party wallet can't disrupt the process (steal funds / ownership)
//    d) That the time lock mechanisms work

const main = async () => {
    const accounts = await ethers.getSigners()
    console.log()

    const Mitama = await ethers.getContractFactory("Mitama")
    const mitama = await Mitama.deploy("TEST_URI")
    await mitama.deployed()

    // const SwapOwnership = await ethers.getContractFactory("SwapOwnership")
    // const swapOwnership = await SwapOwnership.deploy(mitama.address, accounts[1])
    // await swapOwnership.deployed()
    // console.log(swapOwnership.address)

    // await swapOwnership.claimBounty();    

}

main()






