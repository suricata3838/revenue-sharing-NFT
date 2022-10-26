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

/*
 * Recent contract address on Goerli
 **/
//  PASS: 0x9EE05d60d3FAf8735e9fd9CC68E3f9F25537Cd84
//  latest PASS: 0xacad68aF067A557092634c6d5Bc528db27B613e6