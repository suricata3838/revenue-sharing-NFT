const hre = require("hardhat");

const name = "HolderPass"
const symbol = "HPS"
const uri = "https://raw.githubusercontent.com/suricata3838/revenue-sharing-NFT/main/pinata/pass_meta/"

const arguments = [
    name,
    symbol,
    uri
]
module.exports = {
    arguments
}

async function deployHolderPass () {
    const [deployer] = await hre.ethers.getSigners();
    const HolderPass = await hre.ethers.getContractFactory("HolderPass");
    const holderPass = await HolderPass.deploy(
        name,symbol, uri);
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