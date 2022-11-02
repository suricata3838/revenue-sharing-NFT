const hre = require("hardhat");

async function deploySwapOwnership() {
    const [deployer] = await hre.ethers.getSigners();
    const SwapOwnership = await hre.ethers.getContractFactory("SwapOwnership");
    const swapOwnership = await SwapOwnership.deploy(); 
    console.log("SwapOwnership txHash:", swapOwnership.deployTransaction.hash);
    await swapOwnership.deployed();
    console.log("Contract deployed to:", swapOwnership.address, "from ", swapOwnership.address);
}

deploySwapOwnership();