const hre = require("hardhat");

const name = "MitamaHolderPass"
const symbol = "MHP"
const test_baseURI = "https://raw.githubusercontent.com/suricata3838/revenue-sharing-NFT/main/ipfs/holderPass_metadata/"
const baseURI = "ipfs://QmcbszmyqbrgSvihEhEDG1YbzKguwkMbT6Ed4Zz2jhxcse/"
// `baseURI` + gold = metadata of the gold pass
// `baseURI` + silver = metadata of the silver pass

const arguments = [
    name,
    symbol,
    baseURI
]
module.exports = [
    ...arguments
]

async function deployHolderPass () {
    const [deployer] = await hre.ethers.getSigners();
    const HolderPass = await hre.ethers.getContractFactory("HolderPass");
    const holderPass = await HolderPass.deploy(
        name,symbol, baseURI);
    await holderPass.deployed();
    console.log("Contract deployed to:", holderPass.address, "from ", deployer.address);
}

const main = async () => {
    try{
        await deployHolderPass();
    }catch(e){
        console.error(e);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

/**
 * on Mumbai
 */
// https://mumbai.polygonscan.com/address/0x48056293f0DE95B674eD7F8Ef56483Da088D3272#code
// Latest: https://mumbai.polygonscan.com/address/0x6f55804B6EFD2c107adFC202dB05e10a5DbA38F1#code