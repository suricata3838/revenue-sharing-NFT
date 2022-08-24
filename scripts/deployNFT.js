const hre = require("hardhat");

const name = "MitamaTest";
const symbol = "MTM";
const baseURI = "https://gateway.pinata.cloud/ipfs/QmXMJo4qPdobEfL75ChQFpNTm6z1DrBzNZwgtXJSmReRXx/";
const tokenPrice = hre.ethers.utils.parseEther("0.1"); //float?
const maxTokens = 100;
const maxMints = 5;

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    const DynamicNFT = await hre.ethers.getContractFactory("DynamicNFT");
    const dynamicNFT = await DynamicNFT.deploy(
        name, symbol, baseURI, tokenPrice, maxTokens, maxMints);
    await dynamicNFT.deployed();

    console.log("Contract deployed to:", dynamicNFT.address, "from ", deployer.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });